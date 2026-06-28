-- ============================================================
-- 06_metrics_queries.sql
-- Project: U.S. E-Commerce Analytics Mart
-- Purpose: Analytical metric queries for portfolio, README and Power BI
-- ============================================================


-- ============================================================
-- 1. Executive overview metrics
-- Grain of source table: 1 row = 1 order_id
-- Source: mart.fct_orders
-- ============================================================

SELECT
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE is_delivered = 1) AS delivered_orders,
    COUNT(*) FILTER (WHERE is_canceled = 1) AS canceled_orders,
    ROUND(COUNT(*) FILTER (WHERE is_canceled = 1)::DECIMAL / NULLIF(COUNT(*), 0) * 100, 2) AS cancellation_rate_pct,
    ROUND(SUM(net_item_revenue) FILTER (WHERE is_delivered = 1), 2) AS net_revenue,
    ROUND(SUM(gross_item_revenue) FILTER (WHERE is_delivered = 1), 2) AS gross_item_revenue,
    ROUND(SUM(total_discount_amount) FILTER (WHERE is_delivered = 1), 2) AS total_discount_amount,
    ROUND(SUM(total_freight_value) FILTER (WHERE is_delivered = 1), 2) AS total_freight_value,
    ROUND(SUM(net_item_revenue) FILTER (WHERE is_delivered = 1)::DECIMAL / NULLIF(COUNT(*) FILTER (WHERE is_delivered = 1), 0), 2) AS aov
FROM mart.fct_orders;


-- ============================================================
-- 2. Monthly sales dynamics
-- Grain: 1 row = 1 purchase_month
-- Source: mart.fct_orders
-- ============================================================

SELECT
    purchase_month,
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE is_delivered = 1) AS delivered_orders,
    COUNT(*) FILTER (WHERE is_canceled = 1) AS canceled_orders,
    ROUND(COUNT(*) FILTER (WHERE is_canceled = 1)::DECIMAL/ NULLIF(COUNT(*), 0) * 100, 2) AS cancellation_rate_pct,
    ROUND(SUM(net_item_revenue) FILTER (WHERE is_delivered = 1), 2) AS net_revenue,
    ROUND(SUM(gross_item_revenue) FILTER (WHERE is_delivered = 1), 2) AS gross_item_revenue,
    ROUND(SUM(total_discount_amount) FILTER (WHERE is_delivered = 1), 2) AS total_discount_amount,
    ROUND(SUM(total_freight_value) FILTER (WHERE is_delivered = 1), 2) AS total_freight_value,
    ROUND(SUM(net_item_revenue) FILTER (WHERE is_delivered = 1)::DECIMAL / NULLIF(COUNT(*) FILTER (WHERE is_delivered = 1), 0), 2) AS aov
FROM mart.fct_orders 
GROUP BY purchase_month
ORDER BY purchase_month;


-- ============================================================
-- 3. Category performance
-- Grain: 1 row = 1 product_category_name
-- Source: mart.fct_order_items
-- ============================================================

SELECT
    product_category_name,
    COUNT(*) AS items_sold,
    COUNT(DISTINCT order_id) AS orders_count,
    ROUND(SUM(net_item_revenue), 2) AS net_revenue,
    ROUND(SUM(gross_profit), 2) AS gross_profit,
    ROUND(SUM(gross_profit)::DECIMAL / NULLIF(SUM(net_item_revenue), 0) * 100, 2) AS gross_margin_pct,
    ROUND(SUM(net_item_revenue)::DECIMAL / NULLIF(COUNT(*), 0), 2) AS avg_item_revenue
FROM mart.fct_order_items
WHERE is_delivered = 1
GROUP BY product_category_name
ORDER BY gross_profit DESC;


-- ============================================================
-- 4. Monthly category performance
-- Grain: 1 row = 1 purchase_month + 1 product_category_name
-- Source: mart.fct_order_items
-- ============================================================

SELECT
    purchase_month,
    product_category_name,
    COUNT(*) AS items_sold,
    COUNT(DISTINCT order_id) AS orders_count,
    ROUND(SUM(net_item_revenue), 2) AS net_revenue,
    ROUND(SUM(gross_profit), 2) AS gross_profit,
    ROUND(SUM(gross_profit)::DECIMAL / NULLIF(SUM(net_item_revenue), 0) * 100, 2) AS gross_margin_pct,
    ROUND(SUM(net_item_revenue)::DECIMAL / NULLIF(COUNT(*), 0), 2) AS avg_item_revenue
FROM mart.fct_order_items
WHERE is_delivered = 1
GROUP BY purchase_month, product_category_name
ORDER BY purchase_month, net_revenue DESC;


-- ============================================================
-- 5. Monthly category revenue share
-- Grain: 1 row = 1 purchase_month + 1 product_category_name
-- Source: mart.fct_order_items
-- ============================================================

WITH monthly_category AS (
    SELECT
        purchase_month,
        product_category_name,
        COUNT(*) AS items_sold,
        COUNT(DISTINCT order_id) AS orders_count,
        ROUND(SUM(net_item_revenue), 2) AS net_revenue,
        ROUND(SUM(gross_profit), 2) AS gross_profit,
        ROUND(SUM(gross_profit)::DECIMAL / NULLIF(SUM(net_item_revenue), 0) * 100, 2) AS gross_margin_pct,
        ROUND(SUM(net_item_revenue)::DECIMAL / NULLIF(COUNT(*), 0), 2) AS avg_item_revenue
    FROM mart.fct_order_items
    WHERE is_delivered = 1
    GROUP BY purchase_month, product_category_name
)

