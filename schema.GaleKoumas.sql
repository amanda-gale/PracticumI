-- Create Tables --
-- Gale Koumas Practicum I --
-- Fall 2026 --

CREATE TABLE IF NOT EXISTS restaurants (
  rid INTEGER PRIMARY KEY,
  restaurantname VARCHAR(50) NOT NULL,
  city VARCHAR(50) NOT NULL,
  state VARCHAR(2) NOT NULL,
  hastableservice TINYINT(1) NOT NULL DEFAULT 0 CHECK (hastableservice IN (0, 1))
);

CREATE TABLE IF NOT EXISTS customers (
  cid INTEGER PRIMARY KEY,
  customername VARCHAR(50) DEFAULT NULL,
  customerphone VARCHAR(20) DEFAULT NULL,
  customeremail VARCHAR(50) DEFAULT NULL CHECK (CustomerEmail = '' OR CustomerEmail LIKE '%_@_%._%'),
  loyaltymember TINYINT(1) NOT NULL DEFAULT 0 CHECK (loyaltymember IN (0, 1))
);

CREATE TABLE IF NOT EXISTS paymentmethods (
  pmid INTEGER PRIMARY KEY,
  paymentmethod VARCHAR(15) NOT NULL UNIQUE CHECK (paymentmethod IN ('Mobile Payment', 'Credit Card', 'Cash'))
);

CREATE TABLE IF NOT EXISTS mealtypes (
  mtid INTEGER PRIMARY KEY,
  mealtype VARCHAR(10) NOT NULL UNIQUE CHECK (mealtype IN ('Breakfast', 'Lunch', 'Dinner', 'Take-Out'))
);

CREATE TABLE IF NOT EXISTS servers (
  empid INTEGER PRIMARY KEY,
  rid INTEGER NOT NULL,
  servername VARCHAR(50) NOT NULL,
  startdatehired DATE DEFAULT NULL,
  enddatehired DATE DEFAULT NULL,
  hourlyrate DECIMAL(4, 2) NOT NULL DEFAULT 0 CHECK (hourlyrate >= 0),
  birthdate DATE DEFAULT NULL,
  ssn CHAR(11) DEFAULT NULL UNIQUE,
  CONSTRAINT chk_ssn_format
        CHECK (SSN REGEXP '^[0-9]{3}-[0-9]{2}-[0-9]{4}$'),
  CONSTRAINT chk_server_dates
        CHECK (
            enddatehired IS NULL
            OR startdatehired IS NULL
            OR enddatehired >= startdatehired
        ),
  FOREIGN KEY (rid) REFERENCES restaurants(rid)
);

CREATE TABLE IF NOT EXISTS bill (
  billid INTEGER PRIMARY KEY,
  foodbill DECIMAL(10, 2) NOT NULL DEFAULT 0 CHECK (foodbill >= 0),
  tipamount DECIMAL(10, 2) NOT NULL DEFAULT 0 CHECK (tipamount >= 0),
  fooddiscountpercentage DECIMAL (10, 2) NOT NULL DEFAULT 0 CHECK (fooddiscountpercentage BETWEEN 0 AND 1),
  pmid INTEGER NOT NULL,
  orderedalcohol TINYINT(1) NOT NULL DEFAULT 0 CHECK (orderedalcohol IN (0, 1)),
  alcoholbill DECIMAL(10, 2) NOT NULL DEFAULT 0 CHECK (alcoholbill >= 0),
  CONSTRAINT check_alcohol_flag CHECK (alcoholbill = 0 OR orderedalcohol = 1), 
  FOREIGN KEY (pmid) REFERENCES paymentmethods(pmid)
);

CREATE TABLE IF NOT EXISTS visits (
  visitid INTEGER PRIMARY KEY,
  customerid INTEGER DEFAULT NULL,
  restaurantid INTEGER NOT NULL,
  serverempid INTEGER DEFAULT NULL,
  billid INTEGER NOT NULL UNIQUE,
  mtid INTEGER NOT NULL,
  visitdate DATE NOT NULL,
  visittime TIME DEFAULT NULL,
  partysize INTEGER DEFAULT NULL CHECK (partysize BETWEEN 1 AND 20),
  waittime INTEGER DEFAULT NULL CHECK (waittime BETWEEN 0 AND 120),
  FOREIGN KEY (customerid) REFERENCES customers(cid),
  FOREIGN KEY (restaurantid) REFERENCES restaurants(rid),
  FOREIGN KEY (serverempid) REFERENCES servers(empid),
  FOREIGN KEY (billid) REFERENCES bill(billid),
  FOREIGN KEY (mtid) REFERENCES mealtypes(mtid)
);
