CREATE INDEX IF NOT EXISTS idx_raw_customers_customer_id
ON raw.customers(customer_id);

CREATE INDEX IF NOT EXISTS idx_raw_customers_customer_unique_id
ON raw.customers(customer_unique_id);

CREATE INDEX IF NOT EXISTS idx_raw_orders_order_id
ON raw.orders(order_id);

CREATE INDEX IF NOT EXISTS idx_raw_orders_customer_id
ON raw.orders(customer_id);

CREATE INDEX IF NOT EXISTS idx_raw_order_items_order_id
ON raw.order_items(order_id);

CREATE INDEX IF NOT EXISTS idx_raw_order_items_product_id
ON raw.order_items(product_id);

CREATE INDEX IF NOT EXISTS idx_raw_order_items_seller_id
ON raw.order_items(seller_id);

CREATE INDEX IF NOT EXISTS idx_raw_order_payments_order_id
ON raw.order_payments(order_id);

CREATE INDEX IF NOT EXISTS idx_raw_order_reviews_order_id
ON raw.order_reviews(order_id);

CREATE INDEX IF NOT EXISTS idx_raw_products_product_id
ON raw.products(product_id);

CREATE INDEX IF NOT EXISTS idx_raw_sellers_seller_id
ON raw.sellers(seller_id);

CREATE INDEX IF NOT EXISTS idx_raw_geolocation_zip_code_prefix
ON raw.geolocation(zip_code_prefix);