-- CREATING THE DATABASE TO LOAD DATA FROM CSV FILES

CREATE DATABASE Olist_Ecommerce;

-- DATA CLEANING AND VALIDATION.
USE Olist_Ecommerce;

-- MADE ERD FROM OLIST DATASET AND DETERMINED RELATIONSHIPS AMONG THE DIFFERENT ENTITITES.

-- CHANGING TABLE NAMES.

EXEC sp_rename 'OLIST_CUSTOMERS_DATASET', 'R_CUSTOMER';
EXEC sp_rename 'OLIST_GEOLOCATION_DATASET', 'R_GEOLOCATION';
EXEC sp_rename 'OLIST_ORDER_ITEMS_DATASET', 'R_ORDER_ITEM';
EXEC sp_rename 'OLIST_ORDER_PAYMENTS_DATASET', 'R_ORDER_PAYMENT';
EXEC sp_rename 'OLIST_ORDER_REVIEWS_DATASET','R_ORDER_REVIEW';
EXEC sp_rename 'OLIST_ORDERS_DATASET','R_ORDER';
EXEC sp_rename 'OLIST_PRODUCTS_DATASET','R_PRODUCT';
EXEC sp_rename 'OLIST_SELLERS_DATASET','R_SELLER';
EXEC sp_rename 'PRODUCT_CATEGORY_NAME_TRANSLATION','R_PROD_CATG_NAME_TRANSL';


--------------------------------------------------------------------------------------------------------------------------------------------------
-- DATA VALIDATION ADN CLEANING
-- MOVING DATA TO STAGED TABLES TO PERFORM SAFE DATA CLEANING

SELECT * INTO STG_CUSTOMER FROM R_CUSTOMER;
SELECT * INTO STG_GEOLOCATION FROM R_GEOLOCATION;
SELECT * INTO STG_ORDER_ITEM FROM R_ORDER_ITEM;
SELECT * INTO STG_ORDER_PAYMENT FROM R_ORDER_PAYMENT;
SELECT * INTO STG_ORDER_REVIEW FROM R_ORDER_REVIEW;
SELECT * INTO STG_ORDER FROM R_ORDER;
SELECT * INTO STG_PRODUCT FROM R_PRODUCT;
SELECT * INTO STG_SELLER FROM R_SELLER;
SELECT * INTO STG_PROD_CATG_NAME_TRANSL FROM R_PROD_CATG_NAME_TRANSL;

--------------------------------------------------------------------------------------------------------------------------------------------------
-- DATA VALIDATION AND CLEANING (CHECKING DUPLICATES AND NULLS. REMOVING UNECCESARY FIELDS,CHECKING DATA TYPES, FOREIGN KEY CONSTRAINTS)
--------------------------------------------------------------------------------------------------------------------------------------------------
-- STG_CUSTOMER
-- DUPLICATES
SELECT CUSTOMER_ID, COUNT(CUSTOMER_ID) AS DUPLICATE FROM STG_CUSTOMER GROUP BY customer_id HAVING COUNT(customer_id) > 1;
SELECT CUSTOMER_UNIQUE_ID, COUNT(customer_unique_id) AS DUPLICATE FROM STG_CUSTOMER GROUP BY customer_unique_id HAVING COUNT(customer_unique_id) > 1

-- NULLS
SELECT customer_id FROM STG_CUSTOMER WHERE customer_id IS NULL;
SELECT customer_unique_id FROM STG_CUSTOMER WHERE customer_unique_id IS NULL;
SELECT customer_zip_code_prefix FROM STG_CUSTOMER WHERE customer_zip_code_prefix IS NULL;

-- REMOVING UNECESSARY COLUMNS
ALTER TABLE STG_CUSTOMER
DROP COLUMN CUSTOMER_CITY;
ALTER TABLE STG_CUSTOMER
DROP COLUMN CUSTOMER_STATE;

-- CHANGING COLUMN NAME
EXEC sp_rename 'STG_CUSTOMER.CUSTOMER_ZIP_CODE_PREFIX', 'Loc_zip_code', 'COLUMN';

--------------------------------------------------------------------------------------------------------------------------------------------------
-- STG_GEOLOCATION
-- DUPLICATES
SELECT geolocation_zip_code_prefix, COUNT(geolocation_zip_code_prefix) AS DUPLICATE FROM STG_GEOLOCATION 
GROUP BY geolocation_zip_code_prefix HAVING COUNT(geolocation_zip_code_prefix) > 1;
-- NULLS
SELECT geolocation_zip_code_prefix FROM STG_GEOLOCATION WHERE geolocation_zip_code_prefix IS NULL;
SELECT geolocation_lat FROM STG_GEOLOCATION WHERE geolocation_lat IS NULL;
SELECT geolocation_lng FROM STG_GEOLOCATION WHERE geolocation_lng IS NULL;

