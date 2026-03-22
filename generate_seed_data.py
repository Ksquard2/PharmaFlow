import json
from datetime import date, timedelta

# ─────────────────────────────────────────
# TABLE 1 — categories
# ─────────────────────────────────────────
categories = [
    {
        "catagoryid": 1,
        "catagoryName": "Respiratory Antivirals",
        "trendStrength": -0.52,
        "endpoint": "https://api.delphi.cmu.edu/epidata/fluview/",
        "parameters": {"regions": "nat", "epiweeks": "202501-202510"},
    },
    {
        "catagoryid": 2,
        "catagoryName": "Broad Spectrum Antibiotics",
        "trendStrength": -0.18,
        "endpoint": "https://data.cdc.gov/resource/vjzj-u7u8.json",
        "parameters": {
            "$select": "date, pathogen, geography, percent_visits",
            "$where": "geography='Georgia' AND pathogen='ARI'",
            "$order": "date DESC",
            "$limit": 30,
        },
    },
    {
        "catagoryid": 3,
        "catagoryName": "Analgesics and Antipyretics",
        "trendStrength": -0.46,
        "endpoint": "https://api.delphi.cmu.edu/epidata/fluview/",
        "parameters": {"regions": "nat", "epiweeks": "202501-202510"},
    },
    {
        "catagoryid": 4,
        "catagoryName": "Allergy and Anaphylaxis Treatments",
        "trendStrength": 0.31,
        "endpoint": "https://data.cdc.gov/resource/3cxc-4k8q.json",
        "parameters": {
            "$select": "mmwrweek_end, level, pcr_percent_positive, percent_pos_2_week",
            "$where": "level='National'",
            "$order": "mmwrweek_end DESC",
            "$limit": 20,
        },
    },
]

# ─────────────────────────────────────────
# TABLE 2 — items
# Availability score rationale:
#   all_time_nationwide_recalls from nationalAbundance.json
#   methylprednisolone=364 → constrained
#   acetaminophen=199, epinephrine=109, vancomycin=87 → moderate
#   all others → high
# ─────────────────────────────────────────
items = [
    # Respiratory Antivirals (catagoryID 1)
    {"itemid":  1, "itemName": "oseltamivir",       "unitType": "capsules",          "catagoryID": 1, "availabilityStatus": "high_availability",     "lastUpdate": "2026-03-21 06:00:00"},
    {"itemid":  2, "itemName": "zanamivir",          "unitType": "inhalation_powder", "catagoryID": 1, "availabilityStatus": "high_availability",     "lastUpdate": "2026-03-21 06:00:00"},
    {"itemid":  3, "itemName": "peramivir",          "unitType": "vials",             "catagoryID": 1, "availabilityStatus": "high_availability",     "lastUpdate": "2026-03-21 06:00:00"},
    {"itemid":  4, "itemName": "baloxavir",          "unitType": "tablets",           "catagoryID": 1, "availabilityStatus": "high_availability",     "lastUpdate": "2026-03-21 06:00:00"},
    # Broad Spectrum Antibiotics (catagoryID 2)
    {"itemid":  5, "itemName": "ceftriaxone",        "unitType": "vials",             "catagoryID": 2, "availabilityStatus": "high_availability",     "lastUpdate": "2026-03-21 06:00:00"},
    {"itemid":  6, "itemName": "azithromycin",       "unitType": "tablets",           "catagoryID": 2, "availabilityStatus": "high_availability",     "lastUpdate": "2026-03-21 06:00:00"},
    {"itemid":  7, "itemName": "levofloxacin",       "unitType": "tablets",           "catagoryID": 2, "availabilityStatus": "high_availability",     "lastUpdate": "2026-03-21 06:00:00"},
    {"itemid":  8, "itemName": "vancomycin",         "unitType": "vials",             "catagoryID": 2, "availabilityStatus": "moderate_availability", "lastUpdate": "2026-03-21 06:00:00"},
    # Analgesics and Antipyretics (catagoryID 3)
    {"itemid":  9, "itemName": "acetaminophen",      "unitType": "tablets",           "catagoryID": 3, "availabilityStatus": "moderate_availability", "lastUpdate": "2026-03-21 06:00:00"},
    {"itemid": 10, "itemName": "ibuprofen",          "unitType": "tablets",           "catagoryID": 3, "availabilityStatus": "moderate_availability", "lastUpdate": "2026-03-21 06:00:00"},
    {"itemid": 11, "itemName": "naproxen",           "unitType": "tablets",           "catagoryID": 3, "availabilityStatus": "high_availability",     "lastUpdate": "2026-03-21 06:00:00"},
    {"itemid": 12, "itemName": "aspirin",            "unitType": "tablets",           "catagoryID": 3, "availabilityStatus": "high_availability",     "lastUpdate": "2026-03-21 06:00:00"},
    # Allergy and Anaphylaxis (catagoryID 4)
    {"itemid": 13, "itemName": "epinephrine",        "unitType": "vials",             "catagoryID": 4, "availabilityStatus": "moderate_availability", "lastUpdate": "2026-03-21 06:00:00"},
    {"itemid": 14, "itemName": "diphenhydramine",    "unitType": "vials",             "catagoryID": 4, "availabilityStatus": "high_availability",     "lastUpdate": "2026-03-21 06:00:00"},
    {"itemid": 15, "itemName": "cetirizine",         "unitType": "tablets",           "catagoryID": 4, "availabilityStatus": "high_availability",     "lastUpdate": "2026-03-21 06:00:00"},
    {"itemid": 16, "itemName": "methylprednisolone", "unitType": "vials",             "catagoryID": 4, "availabilityStatus": "constrained",           "lastUpdate": "2026-03-21 06:00:00"},
]

