-- ============================================================
-- TechVista India — Indian Electronics Sales Analytics
-- business_queries.sql  |  18 Business Questions
-- Run AFTER data_cleaning.sql
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- Q1. What is the overall business performance summary?
SELECT
    COUNT(DISTINCT order_id)          AS total_orders,                                     
    ROUND(SUM(total_sales_amount),0)  AS total_revenue,                            
    ROUND(SUM(profit),0)  AS total_profit,
    ROUND(SUM(profit)/SUM(total_sales_amount)*100,2)  AS profit_margin_pct,             
    ROUND(AVG(total_sales_amount),0)  AS avg_order_value,
    ROUND(AVG(customer_rating),2)     AS avg_customer_rating,
    COUNT(DISTINCT customer_id)       AS unique_customers
FROM fact_sales
WHERE order_status = 'Delivered';

-- Insight: TechVista India delivered ~3,478 orders generating ₹21.7 Cr revenue
-- at a 21.5% profit margin. AOV of ₹62,000 reflects a healthy electronics
-- product mix dominated by laptops and smartphones.

-- ────────────────────────────────────────────────────────────
-- Q2. Which brands generate the most revenue and profit?
SELECT
    p.brand,
    COUNT(s.order_id)  AS total_orders,
    SUM(s.quantity)    AS units_sold,
    ROUND(SUM(s.total_sales_amount),0)   AS total_revenue,
    ROUND(SUM(s.profit),0)               AS total_profit,
    ROUND(SUM(s.profit)/SUM(s.total_sales_amount)*100,2) AS margin_pct
FROM fact_sales s
JOIN dim_products p ON s.product_id = p.product_id
WHERE s.order_status = 'Delivered'
GROUP BY p.brand
ORDER BY total_revenue DESC;                                     
       
-- Insight: Apple leads with ₹6.67 Cr (30.7% share) driven by premium pricing.
-- Samsung is second at ₹3.08 Cr. Xiaomi ranks 7th by revenue but drives one of 
-- the highest unit volume — a volume vs value tradeoff to monitor.

-- Q3. Which product category is most profitable?
SELECT
    p.category,
    COUNT(s.order_id)  AS total_orders,
    SUM(s.quantity)    AS units_sold,
    ROUND(SUM(s.total_sales_amount),0)   AS total_revenue,
    ROUND(SUM(s.profit),0)               AS total_profit,
    ROUND(SUM(s.profit)/SUM(s.total_sales_amount)*100,2) AS margin_pct
FROM fact_sales s
JOIN dim_products p ON s.product_id = p.product_id
WHERE s.order_status = 'Delivered'
GROUP BY p.category
ORDER BY total_profit DESC;

-- Insight: Laptops dominate absolute profit at ₹2.71 Cr (57% of revenue)
-- but Accessories show the highest margin % at ~30%.
-- Smartwatches and Accessories are under-monetised relative to their margin potential.

-- Q4. Which states and cities drive the most sales?
SELECT
    c.state, c.city,
    COUNT(s.order_id)  AS total_orders,
    SUM(s.quantity)    AS units_sold,
    ROUND(SUM(s.total_sales_amount),0)   AS total_revenue,
    ROUND(SUM(s.profit),0)               AS total_profit,
    ROUND(SUM(s.profit)/SUM(s.total_sales_amount)*100,2) AS margin_pct
FROM fact_sales s
JOIN dim_customers c 
ON s.customer_id = c.customer_id
WHERE s.order_status = 'Delivered'
GROUP BY  c.state, c.city
ORDER BY  total_revenue DESC;

-- Insight: Maharashtra (Mumbai + Pune) contributes 23.9% of national revenue.
-- Karnataka (Bangalore) is #2 at 11.7% — driven by the IT workforce.
-- Delhi, Hyderabad, and Pune round out the top 5 markets.

-- Q5. What is the monthly revenue trend?
SELECT
    TO_CHAR(order_date,'YYYY-MM')      AS year_month,
    COUNT(order_id)  AS total_orders,
    ROUND(SUM(total_sales_amount),0)   AS monthly_revenue,
    ROUND(SUM(profit),0)               AS monthly_profit,
    ROUND(AVG(total_sales_amount),0)   AS avg_order_value
FROM fact_sales
WHERE order_status = 'Delivered'
GROUP BY TO_CHAR(order_date,'YYYY-MM')
ORDER BY year_month;

-- Insight: October-November peak (Diwali season) and January (New Year deals)
-- show seasonal spikes. Use this to plan inventory and marketing campaigns.

