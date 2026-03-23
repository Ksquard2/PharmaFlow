import datetime
from typing import Optional
import json
from sqlalchemy import create_engine, text

DATABASE_URL = "mysql+mysqlconnector://root:newlatiospower@127.0.0.1:3306/PharmaFlow"
engine = create_engine(DATABASE_URL)

def serialize_row(row):
    import decimal
    def _cast(v):
        if isinstance(v, (datetime.date, datetime.datetime)):
            return v.isoformat()
        if isinstance(v, decimal.Decimal):
            return float(v)
        return v
    return {k: _cast(v) for k, v in dict(row._mapping).items()}

def query(sql):
    with engine.connect() as conn:
        result = conn.execute(text(sql))
        return [serialize_row(row) for row in result]

def get_all_categories():
    return query("SELECT * FROM Catagories")

def get_all_locations():
    return query("SELECT * FROM Location")

def get_all_items():
    return query("SELECT * FROM Items")

def get_all_visits():
    return query("SELECT * FROM PatientVisits")

def get_all_events():
    return query("SELECT * FROM InventoryEvents")

def get_all_info():
    return {
        "categories": get_all_categories(),
        "locations": get_all_locations(),
        "items": get_all_items(),
        "visits": get_all_visits(),
        "events": get_all_events(),
    }


# Valid Items.availabilityStatus ENUM values (must match Pharmaflow.sql)
_AVAILABILITY_ENUM = frozenset(
    ("high_availability", "moderate_availability", "constrained", "shortage_risk", "unknown")
)


def update_item_availability(itemid: int, availability_status: str, last_update=None):
    """
    Persist national-supply signal for one item. Uses a transaction so Flask / sync
    callers get committed state before the next SELECT.
    """
    if availability_status not in _AVAILABILITY_ENUM:
        raise ValueError(f"Invalid availabilityStatus: {availability_status!r}")
    if last_update is None:
        last_update = datetime.datetime.now()
    if isinstance(last_update, datetime.datetime):
        lu = last_update.strftime("%Y-%m-%d %H:%M:%S")
    else:
        lu = str(last_update)
    with engine.begin() as conn:
        conn.execute(
            text(
                "UPDATE Items SET availabilityStatus = :st, lastUpdate = :lu "
                "WHERE itemid = :id"
            ),
            {"st": availability_status, "lu": lu, "id": itemid},
        )


# ─────────────────────────────────────────────────────────────────────────────
# CONSTANTS
# ─────────────────────────────────────────────────────────────────────────────


# How many days of usable stock is considered "safe" for coverage pressure.
TARGET_COVERAGE_DAYS = 14

# Maps the availabilityStatus enum to a 0.0–1.0 supply pressure score.
# Higher value = more urgency. "unknown" is treated conservatively.
AVAILABILITY_SCORE = {
    "high_availability":      0.0,
    "moderate_availability":  0.25,
    "constrained":            0.50,
    "shortage_risk":          0.75,
    "unknown":                0.40,
}


# ─────────────────────────────────────────────────────────────────────────────
# Batch
# Represents a single pharmaceutical lot: one drug, one expiration date.
# Multiple restock events can add to the same batch (split shipments).
# ─────────────────────────────────────────────────────────────────────────────

class Batch:
    def __init__(self, batch_number, item_id, expiration_date_str, current_quantity, location_id):
        self.batch_number    = batch_number
        self.item_id         = item_id
        self.location_id     = location_id
        self.current_quantity = current_quantity
        # Parse the date string once so comparisons work throughout
        self.expiration_date = datetime.datetime.strptime(expiration_date_str, "%Y-%m-%d")


# ─────────────────────────────────────────────────────────────────────────────
# CurrentState
# Projected state of one medication after all events have been replayed.
# Holds the batch list, computed velocities, pressure signals, and demand score.
# ─────────────────────────────────────────────────────────────────────────────

