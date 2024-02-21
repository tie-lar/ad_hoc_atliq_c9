/*Displays...*/
SELECT * FROM retail_events_db.dim_campaigns;

SELECT * FROM retail_events_db.dim_products;

SELECT * FROM retail_events_db.dim_stores;

SELECT * FROM retail_events_db.fact_events;

/*Displays all products which have a base price greather than 500 and BOGOF promo type*/
SELECT product_code, base_price, promo_type
FROM retail_events_db.fact_events
WHERE base_price > 500 AND promo_type = "BOGOF";

/*Displays a count of stores in each city in descending order*/
SELECT city, COUNT(store_id) AS store_count
FROM retail_events_db.dim_stores
GROUP BY city
ORDER BY store_count DESC;

/*Creates a new column called Revenue_Before with a data type of integer*/
ALTER TABLE retail_events_db.fact_events 
ADD Revenue_Before INT NULL;

/*Creates a new column called Revenue_After with a data type of integer*/
ALTER TABLE retail_events_db.fact_events 
ADD Revenue_After INT NULL;

/*Creates a new column called Quantity with a data type of integer*/
ALTER TABLE retail_events_db.fact_events
ADD Quantity INT NULL;

/*Creates a new column called Revenue with a data type of integer*/
ALTER TABLE retail_events_db.fact_events 
ADD Revenue INT NULL;

/*Creates a new column called Quantity_after with a data type of integer*/
ALTER TABLE retail_events_db.fact_events 
ADD Quantity_after INT; 

/*Set the Revenue_Before column*/
UPDATE retail_events_db.fact_events
SET Revenue_Before = quantity_sold_before * base_price;

/*Set the Revenue_After column*/
UPDATE retail_events_db.fact_events
SET Revenue_After = Revenue - Revenue_Before;

/*Disables safe mode*/
SET SQL_SAFE_UPDATES = 0;

/*Replicates quantity_sold_after into a new column we created*/
UPDATE retail_events_db.fact_events 
SET Quantity_after = quantity_sold_after;

/*Sets quantity of units sold with the promo type BOGOF to by the original value multiplied by 2*/
UPDATE retail_events_db.fact_events
SET Quantity_after = 
    CASE 
        WHEN promo_type = 'BOGOF' THEN Quantity_after * 2
        ELSE Quantity_after
    END;

/*Sets the total quantity of units sold*/
UPDATE retail_events_db.fact_events
SET Quantity = (
    SELECT SUM(Quantity_after) + SUM(quantity_sold_before)
    WHERE campaign_id = 'CAMP_SAN_01' OR campaign_id = 'CAMP_DIW_01'
);


/*Show revenue before & after promo for each campaign*/
SELECT SUM(Revenue_Before) AS Rev_Bef
FROM retail_events_db.fact_events
WHERE campaign_id = "CAMP_SAN_01"
ORDER BY Rev_Bef DESC;

SELECT SUM(Revenue_After) AS Rev_Aft
FROM retail_events_db.fact_events
WHERE campaign_id = "CAMP_SAN_01"
ORDER BY Rev_Aft DESC;

SELECT SUM(Revenue_Before) AS Rev_Bef
FROM retail_events_db.fact_events
WHERE campaign_id = "CAMP_DIW_01"
ORDER BY Rev_Bef DESC;

SELECT SUM(Revenue_After) AS Rev_Aft
FROM retail_events_db.fact_events
WHERE campaign_id = "CAMP_DIW_01"
ORDER BY Rev_Aft DESC;

/*Displays a column of the count of stores in each city by descending order*/
SELECT city, COUNT(store_id) AS store_count
FROM retail_events_db.dim_stores
GROUP BY city
ORDER BY store_count DESC;

/*Sets the revenue*/
UPDATE retail_events_db.fact_events
SET Revenue = (
    SELECT 
        CASE 
            WHEN promo_type = '50% OFF' THEN quantity_sold_before * base_price + Quantity_after * (base_price * 0.5)
            WHEN promo_type = '25% OFF' THEN quantity_sold_before * base_price + Quantity_after * (base_price * 0.25)
            WHEN promo_type = '33% OFF' THEN quantity_sold_before * base_price + Quantity_after * (base_price * 0.33)
            WHEN promo_type = '500 CASHBACK' THEN quantity_sold_before * base_price + Quantity_after * (base_price - 500)
            WHEN promo_type = 'BOGOF' THEN quantity_sold_before * base_price + Quantity_after * (base_price * 0.5)
            ELSE quantity_sold_before * base_price
        END
);

/*ISU*/

/*Creates a new column called ISU with a data type of integer*/
ALTER TABLE retail_events_db.fact_events 
ADD ISU INT NULL;

UPDATE retail_events_db.fact_events 
SET ISU = Quantity_after - quantity_sold_before;


/*Products ranked by ISU within Diwali campaign*/
SELECT 
    product_code,
    ISU,
    RANK() OVER (PARTITION BY campaign_id ORDER BY ISU DESC) AS category_rank
FROM 
    retail_events_db.fact_events
WHERE 
    campaign_id = 'CAMP_DIW_01';


/*Enables safe mode*/
SET SQL_SAFE_UPDATES = 1;
