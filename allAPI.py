import json
from datetime import date, datetime, timedelta
from typing import Any, Dict, List, Optional
import requests
import replay

# ─────────────────────────────────────────────────────────────────────────────
# Shared HTTP helper
# ─────────────────────────────────────────────────────────────────────────────


def get_json(url: str, params: Optional[Dict[str, Any]] = None) -> Any:
    resp = requests.get(url, params=params, timeout=30)
    resp.raise_for_status()
    return resp.json()

# ─────────────────────────────────────────────────────────────────────────────
# Category proxy APIs (Delphi / CDC)
# ─────────────────────────────────────────────────────────────────────────────

def get_respiratory_antiviral_trend(epiweeks: str = "202501-202510", region: str = "nat") -> Dict[str, Any]:
    url = "https://api.delphi.cmu.edu/epidata/fluview/"
    params = {
        "regions": region,
        "epiweeks": epiweeks,
    }
    return get_json(url, params)


def get_broad_spectrum_antibiotic_proxy(state_name: str = "Georgia", limit: int = 20) -> List[Dict[str, Any]]:
    url = "https://data.cdc.gov/resource/vjzj-u7u8.json"
    params = {
        "$select": "date, pathogen, geography, percent_visits",
        "$where": f"geography='{state_name}'",
        "$order": "date DESC",
        "$limit": limit,
    }
    return get_json(url, params)


def get_analgesics_antipyretics_trend(epiweeks: str = "202501-202510", region: str = "nat") -> Dict[str, Any]:
    url = "https://api.delphi.cmu.edu/epidata/fluview/"
    params = {
        "regions": region,
        "epiweeks": epiweeks,
    }
    return get_json(url, params)


def get_iv_fluids_proxy(state_name: str = "Georgia", limit: int = 10) -> List[Dict[str, Any]]:
    url = "https://data.cdc.gov/resource/f3zz-zga5.json"
    params = {
        "$select": "week_end, geography, label",
        "$where": f"geography='{state_name}'",
        "$order": "week_end DESC",
        "$limit": limit,
    }
    return get_json(url, params)


def get_allergy_anaphylaxis_proxy_rsv(level: str = "National", limit: int = 20) -> List[Dict[str, Any]]:
    url = "https://data.cdc.gov/resource/3cxc-4k8q.json"
    params = {
        "$select": "mmwrweek_end, level, pcr_percent_positive, percent_pos_2_week",
        "$where": f"level='{level}'",
        "$order": "mmwrweek_end DESC",
        "$limit": limit,
    }
    return get_json(url, params)


# ─────────────────────────────────────────────────────────────────────────────
# FDA national recall → risk_signal (HIGH / ELEVATED / LOW)
# ─────────────────────────────────────────────────────────────────────────────

# Map recall tier to Items.availabilityStatus ENUM (same idea as replay.AVAILABILITY_SCORE)
RISK_SIGNAL_TO_AVAILABILITY = {
    "HIGH": "shortage_risk",       # ongoing nationwide recalls in window
    "ELEVATED": "constrained",     # recalls in window, none ongoing
    "LOW": "high_availability",    # no recalls in window — supply signal calm
}


def risk_signal_to_availability(risk_signal: str) -> str:
    return RISK_SIGNAL_TO_AVAILABILITY.get(risk_signal, "unknown")


def get_national_recall_metrics(drug_name: str, days: int = 14) -> dict:
    """
    Nationwide FDA enforcement metrics for one drug name.
    - Recent window: recall_initiation_date in [today-days, today], Nationwide only.
    - All-time: meta total for Nationwide (limit=1 is enough to read meta).
    """
    end_date = datetime.today()
    start_date = end_date - timedelta(days=days)
    date_from = start_date.strftime("%Y%m%d")
    date_to = end_date.strftime("%Y%m%d")

    url = "https://api.fda.gov/drug/enforcement.json"

    params = {
        "search": (
            f'{drug_name} AND distribution_pattern:"Nationwide"'
            f" AND recall_initiation_date:[{date_from}+TO+{date_to}]"
        ),
        "limit": 100,
    }
    resp = requests.get(url, params=params, timeout=30)
    results: List[Dict[str, Any]] = []
    total = 0
    if resp.status_code == 200:
        data = resp.json()
        results = data.get("results", [])
        total = data.get("meta", {}).get("results", {}).get("total", 0)
    else:
        data = {}

    params_all = {
        "search": f'{drug_name} AND distribution_pattern:"Nationwide"',
        "limit": 1,
    }
    resp_all = requests.get(url, params=params_all, timeout=30)
    total_all_time = 0
    if resp_all.status_code == 200:
        total_all_time = resp_all.json().get("meta", {}).get("results", {}).get("total", 0)

    active = [r for r in results if r.get("status", "").lower() == "ongoing"]
    risk_signal = (
        "HIGH" if len(active) > 0 else ("ELEVATED" if total > 0 else "LOW")
    )

    return {
        "drug": drug_name,
        "window_days": days,
        "date_from": date_from,
        "date_to": date_to,
        "recent_nationwide_recalls": total,
        "active_recalls_in_window": len(active),
        "all_time_nationwide_recalls": total_all_time,
        "risk_signal": risk_signal,
        "recent_records": [
            {
                "recall_number": r.get("recall_number"),
                "status": r.get("status"),
                "reason": r.get("reason_for_recall"),
                "product": r.get("product_description"),
                "recall_initiation_date": r.get("recall_initiation_date"),
                "distribution_pattern": r.get("distribution_pattern"),
            }
            for r in results
        ],
    }


