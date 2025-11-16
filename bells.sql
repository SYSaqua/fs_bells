CREATE TABLE IF NOT EXISTS `fs_bells` (
  `job` varchar(50) NOT NULL,
  `label` varchar(50) NOT NULL,
  `coords` varchar(255) NOT NULL,
  PRIMARY KEY (`job`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;