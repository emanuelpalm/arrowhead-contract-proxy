DROP DATABASE IF EXISTS `arrowhead`;
CREATE DATABASE `arrowhead`;
USE `arrowhead`;

-- create tables

CREATE DATABASE IF NOT EXISTS `arrowhead`;

-- Common

CREATE TABLE IF NOT EXISTS `cloud` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `operator` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `secure` int(1) NOT NULL DEFAULT 0 COMMENT 'Is secure?',
  `neighbor` int(1) NOT NULL DEFAULT 0 COMMENT 'Is neighbor cloud?',
  `own_cloud` int(1) NOT NULL DEFAULT 0 COMMENT 'Is own cloud?',
  `authentication_info` varchar(2047) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `cloud` (`operator`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `relay` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `address` varchar(255) NOT NULL,
  `port` int(11) NOT NULL,
  `secure` int(1) NOT NULL DEFAULT 0,
  `exclusive` int(1) NOT NULL DEFAULT 0,
  `type` varchar(255) NOT NULL DEFAULT 'GENERAL_RELAY',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `pair` (`address`, `port`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `cloud_gatekeeper_relay` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `cloud_id` bigint(20) NOT NULL,
  `relay_id` bigint(20) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `pair` (`cloud_id`,`relay_id`),
  CONSTRAINT `gk_cloud_constr` FOREIGN KEY (`cloud_id`) REFERENCES `cloud` (`id`) ON DELETE CASCADE,
  CONSTRAINT `gk_relay_constr` FOREIGN KEY (`relay_id`) REFERENCES `relay` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `cloud_gateway_relay` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `cloud_id` bigint(20) NOT NULL,
  `relay_id` bigint(20) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `pair` (`cloud_id`,`relay_id`),
  CONSTRAINT `gw_cloud_constr` FOREIGN KEY (`cloud_id`) REFERENCES `cloud` (`id`) ON DELETE CASCADE,
  CONSTRAINT `gw_relay_constr` FOREIGN KEY (`relay_id`) REFERENCES `relay` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `system_` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `system_name` varchar(255) NOT NULL,
  `address` varchar(255) NOT NULL,
  `port` int(11) NOT NULL,
  `authentication_info` varchar(2047) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `triple` (`system_name`,`address`,`port`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `service_definition` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `service_definition` varchar(255) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `service_definition` (`service_definition`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `service_interface` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `interface_name` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `interface` (`interface_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT IGNORE INTO `service_interface` (interface_name) VALUES ('HTTP-SECURE-JSON');
INSERT IGNORE INTO `service_interface` (interface_name) VALUES ('HTTP-INSECURE-JSON');

-- Service Registry

CREATE TABLE IF NOT EXISTS `service_registry` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `service_id` bigint(20) NOT NULL,
  `system_id` bigint(20) NOT NULL,
  `service_uri` varchar(255) DEFAULT NULL,
  `end_of_validity` timestamp NULL DEFAULT NULL,
  `secure` varchar(255) NOT NULL DEFAULT 'NOT_SECURE',
  `metadata` text,
  `version` int(11) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `pair` (`service_id`,`system_id`),
  KEY `system` (`system_id`),
  CONSTRAINT `service` FOREIGN KEY (`service_id`) REFERENCES `service_definition` (`id`) ON DELETE CASCADE,
  CONSTRAINT `system` FOREIGN KEY (`system_id`) REFERENCES `system_` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `service_registry_interface_connection` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `service_registry_id` bigint(20) NOT NULL,
  `interface_id` bigint(20) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `pair` (`service_registry_id`,`interface_id`),
  KEY `interface_sr` (`interface_id`),
  CONSTRAINT `interface_sr` FOREIGN KEY (`interface_id`) REFERENCES `service_interface` (`id`) ON DELETE CASCADE,
  CONSTRAINT `service_registry` FOREIGN KEY (`service_registry_id`) REFERENCES `service_registry` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Authorization

CREATE TABLE IF NOT EXISTS `authorization_intra_cloud` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `consumer_system_id` bigint(20) NOT NULL,
  `provider_system_id` bigint(20) NOT NULL,
  `service_id` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `rule` (`consumer_system_id`,`provider_system_id`,`service_id`),
  KEY `provider` (`provider_system_id`),
  KEY `service_intra_auth` (`service_id`),
  CONSTRAINT `service_intra_auth` FOREIGN KEY (`service_id`) REFERENCES `service_definition` (`id`) ON DELETE CASCADE,
  CONSTRAINT `provider` FOREIGN KEY (`provider_system_id`) REFERENCES `system_` (`id`) ON DELETE CASCADE,
  CONSTRAINT `consumer` FOREIGN KEY (`consumer_system_id`) REFERENCES `system_` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `authorization_inter_cloud` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `consumer_cloud_id` bigint(20) NOT NULL,
  `provider_system_id` bigint(20) NOT NULL,
  `service_id` bigint(20) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `rule` (`consumer_cloud_id`, `provider_system_id`, `service_id`),
  KEY `service_inter_auth` (`service_id`),
  CONSTRAINT `cloud` FOREIGN KEY (`consumer_cloud_id`) REFERENCES `cloud` (`id`) ON DELETE CASCADE,
  CONSTRAINT `service_inter_auth` FOREIGN KEY (`service_id`) REFERENCES `service_definition` (`id`) ON DELETE CASCADE,
  CONSTRAINT `provider_inter_auth` FOREIGN KEY (`provider_system_id`) REFERENCES `system_` (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `authorization_inter_cloud_interface_connection` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `authorization_inter_cloud_id` bigint(20) NOT NULL,
  `interface_id` bigint(20) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `pair` (`authorization_inter_cloud_id`,`interface_id`),
  KEY `interface_inter` (`interface_id`),
  CONSTRAINT `auth_inter_interface` FOREIGN KEY (`interface_id`) REFERENCES `service_interface` (`id`) ON DELETE CASCADE,
  CONSTRAINT `auth_inter_cloud` FOREIGN KEY (`authorization_inter_cloud_id`) REFERENCES `authorization_inter_cloud` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `authorization_intra_cloud_interface_connection` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `authorization_intra_cloud_id` bigint(20) NOT NULL,
  `interface_id` bigint(20) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `pair` (`authorization_intra_cloud_id`,`interface_id`),
  KEY `interface_intra` (`interface_id`),
  CONSTRAINT `auth_intra_interface` FOREIGN KEY (`interface_id`) REFERENCES `service_interface` (`id`) ON DELETE CASCADE,
  CONSTRAINT `auth_intra_cloud` FOREIGN KEY (`authorization_intra_cloud_id`) REFERENCES `authorization_intra_cloud` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Orchestrator

CREATE TABLE IF NOT EXISTS `orchestrator_store` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `consumer_system_id` bigint(20) NOT NULL,
  `provider_system_id` bigint(20) NOT NULL,
  `foreign_` int(1) NOT NULL DEFAULT 0,
  `service_id` bigint(20) NOT NULL,
  `service_interface_id` bigint(20) NOT NULL,
  `priority` int(11) NOT NULL,
  `attribute` text,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `priority_rule` (`service_id`, `service_interface_id`, `consumer_system_id`,`priority`),
  UNIQUE KEY `duplication_rule` (`service_id`, `service_interface_id`, `consumer_system_id`,`provider_system_id`, `foreign_`),
  CONSTRAINT `consumer_orch` FOREIGN KEY (`consumer_system_id`) REFERENCES `system_` (`id`) ON DELETE CASCADE,
  CONSTRAINT `service_orch` FOREIGN KEY (`service_id`) REFERENCES `service_definition` (`id`) ON DELETE CASCADE,
  CONSTRAINT `service_intf_orch` FOREIGN KEY (`service_interface_id`) REFERENCES `service_interface` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `foreign_system` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `provider_cloud_id` bigint(20) NOT NULL,
  `system_name` varchar(255) NOT NULL,
  `address` varchar(255) NOT NULL,
  `port` int(11) NOT NULL,
  `authentication_info` varchar(2047) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `triple` (`system_name`,`address`,`port`),
  CONSTRAINT `foreign_cloud` FOREIGN KEY (`provider_cloud_id`) REFERENCES `cloud` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Logs

CREATE TABLE IF NOT EXISTS `logs` (
  `log_id` varchar(100) NOT NULL,
  `entry_date` timestamp NULL DEFAULT NULL,
  `logger` varchar(100) DEFAULT NULL,
  `log_level` varchar(100) DEFAULT NULL,
  `message` text,
  `exception` text,
  PRIMARY KEY (`log_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Event Handler

CREATE TABLE IF NOT EXISTS `event_type` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `event_type_name` varchar(255) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `eventtype` (`event_type_name`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `subscription` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `system_id` bigint(20) NOT NULL,
  `event_type_id` bigint(20) NOT NULL,
  `filter_meta_data` text,
  `match_meta_data` int(1) NOT NULL DEFAULT 0,
  `only_predefined_publishers` int(1) NOT NULL DEFAULT 0,
  `notify_uri` text NOT NULL,
  `start_date` timestamp NULL DEFAULT NULL,
  `end_date` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `pair` (`event_type_id`,`system_id`),
  CONSTRAINT `subscriber_system` FOREIGN KEY (`system_id`) REFERENCES `system_` (`id`) ON DELETE CASCADE,
  CONSTRAINT `event_type` FOREIGN KEY (`event_type_id`) REFERENCES `event_type` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `subscription_publisher_connection` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `subscription_id` bigint(20) NOT NULL,
  `system_id` bigint(20) NOT NULL,
  `authorized` int(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `pair` (`subscription_id`,`system_id`),
  CONSTRAINT `subscription_constraint` FOREIGN KEY (`subscription_id`) REFERENCES `subscription` (`id`) ON DELETE CASCADE,
  CONSTRAINT `system_constraint` FOREIGN KEY (`system_id`) REFERENCES `system_` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Choreographer

CREATE TABLE IF NOT EXISTS `choreographer_action_plan` (
  `id` bigint(20) PRIMARY KEY AUTO_INCREMENT,
  `action_plan_name` varchar(255) UNIQUE NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `choreographer_action` (
  `id` bigint(20) PRIMARY KEY AUTO_INCREMENT,
  `action_name` varchar(255) UNIQUE NOT NULL,
  `next_action_id` bigint(20) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `next_action` FOREIGN KEY (`next_action_id`) REFERENCES `choreographer_action` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `choreographer_action_step` (
  `id` bigint(20) PRIMARY KEY AUTO_INCREMENT,
  `name` varchar(255) UNIQUE NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `choreographer_action_plan_action_connection` (
  `id` bigint(20) PRIMARY KEY AUTO_INCREMENT,
  `action_plan_id` bigint(20) NOT NULL,
  `action_id` bigint(20) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `action_plan_fk1` FOREIGN KEY (`action_plan_id`) REFERENCES `choreographer_action_plan` (`id`) ON DELETE CASCADE,
  CONSTRAINT `action_fk1` FOREIGN KEY (`action_id`) REFERENCES `choreographer_action` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `choreographer_action_action_step_connection` (
  `id` bigint(20) PRIMARY KEY AUTO_INCREMENT,
  `action_id` bigint(20) NOT NULL,
  `action_step_id` bigint(20) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `action_fk2` FOREIGN KEY (`action_id`) REFERENCES `choreographer_action` (`id`) ON DELETE CASCADE,
  CONSTRAINT `action_step_fk1` FOREIGN KEY (`action_step_id`) REFERENCES `choreographer_action_step` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `choreographer_action_step_service_definition_connection` (
  `id` bigint(20) PRIMARY KEY AUTO_INCREMENT,
  `action_step_id` bigint(20) NOT NULL,
  `service_definition_id` bigint(20) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `service_definition` FOREIGN KEY (`service_definition_id`) REFERENCES `service_definition` (`id`) ON DELETE CASCADE,
  CONSTRAINT `action_step` FOREIGN KEY (`action_step_id`) REFERENCES `choreographer_action_step` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `choreographer_next_action_step` (
  `id` bigint(20) PRIMARY KEY AUTO_INCREMENT,
  `action_step_id` bigint(20) NOT NULL,
  `next_action_step_id` bigint(20) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `current_action_step` FOREIGN KEY (`action_step_id`) REFERENCES `choreographer_action_step` (`id`) ON DELETE CASCADE,
  CONSTRAINT `next_action_step` FOREIGN KEY (`action_step_id`) REFERENCES `choreographer_action_step` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Set up privileges

-- Service Registry
CREATE USER IF NOT EXISTS 'service_registry'@'localhost' IDENTIFIED BY 'ZzNNpxrbZGVvfJ8';
CREATE USER IF NOT EXISTS 'service_registry'@'%' IDENTIFIED BY 'ZzNNpxrbZGVvfJ8';

REVOKE ALL, GRANT OPTION FROM 'service_registry'@'localhost';

GRANT ALL PRIVILEGES ON `arrowhead`.`system_` TO 'service_registry'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`service_definition` TO 'service_registry'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`service_interface` TO 'service_registry'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`service_registry` TO 'service_registry'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`service_registry_interface_connection` TO 'service_registry'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`cloud` TO 'service_registry'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`relay` TO 'service_registry'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`cloud_gatekeeper_relay` TO 'service_registry'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`cloud_gateway_relay` TO 'service_registry'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`authorization_intra_cloud` TO 'service_registry'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`authorization_intra_cloud_interface_connection` TO 'service_registry'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`authorization_inter_cloud` TO 'service_registry'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`authorization_inter_cloud_interface_connection` TO 'service_registry'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`orchestrator_store` TO 'service_registry'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`subscription` TO 'service_registry'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`subscription_publisher_connection` TO 'service_registry'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`choreographer_action_plan` TO 'service_registry'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`choreographer_action` TO 'service_registry'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`choreographer_action_step` TO 'service_registry'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`choreographer_action_plan_action_connection` TO 'service_registry'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`choreographer_action_action_step_connection` TO 'service_registry'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`choreographer_action_step_service_definition_connection` TO 'service_registry'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`choreographer_next_action_step` TO 'service_registry'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`logs` TO 'service_registry'@'localhost';

REVOKE ALL, GRANT OPTION FROM 'service_registry'@'%';

GRANT ALL PRIVILEGES ON `arrowhead`.`system_` TO 'service_registry'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`service_definition` TO 'service_registry'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`service_interface` TO 'service_registry'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`service_registry` TO 'service_registry'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`service_registry_interface_connection` TO 'service_registry'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`cloud` TO 'service_registry'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`relay` TO 'service_registry'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`cloud_gatekeeper_relay` TO 'service_registry'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`cloud_gateway_relay` TO 'service_registry'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`authorization_intra_cloud` TO 'service_registry'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`authorization_intra_cloud_interface_connection` TO 'service_registry'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`authorization_inter_cloud` TO 'service_registry'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`authorization_inter_cloud_interface_connection` TO 'service_registry'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`orchestrator_store` TO 'service_registry'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`subscription` TO 'service_registry'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`subscription_publisher_connection` TO 'service_registry'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`choreographer_action_plan` TO 'service_registry'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`choreographer_action` TO 'service_registry'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`choreographer_action_step` TO 'service_registry'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`choreographer_action_plan_action_connection` TO 'service_registry'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`choreographer_action_action_step_connection` TO 'service_registry'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`choreographer_action_step_service_definition_connection` TO 'service_registry'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`choreographer_next_action_step` TO 'service_registry'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`logs` TO 'service_registry'@'%';

FLUSH PRIVILEGES;

-- Authorization
CREATE USER IF NOT EXISTS 'authorization'@'localhost' IDENTIFIED BY 'hqZFUkuHxhekio3';
CREATE USER IF NOT EXISTS 'authorization'@'%' IDENTIFIED BY 'hqZFUkuHxhekio3';

REVOKE ALL, GRANT OPTION FROM 'authorization'@'localhost';

GRANT ALL PRIVILEGES ON `arrowhead`.`authorization_intra_cloud` TO 'authorization'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`authorization_intra_cloud_interface_connection` TO 'authorization'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`authorization_inter_cloud` TO 'authorization'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`authorization_inter_cloud_interface_connection` TO 'authorization'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`system_` TO 'authorization'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`cloud` TO 'authorization'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`relay` TO 'authorization'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`cloud_gatekeeper_relay` TO 'authorization'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`cloud_gateway_relay` TO 'authorization'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`service_definition` TO 'authorization'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`service_interface` TO 'authorization'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`logs` TO 'authorization'@'localhost';

REVOKE ALL, GRANT OPTION FROM 'authorization'@'%';

GRANT ALL PRIVILEGES ON `arrowhead`.`authorization_intra_cloud` TO 'authorization'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`authorization_intra_cloud_interface_connection` TO 'authorization'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`authorization_inter_cloud` TO 'authorization'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`authorization_inter_cloud_interface_connection` TO 'authorization'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`system_` TO 'authorization'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`cloud` TO 'authorization'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`relay` TO 'authorization'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`cloud_gatekeeper_relay` TO 'authorization'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`cloud_gateway_relay` TO 'authorization'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`service_definition` TO 'authorization'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`service_interface` TO 'authorization'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`logs` TO 'authorization'@'%';

FLUSH PRIVILEGES;

-- Orchestrator
CREATE USER IF NOT EXISTS 'orchestrator'@'localhost' IDENTIFIED BY 'KbgD2mTr8DQ4vtc';
CREATE USER IF NOT EXISTS 'orchestrator'@'%' IDENTIFIED BY 'KbgD2mTr8DQ4vtc';

REVOKE ALL, GRANT OPTION FROM 'orchestrator'@'localhost';

GRANT ALL PRIVILEGES ON `arrowhead`.`orchestrator_store` TO 'orchestrator'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`foreign_system` TO 'orchestrator'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`system_` TO 'orchestrator'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`cloud` TO 'orchestrator'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`relay` TO 'orchestrator'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`cloud_gatekeeper_relay` TO 'orchestrator'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`cloud_gateway_relay` TO 'orchestrator'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`service_definition` TO 'orchestrator'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`service_interface` TO 'orchestrator'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`logs` TO 'orchestrator'@'localhost';

REVOKE ALL, GRANT OPTION FROM 'orchestrator'@'%';

GRANT ALL PRIVILEGES ON `arrowhead`.`orchestrator_store` TO 'orchestrator'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`foreign_system` TO 'orchestrator'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`system_` TO 'orchestrator'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`cloud` TO 'orchestrator'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`relay` TO 'orchestrator'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`cloud_gatekeeper_relay` TO 'orchestrator'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`cloud_gateway_relay` TO 'orchestrator'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`service_definition` TO 'orchestrator'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`service_interface` TO 'orchestrator'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`logs` TO 'orchestrator'@'%';

FLUSH PRIVILEGES;

-- Event Handler
CREATE USER IF NOT EXISTS 'event_handler'@'localhost' IDENTIFIED BY 'gRLjXbqu9YwYhfK';
CREATE USER IF NOT EXISTS 'event_handler'@'%' IDENTIFIED BY 'gRLjXbqu9YwYhfK';

REVOKE ALL, GRANT OPTION FROM 'event_handler'@'localhost';

GRANT ALL PRIVILEGES ON `arrowhead`.`event_type` TO 'event_handler'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`subscription` TO 'event_handler'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`subscription_publisher_connection` TO 'event_handler'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`system_` TO 'event_handler'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`logs` TO 'event_handler'@'localhost';

REVOKE ALL, GRANT OPTION FROM 'event_handler'@'%';

GRANT ALL PRIVILEGES ON `arrowhead`.`event_type` TO 'event_handler'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`subscription` TO 'event_handler'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`subscription_publisher_connection` TO 'event_handler'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`system_` TO 'event_handler'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`logs` TO 'event_handler'@'%';

FLUSH PRIVILEGES;

-- Choreographer
CREATE USER IF NOT EXISTS 'choreographer'@'localhost' IDENTIFIED BY 'Qa5yx4oBp4Y9RLX';
CREATE USER IF NOT EXISTS 'choreographer'@'%' IDENTIFIED BY 'Qa5yx4oBp4Y9RLX';

REVOKE ALL, GRANT OPTION FROM 'choreographer'@'localhost';

GRANT ALL PRIVILEGES ON `arrowhead`.`choreographer_action_plan` TO 'choreographer'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`choreographer_action` TO 'choreographer'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`choreographer_action_step` TO 'choreographer'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`choreographer_action_plan_action_connection` TO 'choreographer'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`choreographer_action_action_step_connection` TO 'choreographer'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`choreographer_action_step_service_definition_connection` TO 'choreographer'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`choreographer_next_action_step` TO 'choreographer'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`service_definition` TO 'choreographer'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`logs` TO 'choreographer'@'localhost';

REVOKE ALL, GRANT OPTION FROM 'choreographer'@'%';

GRANT ALL PRIVILEGES ON `arrowhead`.`choreographer_action_plan` TO 'choreographer'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`choreographer_action` TO 'choreographer'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`choreographer_action_step` TO 'choreographer'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`choreographer_action_plan_action_connection` TO 'choreographer'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`choreographer_action_action_step_connection` TO 'choreographer'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`choreographer_action_step_service_definition_connection` TO 'choreographer'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`choreographer_next_action_step` TO 'choreographer'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`service_definition` TO 'choreographer'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`logs` TO 'choreographer'@'%';

FLUSH PRIVILEGES;

-- Gatekeeper
CREATE USER IF NOT EXISTS 'gatekeeper'@'localhost' IDENTIFIED BY 'fbJKYzKhU5t8QtT';
CREATE USER IF NOT EXISTS 'gatekeeper'@'%' IDENTIFIED BY 'fbJKYzKhU5t8QtT';

REVOKE ALL, GRANT OPTION FROM 'gatekeeper'@'localhost';

GRANT ALL PRIVILEGES ON `arrowhead`.`cloud` TO 'gatekeeper'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`relay` TO 'gatekeeper'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`system_` TO 'gatekeeper'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`service_definition` TO 'gatekeeper'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`cloud_gatekeeper_relay` TO 'gatekeeper'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`cloud_gateway_relay` TO 'gatekeeper'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`authorization_inter_cloud` TO 'gatekeeper'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`authorization_inter_cloud_interface_connection` TO 'gatekeeper'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`foreign_system` TO 'gatekeeper'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`logs` TO 'gatekeeper'@'localhost';

REVOKE ALL, GRANT OPTION FROM 'gatekeeper'@'%';

GRANT ALL PRIVILEGES ON `arrowhead`.`cloud` TO 'gatekeeper'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`relay` TO 'gatekeeper'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`system_` TO 'gatekeeper'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`service_definition` TO 'gatekeeper'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`cloud_gatekeeper_relay` TO 'gatekeeper'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`cloud_gateway_relay` TO 'gatekeeper'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`authorization_inter_cloud` TO 'gatekeeper'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`authorization_inter_cloud_interface_connection` TO 'gatekeeper'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`foreign_system` TO 'gatekeeper'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`logs` TO 'gatekeeper'@'%';

FLUSH PRIVILEGES;

-- Gateway
CREATE USER IF NOT EXISTS 'gateway'@'localhost' IDENTIFIED BY 'LfiSM9DpGfDEP5g';
CREATE USER IF NOT EXISTS 'gateway'@'%' IDENTIFIED BY 'LfiSM9DpGfDEP5g';

REVOKE ALL, GRANT OPTION FROM 'gateway'@'localhost';
GRANT ALL PRIVILEGES ON `arrowhead`.`logs` TO 'gateway'@'localhost';

REVOKE ALL, GRANT OPTION FROM 'gateway'@'%';
GRANT ALL PRIVILEGES ON `arrowhead`.`logs` TO 'gateway'@'%';

FLUSH PRIVILEGES;