def _parse_last_update_date(last_update) -> Optional[date]:
    """Normalize serialized lastUpdate from DB to a date for staleness checks."""
    if last_update is None:
        return None
    if isinstance(last_update, datetime):
        return last_update.date()
    if isinstance(last_update, date):
        return last_update
    s = str(last_update).replace("Z", "+00:00")
    try:
        return datetime.fromisoformat(s).date()
    except ValueError:
        return None


def _all_items_refreshed_today(items: List[dict]) -> bool:
    """Your original idea: skip work if every row already has lastUpdate = today."""
    if not items:
        return True
    today = datetime.now().date()
    for row in items:
        d = _parse_last_update_date(row.get("lastUpdate"))
        if d is None or d != today:
            return False
    return True


def sync_recall_availability_from_fda(force: bool = False, days: int = 14) -> dict:
    """
    Pull FDA recall metrics for each Items row and map risk_signal → availabilityStatus.

    - If not force and every item was already updated today, skip (timer-friendly).
    - Updates lastUpdate on each row when a row is successfully processed.
    """
    items = replay.get_all_items()
    if not items:
        return {"ok": True, "skipped": False, "updated": 0, "message": "no items"}

    if not force and _all_items_refreshed_today(items):
        return {
            "ok": True,
            "skipped": True,
            "updated": 0,
            "message": "all items already refreshed today",
        }

    details = []
    errors = []
    for item in items:
        itemid = item["itemid"]
        name = item["itemName"]
        try:
            metrics = get_national_recall_metrics(name, days=days)
            avail = risk_signal_to_availability(metrics["risk_signal"])
            replay.update_item_availability(itemid, avail)
            details.append(
                {
                    "itemid": itemid,
                    "itemName": name,
                    "risk_signal": metrics["risk_signal"],
                    "availabilityStatus": avail,
                    "recent_nationwide_recalls": metrics["recent_nationwide_recalls"],
                }
            )
        except Exception as ex:  # noqa: BLE001 — log and continue
            errors.append({"itemName": name, "error": str(ex)})

    return {
        "ok": len(errors) == 0,
        "skipped": False,
        "updated": len(details),
        "errors": errors,
        "details": details,
    }


# ─────────────────────────────────────────────────────────────────────────────
# CLI: proxy smoke test + optional JSON dump of recall metrics (no DB write)
# ─────────────────────────────────────────────────────────────────────────────

MEDICATIONS = [
    "oseltamivir",
    "zanamivir",
    "peramivir",
    "baloxavir",
    "ceftriaxone",
    "azithromycin",
    "levofloxacin",
    "vancomycin",
    "acetaminophen",
    "ibuprofen",
    "naproxen",
    "aspirin",
    "epinephrine",
    "diphenhydramine",
    "cetirizine",
    "methylprednisolone",
]


if __name__ == "__main__":
    output = {
        "1_respiratory_antivirals": get_respiratory_antiviral_trend(),
        "2_broad_spectrum_antibiotic_proxy": get_broad_spectrum_antibiotic_proxy(),
        "3_analgesics_antipyretics": get_analgesics_antipyretics_trend(),
        "4_iv_fluids_proxy": get_iv_fluids_proxy(),
        "5_allergy_anaphylaxis_proxy_rsv": get_allergy_anaphylaxis_proxy_rsv(),
    }
    with open("medication.json", "w", encoding="utf-8") as f:
        json.dump(output, f, indent=2)
    print("Written proxy sample to medication.json")

    recall_out = {}
    for drug in MEDICATIONS:
        print(f"Fetching recall metrics: {drug}...")
        recall_out[drug] = get_national_recall_metrics(drug, days=14)
    with open("nationalAbundance.json", "w", encoding="utf-8") as f:
        json.dump(recall_out, f, indent=2)
    print("Written nationalAbundance.json (metrics only; no DB update)")
