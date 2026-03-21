# from openai import OpenAI
# client = OpenAI(
#     base_url="http://localhost:11434/v1",
#     api_key="ollama"  # Required by the SDK but Ollama ignores it
# )
# response = client.chat.completions.create(
#     model="llama3.2",  # Whatever model you've pulled
#     messages=[
#         {"role": "user", "content": "What is the capital of France?"}
#     ]
# )
# print(response.choices[0].message.content)

# prepJSON = """
# {
#   "therapeutic_categories": [
#     {
#       "id": "respiratory_antivirals",
#       "display_name": "Respiratory Antivirals",
#       "associated_conditions": ["influenza", "respiratory viral illness"],
#       "medications": [
#         "oseltamivir",
#         "zanamivir",
#         "peramivir",
#         "baloxavir"
#       ]
#     },
#     {
#       "id": "broad_spectrum_antibiotics",
#       "display_name": "Broad-Spectrum Antibiotics",
#       "associated_conditions": ["bacterial infection", "pneumonia", "sepsis"],
#       "medications": [
#         "ceftriaxone",
#         "azithromycin",
#         "levofloxacin",
#         "piperacillin_tazobactam",
#         "amoxicillin_clavulanate",
#         "vancomycin"
#       ]
#     },
#     {
#       "id": "analgesics_antipyretics",
#       "display_name": "Pain and Fever Management",
#       "associated_conditions": ["fever", "pain", "inflammation"],
#       "medications": [
#         "acetaminophen",
#         "ibuprofen",
#         "naproxen",
#         "ketorolac",
#         "aspirin"
#       ]
#     },
#     {
#       "id": "iv_fluids",
#       "display_name": "Intravenous Fluids",
#       "associated_conditions": ["dehydration", "shock", "electrolyte imbalance"],
#       "medications": [
#         "normal_saline",
#         "lactated_ringers",
#         "dextrose_5_percent",
#         "dextrose_saline",
#         "plasma_lyte"
#       ]
#     },
#     {
#       "id": "allergy_anaphylaxis_treatments",
#       "display_name": "Allergy and Anaphylaxis Treatments",
#       "associated_conditions": ["severe allergy", "anaphylaxis"],
#       "medications": [
#         "epinephrine",
#         "diphenhydramine",
#         "cetirizine",
#         "famotidine",
#         "methylprednisolone"
#       ]
#     }
#   ]
# }
# """

# import requests
# import json
# from typing import Any, Dict, List, Optional

# # -----------------------------
# # Helpers
# # -----------------------------

# def get_json(url: str, params: Optional[Dict[str, Any]] = None) -> Any:
#     resp = requests.get(url, params=params, timeout=30)
#     resp.raise_for_status()
#     return resp.json()


# # -----------------------------
# # 1) Respiratory antivirals
# # Strongest external signal:
# # Delphi FluView (ILI / influenza activity)
# # Example docs show:
# # https://api.delphi.cmu.edu/epidata/fluview/?regions=nat&epiweeks=...
# # -----------------------------
# def get_respiratory_antiviral_trend(epiweeks: str = "202501-202510", region: str = "nat") -> Dict[str, Any]:
#     url = "https://api.delphi.cmu.edu/epidata/fluview/"
#     params = {
#         "regions": region,        # e.g. nat, hhs4, cen, etc.
#         "epiweeks": epiweeks      # e.g. 202501-202510
#     }
#     return get_json(url, params)


# # -----------------------------
# # 2) Broad-spectrum antibiotics
# # Practical proxy:
# # CDC NSSP Emergency Department Respiratory Daily dataset
# # You can use respiratory burden as a pressure signal for
# # pneumonia / secondary infection load.
# # -----------------------------
# def get_broad_spectrum_antibiotic_proxy(state_name: str = "Georgia", limit: int = 20) -> List[Dict[str, Any]]:
#     url = "https://data.cdc.gov/resource/vjzj-u7u8.json"
#     params = {
#         "$select": "date, pathogen, geography, percent_visits",
#         "$where": f"geography='{state_name}'",
#         "$order": "date DESC",
#         "$limit": limit
#     }
#     return get_json(url, params)


# # -----------------------------
# # 3) Analgesics / antipyretics
# # Practical proxy:
# # same influenza / ILI activity, since fever reducers
# # often move with seasonal respiratory illness.
# # -----------------------------
# def get_analgesics_antipyretics_trend(epiweeks: str = "202501-202510", region: str = "nat") -> Dict[str, Any]:
#     url = "https://api.delphi.cmu.edu/epidata/fluview/"
#     params = {
#         "regions": region,
#         "epiweeks": epiweeks
#     }
#     return get_json(url, params)