-- AS COLUMN GEOLOCATION_ZIP_CODE_PREFIX HAS DUPLCATES, THIS CAUSES M-M RELATIONSHIP BETWEEN GEOLOCATION WITH BOTH SELLER AND CUSTOMER. 
-- TO SOLVE THAT WE MAKE ANOTHER TABLE LOCATION THAT HOUSES UNIQUE ZIPCODES ALONG WITH CITY AND STATE. THIS WILL BREAK THE M-M RELATIONSHIP INTO 
-- 1-M RELATIONSHIP.

CREATE TABLE R_LOCATION (
Zip_code VARCHAR(10) PRIMARY KEY,
City VARCHAR(100) NOT NULL,
State VARCHAR(50) NOT NULL
);

INSERT INTO R_LOCATION (Zip_code, City, State)
SELECT DISTINCT geolocation_zip_code_prefix, MIN(geolocation_city) AS City, MIN(geolocation_state) AS State
FROM STG_GEOLOCATION
GROUP BY geolocation_zip_code_prefix;

-- REMOVING UNECESSARY COLUMNS FROM GEOLOCATION
ALTER TABLE STG_GEOLOCATION
DROP COLUMN GEOLOCATION_CITY;
ALTER TABLE STG_GEOLOCATION
DROP COLUMN GEOLOCATION_STATE
SELECT * FROM STG_GEOLOCATION

-- CHANGING NAME OF COLUMN IN STG GEOLOCATION TABLE
EXEC sp_rename 'STG_GEOLOCATION.GEOLOCATION_ZIP_CODE_PREFIX', 'Loc_zip_code', 'COLUMN';
--------------------------------------------------------------------------------------------------------------------------------------------------
-- STG_ORDER
-- DUPLICATES
SELECT ORDER_ID , COUNT(ORDER_ID) AS DUPLICATE FROM STG_ORDER GROUP BY ORDER_ID HAVING COUNT(ORDER_ID) > 1;
SELECT CUSTOMER_ID , COUNT(CUSTOMER_ID) AS DUPLICATE FROM STG_ORDER GROUP BY customer_id HAVING COUNT(CUSTOMER_ID) > 1;

-- NULLS
SELECT * FROM STG_ORDER WHERE order_id IS NULL;
SELECT * FROM STG_ORDER WHERE customer_id IS NULL;
SELECT * FROM STG_ORDER WHERE order_status IS NULL;

--------------------------------------------------------------------------------------------------------------------------------------------------
-- STG ORDER ITEM
-- DUPLICATES
SELECT * FROM STG_ORDER_ITEM
SELECT order_id, order_item_id, COUNT(*) AS DUPLICATE FROM STG_ORDER_ITEM GROUP BY order_id, order_item_id HAVING COUNT(*) > 1;

-- NULLS
SELECT ORDER_ID FROM STG_ORDER_ITEM WHERE ORDER_ID IS NULL;
SELECT order_item_id FROM STG_ORDER_ITEM WHERE order_item_id IS NULL;
SELECT product_id FROM STG_ORDER_ITEM WHERE product_id IS NULL;
SELECT price FROM STG_ORDER_ITEM WHERE price IS NULL; 
SELECT freight_value FROM STG_ORDER_ITEM WHERE freight_value IS NULL;

--------------------------------------------------------------------------------------------------------------------------------------------------
-- STG ORDER PAYMENT
-- DUPLICATES
SELECT order_id, payment_sequential, COUNT(*) DUPLICATE FROM STG_ORDER_PAYMENT GROUP BY order_id, payment_sequential HAVING COUNT(*) >1;

-- NULLS
SELECT * FROM STG_ORDER_PAYMENT WHERE ORDER_ID IS NULL;
SELECT * FROM STG_ORDER_PAYMENT WHERE payment_sequential IS NULL;
SELECT * FROM STG_ORDER_PAYMENT WHERE payment_value IS NULL;

--------------------------------------------------------------------------------------------------------------------------------------------------
-- STG ORDER REVIEW
-- DUPLICATES
SELECT review_id,ORDER_ID, COUNT(*) AS DUPLICATE FROM STG_ORDER_REVIEW GROUP BY review_id, order_id HAVING COUNT(*) > 1;

