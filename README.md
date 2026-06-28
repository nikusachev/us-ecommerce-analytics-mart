[Русская версия README](README_RU.md)
# U.S. E-Commerce Analytics Mart

## Project Overview

This project is an end-to-end data analytics portfolio project based on a U.S. e-commerce dataset covering orders, customers, products, sellers, payments, reviews and geolocation data.

The goal of the project is to build a structured analytical layer in PostgreSQL, calculate key business metrics, and create an interactive Power BI dashboard for revenue, profitability, customer behavior and retention analysis.

The project follows a layered analytical architecture:

```text
raw -> stg -> mart -> metrics -> Power BI
```

## Business Questions

The project answers the following business questions:

1. What is the overall business performance in terms of revenue, orders, AOV and margin?
2. Which product categories generate the most revenue and gross profit?
3. Are there seasonal revenue patterns across months and years?
4. Which categories drive seasonal revenue spikes?
5. How important are repeat customers for total revenue?
6. How does customer retention behave after the first purchase month?

## Tech Stack

* PostgreSQL
* DBeaver
* SQL
* Power BI
* Data modeling
* Cohort analysis
* Customer analytics
* Revenue and profitability analysis

## Data Model

The project uses several source tables:

* `customers`
* `orders`
* `order_items`
* `order_payments`
* `order_reviews`
* `products`
* `sellers`
* `geolocation`

The analytical model is built using three layers:

### Raw Layer

The `raw` schema contains source CSV data loaded into PostgreSQL without business transformations.

### Staging Layer

The `stg` schema contains cleaned and prepared views:

* `stg.stg_orders`
* `stg.stg_customers`
* `stg.stg_order_items`
* `stg.stg_order_payments`
* `stg.stg_order_reviews`
* `stg.stg_products`
* `stg.stg_sellers`
* `stg.stg_geolocation`

### Mart Layer

The `mart` schema contains analytical fact and dimension views:

* `mart.fct_orders`
* `mart.fct_order_items`
* `mart.fct_customer_value`
* `mart.fct_cohort_retention`
* `mart.dim_date`

## Key Grain Rules

The project explicitly controls table grain to avoid incorrect joins and duplicated metrics.

| Table                       | Grain                                   | Main Purpose                                            |
| --------------------------- | --------------------------------------- | ------------------------------------------------------- |
| `mart.fct_orders`           | 1 row = 1 order                         | Order-level metrics, revenue, AOV, cancellation rate    |
| `mart.fct_order_items`      | 1 row = 1 order item                    | Category, product, seller and gross profit analysis     |
| `mart.fct_customer_value`   | 1 row = 1 customer                      | Customer value, repeat customers, customer segmentation |
| `mart.fct_cohort_retention` | 1 row = 1 cohort month + 1 month number | Monthly cohort retention                                |
| `mart.dim_date`             | 1 row = 1 calendar date                 | Date filtering in Power BI                              |

## Key Metrics

The project calculates the following metrics:

* Total Orders
* Delivered Orders
* Canceled Orders
* Cancellation Rate
* Net Revenue
* Gross Item Revenue
* Total Discount Amount
* AOV
* Gross Profit
* Gross Margin %
* Items Sold
* Category Revenue Share %
* Total Customers
* Repeat Customer Share %
* Repeat Revenue Share %
* Avg Revenue per Customer
* Avg Orders per Customer
* Monthly Cohort Retention

Detailed metric definitions are available in:

```text
docs/metric_definitions.md
```

## Dashboard Pages

The Power BI dashboard contains five analytical pages:

### 1. Executive Overview

Provides a high-level overview of business performance:

* Net Revenue
* Delivered Orders
* AOV
* Gross Profit
* Gross Margin %
* Cancellation Rate
* Monthly revenue and order trends

![Executive Overview](screenshots/01_executive_overview.png)

### 2. Category Performance

Analyzes category-level revenue, profit and margin.

Key insight:

