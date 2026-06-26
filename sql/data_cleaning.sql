-- ============================================================
-- TechVista India — Indian Electronics Sales Analytics
-- Data Cleaning.sql  |  Run AFTER Schema + Import.sql
-- ============================================================
-- Fixes: nulls | casing | duplicates | validation
-- ============================================================


-- STEP 1 | INSPECT — Count nulls before cleaning

SELECT 'customer_rating' AS column_name,
        COUNT(*) AS null_count
FROM fact_sales WHERE customer_rating IS NULL
UNION ALL
SELECT 'delivery_days', COUNT(*) FROM fact_sales WHERE delivery_days IS NULL
UNION ALL
SELECT 'profit', COUNT(*) FROM fact_sales WHERE profit IS NULL;

-- STEP 2 | NULLS — Fill missing customer_rating with average

UPDATE fact_sales
SET customer_rating = (
    SELECT ROUND(AVG(customer_rating)::NUMERIC, 1)
    FROM   fact_sales
    WHERE  customer_rating IS NOT NULL
)
WHERE customer_rating IS NULL;

-- Verify
SELECT COUNT(*) AS remaining_null_ratings
FROM fact_sales WHERE customer_rating IS NULL;

-- STEP 3 | NULLS — Fill missing delivery_days with median

UPDATE fact_sales
SET delivery_days = (
    SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY delivery_days)
    FROM   fact_sales
    WHERE  delivery_days IS NOT NULL
)
WHERE delivery_days IS NULL;

-- Verify
SELECT COUNT(*) AS remaining_null
FROM fact_sales WHERE delivery_days IS NULL;

-- STEP 4 | CASING — Fix payment_method to standard values
-- (handles Debit Card, DEBIT CARD etc.)

-- Preview inconsistencies first
SELECT DISTINCT payment_method, COUNT(*) AS cnt
FROM fact_sales
GROUP BY payment_method
ORDER BY payment_method;

-- Fix - SET UPPERCASE

UPDATE fact_sales
SET payment_method = UPPER(payment_method);

-- STEP 5 | CASING — Fix gender in dim_customers
SELECT DISTINCT gender FROM dim_customers ORDER BY gender;

UPDATE dim_customers
SET gender = INITCAP(LOWER(gender))
WHERE gender <> INITCAP(LOWER(gender));

-- STEP 6 | DUPLICATES — Find and remove duplicate orders

-- Check for duplicate order_ids (shouldn't exist due to PRIMARY KEY, but check data content)
SELECT order_id, COUNT(*) AS cnt
FROM fact_sales
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Identify rows that are complete duplicates (same order content)
SELECT COUNT(*) AS duplicate_rows
FROM (
  SELECT order_id,
     ROW_NUMBER() OVER (PARTITION BY order_date, product_id, customer_id,
                   quantity, total_sales_amount ORDER BY order_id ) AS rn
    FROM fact_sales
) WHERE rn > 1;            
           
   
SELECT * FROM fact_sales;

-- Remove duplicates
DELETE FROM fact_sales
WHERE order_id IN (
    SELECT order_id FROM (
        SELECT order_id,
        ROW_NUMBER() OVER ( PARTITION BY order_date, product_id, customer_id,
                          quantity, total_sales_amount ORDER BY order_id ) AS rn
     FROM fact_sales
    ) ranked
    WHERE rn > 1                     
);                   
               
        
--  STEP 7 | VALIDATION — PROFIT

-- Flag rows where calculated profit differs from stored profit

SELECT COUNT(*) AS profit_discrepancies
FROM fact_sales
WHERE ABS(profit - (total_sales_amount - total_cost)) > 1;

-- Recalculate profit for consistency

UPDATE fact_sales
SET profit = ROUND(total_sales_amount - total_cost, 2)
WHERE ABS(profit - (total_sales_amount - total_cost)) > 1;

-- STEP 8 | VALIDATION - RATINGS

--Check rating ranges
SELECT COUNT(*) AS out_of_range_ratings
FROM fact_sales
WHERE customer_rating NOT BETWEEN 1.0 AND 5.0;

-- Clamp ratings to valid range 1-5
UPDATE fact_sales
SET customer_rating = GREATEST(1.0, LEAST(5.0, customer_rating))
WHERE customer_rating NOT BETWEEN 1.0 AND 5.0;

--'Data cleaning completed successfully!'