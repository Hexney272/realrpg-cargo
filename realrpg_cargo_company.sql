-- ============================================================
-- RealRPG Cargo - Company System Database Schema
-- Version: 1.0
-- Currency: HUF (Ft)
-- ============================================================

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";

-- ============================================================
-- COMPANIES (Fuvarozó vállalkozások)
-- ============================================================

CREATE TABLE IF NOT EXISTS `realrpg_cargo_companies` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `owner_identifier` VARCHAR(255) NOT NULL,
  `balance` BIGINT(20) NOT NULL DEFAULT 0,
  `reputation` INT(11) NOT NULL DEFAULT 0,
  `level` INT(11) NOT NULL DEFAULT 1,
  `max_employees` INT(11) NOT NULL DEFAULT 5,
  `max_vehicles` INT(11) NOT NULL DEFAULT 3,
  `total_deliveries` INT(11) NOT NULL DEFAULT 0,
  `total_distance` FLOAT NOT NULL DEFAULT 0,
  `total_revenue` BIGINT(20) NOT NULL DEFAULT 0,
  `tax_paid` BIGINT(20) NOT NULL DEFAULT 0,
  `logo` VARCHAR(255) DEFAULT '',
  `description` TEXT DEFAULT '',
  `headquarters_zone_id` INT(11) DEFAULT NULL,
  `founded_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_activity` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  KEY `owner_identifier` (`owner_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- EMPLOYEES (Alkalmazottak)
-- ============================================================

CREATE TABLE IF NOT EXISTS `realrpg_cargo_employees` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `company_id` INT(11) NOT NULL,
  `identifier` VARCHAR(255) NOT NULL,
  `role` ENUM('driver', 'dispatcher', 'manager', 'owner') NOT NULL DEFAULT 'driver',
  `salary` INT(11) NOT NULL DEFAULT 0,
  `deliveries_done` INT(11) NOT NULL DEFAULT 0,
  `distance_driven` FLOAT NOT NULL DEFAULT 0,
  `revenue_generated` BIGINT(20) NOT NULL DEFAULT 0,
  `bonus_earned` BIGINT(20) NOT NULL DEFAULT 0,
  `warnings` INT(11) NOT NULL DEFAULT 0,
  `hired_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_delivery` DATETIME DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `company_employee` (`company_id`, `identifier`),
  KEY `identifier` (`identifier`),
  KEY `company_id` (`company_id`),
  CONSTRAINT `fk_employee_company` FOREIGN KEY (`company_id`)
    REFERENCES `realrpg_cargo_companies` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- VEHICLES (Céges járműpark)
-- ============================================================

CREATE TABLE IF NOT EXISTS `realrpg_cargo_vehicles` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `company_id` INT(11) NOT NULL,
  `model` VARCHAR(50) NOT NULL,
  `plate` VARCHAR(20) NOT NULL,
  `display_name` VARCHAR(100) DEFAULT '',
  `health` INT(11) NOT NULL DEFAULT 1000,
  `mileage` FLOAT NOT NULL DEFAULT 0,
  `fuel` INT(11) NOT NULL DEFAULT 100,
  `purchase_price` BIGINT(20) NOT NULL DEFAULT 0,
  `maintenance_cost` BIGINT(20) NOT NULL DEFAULT 0,
  `status` ENUM('available', 'in_use', 'maintenance', 'destroyed') NOT NULL DEFAULT 'available',
  `assigned_to` VARCHAR(255) DEFAULT NULL,
  `last_service` DATETIME DEFAULT NULL,
  `purchased_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `plate` (`plate`),
  KEY `company_id` (`company_id`),
  CONSTRAINT `fk_vehicle_company` FOREIGN KEY (`company_id`)
    REFERENCES `realrpg_cargo_companies` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- CONTRACTS (Szerződések / Megbízások)
-- ============================================================

CREATE TABLE IF NOT EXISTS `realrpg_cargo_contracts` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `company_id` INT(11) DEFAULT NULL,
  `product_id` INT(11) NOT NULL,
  `zone_from` INT(11) NOT NULL,
  `zone_to` INT(11) NOT NULL,
  `reward` BIGINT(20) NOT NULL DEFAULT 0,
  `bonus_reward` BIGINT(20) NOT NULL DEFAULT 0,
  `penalty` BIGINT(20) NOT NULL DEFAULT 0,
  `required_quality` INT(11) NOT NULL DEFAULT 80,
  `deadline_hours` INT(11) NOT NULL DEFAULT 24,
  `status` ENUM('available', 'accepted', 'in_progress', 'completed', 'failed', 'expired') NOT NULL DEFAULT 'available',
  `assigned_driver` VARCHAR(255) DEFAULT NULL,
  `accepted_at` DATETIME DEFAULT NULL,
  `completed_at` DATETIME DEFAULT NULL,
  `delivery_quality` INT(11) DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `expires_at` DATETIME DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `company_id` (`company_id`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- COMPANY TRANSACTIONS (Pénzügyi tranzakciók)
-- ============================================================

CREATE TABLE IF NOT EXISTS `realrpg_cargo_transactions` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `company_id` INT(11) NOT NULL,
  `type` ENUM('delivery_income', 'contract_income', 'contract_bonus', 'salary_payment', 'vehicle_purchase', 'vehicle_maintenance', 'tax', 'registration', 'bonus', 'penalty', 'withdrawal', 'deposit') NOT NULL,
  `amount` BIGINT(20) NOT NULL DEFAULT 0,
  `balance_after` BIGINT(20) NOT NULL DEFAULT 0,
  `description` VARCHAR(255) DEFAULT '',
  `related_identifier` VARCHAR(255) DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `company_id` (`company_id`),
  KEY `type` (`type`),
  CONSTRAINT `fk_transaction_company` FOREIGN KEY (`company_id`)
    REFERENCES `realrpg_cargo_companies` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- COMPANY INVITES (Meghívások)
-- ============================================================

CREATE TABLE IF NOT EXISTS `realrpg_cargo_invites` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `company_id` INT(11) NOT NULL,
  `target_identifier` VARCHAR(255) NOT NULL,
  `invited_by` VARCHAR(255) NOT NULL,
  `role` ENUM('driver', 'dispatcher', 'manager') NOT NULL DEFAULT 'driver',
  `salary` INT(11) NOT NULL DEFAULT 0,
  `status` ENUM('pending', 'accepted', 'declined', 'expired') NOT NULL DEFAULT 'pending',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `expires_at` DATETIME DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `target_identifier` (`target_identifier`),
  KEY `company_id` (`company_id`),
  CONSTRAINT `fk_invite_company` FOREIGN KEY (`company_id`)
    REFERENCES `realrpg_cargo_companies` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

COMMIT;
