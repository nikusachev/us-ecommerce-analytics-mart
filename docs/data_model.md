Core grain rules:

1. orders:
   grain = 1 row per order_id

2. customers:
   grain = 1 row per customer_id
   customer_unique_id is used for retention and repeat purchase analytics

3. order_items:
   grain = 1 row per order item
   must be aggregated to order_id before joining to order-level marts

4. order_payments:
   raw grain = 1 row per payment part
   staging grain = 1 row per order_id

5. order_reviews:
   grain = 1 row per review
   not every order has a review

6. geolocation:
   raw grain = multiple rows per zip_code_prefix
   staging grain = 1 row per zip_code_prefix

Safe order-level joins:
- stg_orders + stg_customers by customer_id
- stg_orders + aggregated order_items by order_id
- stg_orders + stg_order_payments by order_id
- stg_orders + stg_order_reviews by order_id

Unsafe direct joins:
- orders + raw order_items + raw payments
- customers + raw geolocation