# ─────────────────────────────────────────
# TABLE 3 — locations
# 4 hospital departments + 3 pharmacy/distributors
# ─────────────────────────────────────────
locations = [
    {"locationid": 1, "locationType": "hospital", "locationName": "Emergency Department"},
    {"locationid": 2, "locationType": "hospital", "locationName": "Intensive Care Unit"},
    {"locationid": 3, "locationType": "hospital", "locationName": "General Medical Ward"},
    {"locationid": 4, "locationType": "hospital", "locationName": "Surgical Ward"},
    {"locationid": 5, "locationType": "pharmacy", "locationName": "Cardinal Health - Atlanta Distribution Center"},
    {"locationid": 6, "locationType": "pharmacy", "locationName": "McKesson Southeast Regional Warehouse"},
    {"locationid": 7, "locationType": "pharmacy", "locationName": "AmerisourceBergen Fulfillment Center"},
]

# ─────────────────────────────────────────
# TABLE 4 — patient visits
# 30 days: Feb 20 – Mar 21, 2026
# visitNumber = estimated daily patient count for that category
# Sources:
#   Cat 1 & 3 — scaled from Delphi FluView wili (250-patient hospital)
#   Cat 2     — scaled from CDC NSSP ARI percent_visits (Georgia)
#   Cat 4     — scaled from CDC RSV pcr_percent_positive (National)
# ─────────────────────────────────────────
def generate_patient_visits():
    # 30 daily counts per category (Feb 20 → Mar 21)
    daily = {
        # Respiratory Antivirals — ILI trend: peaked early Feb, declining
        1: [15, 14, 15, 13, 14, 13, 12, 13, 12, 11,
            12, 11, 10, 11, 10, 10,  9, 10,  9,  8,
             9,  9,  8,  9,  8,  8,  9,  8,  9,  8],
        # Broad Spectrum Antibiotics — ARI stable ~12%, slight decline
        2: [31, 33, 30, 32, 31, 29, 28, 30, 31, 29,
            30, 28, 27, 29, 28, 27, 26, 28, 26, 25,
            27, 26, 25, 27, 25, 24, 26, 25, 24, 26],
        # Analgesics/Antipyretics — higher base, follows ILI
        3: [42, 40, 43, 41, 39, 38, 36, 39, 37, 35,
            36, 34, 33, 35, 33, 32, 30, 32, 30, 29,
            31, 30, 28, 29, 27, 26, 28, 27, 25, 26],
        # Allergy/Anaphylaxis — RSV slowly rising
        4: [11, 12, 11, 13, 12, 12, 13, 12, 13, 14,
            13, 14, 15, 13, 14, 15, 14, 15, 16, 14,
            15, 16, 15, 16, 17, 15, 16, 17, 16, 17],
    }

    visits = []
    vid = 1
    start = date(2026, 2, 20)
    for day_offset in range(30):
        d = start + timedelta(days=day_offset)
        day_str = d.strftime("%Y-%m-%d") + " 00:00:00"
        for cat_id in range(1, 5):
            visits.append({
                "visitid": vid,
                "Catagoryid": cat_id,
                "visitNumber": daily[cat_id][day_offset],
                "visitDay": day_str,
            })
            vid += 1
    return visits