class CurrentState:
    def __init__(self, item_id, item_name, category_id, availability_status, catagory_name):
        self.item_id             = item_id
        self.item_name           = item_name
        self.category_id         = category_id
        self.availability_status = availability_status
        self.catagory_name       = catagory_name
        self.total_quantity      = 0
        self.current_velocity    = 0.0   # avg daily usage — last 7 days
        self.local_velocity      = 0.0   # avg daily usage — last 30 days (baseline)
        self.usage_pressure      = 0.0
        self.coverage_pressure   = 0.0
        self.expiration_pressure = 0.0
        self.demand_score        = 0.0

        self.today   = datetime.datetime.now()
        self.batches = []  # populated after full replay

        # Chart data — populated after full replay
        self.safe_qty      = 0
        self.near_qty      = 0
        self.expired_qty   = 0
        self.supply_pressure = 0.0
        self.usage_history = []  # [{date, units_used}] last 30 days

    # ── Stock helpers ────────────────────────────────────────────────────────

    def add_stock(self, quantity):
        self.total_quantity += quantity

    def remove_stock(self, quantity):
        self.total_quantity -= quantity

    # ── Velocity ─────────────────────────────────────────────────────────────

    def compute_velocity(self, events, days) -> float:
        """
        Average daily usage (units/day) over the last `days` days.
        Only counts usage events for this item within the time window.
        Returns a positive number even though quantityDelta is stored negative.
        """
        cutoff = self.today - datetime.timedelta(days=days)
        usage_sum = sum(
            abs(e["quantityDelta"])
            for e in events
            if (e["itemid"]    == self.item_id
                and e["eventType"] == "usage"
                and datetime.datetime.fromisoformat(e["eventTime"]) >= cutoff)
        )
        return usage_sum / days

    # ── Usage pressure ───────────────────────────────────────────────────────

    def compute_usage_pressure(self, events, trend_strength):
        """
        Compares current 7-day velocity against the locally-adjusted expectation.

        category_multiplier scales the 30-day baseline up or down based on
        the external disease trend for this medication's therapeutic category.
        Clamped to [0.85, 1.5] so one bad week cannot dominate the signal.

        Neutral default (0.5) is used if no usage history exists.
        Result is clamped to [0, 1] before storage.
        """
        self.current_velocity = self.compute_velocity(events, 7)
        self.local_velocity   = self.compute_velocity(events, 30)

        category_multiplier = max(0.85, min(1.5, 1.0 + 0.5 * trend_strength))
        target_velocity     = self.local_velocity * category_multiplier

        if target_velocity == 0:
            self.usage_pressure = 0.5  # neutral: no history to compare against
        else:
            self.usage_pressure = min(self.current_velocity / target_velocity, 1.0)

    # ── Coverage pressure ────────────────────────────────────────────────────

    def compute_coverage_pressure(self):
        """
        How close we are to running out of usable (non-expired) stock.

        coverage_days  = usable_quantity / current_velocity
        coverage_pressure = 1 - min(coverage_days / TARGET_COVERAGE_DAYS, 1.0)

        A full 14 days of usable stock → pressure 0.0
        Zero usable stock              → pressure 1.0
        No current usage               → pressure 0.0 (no consumption, no urgency)
        """
        usable_quantity = sum(
            b.current_quantity for b in self.batches
            if b.expiration_date >= self.today and b.current_quantity > 0
        )

        if self.current_velocity == 0:
            self.coverage_pressure = 0.0
            return

        coverage_days          = usable_quantity / self.current_velocity
        self.coverage_pressure = 1.0 - min(coverage_days / TARGET_COVERAGE_DAYS, 1.0)

    # ── Expiration pressure ──────────────────────────────────────────────────

    def compute_expiration_pressure(self):
        """
        Fraction of total stock that is expired or near-expiry, weighted by severity.

        near-expiry threshold: within 14 days of today
        expired: past expiration date

        Weights: near-expiry × 0.6,  expired × 1.0
        Safe stock contributes zero pressure.
        """
        expired_qty = 0
        near_qty    = 0
        safe_qty    = 0
        near_cutoff = self.today + datetime.timedelta(days=14)

        for batch in self.batches:
            qty = max(batch.current_quantity, 0)  # clamp any negative drift
            if batch.expiration_date < self.today:
                expired_qty += qty
            elif batch.expiration_date < near_cutoff:
                near_qty += qty
            else:
                safe_qty += qty

        total = expired_qty + near_qty + safe_qty
        if total == 0:
            self.expiration_pressure = 0.0
            return

        near_pct    = near_qty    / total
        expired_pct = expired_qty / total
        self.expiration_pressure = 0.6 * near_pct + 1.0 * expired_pct

        # Store raw quantities for the expiry breakdown chart
        self.safe_qty    = safe_qty
        self.near_qty    = near_qty
        self.expired_qty = expired_qty

    # ── Demand score ─────────────────────────────────────────────────────────

    def compute_demand_score(self):
        """
        Weighted composite of 4 supply pressure signals (0–100 scale).

          35% usage pressure      — how hard is current demand vs expectation?
          30% coverage pressure   — how many days of usable stock remain?
          20% expiration pressure — how much stock is at expiry risk?
          15% supply pressure     — national availability / recall risk signal
        """
        supply_pressure      = AVAILABILITY_SCORE.get(self.availability_status, 0.40)
        self.supply_pressure = supply_pressure  # stored for chart output
        self.demand_score = 100.0 * (
            0.35 * self.usage_pressure      +
            0.30 * self.coverage_pressure   +
            0.20 * self.expiration_pressure +
            0.15 * supply_pressure
        )


    # ── Usage history (for line chart) ──────────────────────────────────────

    def build_usage_history(self, events, days=30):
        """
        Builds a daily usage time series for the last `days` days.
        Each entry is {date, units_used} — ready for Chart.js labels/data arrays.
        """
        cutoff = self.today - datetime.timedelta(days=days)
        daily  = {}
        for e in events:
            if (e["itemid"]    == self.item_id
                    and e["eventType"] == "usage"
                    and datetime.datetime.fromisoformat(e["eventTime"]) >= cutoff):
                date_str = e["eventTime"][:10]
                daily[date_str] = daily.get(date_str, 0) + abs(e["quantityDelta"])
        self.usage_history = sorted(
            [{"date": d, "units_used": v} for d, v in daily.items()],
            key=lambda x: x["date"],
        )


