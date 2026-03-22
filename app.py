import json
from replay import Inventory
from ollama import readinessCalculator, justify_readiness

# ── Load seed data ────────────────────────────────────────────────────────────
items      = json.load(open("seed_items.json"))
events     = json.load(open("seed_inventoryevents.json"))
categories = json.load(open("seed_categories.json"))
locations  = json.load(open("seed_locations.json"))
visits     = json.load(open("seed_patientvisits.json"))

# ── Run replay ────────────────────────────────────────────────────────────────
inv    = Inventory(items, events, categories, locations, visits)
result = inv.replay()

# ── Sort states by demand score descending ────────────────────────────────────
result["currentStates"].sort(key=lambda x: x["demand_score"], reverse=True)

# ── Write results.json ────────────────────────────────────────────────────────
with open("results.json", "w") as f:
    json.dump(result, f, indent=2)

print(f"Wrote results.json — {len(result['currentStates'])} items, {len(result['batches'])} batches")

# ── Run readiness calculator + Ollama justification for every category ────────
ai_results = []
for cat in result["categories"]:
    readiness = readinessCalculator(result, cat["catagoryid"])
    readiness["justification"] = justify_readiness(readiness)
    ai_results.append(readiness)

ai_results.sort(key=lambda x: x["readiness_score"])   # lowest readiness first

with open("airesults.json", "w") as f:
    json.dump(ai_results, f, indent=2)

print(f"Wrote airesults.json — {len(ai_results)} categories")

# ── Write just the justification text per category to responses.json ──────────
responses = [
    {
        "catagory_name":   r["catagory_name"],
        "readiness_score": r["readiness_score"],
        "readiness_badge": r["readiness_badge"],
        "justification":   r["justification"],
    }
    for r in ai_results
]

with open("responses.json", "w") as f:
    json.dump(responses, f, indent=2)

print(f"Wrote responses.json — {len(responses)} categories")