# ─────────────────────────────────────────
# TABLE 5 — inventory events
# 14 days: Mar 7–20, 2026
#
# Batch strategy:
#   Restocks create lots — some intentionally near-expiry or expired
#   to exercise all three expiry buckets in the replay engine.
#   Usage events follow FEFO (earliest-expiring lot first).
#
# Expiry distribution per medication:
#   oseltamivir   batch 1001 → Mar 28 2026 (NEAR EXPIRY ~7d)
#   ceftriaxone   batch 1008 → Mar 15 2026 (EXPIRED)
#   vancomycin    batch 1013 → Mar 10 2026 (EXPIRED)
#   acetaminophen batch 1015 → Apr 01 2026 (NEAR EXPIRY ~11d)
#   epinephrine   batch 1021 → Apr 03 2026 (NEAR EXPIRY ~13d)
#   methylpred.   batch 1025 → Mar 25 2026 (NEAR EXPIRY ~4d)
#   all others    → SAFE (6–12 months out)
# ─────────────────────────────────────────
def generate_inventory_events():
    events = []
    eid = 1

    # Batch → expiration date lookup (used for both restock + usage events)
    batch_expiry = {
        1001: "2026-03-28",  # oseltamivir   NEAR EXPIRY
        1002: "2026-11-15",  # oseltamivir   safe
        1003: "2026-12-01",  # zanamivir     safe
        1004: "2027-03-15",  # zanamivir     safe
        1005: "2026-10-20",  # peramivir     safe
        1006: "2026-09-15",  # baloxavir     safe
        1007: "2027-01-10",  # baloxavir     safe
        1008: "2026-03-15",  # ceftriaxone   EXPIRED
        1009: "2026-10-30",  # ceftriaxone   safe
        1010: "2026-08-20",  # azithromycin  safe
        1011: "2026-12-05",  # azithromycin  safe
        1012: "2026-07-15",  # levofloxacin  safe
        1013: "2026-03-10",  # vancomycin    EXPIRED
        1014: "2026-12-20",  # vancomycin    safe
        1015: "2026-04-01",  # acetaminophen NEAR EXPIRY
        1016: "2027-01-15",  # acetaminophen safe
        1017: "2026-11-20",  # ibuprofen     safe
        1018: "2027-02-28",  # ibuprofen     safe
        1019: "2026-09-10",  # naproxen      safe
        1020: "2026-06-30",  # aspirin       safe
        1021: "2026-04-03",  # epinephrine   NEAR EXPIRY
        1022: "2026-10-15",  # epinephrine   safe
        1023: "2026-08-12",  # diphenhydramine safe
        1024: "2026-11-30",  # cetirizine    safe
        1025: "2026-03-25",  # methylpred.   NEAR EXPIRY
        1026: "2026-09-01",  # methylpred.   safe
    }

    # ── RESTOCK EVENTS ──────────────────────────────────────────────────
    # (itemid, batchNumber, qty, eventDate, time_hm, locationid)
    # Pharmacy locationids: 5=Cardinal Health, 6=McKesson, 7=AmerisourceBergen
    restocks = [
        # Mar 7 — initial stock arrival for all items
        ( 1, 1001,  300, "2026-03-07", "07:30", 6),  # oseltamivir  near-expiry lot
        ( 2, 1003,  120, "2026-03-07", "07:30", 6),  # zanamivir    safe
        ( 3, 1005,   50, "2026-03-07", "07:30", 6),  # peramivir    safe
        ( 4, 1006,  200, "2026-03-07", "08:00", 5),  # baloxavir    safe
        ( 5, 1008,   20, "2026-03-07", "08:00", 7),  # ceftriaxone  EXPIRED lot (old stock)
        ( 5, 1009,  250, "2026-03-07", "08:05", 7),  # ceftriaxone  safe
        ( 6, 1010,  600, "2026-03-07", "08:15", 5),  # azithromycin safe
        ( 7, 1012,  500, "2026-03-07", "08:15", 5),  # levofloxacin safe
        ( 8, 1013,   15, "2026-03-07", "08:30", 6),  # vancomycin   EXPIRED lot (old stock)
        ( 8, 1014,  200, "2026-03-07", "08:35", 6),  # vancomycin   safe
        ( 9, 1015,  300, "2026-03-07", "09:00", 7),  # acetaminophen near-expiry lot
        ( 9, 1016, 1200, "2026-03-07", "09:05", 7),  # acetaminophen safe
        (10, 1017, 1000, "2026-03-07", "09:00", 5),  # ibuprofen    safe
        (11, 1019,  600, "2026-03-07", "09:15", 5),  # naproxen     safe
        (12, 1020,  800, "2026-03-07", "09:15", 6),  # aspirin      safe
        (13, 1021,   30, "2026-03-07", "09:30", 7),  # epinephrine  near-expiry lot
        (13, 1022,   60, "2026-03-07", "09:35", 7),  # epinephrine  safe
        (14, 1023,  300, "2026-03-07", "09:30", 5),  # diphenhydramine safe
        (15, 1024,  600, "2026-03-07", "09:45", 5),  # cetirizine   safe
        (16, 1025,   40, "2026-03-07", "09:45", 6),  # methylpred.  near-expiry lot
        (16, 1026,   80, "2026-03-07", "09:50", 6),  # methylpred.  safe
        # Mar 12–16 — second wave deliveries
        ( 6, 1011,  400, "2026-03-12", "10:00", 7),  # azithromycin safe (reorder)
        ( 4, 1007,  150, "2026-03-13", "10:00", 5),  # baloxavir    safe (reorder)
        ( 1, 1002,  250, "2026-03-14", "10:00", 6),  # oseltamivir  safe (reorder)
        (10, 1018,  800, "2026-03-15", "10:00", 7),  # ibuprofen    safe (reorder)
        ( 2, 1004,   80, "2026-03-16", "10:00", 5),  # zanamivir    safe (reorder)
    ]

    for itemid, batch, qty, evt_date, hm, locid in restocks:
        events.append({
            "eventid":        eid,
            "itemid":         itemid,
            "eventType":      "restock",
            "batchNumber":    batch,
            "quantityDelta":  qty,
            "expirationDate": batch_expiry[batch],
            "eventTime":      f"{evt_date} {hm}:00",
            "locationid":     locid,
        })
        eid += 1

    # ── USAGE EVENTS ────────────────────────────────────────────────────
    # 14 days × 16 items = 224 events
    # Quantities vary day-to-day to produce a realistic velocity signal.
    # Sign is negative (consumption).

    usage_dates = [f"2026-03-{d:02d}" for d in range(7, 21)]  # Mar 7 – Mar 20

    # Daily usage quantities per item [day0..day13]
    daily_usage = {
        1:  [11, 10, 12, 11, 10, 12, 11,  9, 10, 11, 10, 12, 11, 10],  # oseltamivir
        2:  [ 4,  3,  4,  5,  3,  4,  3,  4,  5,  3,  4,  3,  4,  5],  # zanamivir
        3:  [ 2,  3,  2,  2,  3,  2,  2,  3,  2,  2,  3,  2,  2,  3],  # peramivir
        4:  [ 8,  7,  9,  8,  7,  8,  9,  7,  8,  9,  7,  8,  9,  8],  # baloxavir
        5:  [14, 16, 15, 13, 17, 14, 15, 16, 14, 13, 15, 16, 14, 13],  # ceftriaxone
        6:  [22, 25, 23, 24, 20, 23, 25, 22, 24, 21, 23, 24, 22, 25],  # azithromycin
        7:  [18, 20, 17, 19, 21, 18, 20, 17, 19, 18, 20, 19, 17, 18],  # levofloxacin
        8:  [ 8,  9,  7, 10,  8,  9,  7, 10,  8,  7,  9,  8, 10,  8],  # vancomycin
        9:  [50, 48, 52, 55, 47, 51, 53, 49, 50, 52, 48, 54, 51, 49],  # acetaminophen
        10: [40, 38, 42, 44, 37, 41, 43, 39, 40, 42, 38, 43, 41, 39],  # ibuprofen
        11: [20, 18, 22, 21, 19, 20, 22, 18, 21, 20, 19, 21, 22, 20],  # naproxen
        12: [25, 23, 27, 26, 24, 25, 27, 23, 26, 25, 24, 26, 27, 25],  # aspirin
        13: [ 4,  3,  5,  4,  3,  4,  5,  4,  3,  5,  4,  3,  4,  5],  # epinephrine
        14: [12, 13, 11, 14, 12, 11, 13, 12, 14, 11, 13, 12, 11, 14],  # diphenhydramine
        15: [16, 15, 17, 18, 14, 16, 17, 15, 18, 16, 14, 17, 16, 15],  # cetirizine
        16: [ 5,  4,  6,  5,  4,  5,  6,  4,  5,  6,  4,  5,  6,  5],  # methylpred.
    }

    # FEFO batch assignment per item — switches when near-expiry lot exhausted
    # acetaminophen:     batch 1015 (300 units) lasts days 0-4  (sum=252 < 300), day 5+ → 1016
    # epinephrine:       batch 1021 (30 units)  lasts days 0-6  (sum=28 < 30),  day 7+ → 1022
    # methylprednisolone: batch 1025 (40 units) lasts days 0-7  (sum=39 < 40),  day 8+ → 1026
    def get_batch(itemid, day_idx):
        if itemid ==  9: return 1015 if day_idx < 5 else 1016
        if itemid == 13: return 1021 if day_idx < 7 else 1022
        if itemid == 16: return 1025 if day_idx < 8 else 1026
        return {
            1: 1001, 2: 1003, 3: 1005,  4: 1006,  5: 1009,
            6: 1010, 7: 1012, 8: 1014, 10: 1017, 11: 1019,
            12: 1020, 14: 1023, 15: 1024,
        }[itemid]

    # Primary dispensing location per item
    # IV medications → ICU or ED; oral medications → ward they're most used in
    item_location = {
        1: 1,   # oseltamivir       → ED
        2: 1,   # zanamivir         → ED
        3: 2,   # peramivir         → ICU (IV)
        4: 3,   # baloxavir         → General Ward
        5: 1,   # ceftriaxone       → ED (IV)
        6: 3,   # azithromycin      → General Ward
        7: 3,   # levofloxacin      → General Ward
        8: 2,   # vancomycin        → ICU (IV)
        9: 3,   # acetaminophen     → General Ward
        10: 3,  # ibuprofen         → General Ward
        11: 3,  # naproxen          → General Ward
        12: 4,  # aspirin           → Surgical Ward
        13: 1,  # epinephrine       → ED (emergency)
        14: 1,  # diphenhydramine   → ED
        15: 3,  # cetirizine        → General Ward
        16: 2,  # methylprednisolone → ICU (IV)
    }

    # Vary usage event times across the day
    event_times = [
        "08:30", "09:15", "07:45", "10:00", "08:00", "11:30",
        "09:45", "07:00", "10:30", "08:15", "11:00", "09:00",
        "07:30", "10:45",
    ]

    for day_idx, date_str in enumerate(usage_dates):
        for itemid in range(1, 17):
            qty    = daily_usage[itemid][day_idx]
            batch  = get_batch(itemid, day_idx)
            locid  = item_location[itemid]
            hm     = event_times[day_idx]
            events.append({
                "eventid":        eid,
                "itemid":         itemid,
                "eventType":      "usage",
                "batchNumber":    batch,
                "quantityDelta":  -qty,
                "expirationDate": batch_expiry[batch],
                "eventTime":      f"{date_str} {hm}:00",
                "locationid":     locid,
            })
            eid += 1

    return events


# ─────────────────────────────────────────
# WRITE FILES
# ─────────────────────────────────────────
def write_json(filename, data):
    with open(filename, "w") as f:
        json.dump(data, f, indent=2)
    print(f"  wrote {filename}  ({len(data)} records)")


if __name__ == "__main__":
    print("Generating seed data...")
    write_json("seed_categories.json",      categories)
    write_json("seed_items.json",           items)
    write_json("seed_locations.json",       locations)
    write_json("seed_patientvisits.json",   generate_patient_visits())
    write_json("seed_inventoryevents.json", generate_inventory_events())
    print("Done.")
