DROP TABLE IF EXISTS raw.customers;
DROP TABLE IF EXISTS raw.geolocation;
DROP TABLE IF EXISTS raw.orders;
DROP TABLE IF EXISTS raw.order_items;
DROP TABLE IF EXISTS raw.order_payments;
DROP TABLE IF EXISTS raw.order_reviews;
DROP TABLE IF EXISTS raw.products;
DROP TABLE IF EXISTS raw.sellers;

CREATE TABLE raw.customers (
    customer_id TEXT,
    customer_unique_id TEXT,
    customer_name TEXT,
    customer_gender TEXT,
    customer_age INTEGER,
    customer_zip_code_prefix TEXT,
    customer_city TEXT,
    customer_state TEXT,
    customer_segment TEXT
);

CREATE TABLE raw.geolocation (
    zip_code_prefix TEXT,
    geolocation_lat NUMERIC(12, 8),
    geolocation_lng NUMERIC(12, 8),
    geolocation_city TEXT,
    geolocation_state TEXT
);

CREATE TABLE raw.orders (
    order_id TEXT,
    customer_id TEXT,
    order_status TEXT,
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

CREATE TABLE raw.order_items (
    order_id TEXT,
    order_item_id INTEGER,
    product_id TEXT,
    seller_id TEXT,
    shipping_limit_date TIMESTAMP,
    price NUMERIC(12, 2),
    freight_value NUMERIC(12, 2),
    discount_rate NUMERIC(8, 4)
);

CREATE TABLE raw.order_payments (
    order_id TEXT,
    payment_sequential INTEGER,
    payment_type TEXT,
    payment_installments INTEGER,
    payment_value NUMERIC(12, 2)
);

CREATE TABLE raw.order_reviews (
    review_id TEXT,
    order_id TEXT,
    review_score INTEGER,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);

CREATE TABLE raw.products (
    product_id TEXT,
    product_category_name TEXT,
    product_name TEXT,
    product_brand TEXT,
    product_weight_g NUMERIC(12, 2),
    product_length_cm NUMERIC(12, 2),
    product_height_cm NUMERIC(12, 2),
    product_width_cm NUMERIC(12, 2),
    cost NUMERIC(12, 2),
    price NUMERIC(12, 2)
);

CREATE TABLE raw.sellers (
    seller_id TEXT,
    seller_company_name TEXT,
    seller_contact_name TEXT,
    seller_contact_gender TEXT,
    seller_contact_age INTEGER,
    seller_zip_code_prefix TEXT,
    seller_city TEXT,
    seller_state TEXT
);