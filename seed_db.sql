CREATE DATABASE IF NOT EXISTS PharmaFlow
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE PharmaFlow;

-- Replace any previous seed data (safe re-run of this script)
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `InventoryEvents`;
DROP TABLE IF EXISTS `PatientVisits`;
DROP TABLE IF EXISTS `Items`;
DROP TABLE IF EXISTS `Catagories`;
DROP TABLE IF EXISTS `Location`;
SET FOREIGN_KEY_CHECKS = 1;

-- ─────────────────────────────────────────────────────────────────────
-- SCHEMA
-- ─────────────────────────────────────────────────────────────────────

CREATE TABLE `Items`(
    `itemid`             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `itemName`           VARCHAR(255) NOT NULL,
    `unitType`           VARCHAR(255) NOT NULL,
    `catagoryID`         BIGINT UNSIGNED NOT NULL,
    `availabilityStatus` ENUM('high_availability', 'moderate_availability', 'constrained', 'shortage_risk', 'unknown') NOT NULL,
    `lastUpdate`         DATETIME NOT NULL
);
CREATE TABLE `Location`(
    `locationid`   BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `locationType` ENUM('hospital', 'pharmacy') NOT NULL,
    `locationName` VARCHAR(255) NOT NULL
);
CREATE TABLE `Catagories`(
    `catagoryid`    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `catagoryName`  VARCHAR(255) NOT NULL,
    `trendStrength` DECIMAL(10, 4) NOT NULL,
    `description`   TEXT NOT NULL,
    `imagePath`     VARCHAR(255) NOT NULL,
    `endpoint`      VARCHAR(255) NOT NULL,
    `parameters`    JSON NOT NULL
);
CREATE TABLE `PatientVisits`(
    `visitid`     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `Catagoryid`  BIGINT UNSIGNED NOT NULL,
    `visitNumber` DECIMAL(10, 4) NOT NULL,
    `visitDay`    DATETIME NOT NULL
);
CREATE TABLE `InventoryEvents`(
    `eventid`        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `itemid`         BIGINT UNSIGNED NOT NULL,
    `eventType`      ENUM('restock', 'usage') NOT NULL,
    `batchNumber`    BIGINT UNSIGNED NOT NULL,
    `quantityDelta`  INT NOT NULL,
    `expirationDate` DATE NOT NULL,
    `eventTime`      DATETIME NOT NULL,
    `locationid`     BIGINT UNSIGNED NOT NULL
);
ALTER TABLE `PatientVisits`   ADD CONSTRAINT `patientvisits_catagoryid_foreign`   FOREIGN KEY(`Catagoryid`)  REFERENCES `Catagories`(`catagoryid`);
ALTER TABLE `InventoryEvents` ADD CONSTRAINT `inventoryevents_locationid_foreign` FOREIGN KEY(`locationid`) REFERENCES `Location`(`locationid`);
ALTER TABLE `InventoryEvents` ADD CONSTRAINT `inventoryevents_itemid_foreign`     FOREIGN KEY(`itemid`)     REFERENCES `Items`(`itemid`);
ALTER TABLE `Items`           ADD CONSTRAINT `items_catagoryid_foreign`           FOREIGN KEY(`catagoryID`) REFERENCES `Catagories`(`catagoryid`);

-- ─────────────────────────────────────────────────────────────────────
-- SEED: Catagories
-- ─────────────────────────────────────────────────────────────────────
INSERT INTO `Catagories` (`catagoryid`, `catagoryName`, `trendStrength`, `description`, `imagePath`, `endpoint`, `parameters`) VALUES (1, 'Respiratory Antivirals', -0.52, 'Antiviral medications used to treat and prevent respiratory viral infections, primarily influenza and RSV. These agents work by inhibiting viral replication and are most effective when administered early in the course of illness. Stockpile readiness is critical during flu season and outbreak periods.', 'https://openmoji.org/data/color/svg/1FAC1.svg', 'https://api.delphi.cmu.edu/epidata/fluview/', '{"regions": "nat", "epiweeks": "202501-202510"}');
INSERT INTO `Catagories` (`catagoryid`, `catagoryName`, `trendStrength`, `description`, `imagePath`, `endpoint`, `parameters`) VALUES (2, 'Broad Spectrum Antibiotics', -0.18, 'Wide-coverage antibacterial agents effective against a broad range of gram-positive and gram-negative organisms. Used empirically in serious infections before culture results are available. High-demand during respiratory illness surges due to secondary bacterial pneumonia risk.', 'https://openmoji.org/data/color/svg/1F9A0.svg', 'https://data.cdc.gov/resource/vjzj-u7u8.json', '{"$select": "date, pathogen, geography, percent_visits", "$where": "geography=''Georgia'' AND pathogen=''ARI''", "$order": "date DESC", "$limit": 30}');
INSERT INTO `Catagories` (`catagoryid`, `catagoryName`, `trendStrength`, `description`, `imagePath`, `endpoint`, `parameters`) VALUES (3, 'Analgesics and Antipyretics', -0.46, 'Pain-relieving and fever-reducing medications that form the backbone of symptomatic treatment across nearly every care setting. Demand is closely tied to overall patient volume and spikes sharply during flu season, post-operative surges, and pediatric illness waves.', 'https://openmoji.org/data/color/svg/1F48A.svg', 'https://api.delphi.cmu.edu/epidata/fluview/', '{"regions": "nat", "epiweeks": "202501-202510"}');
INSERT INTO `Catagories` (`catagoryid`, `catagoryName`, `trendStrength`, `description`, `imagePath`, `endpoint`, `parameters`) VALUES (4, 'Allergy and Anaphylaxis Treatments', 0.31, 'Emergency and maintenance medications for allergic reactions ranging from mild urticaria to life-threatening anaphylaxis. Epinephrine availability is a direct patient safety requirement. Seasonal allergen trends and RSV activity drive demand variability throughout the year.', 'https://openmoji.org/data/color/svg/1F489.svg', 'https://data.cdc.gov/resource/3cxc-4k8q.json', '{"$select": "mmwrweek_end, level, pcr_percent_positive, percent_pos_2_week", "$where": "level=''National''", "$order": "mmwrweek_end DESC", "$limit": 20}');