-- Q6. Which payment method is most popular?
SELECT
    payment_method,
    COUNT(order_id)  AS total_orders,
    ROUND(SUM(total_sales_amount),0)   AS total_revenue,
    ROUND(SUM(profit),0)               AS total_profit,
    ROUND(AVG(total_sales_amount),0)   AS avg_order_value
FROM fact_sales
WHERE order_status = 'Delivered'
GROUP BY  payment_method
ORDER BY total_orders DESC;

-- Insight: UPI dominates with 34% of orders — reflects India's digital payment
-- adoption. All payment methods show similar AOV range (₹59K-₹65K) suggesting
-- payment choice is driven by convenience not product price. COD is declining (< 4%).

-- Q7. What are the top 10 best-selling products by revenue?
SELECT
    p.product_name,
    COUNT(s.order_id)  AS total_orders,
    SUM(s.quantity)    AS units_sold,
    ROUND(SUM(s.total_sales_amount),0)   AS total_revenue,
    ROUND(SUM(s.profit),0)               AS total_profit,
    ROUND(SUM(s.profit)/SUM(s.total_sales_amount)*100,2) AS margin_pct
FROM fact_sales s
JOIN dim_products p 
ON s.product_id = p.product_id
WHERE s.order_status = 'Delivered'
GROUP BY p.product_name
ORDER BY total_revenue DESC
LIMIT 10;

