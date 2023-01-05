create table catalog.reservation2
(
    id            int auto_increment primary key,
    email         varchar(255) not null,
    name          varchar(255) not null,
    state         varchar(255) not null,
    licenseid     varchar(255) not null,
    dob           date         not null,
    gender        tinyint(1)   not null,
    pickupdate    date         not null,
    dropoffdate   date         not null,
    rate          varchar(255) not null,
    totalamount   varchar(255) not null,
    depositamount varchar(255) not null,
    sku_id        varchar(255) not null,
    configuration varchar(255) null,
    card          varchar(255) not null,
    expiry        varchar(255) not null,
    cvv           varchar(255) not null,
    execution_id  varchar(255) not null,
    status        varchar(45)  not null,
    van_id        varchar(45)  not null
);

create table catalog.vans
(
    image        varchar(255)         not null,
    brand        varchar(255)         not null,
    model        year                 not null,
    type         varchar(255)         not null,
    rentperday   int                  not null,
    description  varchar(255)         not null,
    rentpermonth int                  not null,
    id           int auto_increment
        primary key,
    reserved     tinyint(1) default 1 not null
);



create
    definer = root@`%` procedure catalog.get_vanlist()
BEGIN
  	SELECT * FROM vans;
END;


create
    definer = root@`%` procedure catalog.get_pending_reservation()
BEGIN
   	SELECT * FROM reservation2 where status != 'Returned' ;
END;

