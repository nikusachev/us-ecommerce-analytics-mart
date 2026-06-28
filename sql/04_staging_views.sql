-- ============================================================
-- 04_staging_views.sql
-- Project: U.S. E-Commerce Analytics Mart
-- Purpose: Prepare cleaned staging views for analytics marts
-- ============================================================


-- ============================================================
-- 1. Orders staging view
-- Grain: 1 row = 1 order
-- Source: raw.orders
-- ============================================================

CREATE OR REPLACE VIEW stg.stg_orders AS
SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_purchase_timestamp::date AS purchase_date,
    DATE_TRUNC('month', order_purchase_timestamp)::date AS purchase_month,
    CASE
        WHEN order_status = 'delivered' THEN 1
        ELSE 0
    END AS is_delivered,
    CASE
        WHEN order_status = 'canceled' THEN 1
        ELSE 0
    END AS is_canceled
FROM raw.orders;


-- ============================================================
-- 2. Customers staging view
-- Grain: 1 row = 1 customer_id
-- Source: raw.customers
-- ============================================================

CREATE OR REPLACE VIEW stg.stg_customers AS
SELECT
    customer_id,
    customer_unique_id,
    customer_name,
    customer_gender,
    customer_age,
    CASE
        WHEN customer_age < 18 THEN 'under_18'
        WHEN customer_age BETWEEN 18 AND 24 THEN '18_24'
        WHEN customer_age BETWEEN 25 AND 34 THEN '25_34'
        WHEN customer_age BETWEEN 35 AND 44 THEN '35_44'
        WHEN customer_age BETWEEN 45 AND 54 THEN '45_54'
        WHEN customer_age >= 55 THEN '55_plus'
        ELSE 'unknown'
    END AS customer_age_group,
    customer_zip_code_prefix,
    customer_city,
    customer_state,
    customer_segment
FROM raw.customers;


-- ============================================================
-- 3. Order items staging view
-- Grain: 1 row = 1 order item
-- Source: raw.order_items
-- ============================================================

CREATE OR REPLACE VIEW stg.stg_order_items AS
SELECT
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value,
    discount_rate,
    ROUND(price * discount_rate, 2) AS discount_amount,
    ROUND(price * (1 - discount_rate), 2) AS net_item_revenue
FROM raw.order_items;


-- ============================================================
-- 4. Products staging view
-- Grain: 1 row = 1 product_id
-- Source: raw.products
-- ============================================================

CREATE OR REPLACE VIEW stg.stg_products AS
SELECT
    product_id,
    product_category_name,
    product_name,
    product_brand,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm,
    cost,
    price,
    ROUND(product_weight_g / 1000.0, 2) AS product_weight_kg,
    ROUND(product_length_cm * product_height_cm * product_width_cm, 2) AS product_volume_cm3
FROM raw.products;


-- ============================================================
-- 5. Sellers staging view
-- Grain: 1 row = 1 seller_id
-- Source: raw.sellers
-- ============================================================

CREATE OR REPLACE VIEW stg.stg_sellers AS
SELECT 
    seller_id,
    seller_company_name,
    seller_contact_name,
    seller_contact_gender,
    seller_contact_age,
    CASE
        WHEN seller_contact_age < 18 THEN 'under_18'
        WHEN seller_contact_age BETWEEN 18 AND 24 THEN '18_24'
        WHEN seller_contact_age BETWEEN 25 AND 34 THEN '25_34'
        WHEN seller_contact_age BETWEEN 35 AND 44 THEN '35_44'
        WHEN seller_contact_age BETWEEN 45 AND 54 THEN '45_54'
        WHEN seller_contact_age >= 55 THEN '55_plus'
        ELSE 'unknown'
    END AS seller_age_group,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM raw.sellers;


-- ============================================================
-- 6. Order payments staging view
-- Grain: 1 row = 1 order_id
-- Source: raw.order_payments
-- Note: payments are aggregated to order level to avoid row multiplication
-- ============================================================

CREATE OR REPLACE VIEW stg.stg_order_payments AS
SELECT
    order_id,
    COUNT(*) AS payment_parts_count,
    ROUND(SUM(payment_value), 2) AS total_payment_value,
    MAX(payment_installments) AS max_payment_installments
FROM raw.order_payments
GROUP BY order_id;


-- ============================================================
-- 7. Order reviews staging view
-- Grain: 1 row = 1 review_id / 1 reviewed order
-- Source: raw.order_reviews
-- Note: not every order has a review
-- ============================================================

CREATE OR REPLACE VIEW stg.stg_order_reviews AS
SELECT 
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp,
    CASE 
        WHEN review_comment_message IS NOT NULL 
         AND TRIM(review_comment_message) <> '' THEN 1
        ELSE 0
    END AS has_review_comment,
    ROUND(
        EXTRACT(EPOCH FROM (review_answer_timestamp - review_creation_date)) / 86400.0, 
        2
    ) AS review_answer_days
FROM raw.order_reviews;


-- ============================================================
-- 8. Geolocation staging view
-- Grain: 1 row = 1 zip_code_prefix
-- Source: raw.geolocation
-- Note: raw geolocation contains multiple rows per zip_code_prefix,
-- so it is aggregated before joining to customers or sellers
-- ============================================================

CREATE OR REPLACE VIEW stg.stg_geolocation AS
SELECT
    zip_code_prefix,
    ROUND(AVG(geolocation_lat), 8) AS avg_lat,
    ROUND(AVG(geolocation_lng), 8) AS avg_lng,
    MIN(geolocation_city) AS geolocation_city,
    MIN(geolocation_state) AS geolocation_state
FROM raw.geolocation
GROUP BY zip_code_prefix;