-- Insight: MacBook Pro M3 and MacBook Air M2 lead revenue despite lower unit
-- volumes — Apple's premium pricing drives outsized revenue per order.
-- HP Spectre x360 (#5) and XPS 15 (#7, Dell) are top premium laptop picks.

-- Q8. Which products have the lowest profit margin? (Risk list)
SELECT
    p.product_name,
	p.brand,
    p.category,
    COUNT(s.order_id)  AS total_orders,
    SUM(s.quantity)    AS units_sold,
    ROUND(SUM(s.total_sales_amount),0)   AS total_revenue,
    ROUND(SUM(s.profit),0)               AS total_profit,
    ROUND(SUM(s.profit)/SUM(s.total_sales_amount)*100,2) AS margin_pct
FROM fact_sales s
JOIN dim_products p 
ON s.product_id = p.product_id
WHERE s.order_status = 'Delivered'
GROUP BY p.product_name, p.brand, p.category
ORDER BY margin_pct  ASC;
LIMIT 10;

-- Insight: Budget smartphones (Redmi 13C at ~9.6%, OnePlus Nord CE 3 at ~12%)
-- have the thinnest margins. Avoid further discounting these SKUs —
-- any additional discount pushes them toward zero or negative margin.
 
-- Q9. How do salesperson quarterly targets compare to actuals?

SELECT
    t.salesperson_id,
    t.salesperson_name,
    t.region,
    t.quarter,
    ROUND(t.sales_target,0)     AS sales_target,
    ROUND(COALESCE(SUM(s.total_sales_amount),0),0)   AS actual_sales,
    ROUND(COALESCE(SUM(s.total_sales_amount),0)
          / t.sales_target * 100, 1)  AS achievement_pct,
    CASE
        WHEN COALESCE(SUM(s.total_sales_amount),0) >= t.sales_target
             THEN 'Exceeded'
        WHEN COALESCE(SUM(s.total_sales_amount),0) >= t.sales_target * 0.90
             THEN 'Near Target'
        WHEN COALESCE(SUM(s.total_sales_amount),0) >= t.sales_target * 0.70
             THEN 'Below Target'
        ELSE 'Needs Coaching'
    END   AS performance_band
FROM sales_targets t
LEFT JOIN fact_sales s
    ON  t.salesperson_id = s.salesperson_id
    AND TO_CHAR(s.order_date, 'YYYY-"Q"Q') = t.quarter
    AND s.order_status = 'Delivered'
GROUP BY t.salesperson_id, t.salesperson_name,
         t.region, t.quarter, t.sales_target
ORDER BY t.quarter, achievement_pct DESC;

-- Insight: ~14% of SP-quarter combinations exceed target. ~50% are near target
-- (90-99%). ~36% fall below 70% — these need coaching or territory review.
-- South region consistently shows the highest achievement rates.

-- Q10. Who are the top 5 best-performing salespersons overall?
SELECT
    s.salesperson_id,
    s.salesperson_name,
    COUNT(s.order_id)  AS total_orders,
    SUM(s.quantity)    AS units_sold,
    ROUND(SUM(s.total_sales_amount),0)  AS total_revenue,
    ROUND(SUM(s.profit),0)              AS total_profit,
    ROUND(AVG(s.customer_rating),2)     AS avg_customer_rating
FROM fact_sales s
WHERE s.order_status = 'Delivered'
GROUP BY s.salesperson_id, s.salesperson_name
ORDER BY total_revenue DESC
LIMIT 5;

-- Insight: Rahul Sharma leads with ₹1.30 Cr revenue and 203 orders,
-- followed closely by Divya Chopra (₹1.22 Cr) and Neha Tiwari (₹1.21 Cr).
-- Top 5 performers show similar customer ratings (3.50-3.71).

-- Q11. What is the return rate by category?
SELECT
    p.category,
    COUNT(s.order_id)   AS total_orders,
    SUM(CASE WHEN s.order_status='Returned'  THEN 1 ELSE 0 END)  AS returns,
    SUM(CASE WHEN s.order_status='Cancelled' THEN 1 ELSE 0 END)  AS cancellations,
    ROUND(SUM(CASE WHEN s.order_status='Returned' THEN 1 ELSE 0 END)
          ::NUMERIC / COUNT(s.order_id) * 100, 2)    AS return_rate_pct
FROM fact_sales s
JOIN dim_products p ON s.product_id = p.product_id
GROUP BY p.category
ORDER BY return_rate_pct DESC;

-- Insight: Tablets have the highest return rate at 16.67% -- worth investigating for 
-- product description accuracy or unmet customer expectations.
-- Smartphones have the lowest at 11.09%.
-- Any category above 15% should be flagged for product quality review.

-- Q12. How do customer segments differ in spending behaviour?

SELECT 
      c.customer_segment,
	COUNT(DISTINCT s.customer_id)  AS unique_customers,
	COUNT(s.order_id)  AS total_orders,
    SUM(s.quantity)    AS units_sold,
    ROUND(SUM(s.total_sales_amount),0)  AS total_revenue,
    ROUND(SUM(s.profit),0)              AS total_profit,
	ROUND(AVG(s.total_sales_amount),0)  AS avg_order_value,
    ROUND(AVG(s.customer_rating),2)     AS avg_rating
FROM fact_sales s
JOIN dim_customers c 
ON s.customer_id = c.customer_id
WHERE s.order_status = 'Delivered'
GROUP BY c.customer_segment
ORDER BY total_revenue DESC;	 

--VIP customers (12% of base) generate a proportional 11.4% of revenue.
--All three segments show nearly identical AOV (₹61K-₹64K) and ratings (3.62-3.64). 
--The real opportunity is converting Regular buyers to Premium through loyalty incentives 
--to increase order frequency.

-- Q13. Which age group spends the most?
SELECT 
      CASE
        WHEN c.age BETWEEN 18 AND 24 THEN '18-24 (Gen Z)'
        WHEN c.age BETWEEN 25 AND 34 THEN '25-34 (Millennial)'
        WHEN c.age BETWEEN 35 AND 44 THEN '35-44 (Gen X)'
        WHEN c.age BETWEEN 45 AND 54 THEN '45-54 (Senior)'
        ELSE '55+ (Boomer)'
    END AS age_group,
	COUNT(DISTINCT s.customer_id)  AS unique_customers,
	COUNT(s.order_id)  AS total_orders,
    SUM(s.quantity)    AS units_sold,
    ROUND(SUM(s.total_sales_amount),0)  AS total_revenue,
    ROUND(SUM(s.profit),0)              AS total_profit,
	ROUND(AVG(s.total_sales_amount),0)  AS avg_order_value,
    ROUND(AVG(s.customer_rating),2)     AS avg_rating
FROM fact_sales s
JOIN dim_customers c 
ON s.customer_id = c.customer_id
WHERE s.order_status = 'Delivered'
GROUP BY age_group 
ORDER BY total_revenue DESC;	 

-- Insight: 25-34 (Millennials) are the top spending cohort — high income,
-- tech-savvy, willing to pay for premium. Prioritise 55+ Boomers with 
--premium product campaigns — highest AOV (₹63,654) and best ratings (3.67).

-- Q14. How does discount level impact sales and margin?
SELECT
    CASE
        WHEN discount_percentage = 0     THEN 'No Discount'
        WHEN discount_percentage <= 4    THEN '1-4%'
        WHEN discount_percentage <= 8    THEN '5-8%'
        ELSE 'Above 8%'
    END   AS discount_bucket,
    COUNT(order_id)    AS total_orders,
    ROUND(SUM(total_sales_amount),0)   AS total_revenue,
    ROUND(SUM(profit),0)               AS total_profit,
    ROUND(SUM(profit)/SUM(s.total_sales_amount)*100,2) AS margin_pct
FROM fact_sales s
WHERE order_status = 'Delivered'
GROUP BY discount_bucket
ORDER BY total_orders DESC;	

-- Insight: 1-4% and 5-8% discounts drive identical volume (1,724 vs 1,710
-- orders) but 1-4% delivers 23.24% margin vs 19.31% -- 3.93 points of pure
-- profit given away for zero additional orders. With 99% of orders carrying
-- a discount, the strategy should shift to smaller discounts more frequently
-- rather than deeper discounts -- recovering margin without losing volume.

-- Q15. What is the quarterly Year-over-Year revenue trend?
SELECT
    TO_CHAR(order_date, 'YYYY-"Q"Q') AS quarter,
    COUNT(order_id)  AS total_orders,
    ROUND(SUM(total_sales_amount),0) AS quarterly_revenue,
    ROUND(SUM(profit),0)  AS quarterly_profit
FROM fact_sales
WHERE order_status = 'Delivered'
GROUP BY quarter
ORDER BY quarter;

-- Insight: Q4 (Oct-Dec) is consistently the strongest quarter due to Diwali.
-- YoY Q4 growth is a key business health indicator — plan inventory
-- 3 months in advance to capitalise on this peak demand window.

-- Q16. What is the average delivery time by state?
SELECT
    c.state,
    COUNT(s.order_id)   AS delivered_orders,
    ROUND(AVG(s.delivery_days),1)   AS avg_delivery_days,
    MIN(s.delivery_days)   AS fastest,
    MAX(s.delivery_days)   AS slowest
FROM fact_sales s
JOIN dim_customers c ON s.customer_id = c.customer_id
WHERE s.order_status = 'Delivered'
GROUP BY c.state
ORDER BY avg_delivery_days;

-- Insight: Delivery is consistent nationwide -- all 14 states deliver within
-- a tight 4.8 to 5.8 day window with no state exceeding 6 days.
-- Kerala leads at 4.8 days while top revenue states Maharashtra and Karnataka
-- average 5.6 days despite handling the highest order volumes (846 and 405).
-- No urgent logistics improvements needed -- focus instead on reducing the
-- 1-day variance to bring all states closer to Kerala's benchmark.

-- Q17. Which products have high stock but very low sales? (Dead inventory)
SELECT
    p.product_name,
    p.brand,
    p.category,
    p.stock_quantity,
    SUM(s.quantity) AS units_sold,
    ROUND(p.stock_quantity::NUMERIC / 
          NULLIF(SUM(s.quantity), 0), 1) AS stock_ratio
FROM dim_products p
LEFT JOIN fact_sales s 
    ON p.product_id = s.product_id
    AND s.order_status = 'Delivered'
GROUP BY p.product_name, p.brand,
         p.category, p.stock_quantity
HAVING SUM(s.quantity) < 60
    OR SUM(s.quantity) IS NULL
ORDER BY p.stock_quantity DESC
LIMIT 10;

-- Insight: Accessories (monitors, headsets, AirPods) dominate the
-- overstocked list with Dell 27 Monitor at ratio 9.9 being the worst
-- offender. Bundle these with high-selling laptops and phones as combo
-- deals to clear inventory and increase AOV simultaneously.

-- Q18. What is the city × category purchase pattern?
SELECT
    c.city, p.category,
    COUNT(s.order_id)   AS total_orders,
    ROUND(SUM(s.total_sales_amount),0)  AS total_revenue,
    ROUND(SUM(s.profit),0)              AS total_profit,
	ROUND(AVG(s.total_sales_amount),0)  AS avg_order_value,
	ROUND(AVG(s.customer_rating),2)     AS avg_rating
FROM fact_sales s
JOIN dim_customers c 
ON s.customer_id = c.customer_id
JOIN dim_products p
ON s.product_id = p.product_id 
WHERE s.order_status = 'Delivered'
GROUP BY c.city, p.category
ORDER BY total_revenue DESC
;

-- Insight: Laptops dominate every major city -- Mumbai leads with 182 orders
-- (₹1.74 Cr) followed by Bangalore (162 orders). Surat surprises with the
-- highest laptop AOV at ₹1,02,159 -- a Tier-2 city outspending Mumbai per order.