-- NULLS
SELECT * FROM STG_ORDER_REVIEW WHERE review_id IS NULL;
SELECT * FROM STG_ORDER_REVIEW WHERE order_id IS NULL;

--------------------------------------------------------------------------------------------------------------------------------------------------
-- STG PROD CATG NAME TRANSL
-- DUPLICATES
SELECT product_category_name, COUNT(product_category_name) DUPLICATE FROM STG_PROD_CATG_NAME_TRANSL GROUP BY product_category_name HAVING COUNT(*) > 1;

-- NULLS 
SELECT * FROM STG_PROD_CATG_NAME_TRANSL WHERE product_category_name IS NULL;
SELECT * FROM STG_PROD_CATG_NAME_TRANSL WHERE product_category_name_english IS NULL;

--------------------------------------------------------------------------------------------------------------------------------------------------
-- STG PRODUCT
-- DUPLICATES
SELECT product_id, COUNT(product_id) DUPLICATE FROM STG_PRODUCT GROUP BY product_id HAVING COUNT(PRODUCT_ID) >1;

-- NULLS
SELECT * FROM STG_PRODUCT WHERE product_id IS NULL;

-- REMOVING UNECCESARY FEILDS (CITY, STATE)

ALTER TABLE STG_SELLER
DROP COLUMN SELLER_CITY;
ALTER TABLE STG_SELLER
DROP COLUMN SELLER_STATE;

-- CHANGING NAME OF COLUMN
EXEC sp_rename 'STG_SELLER.SELLER_ZIP_CODE_PREFIX', 'Loc_zip_code', 'COLUMN';

--------------------------------------------------------------------------------------------------------------------------------------------------
-- BASED ON THE ASSESMENT, DATA SEEMS TO HAVE NO DUPLICATES AND NO NULL VALUES IN THE DESIRED COLUMNS.
--------------------------------------------------------------------------------------------------------------------------------------------------

-- CREATING NEW TABLES WITH DESIRED DATA TYPES AND CONSTRAINTS.

--------------------------------------------------------------------------------------------------------------------------------------------------
-- STG CUSTOMER
-- CHECKING DATA TYPE AND NULLS
SELECT 
    C.NAME AS COLUMN_NAME,
    T.NAME AS DATA_TYPE,
    C.is_nullable
FROM sys.columns C
JOIN sys.types T
    ON C.user_type_id = T.user_type_id
WHERE C.object_id = OBJECT_ID('STG_CUSTOMER');

-- CREATING TABLE CUSTOMER
CREATE TABLE CUSTOMER(
CUSTOMER_ID VARCHAR(50) NOT NULL PRIMARY KEY,
CUSTOMER_UNIQUE_ID VARCHAR(50) NOT NULL,
LOC_ZIP_CODE VARCHAR(10) NOT NULL);


--------------------------------------------------------------------------------------------------------------------------------------------------

-- CREATING TABLE GEOLOCATION

CREATE TABLE GEOLOCATION(
GEO_LOC_ID INT IDENTITY(1,1) PRIMARY KEY,
LOC_ZIP_CODE VARCHAR(10) NOT NULL,
GEO_LATITUDE FLOAT,
GEO_LONGITUDE FLOAT);

--------------------------------------------------------------------------------------------------------------------------------------------------

-- CREATING TABLE LOCATION

CREATE TABLE LOCATION(
LOC_ZIP_CODE VARCHAR(10),
LOC_CITY VARCHAR(50),
LOC_STATE VARCHAR(50),
CONSTRAINT PK_LOC_ZIP_CODE PRIMARY KEY (LOC_ZIP_CODE));

--------------------------------------------------------------------------------------------------------------------------------------------------

-- CREATING TABLE ORDER

CREATE TABLE ORDERS(
ORDER_ID VARCHAR(50) PRIMARY KEY,
CUSTOMER_ID VARCHAR(50) NOT NULL,
ORDER_STATUS VARCHAR(30) NOT NULL,
ORDER_PURCHASE_TIMESTAMP DATETIME NOT NULL,
ORDER_APPROVED_AT DATETIME,
ORDER_DELIVERED_CARRIER_DATE DATETIME,
ORDER_DELIVERED_CUSTOMER_DATE DATETIME,
ORDER_ESTIMATED_DELIVERY_DATE DATETIME);

--------------------------------------------------------------------------------------------------------------------------------------------------
-- CREATING TABLE ORDER ITEM

