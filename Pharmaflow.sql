CREATE TABLE `Items`(
    `itemid` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `itemName` VARCHAR(255) NOT NULL,
    `unitType` VARCHAR(255) NOT NULL,
    `catagoryID` BIGINT NOT NULL,
    `availabilityStatus` ENUM('high', 'moderate', 'constrained', 'shortage_risk', 'unknown') NOT NULL,
    `availabilityScore` DECIMAL(8, 2) NOT NULL,
    `lastUpdate` DATETIME NOT NULL
);
CREATE TABLE `Location`(
    `locationid` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `locationType` ENUM('hospital', 'pharmacy') NOT NULL,
    `locationName` VARCHAR(255) NOT NULL
);
CREATE TABLE `Catagories`(
    `catagoryid` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `catagoryName` VARCHAR(255) NOT NULL,
    `endpoint` VARCHAR(255) NOT NULL,
    `parameters` VARCHAR(255) NOT NULL,
);
CREATE TABLE `PatientVisits`(
    `visitid` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `Catagoryid` BIGINT NOT NULL,
    `visitNumber` DECIMAL(10, 4) NOT NULL,
    `visitDay` DATETIME NOT NULL
);
CREATE TABLE `InventoryEvents`(
    `eventid` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `itemid` BIGINT NOT NULL,
    `batchNumber` BIGINT NOT NULL,
    `quantityDelta` INT NOT NULL,
    `expirationDate` DATE NOT NULL,
    `eventTime` DATETIME NOT NULL,
    `locationid` BIGINT NOT NULL
);
ALTER TABLE
    `PatientVisits` ADD CONSTRAINT `patientvisits_catagoryid_foreign` FOREIGN KEY(`Catagoryid`) REFERENCES `Catagories`(`catagoryid`);
ALTER TABLE
    `InventoryEvents` ADD CONSTRAINT `inventoryevents_locationid_foreign` FOREIGN KEY(`locationid`) REFERENCES `Location`(`locationid`);
ALTER TABLE
    `InventoryEvents` ADD CONSTRAINT `inventoryevents_itemid_foreign` FOREIGN KEY(`itemid`) REFERENCES `Items`(`itemid`);
ALTER TABLE
    `Items` ADD CONSTRAINT `items_catagoryid_foreign` FOREIGN KEY(`catagoryID`) REFERENCES `Catagories`(`catagoryid`);