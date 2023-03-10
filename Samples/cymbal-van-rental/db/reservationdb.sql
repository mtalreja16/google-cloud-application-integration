
create table reservation2 ( id int auto_increment primary key, email varchar(255) not null, name  varchar(255) not null, state varchar(255) not null, licenseid varchar(255) not null, dob  date not null, gender tinyint(1)  not null, pickupdate  date not null, dropoffdate  date not null, rate  varchar(255) not null, totalamount  varchar(255) not null, depositamount varchar(255) not null, sku_id varchar(255) not null, configuration varchar(255) null, card  varchar(255) not null, expiry varchar(255) not null, cvv  varchar(255) not null, execution_id varchar(255) not null, status varchar(45) not null, van_id varchar(45) not null );
create table vans ( image varchar(255) not null, brand varchar(255) not null, model year  not null, type varchar(255) not null, rentperday  int  not null, description varchar(255) not null, rentpermonth int  not null, id  int auto_increment primary key, reserved tinyint(1) default 1 not null );
INSERT INTO vans (id, image, brand, model, type, rentperday, description, rentpermonth, reserved) VALUES (NULL,  "img/image1.jpg ",  "Thor Industries ", 2018,  "family-van ", 150,  "Sleep 8, 32 Feet, Class A ", 1350, 0);
INSERT INTO vans (id, image, brand, model, type, rentperday, description, rentpermonth, reserved) VALUES (NULL,  "img/image2.jpg ",  "Mercedes Benz ", 2012,  "sport-van ", 175,  "Sleep 6, 20 Feet, Class C ", 2500, 0);
INSERT INTO vans (id, image, brand, model, type, rentperday, description, rentpermonth, reserved) VALUES (NULL,  "img/image3.jpg ",  "Forest River ", 2018,  "sport-van ", 145,  "Sleep 6, 20 Feet, Class C ", 1200, 0);
INSERT INTO vans (id, image, brand, model, type, rentperday, description, rentpermonth, reserved) VALUES (NULL,  "img/image4.jpg ",  "Winnebago ", 2017,  "family-van ", 155,  "Sleep 8, 32 Feet, Class A ", 1360, 0);
INSERT INTO vans (id, image, brand, model, type, rentperday, description, rentpermonth, reserved) VALUES (NULL,  "img/image5.jpg ",  "Jayco ", 2016,  "family-van ", 140,  "Sleep 8, 32 Feet, Class A ", 1150, 0);
INSERT INTO vans (id, image, brand, model, type, rentperday, description, rentpermonth, reserved) VALUES (NULL,  "img/image6.jpg ",  "Newmar ", 2008,  "sport-van ", 150,  "Sleep 6, 20 Feet, Class C ", 1400, 0);

DELIMITER //
CREATE PROCEDURE get_pending_reservation()
BEGIN
    SELECT * FROM reservation2 WHERE status != 'Returned';
END //
DELIMITER ;


DELIMITER //
create  procedure get_vanlist()
BEGIN
  	SELECT * FROM vans;
END //
DELIMITER ;