CREATE TABLE ORDER_ITEM(
ORDER_ID VARCHAR(50),
ORDER_ITEM_ID INT,
PRODUCT_ID VARCHAR(50) NOT NULL,
SELLER_ID VARCHAR(50) NOT NULL,
SHIPPING_LIMIT_DATE DATETIME NOT NULL,
PRICE FLOAT NOT NULL,
FREIGHT_VALUE FLOAT NOT NULL,
CONSTRAINT PK_ORDER_ID_ORDER_ITEM_ID PRIMARY KEY (ORDER_ID, ORDER_ITEM_ID));
--------------------------------------------------------------------------------------------------------------------------------------------------

-- CREATING TABLE ORDER_PAYMENT

CREATE TABLE ORDER_PAYMENT(
ORDER_ID VARCHAR(50),
PAYMENT_SEQUENTIAL INT,
PAYMENT_TYPE VARCHAR(30),
PAYMENT_INSTALLMENTS INT,
PAYMENT_VALUE FLOAT NOT NULL,
CONSTRAINT PK_ORDER_ID_PAYMENT_SEQUENTIAL PRIMARY KEY (ORDER_ID, PAYMENT_SEQUENTIAL));

--------------------------------------------------------------------------------------------------------------------------------------------------

CREATE TABLE ORDER_REVIEW(
REVIEW_ID VARCHAR(50),
ORDER_ID VARCHAR(50),
REVIEW_SCORE INT NOT NULL,
REVIEW_COMMENT_TITLE VARCHAR(200),
REVIEW_COMMENT_MESSAGE VARCHAR(200),
REVIEW_CREATION_DATE DATETIME,
REVIEW_ANSWER_TIMESTAMP DATETIME,
CONSTRAINT PK_REVIEW_ID_ORDER_ID PRIMARY KEY(REVIEW_ID,ORDER_ID),
CONSTRAINT CHECK_REVIEW_SCORE CHECK (REVIEW_SCORE BETWEEN 1 AND 5));

--------------------------------------------------------------------------------------------------------------------------------------------------

-- CREATING PROD_CATG_NAME_TRANSL TABLE

CREATE TABLE PROD_CATG_NAME_TRANSL(
CATEGORY_ID INT ,
PRODUCT_CATEGORY_NAME VARCHAR(200),
PRODUCT_CATEGORY_NAME_ENGLISH VARCHAR(200),
CONSTRAINT PK_CATEGORY_ID PRIMARY KEY (CATEGORY_ID));

--------------------------------------------------------------------------------------------------------------------------------------------------

-- CREATING PRODUCT TABLE

CREATE TABLE PRODUCT(
PRODUCT_ID VARCHAR(50),
CATEGORY_ID INT,
PROD_NAME_LENGTH INT,
PROD_DESCRIPTION_LENGTH INT,
PROD_PHOTOS_QTY INT,
PROD_WEIGHT_G FLOAT,
PROD_LENGTH FLOAT,
PRODUCT_HEIGHT_CM FLOAT,
PRODUCT_WIDTH_CM FLOAT,
CONSTRAINT PK_PRODUCT_ID PRIMARY KEY (PRODUCT_ID));

--------------------------------------------------------------------------------------------------------------------------------------------------

-- CREATING SELLER TABLE

CREATE TABLE SELLER(
SELLER_ID VARCHAR(50),
LOC_ZIP_CODE VARCHAR(10) NOT NULL,
CONSTRAINT PK_SELLER_ID PRIMARY KEY (SELLER_ID));

--------------------------------------------------------------------------------------------------------------------------------------------------

-- CHECKING IF FOREIGN KEY CONSTRAINT IS VOILATED IN TABLES.

--------------------------------------------------------------------------------------------------------------------------------------------------

-- BETWEEN GEOLOCATION AND LOCATION TABLE.

SELECT * FROM STG_GEOLOCATION G
WHERE NOT EXISTS(
    SELECT 1 FROM R_LOCATION L
    WHERE G.Loc_zip_code = L.Zip_code);

--------------------------------------------------------------------------------------------------------------------------------------------------

-- LOCATION AND SELLER
SELECT * FROM STG_SELLER S WHERE NOT EXISTS
    (SELECT 1 FROM R_LOCATION L
    WHERE L.Zip_code = S.Loc_zip_code);

-- THERE ARE 7 ORPHAN RECORDS IN SELLER TABLE THAT DOES NOT MATCH TO CORRESPONDING VALUES IN LOCATION TABLE.
-- MAKING A CONTROLLED ENTRY IN THE LOCATION TABLE TO ACCOMODATE MISMATCHED DATA IN THE SELLER TABLE.