-- ─────────────────────────────────────────────────────────────────────
-- SEED: Location
-- ─────────────────────────────────────────────────────────────────────
INSERT INTO `Location` (`locationid`, `locationType`, `locationName`) VALUES (1, 'hospital', 'Emergency Department');
INSERT INTO `Location` (`locationid`, `locationType`, `locationName`) VALUES (2, 'hospital', 'Intensive Care Unit');
INSERT INTO `Location` (`locationid`, `locationType`, `locationName`) VALUES (3, 'hospital', 'General Medical Ward');
INSERT INTO `Location` (`locationid`, `locationType`, `locationName`) VALUES (4, 'hospital', 'Surgical Ward');
INSERT INTO `Location` (`locationid`, `locationType`, `locationName`) VALUES (5, 'pharmacy', 'Cardinal Health - Atlanta Distribution Center');
INSERT INTO `Location` (`locationid`, `locationType`, `locationName`) VALUES (6, 'pharmacy', 'McKesson Southeast Regional Warehouse');
INSERT INTO `Location` (`locationid`, `locationType`, `locationName`) VALUES (7, 'pharmacy', 'AmerisourceBergen Fulfillment Center');

-- ─────────────────────────────────────────────────────────────────────
-- SEED: Items
-- ─────────────────────────────────────────────────────────────────────
INSERT INTO `Items` (`itemid`, `itemName`, `unitType`, `catagoryID`, `availabilityStatus`, `lastUpdate`) VALUES (1, 'oseltamivir', 'capsules', 1, 'high_availability', '2026-03-21 06:00:00');
INSERT INTO `Items` (`itemid`, `itemName`, `unitType`, `catagoryID`, `availabilityStatus`, `lastUpdate`) VALUES (2, 'zanamivir', 'inhalation_powder', 1, 'high_availability', '2026-03-21 06:00:00');
INSERT INTO `Items` (`itemid`, `itemName`, `unitType`, `catagoryID`, `availabilityStatus`, `lastUpdate`) VALUES (3, 'peramivir', 'vials', 1, 'high_availability', '2026-03-21 06:00:00');
INSERT INTO `Items` (`itemid`, `itemName`, `unitType`, `catagoryID`, `availabilityStatus`, `lastUpdate`) VALUES (4, 'baloxavir', 'tablets', 1, 'high_availability', '2026-03-21 06:00:00');
INSERT INTO `Items` (`itemid`, `itemName`, `unitType`, `catagoryID`, `availabilityStatus`, `lastUpdate`) VALUES (5, 'ceftriaxone', 'vials', 2, 'shortage_risk', '2026-03-21 06:00:00');
INSERT INTO `Items` (`itemid`, `itemName`, `unitType`, `catagoryID`, `availabilityStatus`, `lastUpdate`) VALUES (6, 'azithromycin', 'tablets', 2, 'constrained', '2026-03-21 06:00:00');
INSERT INTO `Items` (`itemid`, `itemName`, `unitType`, `catagoryID`, `availabilityStatus`, `lastUpdate`) VALUES (7, 'levofloxacin', 'tablets', 2, 'moderate_availability', '2026-03-21 06:00:00');
INSERT INTO `Items` (`itemid`, `itemName`, `unitType`, `catagoryID`, `availabilityStatus`, `lastUpdate`) VALUES (8, 'vancomycin', 'vials', 2, 'shortage_risk', '2026-03-21 06:00:00');
INSERT INTO `Items` (`itemid`, `itemName`, `unitType`, `catagoryID`, `availabilityStatus`, `lastUpdate`) VALUES (9, 'acetaminophen', 'tablets', 3, 'shortage_risk', '2026-03-21 06:00:00');
INSERT INTO `Items` (`itemid`, `itemName`, `unitType`, `catagoryID`, `availabilityStatus`, `lastUpdate`) VALUES (10, 'ibuprofen', 'tablets', 3, 'moderate_availability', '2026-03-21 06:00:00');
INSERT INTO `Items` (`itemid`, `itemName`, `unitType`, `catagoryID`, `availabilityStatus`, `lastUpdate`) VALUES (11, 'naproxen', 'tablets', 3, 'high_availability', '2026-03-21 06:00:00');
INSERT INTO `Items` (`itemid`, `itemName`, `unitType`, `catagoryID`, `availabilityStatus`, `lastUpdate`) VALUES (12, 'aspirin', 'tablets', 3, 'high_availability', '2026-03-21 06:00:00');
INSERT INTO `Items` (`itemid`, `itemName`, `unitType`, `catagoryID`, `availabilityStatus`, `lastUpdate`) VALUES (13, 'epinephrine', 'vials', 4, 'moderate_availability', '2026-03-21 06:00:00');
INSERT INTO `Items` (`itemid`, `itemName`, `unitType`, `catagoryID`, `availabilityStatus`, `lastUpdate`) VALUES (14, 'diphenhydramine', 'vials', 4, 'moderate_availability', '2026-03-21 06:00:00');
INSERT INTO `Items` (`itemid`, `itemName`, `unitType`, `catagoryID`, `availabilityStatus`, `lastUpdate`) VALUES (15, 'cetirizine', 'tablets', 4, 'high_availability', '2026-03-21 06:00:00');
INSERT INTO `Items` (`itemid`, `itemName`, `unitType`, `catagoryID`, `availabilityStatus`, `lastUpdate`) VALUES (16, 'methylprednisolone', 'vials', 4, 'shortage_risk', '2026-03-21 06:00:00');