SELECT
    purchase_month,
    product_category_name,
    items_sold,
    orders_count,
    net_revenue,
    SUM(net_revenue) OVER (PARTITION BY purchase_month) AS monthly_total_revenue,
    ROUND(net_revenue::DECIMAL / NULLIF(SUM(net_revenue) OVER (PARTITION BY purchase_month), 0) * 100, 2) AS category_revenue_share_pct,
    RANK() OVER (PARTITION BY purchase_month ORDER BY net_revenue DESC) AS category_rank_by_revenue,
    gross_profit,
    gross_margin_pct,
    avg_item_revenue
FROM monthly_category
ORDER BY purchase_month, category_rank_by_revenue;

-- ============================================================
-- 6. Customer value
-- Grain: 1 row = 1 customer_unique_id
-- Source: mart.fct_orders
-- ============================================================

SELECT 
    customer_unique_id,

    MIN(purchase_date) AS first_purchase_date,
    MAX(purchase_date) AS last_purchase_date,
    COUNT(DISTINCT order_id) AS orders_count,
    CASE 
        WHEN COUNT(DISTINCT order_id) > 1 THEN 1
        ELSE 0
    END AS is_repeat_customer,
    MAX(purchase_date) - MIN(purchase_date) AS customer_lifetime_days,
    ROUND(SUM(net_item_revenue), 2) AS net_revenue,
    ROUND(SUM(net_item_revenue)::DECIMAL / NULLIF(COUNT(DISTINCT order_id), 0),2) AS avg_order_value
FROM mart.fct_orders
WHERE is_delivered = 1
GROUP BY customer_unique_id;


-- ============================================================
-- 7. Repeat customers revenue contribution
-- Source: customer-level aggregation from mart.fct_orders
-- ============================================================

WITH customer_value AS (
    SELECT 
        customer_unique_id,
        MIN(purchase_date) AS first_purchase_date,
        MAX(purchase_date) AS last_purchase_date,
        COUNT(DISTINCT order_id) AS orders_count,
        CASE 
            WHEN COUNT(DISTINCT order_id) > 1 THEN 1
            ELSE 0
        END AS is_repeat_customer,
        MAX(purchase_date) - MIN(purchase_date) AS customer_lifetime_days,
        ROUND(SUM(net_item_revenue), 2) AS net_revenue,
        ROUND(SUM(net_item_revenue)::DECIMAL / NULLIF(COUNT(DISTINCT order_id), 0), 2) AS avg_order_value
    FROM mart.fct_orders
    WHERE is_delivered = 1
    GROUP BY customer_unique_id
)

SELECT
    CASE
        WHEN orders_count = 1 THEN 'one_time_customer'
        ELSE 'repeat_customer'
    END AS customer_type,
    COUNT(*) AS customers_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS customers_share_pct,
    ROUND(SUM(net_revenue), 2) AS net_revenue,
    ROUND(SUM(net_revenue) * 100.0 / SUM(SUM(net_revenue)) OVER (), 2) AS revenue_share_pct,
    ROUND(AVG(avg_order_value), 2) AS avg_customer_aov
FROM customer_value
GROUP BY customer_type
ORDER BY customers_count DESC;

-- ============================================================
-- 8. Customer cohort retention
-- Source: mart.fct_orders
-- ============================================================

WITH customer_months AS (
    SELECT DISTINCT
        customer_unique_id,
        purchase_month AS order_month
    FROM mart.fct_orders
    WHERE is_delivered = 1
      AND customer_unique_id IS NOT NULL
),

customer_cohorts AS (
    SELECT
        customer_unique_id,
        MIN(order_month) AS cohort_month
    FROM customer_months
    GROUP BY customer_unique_id
),

cohort_activity AS (
    SELECT
        cm.customer_unique_id,
        cc.cohort_month,
        cm.order_month,
        ((EXTRACT(YEAR FROM cm.order_month)::INT - EXTRACT(YEAR FROM cc.cohort_month)::INT) * 12
            +
            (EXTRACT(MONTH FROM cm.order_month)::INT - EXTRACT(MONTH FROM cc.cohort_month)::INT)
        ) AS month_number
    FROM customer_months AS cm
    LEFT JOIN customer_cohorts AS cc
        ON cm.customer_unique_id = cc.customer_unique_id
),

retention_counts AS (
    SELECT
        cohort_month,
        month_number,
        COUNT(DISTINCT customer_unique_id) AS active_customers
    FROM cohort_activity
    GROUP BY cohort_month, month_number
),

cohort_sizes AS (
    SELECT
        cohort_month,
        active_customers AS cohort_size
    FROM retention_counts
    WHERE month_number = 0
)

SELECT
    rc.cohort_month,
    rc.month_number,
    rc.active_customers,
    cs.cohort_size,
    ROUND(rc.active_customers::DECIMAL / NULLIF(cs.cohort_size, 0) * 100, 2) AS retention_rate_pct
FROM retention_counts AS rc
LEFT JOIN cohort_sizes AS cs
    ON rc.cohort_month = cs.cohort_month
ORDER BY rc.cohort_month, rc.month_number;