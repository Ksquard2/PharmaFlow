from openai import OpenAI
import requests
import json


def readinessCalculator(replayed_data, catagory_id):
    # Pull items and category — myCatagory is a list so index [0] to get the dict
    myItems     = [s for s in replayed_data["currentStates"] if s["catagory_id"] == catagory_id]
    myCatagory  = next(c for c in replayed_data["categories"] if c["catagoryid"] == catagory_id)

    # Readiness score (pure math — Ollama only explains, never calculates)
    avg_demand_score = sum(s["demand_score"] for s in myItems) / len(myItems)
    trend_strength   = myCatagory.get("trendStrength", 0.0)
    trend_pressure   = (trend_strength + 1) / 2
    readiness_score  = round(max(0, min(100, 100 - (0.6 * avg_demand_score + 0.4 * trend_pressure * 100))), 2)

    badge = (
        "Strong"   if readiness_score >= 80 else
        "Adequate" if readiness_score >= 60 else
        "Strained" if readiness_score >= 40 else
        "Critical"
    )

    # Comparative line graph data — supply vs demand trend
    # categoryCharts keys become strings after JSON serialisation
    chart = replayed_data["categoryCharts"][str(catagory_id)]

    return {
        "catagoryid":         catagory_id,
        "catagory_name":      myCatagory["catagoryName"],
        "description":        myCatagory.get("description", ""),
        "imagePath":          myCatagory.get("imagePath", ""),
        "readiness_score":    readiness_score,
        "readiness_badge":    badge,
        "avg_demand_score":   round(avg_demand_score, 2),
        "trend_strength":     trend_strength,
        "supply_trend":       chart["supply_trend"],   # [{date, units_used}]
        "demand_trend":       chart["demand_trend"],   # [{date, visit_count}]
        "medications": [
            {"name": s["itemName"], "demand_score": s["demand_score"]}
            for s in sorted(myItems, key=lambda x: x["demand_score"], reverse=True)
        ],
    }

READINESS_SYSTEM_PROMPT = """You are PharmaFlow's clinical inventory analyst. Your only job is to write a concise, plain-English justification for a pre-calculated category readiness score.

HOW THE SCORE WORKS (do not recalculate — just reference these signals in your explanation):
- Readiness Score (0–100): higher is better. Formula: 100 - (0.6 × avg_demand_score + 0.4 × trend_pressure × 100)
- avg_demand_score: average urgency across all medications in the category (0–100, higher = more pressure)
- trend_strength: external disease-signal strength (-1 to +1). Positive = rising patient volume, negative = declining.
- trend_pressure: normalised trend_strength mapped to (0–1). Feeds 40% of the score.
- supply_trend: daily total units dispensed across all meds in the category (last 14 days)
- demand_trend: daily patient visits attributed to this therapeutic category (last 30 days)
- medications list: individual med names with their own demand scores (0–100)

SCORE BADGES:
- Strong   (80–100): well-stocked, low pressure
- Adequate (60–79):  manageable, monitor closely
- Strained (40–59):  supply struggling to meet demand
- Critical (0–39):   immediate restocking action required

TONE AND FORMAT RULES:
- 3–5 sentences maximum. No bullet points. No headers. No markdown.
- Start with the badge and score, e.g. "Readiness is Strained at 56.5."
- Cite the most stressed medication by name if demand scores vary meaningfully.
- Reference whether supply is trending up or down vs patient demand.
- End with a single, actionable recommendation (restock, monitor, escalate, etc.).
- Never mention the formula directly. Speak in clinical operations language."""


def build_readiness_prompt(readiness_data):
    """Serialise a readinessCalculator result into a focused user prompt for Ollama."""
    d = readiness_data

    # Summarise supply trend direction (first vs last value)
    supply = d["supply_trend"]
    supply_direction = "stable"
    if len(supply) >= 2:
        delta = supply[-1]["units_used"] - supply[0]["units_used"]
        supply_direction = "increasing" if delta > 2 else "decreasing" if delta < -2 else "stable"

    # Summarise demand trend direction
    demand = d["demand_trend"]
    demand_direction = "stable"
    if len(demand) >= 2:
        delta = demand[-1]["visit_count"] - demand[0]["visit_count"]
        demand_direction = "rising" if delta > 1 else "falling" if delta < -1 else "stable"

    med_lines = "\n".join(
        f"  - {m['name']}: demand score {m['demand_score']}"
        for m in d["medications"]
    )

    return f"""Category: {d['catagory_name']}
Readiness Score: {d['readiness_score']} ({d['readiness_badge']})
Avg Demand Score: {d['avg_demand_score']}
Trend Strength: {d['trend_strength']} (external disease signal)
Supply trend (last 14 days): {supply_direction} — latest {supply[-1]['units_used']} units/day
Demand trend (last 30 days): {demand_direction} — latest {demand[-1]['visit_count']} visits/day

Medications by demand pressure (highest first):
{med_lines}

Write a clinical justification for this readiness score."""


def justify_readiness(readiness_data):
    """Full pipeline: build prompts → call Ollama → return explanation string."""
    user_prompt = build_readiness_prompt(readiness_data)
    return call_ollama(READINESS_SYSTEM_PROMPT, user_prompt)


INVENTORY_SYSTEM_PROMPT = """You are PharmaFlow's hospital pharmacy operations analyst.
Write a brief narrative (4–6 sentences) summarizing overall medication inventory health for leadership.
Use ONLY the facts in the user message — do not invent numbers or drug names not listed.
Tone: professional, calm, actionable. No bullet points, no markdown, no headers.
Name specific high-demand medications when helpful. Mention near-expiry or expired stock if the counts are non-trivial.
End with one practical operational next step."""


def build_inventory_prompt(replayed_data: dict) -> str:
    """Compact facts from replay output for the inventory dashboard summary."""
    states = sorted(
        replayed_data.get("currentStates") or [],
        key=lambda x: x.get("demand_score", 0),
        reverse=True,
    )
    at_risk = [s for s in states if s.get("demand_score", 0) >= 65]
    monitor = [s for s in states if 35 <= s.get("demand_score", 0) < 65]
    stable = [s for s in states if s.get("demand_score", 0) < 35]
    exp = replayed_data.get("inventoryExpirySummary") or {}
    cats = replayed_data.get("categories") or []

    lines = [
        f"Total medications: {len(states)}",
        f"Therapeutic categories: {len(cats)}",
        f"Demand tiers — At risk (score ≥65): {len(at_risk)}; Monitor (35–64): {len(monitor)}; Stable (<35): {len(stable)}",
        f"Expiry units — safe: {exp.get('safe_qty', 0)}, nearing expiry: {exp.get('near_qty', 0)}, expired: {exp.get('expired_qty', 0)}",
        "Highest-demand medications (name, demand_score, category):",
    ]
    for s in states[:8]:
        lines.append(
            f"  - {s.get('itemName')}: {s.get('demand_score')} — {s.get('catagory_name', 'unknown')}"
        )
    return "\n".join(lines)


def justify_inventory_health(replayed_data: dict) -> str:
    """Ollama narrative for the Inventory Dashboard 'Overall Inventory Health' section."""
    user_prompt = build_inventory_prompt(replayed_data)
    return call_ollama(INVENTORY_SYSTEM_PROMPT, user_prompt)


def call_ollama(system_prompt, user_prompt):
    client = OpenAI(
        base_url="http://localhost:11434/v1",
        api_key="ollama"  # Required by the SDK but Ollama ignores it
    )
    response = client.chat.completions.create(
        model="llama3.2",  # Whatever model you've pulled
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}
        ]
    )
    return response.choices[0].message.content


