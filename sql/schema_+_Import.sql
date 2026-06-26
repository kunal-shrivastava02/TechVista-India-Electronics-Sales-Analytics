-- ============================================================
-- TechVista India — Indian Electronics Sales Analytics
-- schema.sql  |  Run this FIRST before importing any data
-- ============================================================

-- DIMENSION: Products (53 SKUs)

CREATE TABLE dim_products (
    product_id           VARCHAR(10)    PRIMARY KEY,
    product_name         VARCHAR(100)   NOT NULL,
    brand                VARCHAR(50)    NOT NULL,
    category             VARCHAR(50)    NOT NULL,
    cost_price           NUMERIC(10,2)  NOT NULL CHECK (cost_price > 0),
    selling_price        NUMERIC(10,2)  NOT NULL CHECK (selling_price > 0),
    discount_percentage  NUMERIC(5,2)   DEFAULT 0 CHECK (discount_percentage BETWEEN 0 AND 50),
    stock_quantity       INTEGER        DEFAULT 0,
    warranty_years       SMALLINT       DEFAULT 1,
    rating               NUMERIC(3,1)   CHECK (rating BETWEEN 1.0 AND 5.0)
);


-- DIMENSION: Customers (2,800)

CREATE TABLE dim_customers (
    customer_id       VARCHAR(10)   PRIMARY KEY,
    customer_name     VARCHAR(100)  NOT NULL,
    email             VARCHAR(150),
    phone             VARCHAR(15),
    age               SMALLINT      CHECK (age BETWEEN 15 AND 100),
    gender            VARCHAR(10),
    city              VARCHAR(60),
    state             VARCHAR(60),
    pincode           VARCHAR(10),
    customer_segment  VARCHAR(20)   DEFAULT 'Regular',
    loyalty_points    INTEGER       DEFAULT 0
);


-- SALES TARGETS (20 SPs × 14 quarters = 280 rows)

CREATE TABLE sales_targets (
    target_id         VARCHAR(10)    PRIMARY KEY,
    salesperson_id    VARCHAR(10)    NOT NULL,
    salesperson_name  VARCHAR(100)   NOT NULL,
    region            VARCHAR(30)    NOT NULL,
    quarter           VARCHAR(10)    NOT NULL,
    sales_target      NUMERIC(14,2)  NOT NULL CHECK (sales_target > 0)
);


-- FACT: Sales Transactions (~4,500 rows)

CREATE TABLE fact_sales (
    order_id             VARCHAR(10)    PRIMARY KEY,
    order_date           DATE           NOT NULL,
    product_id           VARCHAR(10)    NOT NULL REFERENCES dim_products(product_id),
    customer_id          VARCHAR(10)    NOT NULL REFERENCES dim_customers(customer_id),
    salesperson_id       VARCHAR(10)    NOT NULL,
    salesperson_name     VARCHAR(100),
    quantity             SMALLINT       NOT NULL DEFAULT 1 CHECK (quantity > 0),
    unit_price           NUMERIC(10,2)  NOT NULL,
    discount_percentage  NUMERIC(5,2)   DEFAULT 0,
    discount_amount      NUMERIC(10,2)  DEFAULT 0,
    final_unit_price     NUMERIC(10,2)  NOT NULL,
    total_sales_amount   NUMERIC(14,2)  NOT NULL CHECK (total_sales_amount > 0),
    total_cost           NUMERIC(14,2)  NOT NULL,
    profit               NUMERIC(14,2),
    payment_method       VARCHAR(30),
    customer_rating      NUMERIC(3,1),
    order_status         VARCHAR(20)    DEFAULT 'Delivered'
                                        CHECK (order_status IN ('Delivered','Returned','Cancelled')),
    delivery_days        SMALLINT
);

-- HOW DATA WAS IMPORTED FOR THIS PROJECT:
--
--   Tool     : pgAdmin 4 (GUI)
--   Method   : Right-click table → Import/Export Data
--   Reason   : No superuser privileges required.
--              Simple, visual, beginner-friendly approach.
--
-- IMPORT SETTINGS USED IN pgAdmin:
--   Import/Export  →  Import
--   Format         →  csv
--   Encoding       →  UTF8
--   Header         →  ON   ← important
--   Delimiter      →  ,   (comma)
--   Quote          →  "   (double quote)
--   NULL Strings   →      (leave blank)
--
-- IMPORT ORDER — follow this exactly (foreign key dependency):
--   Step 1  →  dim_products    (no dependencies)
--   Step 2  →  dim_customers   (no dependencies)
--   Step 3  →  sales_targets   (no dependencies)
--   Step 4  →  fact_sales      (depends on products + customers)

-- VERIFY row counts after import

SELECT 'dim_products'  AS table_name, COUNT(*) AS total_rows FROM dim_products
UNION ALL
SELECT 'dim_customers', COUNT(*) FROM dim_customers
UNION ALL
SELECT 'sales_targets', COUNT(*) FROM sales_targets
UNION ALL
SELECT 'fact_sales',    COUNT(*) FROM fact_sales;

-- Expected results:
-- dim_products  |  53
-- dim_customers | 2800
-- sales_targets |  280
-- fact_sales    | 4500