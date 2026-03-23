import json
import os
import threading
import time
from concurrent.futures import ThreadPoolExecutor

from flask import Flask, jsonify, render_template, request

from allAPI import sync_recall_availability_from_fda
from ollama import justify_inventory_health, justify_readiness, readinessCalculator
from replay import arduino_to_db, get_recent_inventory_events, run_replay

app = Flask(__name__, template_folder="Templates")

# Max parallel Ollama requests (HTTP I/O-bound; tune down if GPU queue saturates)
OLLAMA_MAX_WORKERS = 3

# Background FDA sync interval (seconds). Env: PHARMAFLOW_RECALL_SYNC_SEC
RECALL_SYNC_INTERVAL_SEC = int(os.environ.get("PHARMAFLOW_RECALL_SYNC_SEC", "3600"))

# Injected into templates — refreshed after recall sync + replay
REPLAY_JSON = "null"
AI_DATA_JSON = "[]"
INVENTORY_SUMMARY_TEXT = ""


def _readiness_with_justification(replayed, catagory_id):
    readiness = readinessCalculator(replayed, catagory_id)
    readiness["justification"] = justify_readiness(readiness)
    return readiness


def rebuild_projection_data() -> None:
    """Re-run replay + Ollama from DB and refresh cached JSON globals."""
    global REPLAY_JSON, AI_DATA_JSON, INVENTORY_SUMMARY_TEXT

    print("Running replay from database...")
    result = run_replay()
    result["currentStates"].sort(key=lambda x: x["demand_score"], reverse=True)

    cats = result["categories"]
    cat_ids = [c["catagoryid"] for c in cats]

    print("Generating AI readiness summaries (Ollama, parallel)...")
    if not cat_ids:
        ai_data = []
    else:
        workers = min(OLLAMA_MAX_WORKERS, len(cat_ids))
        with ThreadPoolExecutor(max_workers=workers) as pool:
            ai_data = list(
                pool.map(lambda cid: _readiness_with_justification(result, cid), cat_ids)
            )

    ai_data.sort(key=lambda x: x["readiness_score"])

    print("Generating inventory health summary (Ollama)...")
    try:
        INVENTORY_SUMMARY_TEXT = justify_inventory_health(result)
    except Exception as ex:  # noqa: BLE001
        print(f"  Inventory summary fallback (Ollama unavailable): {ex}")
        exp = result.get("inventoryExpirySummary") or {}
        n = len(result.get("currentStates") or [])
        INVENTORY_SUMMARY_TEXT = (
            f"{n} medications tracked across {len(cats)} categories. "
            f"Expiry snapshot: {exp.get('near_qty', 0)} units nearing expiry, "
            f"{exp.get('expired_qty', 0)} expired. "
            "Start Ollama for an AI-generated narrative in this section."
        )

    REPLAY_JSON = json.dumps(result)
    AI_DATA_JSON = json.dumps(ai_data)


def _initial_fda_sync() -> None:
    """Pull FDA recall metrics → DB before first replay (skips if already fresh today)."""
    try:
        print("FDA recall sync (openFDA)…")
        out = sync_recall_availability_from_fda(force=False)
        if out.get("skipped"):
            print(f"  {out.get('message')}")
        else:
            print(f"  updated {out.get('updated')} item(s); ok={out.get('ok')}")
            if out.get("errors"):
                print(f"  warnings: {len(out['errors'])} row(s) failed")
    except Exception as ex:  # noqa: BLE001 — startup must not crash if FDA is down
        print(f"  FDA sync skipped (offline or error): {ex}")


def _background_recall_loop() -> None:
    """Periodic sync + replay refresh when new recall data lands."""
    while True:
        time.sleep(RECALL_SYNC_INTERVAL_SEC)
        try:
            out = sync_recall_availability_from_fda(force=False)
            if out.get("skipped"):
                continue
            if out.get("updated", 0) > 0:
                print("[recall-sync] DB updated; rebuilding projection…")
                rebuild_projection_data()
                print("[recall-sync] projection refreshed.")
        except Exception as ex:  # noqa: BLE001
            print(f"[recall-sync] error: {ex}")


# ── Startup ───────────────────────────────────────────────────────────────────
_initial_fda_sync()
rebuild_projection_data()

_bg = threading.Thread(
    target=_background_recall_loop, daemon=True, name="pharmaflow-recall-sync"
)
_bg.start()


def _render(template):
    return render_template(
        template,
        replay_data=REPLAY_JSON,
        ai_data=AI_DATA_JSON,
        inventory_summary=INVENTORY_SUMMARY_TEXT,
    )


# ── Routes ─────────────────────────────────────────────────────────────────────
@app.route("/api/event", methods=["POST"])
def smartBinScan():
    """
    Hardware / bridge POST. Body: {"event": { ... }} — see replay.arduino_to_db docstring.

    Inserts only — does not run replay or Ollama (fast for live demos). Refresh dashboards
    via /api/refresh-recalls or restart the app if you need projection data updated.
    """
    data = request.get_json(silent=True)
    if not isinstance(data, dict) or "event" not in data:
        return (
            jsonify(
                {
                    "ok": False,
                    "error": 'Body must be JSON with an "event" object (see replay.arduino_to_db).',
                }
            ),
            400,
        )
    try:
        arduino_to_db(data["event"])
    except (ValueError, KeyError, TypeError) as ex:
        return jsonify({"ok": False, "error": str(ex)}), 400
    except Exception as ex:  # noqa: BLE001 — DB / driver errors
        return jsonify({"ok": False, "error": str(ex)}), 500

    return jsonify({"ok": True, "message": "success"}), 200

@app.route("/")
def inventory():
    return _render("inventory.html")


@app.route("/readiness")
def readiness():
    return _render("preditition.html")


@app.route("/category")
def category():
    return _render("catagory.html")


@app.route("/medication")
def medication():
    return _render("medicine.html")


@app.route("/demo/inventory-event-log")
def inventory_event_log_demo():
    """Latest 5 inventory events from DB (fresh query on each request)."""
    events = get_recent_inventory_events(5)
    return render_template("hw_inventory_log_demo.html", events=events)


@app.route("/api/refresh-recalls")
def api_refresh_recalls():
    """
    Manual trigger: force FDA sync + full replay + Ollama rebuild.
    Query: ?force=1 — skip the 'already refreshed today' guard.
    """
    force = request.args.get("force", "0") == "1"
    try:
        out = sync_recall_availability_from_fda(force=force)
        rebuild_projection_data()
        return jsonify({"ok": True, "sync": out, "message": "projection rebuilt"})
    except Exception as ex:  # noqa: BLE001
        return jsonify({"ok": False, "error": str(ex)}), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