INSERT INTO R_LOCATION (Zip_code,City,State)
VALUES (0000,'UNKNOWN','UNKOWN');

BEGIN TRANSACTION;

UPDATE STG_SELLER
SET LOC_ZIP_CODE = 0 
WHERE NOT EXISTS
    (SELECT 1 FROM R_LOCATION L 
    WHERE L.Zip_code = STG_SELLER.Loc_zip_code);

COMMIT TRANSACTION;

--------------------------------------------------------------------------------------------------------------------------------------------------

-- LOCATION AND CUSTOMER TABLE.

SELECT * FROM STG_CUSTOMER WHERE NOT EXISTS(
    SELECT 1 FROM R_LOCATION L WHERE L.Zip_code = STG_CUSTOMER.Loc_zip_code);

-- THERE ARE 278 OPRHAN RECORDS IN CUSTOMER TABLE THAT DOES NOT HAVE ANY CORRESPONDING VALUE IN LOCATION TABLE. CHANGING THESE VALUES TO CONTROLL.

BEGIN TRANSACTION;

UPDATE STG_CUSTOMER
SET Loc_zip_code = 0 WHERE NOT EXISTS (
    SELECT 1 FROM R_LOCATION L
    WHERE L.Zip_code = STG_CUSTOMER.Loc_zip_code);

COMMIT TRANSACTION;

--------------------------------------------------------------------------------------------------------------------------------------------------

-- CUSTOMER AND ORDER TABLE

SELECT * FROM STG_ORDER
WHERE NOT EXISTS (
    SELECT 1 FROM STG_CUSTOMER C WHERE C.customer_id = STG_ORDER.customer_id);

-- NO ORPHAN RECORDS FOR CUSTOMER_ID IN ORDER TABLE.

--------------------------------------------------------------------------------------------------------------------------------------------------

-- ORDER AND ORDER PAYMENT TABLE

SELECT * FROM STG_ORDER_PAYMENT WHERE NOT EXISTS(
    SELECT * FROM STG_ORDER O WHERE O.order_id = STG_ORDER_PAYMENT.order_id); 

-- NO ORPHAN RECORDS.

--------------------------------------------------------------------------------------------------------------------------------------------------

-- ORDER AND ORDER REVIEW TABLE.

SELECT * FROM STG_ORDER_REVIEW WHERE NOT EXISTS (
    SELECT 1 FROM STG_ORDER O WHERE O.order_id = STG_ORDER_REVIEW.order_id);

-- NO ORPHAN RECORDS FOUND.

--------------------------------------------------------------------------------------------------------------------------------------------------

-- ORDER AND ORDER_ITEM TABLE.

SELECT * FROM STG_ORDER_ITEM WHERE NOT EXISTS (
    SELECT 1 FROM STG_ORDER O WHERE O.order_id = STG_ORDER_ITEM.order_id);

-- NO ORPHAN RECORDS.

--------------------------------------------------------------------------------------------------------------------------------------------------

-- SELLER AND ORDER_ITEM TABLE 

SELECT * FROM STG_ORDER_ITEM WHERE NOT EXISTS(
    SELECT 1 FROM STG_SELLER S WHERE S.seller_id = STG_ORDER_ITEM.seller_id);

-- NO ORPHAN RECORDS.

--------------------------------------------------------------------------------------------------------------------------------------------------

-- PRODUCT AND ORDER_TEM TABLE

SELECT * FROM STG_ORDER_ITEM WHERE NOT EXISTS(
    SELECT 1 FROM STG_PRODUCT P WHERE P.product_id = STG_ORDER_ITEM.product_id);

-- NO ORPHAN RECORDS

--------------------------------------------------------------------------------------------------------------------------------------------------

-- PRODUCT AND PROD_CATG_NAME_TRANSL

SELECT * FROM STG_PRODUCT WHERE product_category_name IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM STG_PROD_CATG_NAME_TRANSL P WHERE  P.product_category_name = STG_PRODUCT.product_category_name);


-- 13 ORPHAN RECORDS FOUND. ADDING CONTROLLED RECORD TO STG_PROD_CATG_NAME_TRANSL AND ASSIGNING THE ORPHAN RECORDS THAT RECORD

SELECT * FROM STG_PROD_CATG_NAME_TRANSL;
SELECT * FROM STG_PRODUCT WHERE product_category_name = 'NOT_ASSIGNED';

