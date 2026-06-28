-- ============================================================
-- 03_data_quality_checks.sql
-- Project: U.S. E-Commerce Analytics Mart
-- Purpose: Validate raw data quality, table grain and key relationships
-- ============================================================


-- ============================================================
-- 1. Row count and grain checks
-- ============================================================

SELECT 'customers_rows' AS check_name, COUNT(*) AS value FROM raw.customers
UNION ALL
SELECT 'customers_distinct_customer_id', COUNT(DISTINCT customer_id) FROM raw.customers
UNION ALL
SELECT 'customers_distinct_customer_unique_id', COUNT(DISTINCT customer_unique_id) FROM raw.customers

UNION ALL
SELECT 'orders_rows', COUNT(*) FROM raw.orders
UNION ALL
SELECT 'orders_distinct_order_id', COUNT(DISTINCT order_id) FROM raw.orders

UNION ALL
SELECT 'order_items_rows', COUNT(*) FROM raw.order_items
UNION ALL
SELECT 'order_items_distinct_order_item_key', COUNT(DISTINCT (order_id, order_item_id)) FROM raw.order_items

UNION ALL
SELECT 'order_payments_rows', COUNT(*) FROM raw.order_payments
UNION ALL
SELECT 'order_payments_distinct_payment_key', COUNT(DISTINCT (order_id, payment_sequential)) FROM raw.order_payments

UNION ALL
SELECT 'order_reviews_rows', COUNT(*) FROM raw.order_reviews
UNION ALL
SELECT 'order_reviews_distinct_review_id', COUNT(DISTINCT review_id) FROM raw.order_reviews
UNION ALL
SELECT 'order_reviews_distinct_order_id', COUNT(DISTINCT order_id) FROM raw.order_reviews

UNION ALL
SELECT 'products_rows', COUNT(*) FROM raw.products
UNION ALL
SELECT 'products_distinct_product_id', COUNT(DISTINCT product_id) FROM raw.products

UNION ALL
SELECT 'sellers_rows', COUNT(*) FROM raw.sellers
UNION ALL
SELECT 'sellers_distinct_seller_id', COUNT(DISTINCT seller_id) FROM raw.sellers

UNION ALL
SELECT 'geolocation_rows', COUNT(*) FROM raw.geolocation
UNION ALL
SELECT 'geolocation_distinct_zip_code_prefix', COUNT(DISTINCT zip_code_prefix) FROM raw.geolocation;


-- ============================================================
-- 2. Orphan records checks
-- Checks whether foreign keys reference existing records
-- ============================================================

SELECT 'orders_without_customer' AS check_name, COUNT(*) AS value
FROM raw.orders o
LEFT JOIN raw.customers c 
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL

UNION ALL
SELECT 'order_items_without_order', COUNT(*)
FROM raw.order_items oi
LEFT JOIN raw.orders o 
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL
SELECT 'order_payments_without_order', COUNT(*)
FROM raw.order_payments op
LEFT JOIN raw.orders o 
    ON op.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL
SELECT 'order_reviews_without_order', COUNT(*)
FROM raw.order_reviews r
LEFT JOIN raw.orders o 
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL
SELECT 'order_items_without_product', COUNT(*)
FROM raw.order_items oi
LEFT JOIN raw.products p 
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL

UNION ALL
SELECT 'order_items_without_seller', COUNT(*)
FROM raw.order_items oi
LEFT JOIN raw.sellers s 
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;


-- ============================================================
-- 3. Order status distribution
-- Used to define which orders are included in sales metrics
-- ============================================================

SELECT
    order_status,
    COUNT(*) AS orders_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS share_pct
FROM raw.orders
GROUP BY order_status
ORDER BY orders_count DESC;


-- ============================================================
-- Business rule based on order status check:
-- Revenue, AOV, gross profit and customer value metrics
-- should be calculated only for delivered orders.
--
-- Canceled orders should be excluded from sales metrics
-- and used separately for cancellation rate.
-- ============================================================

-- ============================================================
-- 4. Money and discount checks
-- Checks whether monetary fields are valid for revenue and profit metrics
-- ============================================================

SELECT 'order_items_price_null' AS check_name, COUNT(*) AS value
FROM raw.order_items
WHERE price IS NULL

UNION ALL
SELECT 'order_items_price_less_or_equal_zero', COUNT(*)
FROM raw.order_items
WHERE price <= 0

UNION ALL
SELECT 'freight_value_null', COUNT(*)
FROM raw.order_items
WHERE freight_value IS NULL

UNION ALL
SELECT 'freight_value_negative', COUNT(*)
FROM raw.order_items
WHERE freight_value < 0

UNION ALL
SELECT 'discount_rate_null', COUNT(*)
FROM raw.order_items
WHERE discount_rate IS NULL

UNION ALL
SELECT 'discount_rate_out_of_range', COUNT(*)
FROM raw.order_items
WHERE discount_rate < 0 OR discount_rate > 1

UNION ALL
SELECT 'payment_value_null', COUNT(*)
FROM raw.order_payments
WHERE payment_value IS NULL

UNION ALL
SELECT 'payment_value_less_or_equal_zero', COUNT(*)
FROM raw.order_payments
WHERE payment_value <= 0

UNION ALL
SELECT 'product_cost_null', COUNT(*)
FROM raw.products
WHERE cost IS NULL

UNION ALL
SELECT 'product_price_null', COUNT(*)
FROM raw.products
WHERE price IS NULL

UNION ALL
SELECT 'product_cost_negative', COUNT(*)
FROM raw.products
WHERE cost < 0

UNION ALL
SELECT 'product_price_less_or_equal_zero', COUNT(*)
FROM raw.products
WHERE price <= 0;

-- ============================================================
-- 5. Date range checks
-- Checks the available time period in the orders table
-- ============================================================

SELECT
    MIN(order_purchase_timestamp) AS min_purchase_date,
    MAX(order_purchase_timestamp) AS max_purchase_date,
    MIN(order_delivered_customer_date) AS min_customer_delivery_date,
    MAX(order_delivered_customer_date) AS max_customer_delivery_date,
    MIN(order_estimated_delivery_date) AS min_estimated_delivery_date,
    MAX(order_estimated_delivery_date) AS max_estimated_delivery_date
FROM raw.orders;


-- ============================================================
-- 6. Date logic checks
-- Checks whether delivery dates are earlier than purchase dates
-- ============================================================

SELECT 'approved_before_purchase' AS check_name, COUNT(*) AS value
FROM raw.orders
WHERE order_approved_at IS NOT NULL
  AND order_approved_at < order_purchase_timestamp

UNION ALL
SELECT 'carrier_before_purchase', COUNT(*)
FROM raw.orders
WHERE order_delivered_carrier_date IS NOT NULL
  AND order_delivered_carrier_date < order_purchase_timestamp

UNION ALL
SELECT 'customer_delivery_before_purchase', COUNT(*)
FROM raw.orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_delivered_customer_date < order_purchase_timestamp

UNION ALL
SELECT 'customer_delivery_before_carrier', COUNT(*)
FROM raw.orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_delivered_carrier_date IS NOT NULL
  AND order_delivered_customer_date < order_delivered_carrier_date;

-- Date checks passed.
-- The latest estimated delivery date is 2026-01-20.