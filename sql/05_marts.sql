-- ============================================================
-- 05_marts.sql
-- Project: U.S. E-Commerce Analytics Mart
-- Purpose: Build analytical marts for metrics and Power BI
-- ============================================================


-- ============================================================
-- 1. Orders fact mart
-- Grain: 1 row = 1 order_id
-- Purpose: central order-level fact table for Power BI and metrics
-- ============================================================

CREATE OR REPLACE VIEW mart.fct_orders AS
WITH order_items_agg AS (
    SELECT
        order_id,
        COUNT(*) AS items_count,
        COUNT(DISTINCT product_id) AS products_count,
        COUNT(DISTINCT seller_id) AS sellers_count,
        ROUND(SUM(price), 2) AS gross_item_revenue,
        ROUND(SUM(discount_amount), 2) AS total_discount_amount,
        ROUND(SUM(net_item_revenue), 2) AS net_item_revenue,
        ROUND(SUM(freight_value), 2) AS total_freight_value
    FROM stg.stg_order_items
    GROUP BY order_id
)

SELECT
    o.order_id,
    o.customer_id,
    o.order_status,
    o.purchase_date,
    o.purchase_month,
    o.is_delivered,
    o.is_canceled,
    c.customer_unique_id,
    c.customer_age_group,
    c.customer_city,
    c.customer_state,
    c.customer_segment,
    oi.items_count,
    oi.products_count,
    oi.sellers_count,
    oi.gross_item_revenue,
    oi.total_discount_amount,
    oi.net_item_revenue,
    oi.total_freight_value,
    p.payment_parts_count,
    p.total_payment_value,
    p.max_payment_installments,
    r.review_score,
    r.has_review_comment,
    r.review_answer_days

FROM stg.stg_orders AS o
LEFT JOIN stg.stg_customers AS c
    ON o.customer_id = c.customer_id
LEFT JOIN order_items_agg AS oi
    ON o.order_id = oi.order_id
LEFT JOIN stg.stg_order_payments AS p
    ON o.order_id = p.order_id
LEFT JOIN stg.stg_order_reviews AS r
    ON o.order_id = r.order_id;


-- ============================================================
-- 2. Order items fact mart
-- Grain: 1 row = 1 order item
-- Purpose: product, category, seller and gross profit analytics
-- ============================================================

CREATE OR REPLACE VIEW mart.fct_order_items AS
SELECT 
    oi.order_id,
    oi.order_item_id,
    oi.product_id,
    oi.seller_id,
    oi.shipping_limit_date,
    oi.price,
    oi.freight_value,
    oi.discount_rate,
    oi.discount_amount,
    oi.net_item_revenue,
    o.order_status,
    o.purchase_date,
    o.purchase_month,
    o.is_delivered,
    o.is_canceled,
    p.product_category_name,
    p.product_name,
    p.product_brand,
    p.cost,
    p.product_weight_kg,
    p.product_volume_cm3,
    s.seller_city,
    s.seller_state,
    s.seller_age_group,

    ROUND(oi.net_item_revenue - p.cost, 2) AS gross_profit

FROM stg.stg_order_items AS oi 
LEFT JOIN stg.stg_orders AS o
    ON oi.order_id = o.order_id
LEFT JOIN stg.stg_products AS p
    ON oi.product_id = p.product_id
LEFT JOIN stg.stg_sellers AS s
    ON oi.seller_id = s.seller_id;

-- ============================================================
-- 3. Date dimension
-- Grain: 1 row = 1 calendar date
-- Purpose: date filtering and time intelligence in Power BI
-- ============================================================

CREATE OR REPLACE VIEW mart.dim_date AS
SELECT
    date_day::date AS date_day,
    EXTRACT(YEAR FROM date_day)::int AS year,
    EXTRACT(MONTH FROM date_day)::int AS month_number,
    TO_CHAR(date_day, 'Month') AS month_name,
    DATE_TRUNC('month', date_day)::date AS month_start,
    EXTRACT(QUARTER FROM date_day)::int AS quarter,
    EXTRACT(DOW FROM date_day)::int AS day_of_week
FROM GENERATE_SERIES(
    (SELECT MIN(purchase_date) FROM mart.fct_orders),
    (SELECT MAX(purchase_date) FROM mart.fct_orders),
    INTERVAL '1 day'
) AS date_day;

-- ============================================================
-- 4. Customer value fact mart
-- Grain: 1 row = 1 customer_unique_id
-- Purpose: customer value, repeat purchase and segmentation analysis
-- ============================================================

CREATE OR REPLACE VIEW mart.fct_customer_value AS
SELECT
    customer_unique_id,
    MIN(purchase_date) AS first_purchase_date,
    DATE_TRUNC('month', MIN(purchase_date))::date AS cohort_month,
    MAX(purchase_date) AS last_purchase_date,
    COUNT(DISTINCT order_id) AS orders_count,
    CASE 
        WHEN COUNT(DISTINCT order_id) > 1 THEN 1
        ELSE 0
    END AS is_repeat_customer,
    CASE 
        WHEN COUNT(DISTINCT order_id) > 1 THEN 'repeat_customer'
        ELSE 'one_time_customer'
    END AS customer_type,
    MAX(purchase_date) - MIN(purchase_date) AS customer_lifetime_days,
    ROUND(SUM(net_item_revenue), 2) AS net_revenue,
    ROUND(SUM(net_item_revenue)::DECIMAL / NULLIF(COUNT(DISTINCT order_id), 0), 2) AS avg_order_value,
    MAX(customer_segment) AS customer_segment,
    MAX(customer_age_group) AS customer_age_group,
    MAX(customer_state) AS customer_state

FROM mart.fct_orders
WHERE is_delivered = 1
  AND customer_unique_id IS NOT NULL
GROUP BY customer_unique_id;

-- ============================================================
-- 5. Cohort retention fact mart
-- Grain: 1 row = 1 cohort_month + 1 month_number
-- Purpose: monthly customer retention analysis
-- ============================================================
CREATE OR REPLACE VIEW mart.fct_cohort_retention AS
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