ALTER TABLE STG_PROD_CATG_NAME_TRANSL
ADD CATEGORY_ID INT IDENTITY(1,1) PRIMARY KEY;

SET IDENTITY_INSERT STG_PROD_CATG_NAME_TRANSL ON;

INSERT INTO STG_PROD_CATG_NAME_TRANSL (product_category_name,product_category_name_english, CATEGORY_ID) VALUES(
'NOT_ASSIGNED', 'NO_TRANSLATION',0);

SET IDENTITY_INSERT STG_PROD_CATG_NAME_TRANSL OFF;


BEGIN TRANSACTION;

UPDATE STG_PRODUCT
SET product_category_name = 'NOT_ASSIGNED' WHERE product_category_name IS NOT NULL AND NOT EXISTS(
    SELECT 1 FROM STG_PROD_CATG_NAME_TRANSL C WHERE C.product_category_name = STG_PRODUCT.product_category_name);

COMMIT TRANSACTION;


--------------------------------------------------------------------------------------------------------------------------------------------------

-- INSERTING THE CLEANED DATA INTO NEW CREATED TABLES. USING CAST TO MAKE SURE NO ERROR IS ENCOUNTERED.

--------------------------------------------------------------------------------------------------------------------------------------------------

-- LOCATION

INSERT INTO LOCATION(LOC_ZIP_CODE,LOC_CITY,LOC_STATE) 
SELECT
    CAST (ZIP_CODE AS VARCHAR(10)),
    CAST (CITY AS VARCHAR(50)),
    CAST (STATE AS VARCHAR(50))
    FROM R_LOCATION;

--------------------------------------------------------------------------------------------------------------------------------------------------

-- GEOLOCATION

INSERT INTO GEOLOCATION(LOC_ZIP_CODE,GEO_LATITUDE,GEO_LONGITUDE)
SELECT 
    CAST(LOC_ZIP_CODE AS VARCHAR(10)),
    CAST (GEOLOCATION_LAT AS FLOAT),
    CAST (GEOLOCATION_LNG AS FLOAT)
FROM STG_GEOLOCATION;

--------------------------------------------------------------------------------------------------------------------------------------------------

-- SELLER

INSERT INTO SELLER (SELLER_ID, LOC_ZIP_CODE)
SELECT 
    CAST(SELLER_ID AS VARCHAR(50)),
    CAST(LOC_ZIP_CODE AS VARCHAR(10))
FROM STG_SELLER;

--------------------------------------------------------------------------------------------------------------------------------------------------

-- CUSTOMER

INSERT INTO CUSTOMER(CUSTOMER_ID,CUSTOMER_UNIQUE_ID,LOC_ZIP_CODE)
SELECT 
    CAST(customer_id AS VARCHAR(50)),
    CAST(CUSTOMER_UNIQUE_ID AS VARCHAR(50)),
    CAST(LOC_ZIP_CODE AS VARCHAR(10))
FROM STG_CUSTOMER;

--------------------------------------------------------------------------------------------------------------------------------------------------

-- ORDER

INSERT INTO ORDERS(ORDER_ID,CUSTOMER_ID,ORDER_STATUS,ORDER_PURCHASE_TIMESTAMP,ORDER_APPROVED_AT,
            ORDER_DELIVERED_CARRIER_DATE,ORDER_DELIVERED_CUSTOMER_DATE,ORDER_ESTIMATED_DELIVERY_DATE)
SELECT 
    CAST(order_id AS varchar(50)),
    CAST(CUSTOMER_ID AS VARCHAR(50)),
    CAST(order_status AS VARCHAR(30)),
    CAST(order_purchase_timestamp AS datetime),
    CAST(order_approved_at AS datetime),
    CAST(order_delivered_carrier_date AS datetime),
    CAST(order_delivered_customer_date AS datetime),
    CAST(order_estimated_delivery_date AS datetime)
FROM STG_ORDER;

--------------------------------------------------------------------------------------------------------------------------------------------------

-- ORDER PAYMENT

INSERT INTO ORDER_PAYMENT(ORDER_ID,PAYMENT_SEQUENTIAL,PAYMENT_TYPE,PAYMENNT_INSTALLMENTS,PAYMENT_VALUE)
SELECT
    CAST(order_id AS VARCHAR(50)),
    CAST(payment_sequential AS INT),
    CAST(payment_type AS VARCHAR(30)),
    CAST(payment_installments AS INT),
    CAST(payment_value AS FLOAT)
FROM STG_ORDER_PAYMENT;

