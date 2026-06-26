# TechVista India — Electronics Sales Analytics

An end-to-end data analytics project analysing 3.5 years of sales for a fictional Indian electronics retailer — from raw data to an interactive Power BI dashboard.

**Stack:** PostgreSQL · pgAdmin · Power BI Desktop · DAX

\---

## Overview

TechVista India is a simulated electronics retailer selling laptops, smartphones, tablets, smartwatches, and accessories across 20 Indian cities. This project covers the full analytics lifecycle: designing the database, cleaning the data, writing analytical SQL, and surfacing insights in a four-page Power BI dashboard.

|Metric|Value|
|-|-|
|Total Revenue|₹21.69 Cr|
|Total Profit|₹4.67 Cr|
|Profit Margin|21.51%|
|Total Orders|3,478|
|Avg Order Value|₹62,377|
|Unique Customers|2,866|

\---

## Data Model — Star Schema

|Table|Type|Rows|Description|
|-|-|-|-|
|`fact\_sales`|Fact|4,500|One row per order — the core transactional table|
|`dim\_products`|Dimension|53|Product catalogue (8 brands, 5 categories)|
|`dim\_customers`|Dimension|2,800|Customer master (demographics, location, segment)|
|`sales\_targets`|Dimension|280|Quarterly targets (20 salespersons × 14 quarters)|

\---

## Dashboard

A four-page interactive Power BI report, each page with its own theme and focus.

### Executive Overview

The leadership view — total revenue, profit, margin, and order volume at a glance.

Tracks monthly revenue trend, sales by city and state, and category and brand

contribution to give management a single-screen health check of the business.

### Product Analysis

A deep dive into what sells and what earns. Compares revenue, profit, and margin

across brands and categories, surfaces the top-performing products, and flags

thin-margin SKUs and slow-moving inventory that need attention.

### Customer Analysis

Understands who buys and how they behave. Breaks down revenue by customer segment,

age group, and city, and compares average order value and ratings across groups

to reveal the most valuable — and most underserved — customer profiles.

### Salesperson Performance

Measures the sales team against their quarterly targets. Combines an achievement

gauge, a target-vs-actual breakdown, and a revenue ranking to identify top

performers, coaching needs, and regional coverage gaps.

\---

## Key Business Insights

Each insight pairs a problem found in the data with a recommended action.

**Revenue is dangerously concentrated in one supplier.**
A single brand drives 31% of revenue and 36% of profit — one supply disruption or contract dispute could erase nearly a third of the business. *Recommendation: grow second-tier brands (HP, Dell) that already hold 21%+ margins to reduce dependency.*

**Cash is frozen in dead stock while bestsellers risk running out.**
Several accessories and tablets carry up to 10× more stock than they sell, while top phones are close to stockout — capital is tied up in slow movers and sales are at risk from shortages. *Recommendation: bundle slow movers with laptops to clear them, and reorder fast movers immediately.*

**An entire sales region depends on a single person.**
One region's revenue comes 100% from a single salesperson — if they leave, that territory collapses overnight. *Recommendation: hire a second representative for the region and rebalance territory coverage.*

**Predictable festival demand is not being planned for.**
Q4 (Diwali season) revenue is consistently about double the Q3 low every year, yet sales targets are flat across quarters and inventory is not pre-built. *Recommendation: pre-load stock during the Q3 lull and set Q4 stretch targets to capture the surge.*

**Budget products are one discount away from a loss.**
The thinnest-margin product runs at just 9.67% margin, and one brand holds four of the ten lowest-margin SKUs — any further discounting risks selling at a loss. *Recommendation: enforce a strict discount floor on all products below 15% margin.*

\---

## SQL

The analysis is split across five files, run in order.

|File|Purpose|
|-|-|
|`schema.sql`|Creates the 4 tables, constraints, indexes, and star schema|
|`data\_import.sql`|Loads the CSV data into PostgreSQL|
|`data\_cleaning.sql`|Cleans the data — NULL handling, deduplication, casing fixes, profit validation|
|`business\_queries.sql`|18 business queries covering revenue, margin, returns, segments, and seasonality|
|`advanced\_queries.sql`|10 advanced queries using subqueries, CTEs, window functions, and date analysis|

**Techniques demonstrated:** window functions (`RANK`, `LAG`, running totals), CTEs, nested subqueries, conditional aggregation, and data-quality handling with `COALESCE`, and `PERCENTILE\_CONT`.

\---

## Power BI

* Four-page report with consistent theming and cross-page slicers (Year, Category, Region)
* Core measures: Total Sales, Total Profit, Profit Margin %, and target-achievement tracking
* KPI cards, achievement gauge, donut, geographic map, and ranked bar charts

\---

## Project Structure

```
TechVista-India-Sales-Analytics/
├── README.md
├── dashboard/
│   ├── TechVista\_Dashboard.pbix
│   └── screenshots/
│       ├── 01\_executive\_overview.png
│       ├── 02\_product\_analysis.png
│       ├── 03\_customer\_analysis.png
│       └── 04\_salesperson\_performance.png
├── sql/
│   ├── schema\_+\_import.sql
│   ├── data\_cleaning.sql
│   ├── business\_queries.sql
│   └── advanced\_queries.sql
└── data/
    ├── fact\_sales.csv
    ├── dim\_products.csv
    ├── dim\_customers.csv
    └── sales\_targets.csv
```

\---

## Notes

All data is synthetic, generated for portfolio purposes — no real customer information is included. Insights were verified directly against the dataset.