-- ─────────────────────────────────────────────────────────────────────
-- SEED: PatientVisits
-- ─────────────────────────────────────────────────────────────────────
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (1, 1, 15, '2026-02-20 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (2, 2, 31, '2026-02-20 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (3, 3, 42, '2026-02-20 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (4, 4, 11, '2026-02-20 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (5, 1, 14, '2026-02-21 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (6, 2, 33, '2026-02-21 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (7, 3, 40, '2026-02-21 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (8, 4, 12, '2026-02-21 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (9, 1, 15, '2026-02-22 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (10, 2, 30, '2026-02-22 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (11, 3, 43, '2026-02-22 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (12, 4, 11, '2026-02-22 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (13, 1, 13, '2026-02-23 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (14, 2, 32, '2026-02-23 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (15, 3, 41, '2026-02-23 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (16, 4, 13, '2026-02-23 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (17, 1, 14, '2026-02-24 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (18, 2, 31, '2026-02-24 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (19, 3, 39, '2026-02-24 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (20, 4, 12, '2026-02-24 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (21, 1, 13, '2026-02-25 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (22, 2, 29, '2026-02-25 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (23, 3, 38, '2026-02-25 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (24, 4, 12, '2026-02-25 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (25, 1, 12, '2026-02-26 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (26, 2, 28, '2026-02-26 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (27, 3, 36, '2026-02-26 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (28, 4, 13, '2026-02-26 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (29, 1, 13, '2026-02-27 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (30, 2, 30, '2026-02-27 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (31, 3, 39, '2026-02-27 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (32, 4, 12, '2026-02-27 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (33, 1, 12, '2026-02-28 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (34, 2, 31, '2026-02-28 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (35, 3, 37, '2026-02-28 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (36, 4, 13, '2026-02-28 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (37, 1, 11, '2026-03-01 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (38, 2, 29, '2026-03-01 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (39, 3, 35, '2026-03-01 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (40, 4, 14, '2026-03-01 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (41, 1, 12, '2026-03-02 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (42, 2, 30, '2026-03-02 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (43, 3, 36, '2026-03-02 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (44, 4, 13, '2026-03-02 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (45, 1, 11, '2026-03-03 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (46, 2, 28, '2026-03-03 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (47, 3, 34, '2026-03-03 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (48, 4, 14, '2026-03-03 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (49, 1, 10, '2026-03-04 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (50, 2, 27, '2026-03-04 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (51, 3, 33, '2026-03-04 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (52, 4, 15, '2026-03-04 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (53, 1, 11, '2026-03-05 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (54, 2, 29, '2026-03-05 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (55, 3, 35, '2026-03-05 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (56, 4, 13, '2026-03-05 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (57, 1, 10, '2026-03-06 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (58, 2, 28, '2026-03-06 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (59, 3, 33, '2026-03-06 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (60, 4, 14, '2026-03-06 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (61, 1, 10, '2026-03-07 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (62, 2, 27, '2026-03-07 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (63, 3, 32, '2026-03-07 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (64, 4, 15, '2026-03-07 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (65, 1, 9, '2026-03-08 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (66, 2, 26, '2026-03-08 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (67, 3, 30, '2026-03-08 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (68, 4, 14, '2026-03-08 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (69, 1, 10, '2026-03-09 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (70, 2, 28, '2026-03-09 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (71, 3, 32, '2026-03-09 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (72, 4, 15, '2026-03-09 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (73, 1, 9, '2026-03-10 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (74, 2, 26, '2026-03-10 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (75, 3, 30, '2026-03-10 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (76, 4, 16, '2026-03-10 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (77, 1, 8, '2026-03-11 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (78, 2, 25, '2026-03-11 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (79, 3, 29, '2026-03-11 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (80, 4, 14, '2026-03-11 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (81, 1, 9, '2026-03-12 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (82, 2, 27, '2026-03-12 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (83, 3, 31, '2026-03-12 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (84, 4, 15, '2026-03-12 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (85, 1, 9, '2026-03-13 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (86, 2, 26, '2026-03-13 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (87, 3, 30, '2026-03-13 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (88, 4, 16, '2026-03-13 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (89, 1, 8, '2026-03-14 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (90, 2, 25, '2026-03-14 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (91, 3, 28, '2026-03-14 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (92, 4, 15, '2026-03-14 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (93, 1, 9, '2026-03-15 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (94, 2, 27, '2026-03-15 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (95, 3, 29, '2026-03-15 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (96, 4, 16, '2026-03-15 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (97, 1, 8, '2026-03-16 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (98, 2, 25, '2026-03-16 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (99, 3, 27, '2026-03-16 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (100, 4, 17, '2026-03-16 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (101, 1, 8, '2026-03-17 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (102, 2, 24, '2026-03-17 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (103, 3, 26, '2026-03-17 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (104, 4, 15, '2026-03-17 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (105, 1, 9, '2026-03-18 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (106, 2, 26, '2026-03-18 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (107, 3, 28, '2026-03-18 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (108, 4, 16, '2026-03-18 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (109, 1, 8, '2026-03-19 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (110, 2, 25, '2026-03-19 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (111, 3, 27, '2026-03-19 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (112, 4, 17, '2026-03-19 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (113, 1, 9, '2026-03-20 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (114, 2, 24, '2026-03-20 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (115, 3, 25, '2026-03-20 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (116, 4, 16, '2026-03-20 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (117, 1, 8, '2026-03-21 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (118, 2, 26, '2026-03-21 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (119, 3, 26, '2026-03-21 00:00:00');
INSERT INTO `PatientVisits` (`visitid`, `Catagoryid`, `visitNumber`, `visitDay`) VALUES (120, 4, 17, '2026-03-21 00:00:00');

-- ─────────────────────────────────────────────────────────────────────
-- SEED: InventoryEvents
-- ─────────────────────────────────────────────────────────────────────
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (1, 1, 'restock', 1001, 300, '2026-03-28', '2026-03-07 07:30:00', 6);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (2, 2, 'restock', 1003, 320, '2026-12-01', '2026-03-07 07:30:00', 6);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (3, 3, 'restock', 1005, 260, '2026-10-20', '2026-03-07 07:30:00', 6);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (4, 4, 'restock', 1006, 520, '2026-09-15', '2026-03-07 08:00:00', 5);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (5, 5, 'restock', 1008, 20, '2026-03-15', '2026-03-07 08:00:00', 7);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (6, 5, 'restock', 1009, 72, '2026-10-30', '2026-03-07 08:05:00', 7);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (7, 6, 'restock', 1010, 220, '2026-08-20', '2026-03-07 08:15:00', 5);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (8, 7, 'restock', 1012, 520, '2026-07-15', '2026-03-07 08:15:00', 5);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (9, 8, 'restock', 1013, 15, '2026-03-10', '2026-03-07 08:30:00', 6);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (10, 8, 'restock', 1014, 72, '2026-12-20', '2026-03-07 08:35:00', 6);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (11, 9, 'restock', 1015, 420, '2026-04-01', '2026-03-07 09:00:00', 7);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (12, 9, 'restock', 1016, 580, '2027-01-15', '2026-03-07 09:05:00', 7);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (13, 10, 'restock', 1017, 1000, '2026-11-20', '2026-03-07 09:00:00', 5);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (14, 11, 'restock', 1019, 1600, '2026-09-10', '2026-03-07 09:15:00', 5);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (15, 12, 'restock', 1020, 1800, '2026-06-30', '2026-03-07 09:15:00', 6);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (16, 13, 'restock', 1021, 30, '2026-04-03', '2026-03-07 09:30:00', 7);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (17, 13, 'restock', 1022, 60, '2026-10-15', '2026-03-07 09:35:00', 7);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (18, 14, 'restock', 1023, 300, '2026-08-12', '2026-03-07 09:30:00', 5);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (19, 15, 'restock', 1024, 1100, '2026-11-30', '2026-03-07 09:45:00', 5);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (20, 16, 'restock', 1025, 40, '2026-03-25', '2026-03-07 09:45:00', 6);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (21, 16, 'restock', 1026, 42, '2026-09-01', '2026-03-07 09:50:00', 6);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (22, 6, 'restock', 1011, 200, '2026-12-05', '2026-03-12 10:00:00', 7);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (23, 4, 'restock', 1007, 150, '2027-01-10', '2026-03-13 10:00:00', 5);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (24, 1, 'restock', 1002, 250, '2026-11-15', '2026-03-14 10:00:00', 6);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (25, 10, 'restock', 1018, 800, '2027-02-28', '2026-03-15 10:00:00', 7);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (26, 2, 'restock', 1004, 200, '2027-03-15', '2026-03-16 10:00:00', 5);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (27, 1, 'usage', 1001, -13, '2026-03-28', '2026-03-07 08:30:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (28, 2, 'usage', 1003, -7, '2026-12-01', '2026-03-07 08:30:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (29, 3, 'usage', 1005, -6, '2026-10-20', '2026-03-07 08:30:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (30, 4, 'usage', 1006, -9, '2026-09-15', '2026-03-07 08:30:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (31, 5, 'usage', 1009, -33, '2026-10-30', '2026-03-07 08:30:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (32, 6, 'usage', 1010, -47, '2026-08-20', '2026-03-07 08:30:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (33, 7, 'usage', 1012, -19, '2026-07-15', '2026-03-07 08:30:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (34, 8, 'usage', 1014, -16, '2026-12-20', '2026-03-07 08:30:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (35, 9, 'usage', 1015, -112, '2026-04-01', '2026-03-07 08:30:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (36, 10, 'usage', 1017, -41, '2026-11-20', '2026-03-07 08:30:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (37, 11, 'usage', 1019, -9, '2026-09-10', '2026-03-07 08:30:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (38, 12, 'usage', 1020, -9, '2026-06-30', '2026-03-07 08:30:00', 4);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (39, 13, 'usage', 1021, -4, '2026-04-03', '2026-03-07 08:30:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (40, 14, 'usage', 1023, -13, '2026-08-12', '2026-03-07 08:30:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (41, 15, 'usage', 1024, -8, '2026-11-30', '2026-03-07 08:30:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (42, 16, 'usage', 1025, -11, '2026-03-25', '2026-03-07 08:30:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (43, 1, 'usage', 1001, -12, '2026-03-28', '2026-03-08 09:15:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (44, 2, 'usage', 1003, -7, '2026-12-01', '2026-03-08 09:15:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (45, 3, 'usage', 1005, -6, '2026-10-20', '2026-03-08 09:15:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (46, 4, 'usage', 1006, -9, '2026-09-15', '2026-03-08 09:15:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (47, 5, 'usage', 1009, -38, '2026-10-30', '2026-03-08 09:15:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (48, 6, 'usage', 1010, -54, '2026-08-20', '2026-03-08 09:15:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (49, 7, 'usage', 1012, -21, '2026-07-15', '2026-03-08 09:15:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (50, 8, 'usage', 1014, -18, '2026-12-20', '2026-03-08 09:15:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (51, 9, 'usage', 1015, -108, '2026-04-01', '2026-03-08 09:15:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (52, 10, 'usage', 1017, -39, '2026-11-20', '2026-03-08 09:15:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (53, 11, 'usage', 1019, -9, '2026-09-10', '2026-03-08 09:15:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (54, 12, 'usage', 1020, -9, '2026-06-30', '2026-03-08 09:15:00', 4);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (55, 13, 'usage', 1021, -3, '2026-04-03', '2026-03-08 09:15:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (56, 14, 'usage', 1023, -14, '2026-08-12', '2026-03-08 09:15:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (57, 15, 'usage', 1024, -8, '2026-11-30', '2026-03-08 09:15:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (58, 16, 'usage', 1025, -9, '2026-03-25', '2026-03-08 09:15:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (59, 1, 'usage', 1001, -14, '2026-03-28', '2026-03-09 07:45:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (60, 2, 'usage', 1003, -7, '2026-12-01', '2026-03-09 07:45:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (61, 3, 'usage', 1005, -6, '2026-10-20', '2026-03-09 07:45:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (62, 4, 'usage', 1006, -9, '2026-09-15', '2026-03-09 07:45:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (63, 5, 'usage', 1009, -35, '2026-10-30', '2026-03-09 07:45:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (64, 6, 'usage', 1010, -49, '2026-08-20', '2026-03-09 07:45:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (65, 7, 'usage', 1012, -18, '2026-07-15', '2026-03-09 07:45:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (66, 8, 'usage', 1014, -14, '2026-12-20', '2026-03-09 07:45:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (67, 9, 'usage', 1015, -117, '2026-04-01', '2026-03-09 07:45:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (68, 10, 'usage', 1017, -43, '2026-11-20', '2026-03-09 07:45:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (69, 11, 'usage', 1019, -9, '2026-09-10', '2026-03-09 07:45:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (70, 12, 'usage', 1020, -9, '2026-06-30', '2026-03-09 07:45:00', 4);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (71, 13, 'usage', 1021, -4, '2026-04-03', '2026-03-09 07:45:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (72, 14, 'usage', 1023, -12, '2026-08-12', '2026-03-09 07:45:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (73, 15, 'usage', 1024, -8, '2026-11-30', '2026-03-09 07:45:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (74, 16, 'usage', 1025, -13, '2026-03-25', '2026-03-09 07:45:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (75, 1, 'usage', 1001, -13, '2026-03-28', '2026-03-10 10:00:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (76, 2, 'usage', 1003, -7, '2026-12-01', '2026-03-10 10:00:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (77, 3, 'usage', 1005, -6, '2026-10-20', '2026-03-10 10:00:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (78, 4, 'usage', 1006, -9, '2026-09-15', '2026-03-10 10:00:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (79, 5, 'usage', 1009, -31, '2026-10-30', '2026-03-10 10:00:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (80, 6, 'usage', 1010, -52, '2026-08-20', '2026-03-10 10:00:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (81, 7, 'usage', 1012, -20, '2026-07-15', '2026-03-10 10:00:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (82, 8, 'usage', 1014, -20, '2026-12-20', '2026-03-10 10:00:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (83, 9, 'usage', 1015, -124, '2026-04-01', '2026-03-10 10:00:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (84, 10, 'usage', 1017, -45, '2026-11-20', '2026-03-10 10:00:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (85, 11, 'usage', 1019, -9, '2026-09-10', '2026-03-10 10:00:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (86, 12, 'usage', 1020, -9, '2026-06-30', '2026-03-10 10:00:00', 4);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (87, 13, 'usage', 1021, -4, '2026-04-03', '2026-03-10 10:00:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (88, 14, 'usage', 1023, -15, '2026-08-12', '2026-03-10 10:00:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (89, 15, 'usage', 1024, -8, '2026-11-30', '2026-03-10 10:00:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (90, 16, 'usage', 1025, -11, '2026-03-25', '2026-03-10 10:00:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (91, 1, 'usage', 1001, -12, '2026-03-28', '2026-03-11 08:00:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (92, 2, 'usage', 1003, -7, '2026-12-01', '2026-03-11 08:00:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (93, 3, 'usage', 1005, -6, '2026-10-20', '2026-03-11 08:00:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (94, 4, 'usage', 1006, -9, '2026-09-15', '2026-03-11 08:00:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (95, 5, 'usage', 1009, -40, '2026-10-30', '2026-03-11 08:00:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (96, 6, 'usage', 1010, -43, '2026-08-20', '2026-03-11 08:00:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (97, 7, 'usage', 1012, -22, '2026-07-15', '2026-03-11 08:00:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (98, 8, 'usage', 1014, -16, '2026-12-20', '2026-03-11 08:00:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (99, 9, 'usage', 1015, -106, '2026-04-01', '2026-03-11 08:00:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (100, 10, 'usage', 1017, -38, '2026-11-20', '2026-03-11 08:00:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (101, 11, 'usage', 1019, -9, '2026-09-10', '2026-03-11 08:00:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (102, 12, 'usage', 1020, -9, '2026-06-30', '2026-03-11 08:00:00', 4);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (103, 13, 'usage', 1021, -3, '2026-04-03', '2026-03-11 08:00:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (104, 14, 'usage', 1023, -13, '2026-08-12', '2026-03-11 08:00:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (105, 15, 'usage', 1024, -8, '2026-11-30', '2026-03-11 08:00:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (106, 16, 'usage', 1025, -9, '2026-03-25', '2026-03-11 08:00:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (107, 1, 'usage', 1001, -14, '2026-03-28', '2026-03-12 11:30:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (108, 2, 'usage', 1003, -7, '2026-12-01', '2026-03-12 11:30:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (109, 3, 'usage', 1005, -6, '2026-10-20', '2026-03-12 11:30:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (110, 4, 'usage', 1006, -9, '2026-09-15', '2026-03-12 11:30:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (111, 5, 'usage', 1009, -33, '2026-10-30', '2026-03-12 11:30:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (112, 6, 'usage', 1010, -49, '2026-08-20', '2026-03-12 11:30:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (113, 7, 'usage', 1012, -19, '2026-07-15', '2026-03-12 11:30:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (114, 8, 'usage', 1014, -18, '2026-12-20', '2026-03-12 11:30:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (115, 9, 'usage', 1015, -115, '2026-04-01', '2026-03-12 11:30:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (116, 10, 'usage', 1017, -42, '2026-11-20', '2026-03-12 11:30:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (117, 11, 'usage', 1019, -9, '2026-09-10', '2026-03-12 11:30:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (118, 12, 'usage', 1020, -9, '2026-06-30', '2026-03-12 11:30:00', 4);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (119, 13, 'usage', 1021, -4, '2026-04-03', '2026-03-12 11:30:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (120, 14, 'usage', 1023, -12, '2026-08-12', '2026-03-12 11:30:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (121, 15, 'usage', 1024, -8, '2026-11-30', '2026-03-12 11:30:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (122, 16, 'usage', 1026, -11, '2026-09-01', '2026-03-12 11:30:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (123, 1, 'usage', 1001, -13, '2026-03-28', '2026-03-13 09:45:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (124, 2, 'usage', 1003, -7, '2026-12-01', '2026-03-13 09:45:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (125, 3, 'usage', 1005, -6, '2026-10-20', '2026-03-13 09:45:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (126, 4, 'usage', 1006, -9, '2026-09-15', '2026-03-13 09:45:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (127, 5, 'usage', 1009, -35, '2026-10-30', '2026-03-13 09:45:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (128, 6, 'usage', 1010, -54, '2026-08-20', '2026-03-13 09:45:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (129, 7, 'usage', 1012, -21, '2026-07-15', '2026-03-13 09:45:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (130, 8, 'usage', 1014, -14, '2026-12-20', '2026-03-13 09:45:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (131, 9, 'usage', 1016, -119, '2027-01-15', '2026-03-13 09:45:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (132, 10, 'usage', 1017, -44, '2026-11-20', '2026-03-13 09:45:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (133, 11, 'usage', 1019, -9, '2026-09-10', '2026-03-13 09:45:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (134, 12, 'usage', 1020, -9, '2026-06-30', '2026-03-13 09:45:00', 4);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (135, 13, 'usage', 1021, -4, '2026-04-03', '2026-03-13 09:45:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (136, 14, 'usage', 1023, -14, '2026-08-12', '2026-03-13 09:45:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (137, 15, 'usage', 1024, -8, '2026-11-30', '2026-03-13 09:45:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (138, 16, 'usage', 1026, -13, '2026-09-01', '2026-03-13 09:45:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (139, 1, 'usage', 1001, -11, '2026-03-28', '2026-03-14 07:00:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (140, 2, 'usage', 1003, -1, '2026-12-01', '2026-03-14 07:00:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (141, 3, 'usage', 1005, -1, '2026-10-20', '2026-03-14 07:00:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (142, 4, 'usage', 1006, -1, '2026-09-15', '2026-03-14 07:00:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (143, 5, 'usage', 1009, -38, '2026-10-30', '2026-03-14 07:00:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (144, 6, 'usage', 1010, -47, '2026-08-20', '2026-03-14 07:00:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (145, 7, 'usage', 1012, -18, '2026-07-15', '2026-03-14 07:00:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (146, 8, 'usage', 1014, -20, '2026-12-20', '2026-03-14 07:00:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (147, 9, 'usage', 1016, -110, '2027-01-15', '2026-03-14 07:00:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (148, 10, 'usage', 1017, -40, '2026-11-20', '2026-03-14 07:00:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (149, 11, 'usage', 1019, -1, '2026-09-10', '2026-03-14 07:00:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (150, 12, 'usage', 1020, -1, '2026-06-30', '2026-03-14 07:00:00', 4);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (151, 13, 'usage', 1022, -4, '2026-10-15', '2026-03-14 07:00:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (152, 14, 'usage', 1023, -13, '2026-08-12', '2026-03-14 07:00:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (153, 15, 'usage', 1024, -1, '2026-11-30', '2026-03-14 07:00:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (154, 16, 'usage', 1026, -9, '2026-09-01', '2026-03-14 07:00:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (155, 1, 'usage', 1001, -12, '2026-03-28', '2026-03-15 10:30:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (156, 2, 'usage', 1003, -1, '2026-12-01', '2026-03-15 10:30:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (157, 3, 'usage', 1005, -1, '2026-10-20', '2026-03-15 10:30:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (158, 4, 'usage', 1006, -1, '2026-09-15', '2026-03-15 10:30:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (159, 5, 'usage', 1009, -33, '2026-10-30', '2026-03-15 10:30:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (160, 6, 'usage', 1010, -52, '2026-08-20', '2026-03-15 10:30:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (161, 7, 'usage', 1012, -20, '2026-07-15', '2026-03-15 10:30:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (162, 8, 'usage', 1014, -16, '2026-12-20', '2026-03-15 10:30:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (163, 9, 'usage', 1016, -112, '2027-01-15', '2026-03-15 10:30:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (164, 10, 'usage', 1017, -41, '2026-11-20', '2026-03-15 10:30:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (165, 11, 'usage', 1019, -1, '2026-09-10', '2026-03-15 10:30:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (166, 12, 'usage', 1020, -1, '2026-06-30', '2026-03-15 10:30:00', 4);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (167, 13, 'usage', 1022, -3, '2026-10-15', '2026-03-15 10:30:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (168, 14, 'usage', 1023, -15, '2026-08-12', '2026-03-15 10:30:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (169, 15, 'usage', 1024, -1, '2026-11-30', '2026-03-15 10:30:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (170, 16, 'usage', 1026, -11, '2026-09-01', '2026-03-15 10:30:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (171, 1, 'usage', 1001, -13, '2026-03-28', '2026-03-16 08:15:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (172, 2, 'usage', 1003, -1, '2026-12-01', '2026-03-16 08:15:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (173, 3, 'usage', 1005, -1, '2026-10-20', '2026-03-16 08:15:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (174, 4, 'usage', 1006, -1, '2026-09-15', '2026-03-16 08:15:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (175, 5, 'usage', 1009, -31, '2026-10-30', '2026-03-16 08:15:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (176, 6, 'usage', 1010, -45, '2026-08-20', '2026-03-16 08:15:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (177, 7, 'usage', 1012, -19, '2026-07-15', '2026-03-16 08:15:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (178, 8, 'usage', 1014, -14, '2026-12-20', '2026-03-16 08:15:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (179, 9, 'usage', 1016, -117, '2027-01-15', '2026-03-16 08:15:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (180, 10, 'usage', 1017, -43, '2026-11-20', '2026-03-16 08:15:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (181, 11, 'usage', 1019, -1, '2026-09-10', '2026-03-16 08:15:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (182, 12, 'usage', 1020, -1, '2026-06-30', '2026-03-16 08:15:00', 4);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (183, 13, 'usage', 1022, -4, '2026-10-15', '2026-03-16 08:15:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (184, 14, 'usage', 1023, -12, '2026-08-12', '2026-03-16 08:15:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (185, 15, 'usage', 1024, -1, '2026-11-30', '2026-03-16 08:15:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (186, 16, 'usage', 1026, -13, '2026-09-01', '2026-03-16 08:15:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (187, 1, 'usage', 1001, -12, '2026-03-28', '2026-03-17 11:00:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (188, 2, 'usage', 1003, -1, '2026-12-01', '2026-03-17 11:00:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (189, 3, 'usage', 1005, -1, '2026-10-20', '2026-03-17 11:00:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (190, 4, 'usage', 1006, -1, '2026-09-15', '2026-03-17 11:00:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (191, 5, 'usage', 1009, -35, '2026-10-30', '2026-03-17 11:00:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (192, 6, 'usage', 1010, -49, '2026-08-20', '2026-03-17 11:00:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (193, 7, 'usage', 1012, -21, '2026-07-15', '2026-03-17 11:00:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (194, 8, 'usage', 1014, -18, '2026-12-20', '2026-03-17 11:00:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (195, 9, 'usage', 1016, -108, '2027-01-15', '2026-03-17 11:00:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (196, 10, 'usage', 1017, -39, '2026-11-20', '2026-03-17 11:00:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (197, 11, 'usage', 1019, -1, '2026-09-10', '2026-03-17 11:00:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (198, 12, 'usage', 1020, -1, '2026-06-30', '2026-03-17 11:00:00', 4);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (199, 13, 'usage', 1022, -4, '2026-10-15', '2026-03-17 11:00:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (200, 14, 'usage', 1023, -14, '2026-08-12', '2026-03-17 11:00:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (201, 15, 'usage', 1024, -1, '2026-11-30', '2026-03-17 11:00:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (202, 16, 'usage', 1026, -9, '2026-09-01', '2026-03-17 11:00:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (203, 1, 'usage', 1001, -14, '2026-03-28', '2026-03-18 09:00:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (204, 2, 'usage', 1003, -1, '2026-12-01', '2026-03-18 09:00:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (205, 3, 'usage', 1005, -1, '2026-10-20', '2026-03-18 09:00:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (206, 4, 'usage', 1006, -1, '2026-09-15', '2026-03-18 09:00:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (207, 5, 'usage', 1009, -38, '2026-10-30', '2026-03-18 09:00:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (208, 6, 'usage', 1010, -52, '2026-08-20', '2026-03-18 09:00:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (209, 7, 'usage', 1012, -20, '2026-07-15', '2026-03-18 09:00:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (210, 8, 'usage', 1014, -16, '2026-12-20', '2026-03-18 09:00:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (211, 9, 'usage', 1016, -122, '2027-01-15', '2026-03-18 09:00:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (212, 10, 'usage', 1017, -44, '2026-11-20', '2026-03-18 09:00:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (213, 11, 'usage', 1019, -1, '2026-09-10', '2026-03-18 09:00:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (214, 12, 'usage', 1020, -1, '2026-06-30', '2026-03-18 09:00:00', 4);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (215, 13, 'usage', 1022, -3, '2026-10-15', '2026-03-18 09:00:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (216, 14, 'usage', 1023, -13, '2026-08-12', '2026-03-18 09:00:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (217, 15, 'usage', 1024, -1, '2026-11-30', '2026-03-18 09:00:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (218, 16, 'usage', 1026, -11, '2026-09-01', '2026-03-18 09:00:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (219, 1, 'usage', 1001, -13, '2026-03-28', '2026-03-19 07:30:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (220, 2, 'usage', 1003, -1, '2026-12-01', '2026-03-19 07:30:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (221, 3, 'usage', 1005, -1, '2026-10-20', '2026-03-19 07:30:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (222, 4, 'usage', 1006, -1, '2026-09-15', '2026-03-19 07:30:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (223, 5, 'usage', 1009, -33, '2026-10-30', '2026-03-19 07:30:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (224, 6, 'usage', 1010, -47, '2026-08-20', '2026-03-19 07:30:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (225, 7, 'usage', 1012, -18, '2026-07-15', '2026-03-19 07:30:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (226, 8, 'usage', 1014, -20, '2026-12-20', '2026-03-19 07:30:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (227, 9, 'usage', 1016, -115, '2027-01-15', '2026-03-19 07:30:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (228, 10, 'usage', 1017, -42, '2026-11-20', '2026-03-19 07:30:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (229, 11, 'usage', 1019, -1, '2026-09-10', '2026-03-19 07:30:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (230, 12, 'usage', 1020, -1, '2026-06-30', '2026-03-19 07:30:00', 4);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (231, 13, 'usage', 1022, -4, '2026-10-15', '2026-03-19 07:30:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (232, 14, 'usage', 1023, -12, '2026-08-12', '2026-03-19 07:30:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (233, 15, 'usage', 1024, -1, '2026-11-30', '2026-03-19 07:30:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (234, 16, 'usage', 1026, -13, '2026-09-01', '2026-03-19 07:30:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (235, 1, 'usage', 1001, -12, '2026-03-28', '2026-03-20 10:45:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (236, 2, 'usage', 1003, -1, '2026-12-01', '2026-03-20 10:45:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (237, 3, 'usage', 1005, -1, '2026-10-20', '2026-03-20 10:45:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (238, 4, 'usage', 1006, -1, '2026-09-15', '2026-03-20 10:45:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (239, 5, 'usage', 1009, -31, '2026-10-30', '2026-03-20 10:45:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (240, 6, 'usage', 1010, -54, '2026-08-20', '2026-03-20 10:45:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (241, 7, 'usage', 1012, -19, '2026-07-15', '2026-03-20 10:45:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (242, 8, 'usage', 1014, -16, '2026-12-20', '2026-03-20 10:45:00', 2);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (243, 9, 'usage', 1016, -110, '2027-01-15', '2026-03-20 10:45:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (244, 10, 'usage', 1017, -40, '2026-11-20', '2026-03-20 10:45:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (245, 11, 'usage', 1019, -1, '2026-09-10', '2026-03-20 10:45:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (246, 12, 'usage', 1020, -1, '2026-06-30', '2026-03-20 10:45:00', 4);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (247, 13, 'usage', 1022, -4, '2026-10-15', '2026-03-20 10:45:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (248, 14, 'usage', 1023, -15, '2026-08-12', '2026-03-20 10:45:00', 1);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (249, 15, 'usage', 1024, -1, '2026-11-30', '2026-03-20 10:45:00', 3);
INSERT INTO `InventoryEvents` (`eventid`, `itemid`, `eventType`, `batchNumber`, `quantityDelta`, `expirationDate`, `eventTime`, `locationid`) VALUES (250, 16, 'usage', 1026, -11, '2026-09-01', '2026-03-20 10:45:00', 2);
