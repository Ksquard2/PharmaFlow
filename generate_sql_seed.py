import json

lines = []

# ── Header ────────────────────────────────────────────────────────────────────
lines += [
    "CREATE DATABASE IF NOT EXISTS PharmaFlow",
    "    DEFAULT CHARACTER SET utf8mb4",
    "    DEFAULT COLLATE utf8mb4_unicode_ci;",
    "",
    "USE PharmaFlow;",
    "",
    "-- Replace any previous seed data (safe re-run of this script)",
    "SET FOREIGN_KEY_CHECKS = 0;",
    "DROP TABLE IF EXISTS `InventoryEvents`;",
    "DROP TABLE IF EXISTS `PatientVisits`;",
    "DROP TABLE IF EXISTS `Items`;",
    "DROP TABLE IF EXISTS `Catagories`;",
    "DROP TABLE IF EXISTS `Location`;",
    "SET FOREIGN_KEY_CHECKS = 1;",
    "",
]

# ── Schema ────────────────────────────────────────────────────────────────────
lines += [
    "-- ─────────────────────────────────────────────────────────────────────",
    "-- SCHEMA",
    "-- ─────────────────────────────────────────────────────────────────────",
    "",
    "CREATE TABLE `Items`(",
    "    `itemid`             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,",
    "    `itemName`           VARCHAR(255) NOT NULL,",
    "    `unitType`           VARCHAR(255) NOT NULL,",
    "    `catagoryID`         BIGINT UNSIGNED NOT NULL,",
    "    `availabilityStatus` ENUM('high_availability', 'moderate_availability', 'constrained', 'shortage_risk', 'unknown') NOT NULL,",
    "    `lastUpdate`         DATETIME NOT NULL",
    ");",
    "CREATE TABLE `Location`(",
    "    `locationid`   BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,",
    "    `locationType` ENUM('hospital', 'pharmacy') NOT NULL,",
    "    `locationName` VARCHAR(255) NOT NULL",
    ");",
    "CREATE TABLE `Catagories`(",
    "    `catagoryid`    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,",
    "    `catagoryName`  VARCHAR(255) NOT NULL,",
    "    `trendStrength` DECIMAL(10, 4) NOT NULL,",
    "    `description`   TEXT NOT NULL,",
    "    `imagePath`     VARCHAR(255) NOT NULL,",
    "    `endpoint`      VARCHAR(255) NOT NULL,",
    "    `parameters`    JSON NOT NULL",
    ");",
    "CREATE TABLE `PatientVisits`(",
    "    `visitid`     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,",
    "    `Catagoryid`  BIGINT UNSIGNED NOT NULL,",
    "    `visitNumber` DECIMAL(10, 4) NOT NULL,",
    "    `visitDay`    DATETIME NOT NULL",
    ");",
    "CREATE TABLE `InventoryEvents`(",
    "    `eventid`        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,",
    "    `itemid`         BIGINT UNSIGNED NOT NULL,",
    "    `eventType`      ENUM('restock', 'usage') NOT NULL,",
    "    `batchNumber`    BIGINT UNSIGNED NOT NULL,",
    "    `quantityDelta`  INT NOT NULL,",
    "    `expirationDate` DATE NOT NULL,",
    "    `eventTime`      DATETIME NOT NULL,",
    "    `locationid`     BIGINT UNSIGNED NOT NULL",
    ");",
    "ALTER TABLE `PatientVisits`   ADD CONSTRAINT `patientvisits_catagoryid_foreign`   FOREIGN KEY(`Catagoryid`)  REFERENCES `Catagories`(`catagoryid`);",
    "ALTER TABLE `InventoryEvents` ADD CONSTRAINT `inventoryevents_locationid_foreign` FOREIGN KEY(`locationid`) REFERENCES `Location`(`locationid`);",
    "ALTER TABLE `InventoryEvents` ADD CONSTRAINT `inventoryevents_itemid_foreign`     FOREIGN KEY(`itemid`)     REFERENCES `Items`(`itemid`);",
    "ALTER TABLE `Items`           ADD CONSTRAINT `items_catagoryid_foreign`           FOREIGN KEY(`catagoryID`) REFERENCES `Catagories`(`catagoryid`);",
    "",
]