--------------------------------------------------------------------------------------------------------------------------------------------------

-- ORDER_REVIEW

INSERT INTO ORDER_REVIEW(REVIEW_ID,ORDER_ID,REVIEW_SCORE,REVIEW_COMMENT_TITLE,REVIEW_COMMENT_MESSAGE,REVIEW_CREATION_DATE,REVIEW_ANSWER_TIMESTAMP)
SELECT
    CAST(review_id AS VARCHAR(50)),
    CAST(order_id AS VARCHAR(50)),
    CAST(review_score AS INT),
    CAST(review_comment_title AS VARCHAR(200)),
    CAST(review_comment_message AS VARCHAR(200)),
    CAST(review_creation_date AS datetime),
    CAST(review_answer_timestamp AS datetime)
FROM STG_ORDER_REVIEW;

--------------------------------------------------------------------------------------------------------------------------------------------------

-- ORDER ITEM

INSERT INTO ORDER_ITEM (ORDER_ID,ORDER_ITEM_ID,PRODUCT_ID,SELLER_ID,SHIPPING_LIMIT_DATE,PRICE,FREIGHT_VALUE)
SELECT
    CAST(order_id AS VARCHAR(50)),
    CAST(order_item_id AS INT),
    CAST(product_id AS VARCHAR(50)),
    CAST(seller_id AS VARCHAR(50)),
    CAST(shipping_limit_date AS datetime),
    CAST(price AS FLOAT),
    CAST(freight_value AS FLOAT)
FROM STG_ORDER_ITEM;

--------------------------------------------------------------------------------------------------------------------------------------------------

--PRODUCT

-- AS WE HAVE CREATED NEW COLUMN CATEGORY_ID IN PRODUCT TABLE, AND REMOVED OLD COLUMN PRODUCT_CATEGORY-NAME FOR BETTER FOREIGN KEY CONSTRAINT, WE WILL
-- THEREFORE FIRST POPULATE THE CATEGOTRY ID COLUMN WITH APPROPRIATE VALUES.

-- STEP 1: CREATE NEW COLUMN CATEGORY ID IN STG_PRODUCT.
ALTER TABLE STG_PRODUCT
ADD CATEGORY_ID INT;

-- STEP 2: INSERT CORRESPONDING VALUES OF CATEGORY_ID FROM STG_PROD_CATG_NAME_TRANSL INTO STG_PRODUCT.

UPDATE P
SET P.CATEGORY_ID = CAST(T.CATEGORY_ID AS INT)
FROM STG_PRODUCT P
JOIN STG_PROD_CATG_NAME_TRANSL T
ON P.product_category_name = T.product_category_name;

-- NOW DELETING PROD_CATEGORY_NAME FROM STG_PRODUCT TABLE

ALTER TABLE STG_PRODUCT
DROP COLUMN PRODUCT_CATEGORY_NAME;

-- NOW INSERTING THE DATA FROM STG_PRODUCT INTO PRODUCT TABLE.

INSERT INTO PRODUCT (PRODUCT_ID,CATEGORY_ID,PROD_NAME_LENGTH,PROD_DESCRIPTION_LENGTH,PROD_PHOTOS_QTY,
                    PROD_WEIGHT_G,PROD_LENGTH,PRODUCT_HEIGHT_CM,PRODUCT_WIDTH_CM)
SELECT
    CAST(product_id AS VARCHAR(50)),
    CAST(CATEGORY_ID AS INT),
    CAST(product_name_lenght AS int),
    CAST(product_description_lenght AS int),
    CAST(product_photos_qty AS int),
    CAST(product_weight_g AS FLOAT),
    CAST(product_length_cm AS FLOAT),
    CAST(product_height_cm AS float),
    CAST(product_width_cm AS float)
FROM STG_PRODUCT;

--------------------------------------------------------------------------------------------------------------------------------------------------

-- PROD_CATG_NAME_TRANSL

INSERT INTO PROD_CATG_NAME_TRANSL(CATEGORY_ID,PRODUCT_CATEGORY_NAME,PRODUCT_CATEGORY_NAME_ENGLISH)
SELECT
    CAST(CATEGORY_ID AS int),
    CAST(product_category_name AS VARCHAR(200)),
    CAST(product_category_name_english AS VARCHAR(200))
FROM STG_PROD_CATG_NAME_TRANSL;

--------------------------------------------------------------------------------------------------------------------------------------------------

-- ADDING FOREIGN KEY CONSTRAINTS.

--------------------------------------------------------------------------------------------------------------------------------------------------

