-- ============================================================
-- TechVista India — Indian Electronics Sales Analytics
-- advanced_queries.sql
-- Topics: Subqueries | CTEs | Window Functions | Date Analysis
-- ============================================================


-- A1. Products earning above-average profit margin

SELECT
    p.product_name,
    p.brand,
    p.category,
    ROUND(SUM(s.profit)/SUM(s.total_sales_amount)*100,2) AS margin_pct
FROM fact_sales s
JOIN dim_products p ON s.product_id = p.product_id
WHERE s.order_status = 'Delivered'
GROUP BY p.product_name, p.brand, p.category
HAVING ROUND(SUM(s.profit)/SUM(s.total_sales_amount)*100,2) >
    (SELECT ROUND(SUM(profit)/SUM(total_sales_amount)*100,2)
     FROM fact_sales WHERE order_status = 'Delivered')
ORDER BY margin_pct DESC;


-- Insight: Accessories (AirPods, Buds, Gaming Headsets) and Smartwatches
-- consistently outperform the average margin. These are high-priority
-- products to push harder through marketing and bundling.

-- A2. Customers who spent above average

WITH customer_spending AS (
    SELECT
        s.customer_id,
		c.customer_name, 
		c.city,
		c.customer_segment,
        ROUND(SUM(s.total_sales_amount),0) AS total_spent
    FROM fact_sales s
	JOIN dim_customers c
	ON s.customer_id = c.customer_id
	WHERE  order_status = 'Delivered'
    GROUP BY s.customer_id, c.customer_name, c.city, c.customer_segment
)
SELECT *
FROM customer_spending
WHERE total_spent >
(
    SELECT AVG(total_spent)
    FROM customer_spending
)
ORDER BY total_spent DESC
LIMIT 20;

-- Insight: High-value customers above average spend are prime candidates
-- for the loyalty program upgrade from Regular to Premium/VIP tier.


-- A3. CTE — Monthly revenue with Month-over-Month growth %

WITH monthly_revenue AS (
    SELECT
        TO_CHAR(order_date,'YYYY-MM')    AS yr_month,
        SUM(total_sales_amount) AS revenue
    FROM fact_sales
	WHERE order_status = 'Delivered'
    GROUP BY yr_month
)
SELECT
    yr_month,
    revenue,
	LAG(revenue) OVER(ORDER BY yr_month) AS previous_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER(ORDER BY yr_month)) * 100.0 
        /
        LAG(revenue) OVER(ORDER BY yr_month), 2) AS mom_growth_pct
FROM monthly_revenue
ORDER BY yr_month;

-- Insight: Positive MoM in Oct-Nov confirms Diwali season impact.
-- Negative MoM in Jan-Feb is normal post-holiday normalisation.
-- Use this to set realistic monthly targets for the sales team.

-- A4. CTE — Brand performance with revenue share %
WITH brand_sales AS(
SELECT
        p.brand,
		COUNT(DISTINCT p.product_name) AS SKUs,
		ROUND(SUM(s.total_sales_amount),0) AS brand_revenue,
		ROUND(SUM(s.profit),0)             AS brand_profit
    FROM fact_sales s
	JOIN dim_products p
	ON s.product_id = p.product_id 
	WHERE  order_status = 'Delivered'
    GROUP BY p.brand
)
SELECT * , 
      ROUND(brand_revenue/(SELECT SUM(total_sales_amount)
     FROM fact_sales WHERE order_status = 'Delivered')*100,1) AS brand_share
FROM brand_sales
ORDER BY  brand_share DESC;
       
-- Insight: Apple alone contributes ~31% of revenue with just 11 SKUs.
-- This concentration is a risk — losing Apple supply would remove
-- nearly a third of revenue. Diversify by growing Samsung and HP share.

-- A5. WINDOW FUNCTION — Running total of monthly revenue
SELECT
    TO_CHAR(order_date,'YYYY-MM') AS yr_month,
    SUM(total_sales_amount) AS monthly_revenue,
    SUM(SUM(total_sales_amount))
        OVER (ORDER BY TO_CHAR(order_date,'YYYY-MM')) AS running_total
FROM fact_sales
WHERE order_status = 'Delivered'
GROUP BY TO_CHAR(order_date,'YYYY-MM')
ORDER BY yr_month;	     

-- Insight: Running total shows cumulative business progress toward annual
-- revenue milestones.

-- A6. WINDOW FUNCTION — Rank salespersons within each region
WITH sp_perf AS (
    SELECT
        s.salesperson_id,
        s.salesperson_name,
        t.region,
        ROUND(SUM(s.total_sales_amount),0) AS total_revenue
    FROM fact_sales s
    JOIN (SELECT DISTINCT salesperson_id, region FROM sales_targets) t 
	ON s.salesperson_id = t.salesperson_id
    WHERE s.order_status = 'Delivered'
    GROUP BY s.salesperson_id, s.salesperson_name, t.region
)
SELECT *, RANK() 
       OVER(PARTITION BY region ORDER BY total_revenue DESC) AS rank_in_region
  FROM sp_perf;

-- Insight: Regional #1 performers are natural candidates for team lead roles.

-- A7. WINDOW FUNCTION — Top 3 products per category
SELECT * FROM (
SELECT
        p.category,
        p.brand,
		p.product_name,
        ROUND(SUM(s.total_sales_amount),0) AS product_revenue,
		RANK()
        OVER(PARTITION BY category ORDER BY SUM(total_sales_amount) DESC) AS rnk_prods
    FROM fact_sales s
    JOIN dim_products p ON s.product_id = p.product_id
    WHERE s.order_status = 'Delivered'
    GROUP BY p.category, p.brand, p.product_name
)
WHERE rnk_prods <= 3;
	
-- Insight: Category-level top 3 products should be prioritised for
-- in-store placement, marketing spend, and stock replenishment.

-- A8. DATE ANALYSIS — Sales by day of week
SELECT
    TO_CHAR(order_date,'Day')           AS day_name,
    EXTRACT(DOW FROM order_date)        AS dow_number,
    COUNT(order_id)                     AS total_orders,
    ROUND(SUM(total_sales_amount),0)    AS total_revenue
FROM fact_sales
WHERE order_status = 'Delivered'
GROUP BY day_name, dow_number
ORDER BY dow_number;

-- Insight: Weekend orders (Saturday/Sunday) typically spike.
-- Schedule email and WhatsApp marketing campaigns for Friday evenings
-- to capture the weekend shopping intent.


-- A9. CTE Region performance with revenue share %
WITH regoin_perf AS (
SELECT t.region,
       COUNT(DISTINCT t.salesperson_id) AS total_salesperson,
       SUM(s.total_sales_amount) AS region_sales
	   FROM fact_sales s
	  JOIN (SELECT DISTINCT salesperson_id, region FROM sales_targets) t
	  ON t.salesperson_id = s.salesperson_id
	  WHERE order_status = 'Delivered'
	  GROUP  BY t.region
	  ORDER BY region_sales DESC
)
SELECT *,
        ROUND(region_sales/(SELECT SUM(total_sales_amount) 
                    FROM fact_sales WHERE order_status = 'Delivered')*100,1) AS region_share
FROM regoin_perf;

-- Insight: South dominates with 37.1% of revenue (₹8.04 Cr) powered by its
-- 7 salespersons -- the largest team. Add salespersons to under-covered
--  regions (Central, East) to unlock proportional revenue.  