def esc(val):
    """Escape single quotes for SQL string literals."""
    return str(val).replace("'", "''")

# ── Catagories ────────────────────────────────────────────────────────────────
cats = json.load(open("seed_categories.json"))
lines += [
    "-- ─────────────────────────────────────────────────────────────────────",
    "-- SEED: Catagories",
    "-- ─────────────────────────────────────────────────────────────────────",
]
for c in cats:
    lines.append(
        f"INSERT INTO `Catagories` (`catagoryid`, `catagoryName`, `trendStrength`, `description`, `imagePath`, `endpoint`, `parameters`) VALUES "
        f"({c['catagoryid']}, '{esc(c['catagoryName'])}', {c['trendStrength']}, "
        f"'{esc(c['description'])}', '{esc(c['imagePath'])}', "
        f"'{esc(c['endpoint'])}', '{esc(json.dumps(c['parameters']))}');"
    )
lines.append("")

# ── Location ──────────────────────────────────────────────────────────────────
locs = json.load(open("seed_locations.json"))
lines += [
    "-- ─────────────────────────────────────────────────────────────────────",
    "-- SEED: Location",
    "-- ─────────────────────────────────────────────────────────────────────",
]
for l in locs:
    lines.append(
        f"INSERT INTO `Location` (`locationid`, `locationType`, `locationName`) VALUES "
        f"({l['locationid']}, '{esc(l['locationType'])}', '{esc(l['locationName'])}');"
    )
lines.append("")

# ── Items ─────────────────────────────────────────────────────────────────────
items = json.load(open("seed_items.json"))
lines += [
    "-- ─────────────────────────────────────────────────────────────────────",
    "-- SEED: Items",
    "-- ─────────────────────────────────────────────────────────────────────",
]
for i in items:
    lines.append(
        f"INSERT INTO `Items` (`itemid`, `itemName`, `unitType`, `catagoryID`, `availabilityStatus`, `lastUpdate`) VALUES "
        f"({i['itemid']}, '{esc(i['itemName'])}', '{esc(i['unitType'])}', "
        f"{i['catagoryID']}, '{esc(i['availabilityStatus'])}', '{esc(i['lastUpdate'])}');"
    )
lines.append("")

# ── PatientVisits ─────────────────────────────────────────────────────────────
visits = json.load(open("seed_patientvisits.json"))
lines += [
    "-- ─────────────────────────────────────────────────────────────────────",
    "-- SEED: PatientVisits",
    "-- ─────────────────────────────────────────────────────────────────────",
]
for v in visits:
    lines.append(
        f"INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES "
        f"({v['visitid']}, {v['Catagoryid']}, {v['visitNumber']}, '{esc(v['visitDay'])}');"
    )
lines.append("")

# ── InventoryEvents ───────────────────────────────────────────────────────────
events = json.load(open("seed_inventoryevents.json"))
lines += [
    "-- ─────────────────────────────────────────────────────────────────────",
    "-- SEED: InventoryEvents",
    "-- ─────────────────────────────────────────────────────────────────────",
]
for e in events:
    lines.append(
        f"INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES "
        f"({e['eventid']}, {e['itemid']}, '{esc(e['eventType'])}', {e['batchNumber']}, "
        f"{e['quantityDelta']}, '{esc(e['expirationDate'])}', '{esc(e['eventTime'])}', {e['locationid']});"
    )
lines.append("")

# ── Write ─────────────────────────────────────────────────────────────────────
with open("seed_db.sql", "w") as f:
    f.write("\n".join(lines))

print(f"Wrote seed_db.sql")
print(f"  {len(cats)} categories")
print(f"  {len(locs)} locations")
print(f"  {len(items)} items")
print(f"  {len(visits)} patient visits")
print(f"  {len(events)} inventory events")
