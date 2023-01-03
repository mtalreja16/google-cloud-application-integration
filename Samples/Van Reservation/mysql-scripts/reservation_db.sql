use catalog;

CREATE TABLE `reservation2` (
  `id` int NOT NULL AUTO_INCREMENT,
  `email` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `state` varchar(255) NOT NULL,
  `licenseid` varchar(255) NOT NULL,
  `dob` date NOT NULL,
  `gender` tinyint(1) NOT NULL,
  `pickupdate` date NOT NULL,
  `dropoffdate` date NOT NULL,
  `rate` varchar(255) NOT NULL,
  `taxamount` varchar(255) DEFAULT NULL,
  `totalamount` varchar(255) NOT NULL,
  `depositamount` varchar(255) NOT NULL,
  `sku_id` varchar(255) NOT NULL,
  `configuration` varchar(255) DEFAULT NULL,
  `card` varchar(255) NOT NULL,
  `expiry` varchar(255) NOT NULL,
  `cvv` varchar(255) NOT NULL,
  `execution_id` varchar(255) NOT NULL,
  `status` varchar(45) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb3;

DELIMITER //

DELIMITER $$
CREATE DEFINER=`root`@`%` PROCEDURE `get_pending_reservation`()
BEGIN
 SELECT * FROM reservation2;
END$$
DELIMITER ;
