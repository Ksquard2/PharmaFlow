#!/usr/bin/env python3
"""One-off generator: embed seed JSON into hw_inventory_log_demo.html"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    events = json.loads((ROOT / "seed_inventoryevents.json").read_text())
    items = json.loads((ROOT / "seed_items.json").read_text())
    locs = json.loads((ROOT / "seed_locations.json").read_text())

    events_js = json.dumps(events, separators=(",", ":"))
    items_js = json.dumps(items, separators=(",", ":"))
    locs_js = json.dumps(locs, separators=(",", ":"))

    # Escape for embedding inside </script>
    events_js = events_js.replace("<", "\\u003c")
    items_js = items_js.replace("<", "\\u003c")
    locs_js = locs_js.replace("<", "\\u003c")

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Live Inventory Event Log — PharmaFlow Demo</title>
  <style>
    * {{ box-sizing: border-box; margin: 0; padding: 0; }}
    body {{
      font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
      background: linear-gradient(145deg, #f0f9ff 0%, #e0f2fe 50%, #dbeafe 100%);
      min-height: 100vh;
      color: #0f172a;
    }}
    .header {{
      background: #fff;
      border-bottom: 1px solid #e2e8f0;
      box-shadow: 0 1px 3px rgba(0,0,0,.08);
    }}
    .header-inner {{
      max-width: 1280px;
      margin: 0 auto;
      padding: 1rem 1.5rem;
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      justify-content: space-between;
      gap: 0.75rem;
    }}
    .logo-section {{ display: flex; align-items: center; gap: 0.65rem; }}
    .logo-text {{
      font-size: clamp(1.1rem, 1.4vw + 0.75rem, 1.4rem);
      font-weight: 600;
      color: #0f172a;
    }}
    .logo-thumb {{
      display: inline-flex;
      width: clamp(2.65rem, 2.5vw + 1.85rem, 3.35rem);
      height: clamp(2.65rem, 2.5vw + 1.85rem, 3.35rem);
      border-radius: 10px;
      overflow: hidden;
      text-decoration: none;
    }}
    .logo-thumb img {{ width: 100%; height: 100%; object-fit: contain; }}
    nav {{ display: flex; flex-wrap: wrap; gap: 0.5rem; align-items: center; }}
    .nav-link {{
      color: #475569;
      text-decoration: none;
      font-size: 0.875rem;
      padding: 0.5rem 1rem;
      border-radius: 0.5rem;
    }}
    .nav-link:hover {{ background: #f1f5f9; color: #0f172a; }}
    .nav-link.active {{ background: #eff6ff; color: #1d4ed8; font-weight: 600; }}
    main {{ max-width: 1280px; margin: 0 auto; padding: 2rem 1.5rem 2.5rem; }}
    h1 {{ font-size: 1.5rem; font-weight: 700; margin-bottom: 0.35rem; }}
    .subtitle {{ color: #64748b; font-size: 0.95rem; margin-bottom: 1rem; }}
    .events {{ display: flex; flex-direction: column; gap: 0.75rem; }}
    .event-card {{
      background: #fff;
      border-radius: 0.5rem;
      border: 1px solid #e2e8f0;
      padding: 1rem 1.1rem;
      box-shadow: 0 1px 2px rgba(0,0,0,.04);
    }}
    .event-card.hardware {{
      border-color: #3b82f6;
      box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.25);
      background: linear-gradient(180deg, #eff6ff 0%, #fff 40%);
    }}
    .event-card .row {{
      display: flex;
      flex-wrap: wrap;
      gap: 0.35rem 1rem;
      align-items: baseline;
      margin-bottom: 0.35rem;
    }}
    .med {{ font-weight: 700; font-size: 1.05rem; color: #0f172a; }}
    .badge {{
      display: inline-block;
      font-size: 0.7rem;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.04em;
      padding: 0.2rem 0.45rem;
      border-radius: 0.25rem;
    }}
    .badge.hw {{ background: #dbeafe; color: #1e40af; }}
    .badge.seed {{ background: #f1f5f9; color: #475569; }}
    .meta {{ font-size: 0.85rem; color: #64748b; }}
    .meta span {{ margin-right: 0.75rem; }}
    .qty-neg {{ color: #b91c1c; font-weight: 600; }}
    .qty-pos {{ color: #15803d; font-weight: 600; }}
    footer {{ margin-top: 2rem; font-size: 0.75rem; color: #94a3b8; }}
  </style>
</head>
<body>
  <header class="header">
    <div class="header-inner">
      <div class="logo-section">
        <a href="/" class="logo-thumb" title="PharmaFlow home"><img src="/static/logo.jpg" alt="PharmaFlow"></a>
        <span class="logo-text">PharmaFlow</span>
      </div>
      <nav aria-label="Primary">
        <a href="/" class="nav-link">Inventory Dashboard</a>
        <a href="/readiness" class="nav-link">Illness Readiness</a>
        <a href="/demo/inventory-event-log" class="nav-link active">Event log (demo)</a>
      </nav>
    </div>
  </header>
  <main>
    <h1>Live Inventory Event Log</h1>
    <p class="subtitle">Latest dispense &amp; restock activity (demo — last 5 events)</p>
    <section aria-label="Recent inventory events">
      <h2 class="visually-hidden" style="position:absolute;width:1px;height:1px;overflow:hidden;">Recent events</h2>
      <div id="event-list" class="events"></div>
    </section>
    <footer>PharmaFlow hackathon demo · <kbd>sessionStorage</kbd> + server boot id · Ibuprofen scans reset when Flask restarts</footer>
  </main>

  <script>
    /** Set by Flask each process start — client clears fake scans when this changes */
    const SERVER_BOOT_ID = "{{{{ server_boot_id }}}}";
    const BOOT_STORAGE_KEY = "pharmaflow_demo_server_boot_id";

    /** Embedded from seed_inventoryevents.json (generated) — not fetched at runtime */
    const SEED_INVENTORY_EVENTS = {events_js};
    const SEED_ITEMS = {items_js};
    const SEED_LOCATIONS = {locs_js};

    const STORAGE_KEY = "pharmaflow_demo_hw_ibuprofen_scans";

    const itemById = Object.fromEntries(SEED_ITEMS.map(function (x) {{ return [x.itemid, x]; }}));
    const locById = Object.fromEntries(SEED_LOCATIONS.map(function (x) {{ return [x.locationid, x]; }}));

    function padEventId(n) {{
      return "DEMO-" + String(n).padStart(6, "0");
    }}

    function normalizeSeedEvent(raw) {{
      var it = itemById[raw.itemid] || {{ itemName: "unknown", unitType: "unit" }};
      var loc = locById[raw.locationid] || {{ locationName: "unknown" }};
      var iso = raw.eventTime.indexOf("T") >= 0 ? raw.eventTime : raw.eventTime.replace(" ", "T");
      return {{
        eventId: raw.eventid,
        itemId: String(raw.itemid),
        itemName: it.itemName,
        batchNumber: raw.batchNumber,
        quantityDelta: raw.quantityDelta,
        unitType: it.unitType,
        locationId: raw.locationid,
        locationName: loc.locationName,
        eventTime: iso,
        sourceType: raw.eventType === "usage" ? "inventory_system" : "restock_delivery",
        eventType: raw.eventType,
        _sortKey: iso
      }};
    }}

    function fixTimeForSort(isoOrSql) {{
      if (!isoOrSql) return 0;
      var s = String(isoOrSql).replace(" ", "T");
      if (/^\\d{{4}}-\\d{{2}}-\\d{{2}}T\\d{{2}}:\\d{{2}}:\\d{{2}}$/.test(s)) s += ".000Z";
      var t = Date.parse(s);
      return isNaN(t) ? 0 : t;
    }}

    function makeHardwareIbuprofenEvent(seq) {{
      var t = new Date().toISOString();
      return {{
        eventId: padEventId(seq),
        itemId: "ibuprofen",
        itemName: "Ibuprofen",
        batchNumber: 1017,
        quantityDelta: -40,
        unitType: "tablets",
        locationId: 3,
        locationName: (locById[3] && locById[3].locationName) || "General Medical Ward",
        eventTime: t,
        sourceType: "hardware_scan",
        eventType: "usage",
        _sortKey: t
      }};
    }}

    function loadHardwareHistory() {{
      try {{
        var raw = sessionStorage.getItem(STORAGE_KEY);
        return raw ? JSON.parse(raw) : [];
      }} catch (e) {{
        return [];
      }}
    }}

    function saveHardwareHistory(arr) {{
      sessionStorage.setItem(STORAGE_KEY, JSON.stringify(arr.slice(0, 200)));
    }}

    function escapeHtml(s) {{
      var d = document.createElement("div");
      d.textContent = s;
      return d.innerHTML;
    }}

    function formatTime(t) {{
      try {{
        var d = new Date(t.indexOf("T") >= 0 ? t : t.replace(" ", "T"));
        if (isNaN(d.getTime())) return t;
        return d.toLocaleString();
      }} catch (e) {{
        return t;
      }}
    }}

    function render() {{
      var normalizedSeed = SEED_INVENTORY_EVENTS.map(normalizeSeedEvent);
      var prevBoot = sessionStorage.getItem(BOOT_STORAGE_KEY);
      var serverRestarted = prevBoot !== SERVER_BOOT_ID;
      if (serverRestarted) {{
        sessionStorage.removeItem(STORAGE_KEY);
        sessionStorage.setItem(BOOT_STORAGE_KEY, SERVER_BOOT_ID);
      }}
      /** First load after Flask restart: show seed-only top 5 (no new ibuprofen row). Later reloads add scans. */
      var skipNewHardwareScan = serverRestarted;

      var hwHistory = loadHardwareHistory();
      var maxId = 0;
      for (var i = 0; i < hwHistory.length; i++) {{
        var m = /^DEMO-(\\d+)$/.exec(String(hwHistory[i].eventId));
        if (m) maxId = Math.max(maxId, parseInt(m[1], 10));
      }}
      var nextSeq = maxId + 1;

      if (!skipNewHardwareScan) {{
        var newest = makeHardwareIbuprofenEvent(nextSeq);
        hwHistory.unshift(newest);
        saveHardwareHistory(hwHistory);
      }}

      var combined = hwHistory.concat(normalizedSeed);
      combined.sort(function (a, b) {{
        return fixTimeForSort(b._sortKey || b.eventTime) - fixTimeForSort(a._sortKey || a.eventTime);
      }});
      var top5 = combined.slice(0, 5);

      var el = document.getElementById("event-list");
      el.innerHTML = "";
      top5.forEach(function (ev) {{
        var card = document.createElement("article");
        card.className = "event-card" + (ev.sourceType === "hardware_scan" ? " hardware" : "");
        card.setAttribute("role", "article");

        var qtyClass = ev.quantityDelta < 0 ? "qty-neg" : "qty-pos";
        var qtyLabel = (ev.quantityDelta >= 0 ? "+" : "") + ev.quantityDelta;

        var badge = ev.sourceType === "hardware_scan"
          ? '<span class="badge hw">Hardware scan</span>'
          : '<span class="badge seed">' + escapeHtml(ev.sourceType) + "</span>";

        card.innerHTML =
          '<div class="row">' +
            '<span class="med">' + escapeHtml(ev.itemName) + "</span>" +
            badge +
          "</div>" +
          '<div class="meta">' +
            '<span><strong>Qty:</strong> <span class="' + qtyClass + '">' + qtyLabel + "</span> " + escapeHtml(ev.unitType) + "</span>" +
            '<span><strong>Location:</strong> ' + escapeHtml(ev.locationName) + "</span>" +
            '<span><strong>Batch:</strong> ' + escapeHtml(String(ev.batchNumber)) + "</span>" +
          "</div>" +
          '<div class="meta">' +
            '<span><strong>Time:</strong> <time datetime="' + escapeHtml(ev.eventTime) + '">' + escapeHtml(formatTime(ev.eventTime)) + "</time></span>" +
            '<span><strong>Source:</strong> ' + escapeHtml(ev.sourceType) + "</span>" +
            '<span><strong>Event ID:</strong> ' + escapeHtml(String(ev.eventId)) + "</span>" +
          "</div>";
        el.appendChild(card);
      }});
    }}

    render();
  </script>
</body>
</html>
"""

    out = ROOT / "Templates" / "hw_inventory_log_demo.html"
    out.write_text(html, encoding="utf-8")
    print(f"Wrote {out} ({len(html) // 1024} KB)")


if __name__ == "__main__":
    main()