# # -----------------------------
# # 4) IV fluids
# # Practical proxy:
# # ARI activity by state or broader respiratory burden.
# # This is not a direct IV-fluid API, just a system stress proxy.
# # -----------------------------
# def get_iv_fluids_proxy(state_name: str = "Georgia", limit: int = 10) -> List[Dict[str, Any]]:
#     url = "https://data.cdc.gov/resource/f3zz-zga5.json"
#     params = {
#         "$select": "week_end, geography, label",
#         "$where": f"geography='{state_name}'",
#         "$order": "week_end DESC",
#         "$limit": limit
#     }
#     return get_json(url, params)


# # -----------------------------
# # 5) Allergy / anaphylaxis treatments
# # Honest answer:
# # there is no equally strong direct public API here.
# # For a hackathon, use RSV or seasonal respiratory signals,
# # OR keep this category mostly inventory-driven.
# # If you still want an external signal example, here is RSV.
# # -----------------------------
# def get_allergy_anaphylaxis_proxy_rsv(level: str = "National", limit: int = 20) -> List[Dict[str, Any]]:
#     url = "https://data.cdc.gov/resource/3cxc-4k8q.json"
#     params = {
#         "$select": "mmwrweek_end, level, pcr_percent_positive, percent_pos_2_week",
#         "$where": f"level='{level}'",
#         "$order": "mmwrweek_end DESC",
#         "$limit": limit
#     }
#     return get_json(url, params)


# if __name__ == "__main__":
#     output = {
#         "1_respiratory_antivirals": get_respiratory_antiviral_trend(),
#         "2_broad_spectrum_antibiotic_proxy": get_broad_spectrum_antibiotic_proxy(),
#         "3_analgesics_antipyretics": get_analgesics_antipyretics_trend(),
#         "4_iv_fluids_proxy": get_iv_fluids_proxy(),
#         "5_allergy_anaphylaxis_proxy_rsv": get_allergy_anaphylaxis_proxy_rsv(),
#     }
#     with open("medication.json", "w") as f:
#         json.dump(output, f, indent=2)
#     print("Written to medication.json")

import requests
import json
from datetime import datetime, timedelta

MEDICATIONS = [
    "oseltamivir", "zanamivir", "peramivir", "baloxavir",
    "ceftriaxone", "azithromycin", "levofloxacin", "vancomycin",
    "acetaminophen", "ibuprofen", "naproxen", "aspirin",
    "epinephrine", "diphenhydramine", "cetirizine", "methylprednisolone",
]

def get_national_recall_metrics(drug_name: str, days: int = 7) -> dict:
    """
    Returns nationwide recall/enforcement metrics for a drug over the last `days` days.
    Uses recall_initiation_date range + nationwide distribution filter.
    Falls back to all-time nationwide count if no recent records found.
    """
    end_date = datetime.today()
    start_date = end_date - timedelta(days=days)
    date_from = start_date.strftime("%Y%m%d")
    date_to = end_date.strftime("%Y%m%d")

    url = "https://api.fda.gov/drug/enforcement.json"

    # Recent 7-day window, nationwide only
    params = {
        "search": (
            f'{drug_name} AND distribution_pattern:"Nationwide"'
            f' AND recall_initiation_date:[{date_from}+TO+{date_to}]'
        ),
        "limit": 100,
    }
    resp = requests.get(url, params=params)
    if resp.status_code == 200:
        data = resp.json()
        results = data.get("results", [])
        total = data["meta"]["results"]["total"]
    else:
        results = []
        total = 0

    # All-time nationwide count for context
    params_all = {
        "search": f'{drug_name} AND distribution_pattern:"Nationwide"',
        "limit": 1,
    }
    resp_all = requests.get(url, params=params_all)
    total_all_time = 0
    if resp_all.status_code == 200:
        total_all_time = resp_all.json()["meta"]["results"]["total"]

    active = [r for r in results if r.get("status", "").lower() == "ongoing"]

    return {
        "drug": drug_name,
        "window_days": days,
        "date_from": date_from,
        "date_to": date_to,
        "recent_nationwide_recalls": total,
        "active_recalls_in_window": len(active),
        "all_time_nationwide_recalls": total_all_time,
        "risk_signal": "HIGH" if len(active) > 0 else ("ELEVATED" if total > 0 else "LOW"),
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


if __name__ == "__main__":
    output = {}
    for drug in MEDICATIONS:
        print(f"Fetching: {drug}...")
        output[drug] = get_national_recall_metrics(drug, days=7)

    with open("medication.json", "w") as f:
        json.dump(output, f, indent=2)
    print("Written to medication.json")