# ─────────────────────────────────────────────────────────────────────────────
# Inventory
# Orchestrates the full replay: loads all events in order, builds lots,
# projects current state for every item, then runs scoring.
# ─────────────────────────────────────────────────────────────────────────────

class Inventory:
    def __init__(self, items, events, categories, locations, visits):
        self.items      = items
        self.events     = events
        self.categories = categories
        self.locations  = locations
        self.visits     = visits
        self.states  = []   # List[CurrentState]
        self.batches = []   # List[Batch]

    # ── Private lookup helpers ────────────────────────────────────────────────

    def _find_state(self, item_id) -> Optional[CurrentState]:
        return next((s for s in self.states if s.item_id == item_id), None)

    def _find_batch(self, batch_number) -> Optional[Batch]:
        return next((b for b in self.batches if b.batch_number == batch_number), None)

    def _get_trend_strength(self, category_id) -> float:
        """Look up the pre-computed trendStrength for a therapeutic category."""
        for cat in self.categories:
            if cat["catagoryid"] == category_id:
                return cat.get("trendStrength", 0.0)
        return 0.0  # neutral fallback if category not found

    # ── Main replay ───────────────────────────────────────────────────────────

    def replay(self) -> dict:
        # ── Step 1: initialise one CurrentState per item ──────────────────────
        cat_name = {c["catagoryid"]: c["catagoryName"] for c in self.categories}
        for item in self.items:
            self.states.append(CurrentState(
                item_id=item["itemid"],
                item_name=item["itemName"],
                category_id=item["catagoryID"],
                availability_status=item["availabilityStatus"],
                catagory_name=cat_name.get(item["catagoryID"], "unknown"),
            ))

        # ── Step 2: walk events in chronological order ────────────────────────
        for event in self.events:
            state = self._find_state(event["itemid"])
            if state is None:
                continue  # event references an unknown item — skip

            if event["eventType"] == "restock":
                batch = self._find_batch(event["batchNumber"])
                if batch is None:
                    # First time seeing this batch — create the lot
                    batch = Batch(
                        batch_number=event["batchNumber"],
                        item_id=event["itemid"],
                        expiration_date_str=event["expirationDate"],
                        current_quantity=0,
                        location_id=event["locationid"],
                    )
                    self.batches.append(batch)
                # Add the restocked quantity to both the lot and the item total
                batch.current_quantity += event["quantityDelta"]
                state.add_stock(event["quantityDelta"])

            elif event["eventType"] == "usage":
                qty = abs(event["quantityDelta"])
                state.remove_stock(qty)
                # Deduct from the specific batch cited in the event.
                # FEFO ordering is enforced at event-generation time
                # (seed data / hardware bin layer); replay just trusts the log.
                batch = self._find_batch(event["batchNumber"])
                if batch:
                    batch.current_quantity -= qty

        # ── Step 3: assign each batch to its item's state ─────────────────────
        for batch in self.batches:
            state = self._find_state(batch.item_id)
            if state:
                state.batches.append(batch)

        # ── Step 4: compute pressure signals and demand score per item ─────────
        for state in self.states:
            trend_strength = self._get_trend_strength(state.category_id)
            state.compute_usage_pressure(self.events, trend_strength)
            state.compute_coverage_pressure()
            state.compute_expiration_pressure()
            state.compute_demand_score()
            state.build_usage_history(self.events)
        
        # ── Step 5: build chart data ──────────────────────────────────────────

        # Map category_id → item_ids for category-level aggregations
        from collections import defaultdict
        cat_item_ids = defaultdict(set)
        for item in self.items:
            cat_item_ids[item["catagoryID"]].add(item["itemid"])

        # Daily usage per category — supply side of the readiness line chart
        cat_daily_usage = defaultdict(lambda: defaultdict(int))
        for event in self.events:
            if event["eventType"] == "usage":
                date_str = event["eventTime"][:10]
                for cat_id, item_ids in cat_item_ids.items():
                    if event["itemid"] in item_ids:
                        cat_daily_usage[cat_id][date_str] += abs(event["quantityDelta"])

        # Patient visits per category — demand side of the readiness line chart
        cat_demand = defaultdict(list)
        for v in self.visits:
            cat_demand[v["Catagoryid"]].append({
                "date":        v["visitDay"][:10],
                "visit_count": v["visitNumber"],
            })

        # Per-category chart package
        category_charts = {}
        for cat in self.categories:
            cid = cat["catagoryid"]
            category_charts[str(cid)] = {
                "catagory_id":   cid,
                "catagory_name": cat["catagoryName"],
                "trend_strength": cat.get("trendStrength", 0.0),
                # Supply trend: units dispensed per day across all meds in category
                "supply_trend": sorted(
                    [{"date": d, "units_used": u} for d, u in cat_daily_usage[cid].items()],
                    key=lambda x: x["date"],
                ),
                # Demand trend: external patient visit signal per day
                "demand_trend": sorted(cat_demand[cid], key=lambda x: x["date"]),
            }

        # Global expiry summary — for the inventory dashboard donut chart
        inventory_expiry_summary = {
            "safe_qty":    sum(s.safe_qty    for s in self.states),
            "near_qty":    sum(s.near_qty    for s in self.states),
            "expired_qty": sum(s.expired_qty for s in self.states),
        }

        # Location aggregation — for the inventory dashboard pie charts
        loc_lookup = {loc["locationid"]: loc for loc in self.locations}

        # Hospital usage by department (usage events at hospital-type locations)
        loc_usage = defaultdict(int)
        for event in self.events:
            if event["eventType"] == "usage":
                loc_usage[event["locationid"]] += abs(event["quantityDelta"])

        usage_by_hospital = [
            {
                "locationName": loc_lookup[lid]["locationName"],
                "units_used":   units,
            }
            for lid, units in sorted(loc_usage.items(), key=lambda x: -x[1])
            if lid in loc_lookup and loc_lookup[lid]["locationType"] == "hospital"
        ]

        # Pharmacy procurement by supplier (restock events at pharmacy-type locations)
        loc_restock = defaultdict(int)
        for event in self.events:
            if event["eventType"] == "restock":
                loc_restock[event["locationid"]] += event["quantityDelta"]

        restock_by_pharmacy = [
            {
                "locationName":    loc_lookup[lid]["locationName"],
                "units_restocked": units,
            }
            for lid, units in sorted(loc_restock.items(), key=lambda x: -x[1])
            if lid in loc_lookup and loc_lookup[lid]["locationType"] == "pharmacy"
        ]

        # ── Step 6: return serialisable snapshot ──────────────────────────────
        return {
            "currentStates": [
                {
                    "itemid":              s.item_id,
                    "itemName":            s.item_name,
                    "catagory_id":         s.category_id,
                    "catagory_name":       s.catagory_name,
                    "total_quantity":      s.total_quantity,
                    "current_velocity":    round(s.current_velocity, 4),
                    "local_velocity":      round(s.local_velocity, 4),
                    # ── 4 demand score signals (for the medication detail bar chart)
                    "usage_pressure":      round(s.usage_pressure, 4),
                    "coverage_pressure":   round(s.coverage_pressure, 4),
                    "expiration_pressure": round(s.expiration_pressure, 4),
                    "supply_pressure":     round(s.supply_pressure, 4),
                    "demand_score":        round(s.demand_score, 2),
                    # ── Expiry breakdown (for the medication detail expiry donut)
                    "expiry_breakdown": {
                        "safe_qty":    s.safe_qty,
                        "near_qty":    s.near_qty,
                        "expired_qty": s.expired_qty,
                    },
                    # ── 30-day daily usage (for the medication detail line chart)
                    "usage_history": s.usage_history,
                }
                for s in self.states
            ],
            "batches": [
                {
                    "batch_number":     b.batch_number,
                    "item_id":          b.item_id,
                    "expiration_date":  b.expiration_date.strftime("%Y-%m-%d"),
                    "current_quantity": b.current_quantity,
                    "location_id":      b.location_id,
                }
                for b in self.batches
            ],
            # Per-category supply/demand trends (for the readiness detail line chart)
            "categoryCharts": category_charts,
            # Global expiry totals (for the inventory dashboard donut chart)
            "inventoryExpirySummary": inventory_expiry_summary,
            # Location breakdown (for the inventory dashboard pie charts)
            "usageByHospital":    usage_by_hospital,
            "restockByPharmacy":  restock_by_pharmacy,
            "categories": self.categories,
        }

def run_replay():
    info = get_all_info()
    inv = Inventory(info["items"], info["events"], info["categories"], info["locations"], info["visits"])
    result = inv.replay()
    with open("results.json", "w") as f:
        json.dump(result, f, indent=2)
    return result

if __name__ == "__main__":
    result = run_replay()