-- ADDING FOREIGN KEY CONSTRAINT TO SELLER, CUSTOMER AND GEOLOCATION TABLE FROM LOCATION TABLE

-- GEOLOCATION
ALTER TABLE GEOLOCATION
ADD CONSTRAINT FK_ZIP_CODE_LOCATION_ON_LOC_ZIP_CODE_GEOLOCATION FOREIGN KEY (LOC_ZIP_CODE) REFERENCES LOCATION(LOC_ZIP_CODE);

-- CUSTOMER
ALTER TABLE SELLER
ADD CONSTRAINT FK_ZIP_CODE_LOCATION_ON_LOC_ZIP_CODE_SELLER FOREIGN KEY (LOC_ZIP_CODE) REFERENCES LOCATION(LOC_ZIP_CODE);

-- SELLER
ALTER TABLE CUSTOMER
ADD CONSTRAINT FK_ZIP_CODE_LOCATION_ON_LOC_ZIP_CODE_CUSTOMER FOREIGN KEY (LOC_ZIP_CODE) REFERENCES LOCATION(LOC_ZIP_CODE);

--------------------------------------------------------------------------------------------------------------------------------------------------

-- ADDING FK TO ORDERS TABLE

ALTER TABLE ORDERS
ADD CONSTRAINT FK_CUSTOMER_ID_CUSTOMER_ON_CUSTOMER_ID_ORDERS FOREIGN KEY (CUSTOMER_ID) REFERENCES CUSTOMER(CUSTOMER_ID);

--------------------------------------------------------------------------------------------------------------------------------------------------

-- ADDING FK TO ORDER REVIEW, ORDER PAYMENT AND ORDER ITEM TABLE

-- ORDER REVIEW
ALTER TABLE ORDER_REVIEW
ADD CONSTRAINT FK_ORDER_ID_ORDERS_ON_ORDER_ID_ORDER_REVIEW FOREIGN KEY (ORDER_ID) REFERENCES ORDERS(ORDER_ID);

-- ORDER PAYMENT

ALTER TABLE ORDER_PAYMENT
ADD CONSTRAINT FK_ORDER_ID_ORDERS_ON_ORDER_ID_ORDER_PAYMENT FOREIGN KEY (ORDER_ID) REFERENCES ORDERS(ORDER_ID);

-- ORDER ITEM
ALTER TABLE ORDER_ITEM
ADD CONSTRAINT FK_ORDER_ID_ORDERS_ON_ORDER_ID_ORDER_ITEM FOREIGN KEY (ORDER_ID) REFERENCES ORDERS(ORDER_ID);

--------------------------------------------------------------------------------------------------------------------------------------------------

-- ADDING FK TO ORDER_ITEM FROM SELLER

ALTER TABLE ORDER_ITEM
ADD CONSTRAINT FK_SELLER_ID_SELLERS_ON_SELLER_ID_ORDER_ITEM FOREIGN KEY (SELLER_ID) REFERENCES SELLER(SELLER_ID);

--------------------------------------------------------------------------------------------------------------------------------------------------

-- ADDING FK TO ORDER_ITEM FROM PRODUCT
ALTER TABLE ORDER_ITEM
ADD CONSTRAINT FK_PRODUCT_ID_PRODUCT_ON_PRODUCT_ID_ORDER_ITEM FOREIGN KEY (PRODUCT_ID) REFERENCES PRODUCT(PRODUCT_ID);

--------------------------------------------------------------------------------------------------------------------------------------------------

-- ADDING FK TO PRODUCT FROM PROD_CATG_NAME_TRANSL
ALTER TABLE PRODUCT
ADD CONSTRAINT FK_CATEGORY_ID_PROD_CATG_ON_CATEGORY_ID_PRODUCT FOREIGN KEY (CATEGORY_ID) REFERENCES PROD_CATG_NAME_TRANSL(CATEGORY_ID);

--------------------------------------------------------------------------------------------------------------------------------------------------

-- DROPPING THE STAGED TABLES.

DROP TABLE STG_CUSTOMER;
DROP TABLE STG_GEOLOCATION;
DROP TABLE STG_ORDER;
DROP TABLE STG_ORDER_ITEM;
DROP TABLE STG_ORDER_PAYMENT;
DROP TABLE STG_ORDER_REVIEW;
DROP TABLE STG_PROD_CATG_NAME_TRANSL;
DROP TABLE STG_PRODUCT;
DROP TABLE STG_SELLER;

--------------------------------------------------------------------------------------------------------------------------------------------------