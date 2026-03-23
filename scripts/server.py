"""
Bridge: watches a JSON file (e.g. written by Arduino tooling) and POSTs each event to PharmaFlow.

Runs on the machine next to the hardware (or anywhere). The Flask app can be on another
computer — set PHARMAFLOW_NGROK_BASE or PHARMAFLOW_SCAN_URL to your ngrok URL.

Local dev (Flask on same machine):
  python scripts/server.py

Remote Flask via ngrok (on the bridge computer):
  export PHARMAFLOW_NGROK_BASE="https://YOUR-SUBDOMAIN.ngrok-free.app"
  python scripts/server.py

Or full URL override:
  export PHARMAFLOW_SCAN_URL="https://YOUR-SUBDOMAIN.ngrok-free.app/api/event"

The watched file should contain ONE JSON object — the inner "event" payload, e.g.:
{
  "itemid": 1,
  "eventType": "usage",
  "batchNumber": 1001,
  "quantityDelta": -1,
  "expirationDate": "2026-03-28",
  "locationid": 1
}

Flask wraps it as {"event": <that object>}. eventTime is set on the server (NOW()).

Env:
  PHARMAFLOW_EVENTS_FILE  — default: events.json
  PHARMAFLOW_NGROK_BASE   — e.g. https://abc.ngrok-free.app (path /api/event is appended)
  PHARMAFLOW_SCAN_URL     — full POST URL if set (overrides base + default)
"""
from __future__ import annotations

import json
import os
import ssl
import time
import urllib.error
import urllib.request

FILE_PATH = os.environ.get("PHARMAFLOW_EVENTS_FILE", "events.json")


def resolve_api_url() -> str:
    """POST target for /api/event — localhost for dev, ngrok URL on the bridge PC."""
    explicit = os.environ.get("PHARMAFLOW_SCAN_URL", "").strip()
    if explicit:
        return explicit
    base = os.environ.get("PHARMAFLOW_NGROK_BASE", "").strip()
    if base:
        return base.rstrip("/") + "/api/event"
    return "http://127.0.0.1:5000/api/event"


API_URL = resolve_api_url()


def _request_headers() -> dict[str, str]:
    h = {
        "Content-Type": "application/json",
        "User-Agent": "PharmaFlow-bridge/1.0",
    }
    # ngrok free tier: avoids interstitial HTML on automated requests
    if "ngrok" in API_URL.lower():
        h["ngrok-skip-browser-warning"] = "true"
    return h


def send_event(event: dict) -> None:
    payload = {"event": event}
    data = json.dumps(payload).encode("utf-8")

    req = urllib.request.Request(
        API_URL,
        data=data,
        headers=_request_headers(),
        method="POST",
    )

    # Allow ngrok HTTPS (use system CAs)
    ctx = ssl.create_default_context()
    try:
        with urllib.request.urlopen(req, timeout=30, context=ctx) as response:
            body = response.read().decode("utf-8", errors="replace")
            print("Sent:", event, "->", response.status, body)
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8", errors="replace")
        print(f"HTTP {e.code} from {API_URL}: {err_body[:500]}")
        raise
    except urllib.error.URLError as e:
        print(f"Connection error to {API_URL}: {e}")
        raise


def process_file() -> None:
    try:
        with open(FILE_PATH, encoding="utf-8") as f:
            content = f.read().strip()

        if not content:
            return

        event = json.loads(content)
        if not isinstance(event, dict):
            raise TypeError("JSON root must be an object")

        send_event(event)

        with open(FILE_PATH, "w", encoding="utf-8") as f:
            f.write("")

    except json.JSONDecodeError as e:
        print(f"Invalid JSON in {FILE_PATH}: {e}")
    except Exception as e:
        print(f"Error processing file: {e}")


if __name__ == "__main__":
    print(f"Watching {FILE_PATH!r}")
    print(f"POST -> {API_URL}")
    if "ngrok" in API_URL.lower():
        print("  (ngrok: ensure Flask is running on the server and `ngrok http 5000` points to it)")
    else:
        print("  (set PHARMAFLOW_NGROK_BASE or PHARMAFLOW_SCAN_URL to reach a remote Flask)")

    while True:
        process_file()
        time.sleep(5)