Electronics generates the highest revenue and gross profit, while categories such as fashion, toys and home goods show higher gross margin percentages.

![Category Performance](screenshots/02_category_performance.png)

### 3. Revenue & Seasonality

Shows monthly revenue dynamics and category contribution over time.

Key insight:

Revenue shows strong seasonal spikes in November and December. Electronics is the main driver of these peaks and accounts for the largest share of total revenue.

![Revenue & Seasonality](screenshots/03_revenue_seasonality.png)

### 4. Customer Analytics

Analyzes customer value, repeat customers and customer segments.

Key insight:

Repeat customers represent the majority of the customer base and generate most of the revenue. Revenue dominance is driven mainly by purchase frequency rather than higher average order value.

![Customer Analytics](screenshots/04_customer_analytics.png)

### 5. Cohort Retention

Analyzes monthly customer retention after the first purchase month.

Key insight:

After the first purchase month, monthly retention stabilizes around 3–4%. The first 12 months are used to evaluate early repeat purchase behavior and compare cohort quality over time.

![Cohort Retention](screenshots/05_cohort_retention.png)

## Main Business Findings

### 1. Revenue and Orders

The dataset contains 1,000,000 orders, of which 933,748 were delivered and 66,252 were canceled.

Net revenue from delivered orders is approximately 906.26 million, with an average order value of 970.56.

### 2. Profitability

Total gross profit is approximately 229.54 million, with an overall gross margin of 25.33%.

### 3. Category Performance

Electronics is the dominant category by revenue and gross profit. It accounts for the largest share of total net revenue, but it does not have the highest gross margin.

Fashion, toys and home goods show higher margin levels, which may make them strategically important despite lower absolute revenue.

### 4. Seasonality

Revenue has visible seasonal spikes in November and December. These spikes are largely driven by electronics, whose revenue share increases during peak months.

### 5. Customer Behavior

Repeat customers account for 82.10% of customers and generate 94.70% of total customer revenue.

This indicates that revenue concentration is mainly driven by purchase frequency rather than significantly higher average order value.

### 6. Retention

Monthly retention after the first purchase month is relatively low and stabilizes around 3–4% during the first 12 months.

This suggests that repeat purchases are distributed across different months rather than concentrated immediately after the first order.

## Repository Structure

```text
us-ecommerce-analytics-mart/
│
├── README.md
├── .gitignore
│
├── sql/
│   ├── 01_create_raw_tables.sql
│   ├── 02_create_raw_indexes.sql
│   ├── 03_data_quality_checks.sql
│   ├── 04_staging_views.sql
│   ├── 05_marts.sql
│   └── 06_metrics_queries.sql
│
├── docs/
│   ├── metric_definitions.md
│   └── data_model.md
│
├── powerbi/
│   └── us_ecommerce_analytics_dashboard.pbix
│
└── screenshots/
    ├── 01_executive_overview.png
    ├── 02_category_performance.png
    ├── 03_revenue_seasonality.png
    ├── 04_customer_analytics.png
    └── 05_cohort_retention.png
```

## How to Reproduce

1. Create a PostgreSQL database.
2. Create schemas: `raw`, `stg`, `mart`.
3. Load the source CSV files into the `raw` schema.
4. Run SQL scripts in the following order:

```text
01_create_raw_tables.sql
02_create_raw_indexes.sql
03_data_quality_checks.sql
04_staging_views.sql
05_marts.sql
06_metrics_queries.sql
```

5. Open the Power BI file:

```text
powerbi/us_ecommerce_analytics_dashboard.pbix
```

6. Refresh the model connection if needed.

## Notes

The raw dataset is not included in this repository due to file size. The project focuses on SQL modeling, metric logic, analytical marts and dashboard design.

## Future Improvements

- Add regional analytics using customer_state, seller_state and aggregated geolocation data.
- Build a regional dashboard page with revenue, orders, AOV and cancellation rate by state.
- Add map-based visualization using aggregated zip-level coordinates.