/*
===============================================================================
Olist E-commerce Data Quality Checks
Database: olist_ecommerce
Purpose : Validate imported table sizes, table grain, key relationships, and
          critical fields before business analysis.
Author  : Charlie Wang
===============================================================================

Important notes:
- This is a read-only audit. The queries below do not modify source data.
- Not every table should have one row per order_id. Order items, payments, and
  reviews have their own table grain and therefore require composite keys.
- Empty strings are checked separately from NULL values where relevant.
===============================================================================
*/

USE olist_ecommerce;

-- 1. IMPORTED TABLE ROW COUNTS
-- Confirms that all nine source CSV files were loaded completely.
SELECT 'customers' AS table_name, COUNT(*) AS row_count
FROM olist_customers_dataset
UNION ALL
SELECT 'geolocation', COUNT(*)
FROM olist_geolocation_dataset
UNION ALL
SELECT 'order_items', COUNT(*)
FROM olist_order_items_dataset
UNION ALL
SELECT 'order_payments', COUNT(*)
FROM olist_order_payments_dataset
UNION ALL
SELECT 'order_reviews', COUNT(*)
FROM olist_order_reviews_dataset
UNION ALL
SELECT 'orders', COUNT(*)
FROM olist_orders_dataset
UNION ALL
SELECT 'products', COUNT(*)
FROM olist_products_dataset
UNION ALL
SELECT 'sellers', COUNT(*)
FROM olist_sellers_dataset
UNION ALL
SELECT 'category_translation', COUNT(*)
FROM product_category_name_translation;

-- 2. ORDER ID UNIQUENESS
-- Observed: 99,441 rows and 0 duplicate order IDs.
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_order_ids,
    COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_order_rows
FROM olist_orders_dataset;

-- 3. CUSTOMER ID UNIQUENESS
-- customer_id identifies a customer record; customer_unique_id is used later
-- to identify the same shopper across multiple orders.
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customer_ids,
    COUNT(*) - COUNT(DISTINCT customer_id) AS duplicate_customer_ids
FROM olist_customers_dataset;

-- 4. PRODUCT ID UNIQUENESS
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT product_id) AS unique_product_ids,
    COUNT(*) - COUNT(DISTINCT product_id) AS duplicate_product_ids
FROM olist_products_dataset;

-- 5. SELLER ID UNIQUENESS
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT seller_id) AS unique_seller_ids,
    COUNT(*) - COUNT(DISTINCT seller_id) AS duplicate_seller_ids
FROM olist_sellers_dataset;

-- 6. ORDER-ITEM COMPOSITE KEY
-- One order can contain multiple items. The combination of order_id and
-- order_item_id should identify one order-item row.
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id, order_item_id) AS unique_order_items,
    COUNT(*) - COUNT(DISTINCT order_id, order_item_id)
        AS duplicate_order_items
FROM olist_order_items_dataset;

-- 7. PAYMENT COMPOSITE KEY
-- One order can have multiple payment records. The combination of order_id and
-- payment_sequential should identify one payment row.
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id, payment_sequential) AS unique_payment_records,
    COUNT(*) - COUNT(DISTINCT order_id, payment_sequential)
        AS duplicate_payment_records
FROM olist_order_payments_dataset;

-- 8. REVIEW TABLE GRAIN
-- review_id and order_id are not unique separately.
SELECT
    COUNT(*) AS total_review_rows,
    COUNT(DISTINCT review_id) AS unique_review_ids,
    COUNT(DISTINCT order_id) AS reviewed_orders
FROM olist_order_reviews_dataset;

-- The review_id and order_id combination uniquely identifies each review row.
SELECT
    COUNT(*) AS total_review_rows,
    COUNT(DISTINCT review_id, order_id) AS unique_review_order_pairs,
    COUNT(*) - COUNT(DISTINCT review_id, order_id)
        AS duplicate_review_order_pairs
FROM olist_order_reviews_dataset;

-- 9. ORDER STATUS DISTRIBUTION
SELECT
    order_status,
    COUNT(order_id) AS order_count
FROM olist_orders_dataset
GROUP BY order_status
ORDER BY order_count DESC;

-- 10. ORDER-DATE COVERAGE
-- Observed range: 2016-09-04 to 2018-10-17. The first and last calendar months
-- are partial and should not be compared directly with complete months.
SELECT
    MIN(order_purchase_timestamp) AS first_order_date,
    MAX(order_purchase_timestamp) AS last_order_date
FROM olist_orders_dataset;

-- 11. MISSING CRITICAL ORDER FIELDS
SELECT
    COUNT(*) - COUNT(customer_id) AS missing_customer_id,
    COUNT(*) - COUNT(order_status) AS missing_order_status,
    COUNT(*) - COUNT(order_purchase_timestamp) AS missing_purchase_date
FROM olist_orders_dataset;

-- 12. ORDER-ITEM MONETARY FIELDS
-- Observed: no missing or negative prices/freight values. Zero freight may
-- represent free shipping.
SELECT
    COUNT(*) - COUNT(price) AS missing_price,
    MIN(price) AS minimum_price,
    MAX(price) AS maximum_price,
    COUNT(*) - COUNT(freight_value) AS missing_freight_value,
    MIN(freight_value) AS minimum_freight_value,
    MAX(freight_value) AS maximum_freight_value
FROM olist_order_items_dataset;

-- 13. PAYMENT VALUE AND INSTALLMENT RANGE
SELECT
    COUNT(*) - COUNT(payment_value) AS missing_payment_value,
    MIN(payment_value) AS minimum_payment_value,
    MAX(payment_value) AS maximum_payment_value,
    COUNT(*) - COUNT(payment_installments) AS missing_installments,
    MIN(payment_installments) AS minimum_installments,
    MAX(payment_installments) AS maximum_installments
FROM olist_order_payments_dataset;

-- Inspect zero-value payments and zero-installment records.
-- Observed: 9 zero-value payments and 2 positive credit-card payments with
-- zero installments. Raw values are retained and documented rather than
-- changed without supporting evidence.
SELECT
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
FROM olist_order_payments_dataset
WHERE payment_value = 0
   OR payment_installments = 0
ORDER BY payment_value, payment_installments;

-- 14. PRODUCT CATEGORY COMPLETENESS
-- NULLIF converts blank category strings to NULL for this calculation only.
-- Observed: 610 of 32,951 products have no category name.
SELECT
    COUNT(*) AS total_products,
    COUNT(NULLIF(TRIM(product_category_name), ''))
        AS categorized_products,
    COUNT(*) - COUNT(NULLIF(TRIM(product_category_name), ''))
        AS missing_product_category
FROM olist_products_dataset;

-- 15. CATEGORY-TRANSLATION KEY UNIQUENESS
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT product_category_name) AS unique_category_names,
    COUNT(*) - COUNT(DISTINCT product_category_name)
        AS duplicate_category_names
FROM product_category_name_translation;

-- 16. REVIEW-SCORE COMPLETENESS AND RANGE
SELECT
    COUNT(*) - COUNT(review_score) AS missing_review_score,
    MIN(review_score) AS minimum_review_score,
    MAX(review_score) AS maximum_review_score
FROM olist_order_reviews_dataset;

-- 17. PRODUCT CATEGORIES WITHOUT ENGLISH TRANSLATION
-- Observed: 13 product rows across 2 category names lack a translation.
SELECT
    COUNT(*) AS product_rows_without_translation,
    COUNT(DISTINCT p.product_category_name)
        AS category_names_without_translation
FROM olist_products_dataset AS p
LEFT JOIN product_category_name_translation AS t
    ON p.product_category_name = t.product_category_name
WHERE NULLIF(TRIM(p.product_category_name), '') IS NOT NULL
  AND t.product_category_name IS NULL;

SELECT DISTINCT
    p.product_category_name AS untranslated_category
FROM olist_products_dataset AS p
LEFT JOIN product_category_name_translation AS t
    ON p.product_category_name = t.product_category_name
WHERE NULLIF(TRIM(p.product_category_name), '') IS NOT NULL
  AND t.product_category_name IS NULL
ORDER BY untranslated_category;

-- 18. ORDERS WITHOUT A MATCHING CUSTOMER
SELECT
    COUNT(*) AS orders_without_matching_customer
FROM olist_orders_dataset AS o
LEFT JOIN olist_customers_dataset AS c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- 19. CHILD ROWS WITHOUT A MATCHING ORDER
SELECT
    'order_items_to_orders' AS relationship_check,
    COUNT(*) AS unmatched_rows
FROM olist_order_items_dataset AS i
LEFT JOIN olist_orders_dataset AS o
    ON i.order_id = o.order_id
WHERE o.order_id IS NULL
UNION ALL
SELECT
    'payments_to_orders',
    COUNT(*)
FROM olist_order_payments_dataset AS p
LEFT JOIN olist_orders_dataset AS o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL
UNION ALL
SELECT
    'reviews_to_orders',
    COUNT(*)
FROM olist_order_reviews_dataset AS r
LEFT JOIN olist_orders_dataset AS o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;

-- 20. ORDER ITEMS WITHOUT A MATCHING PRODUCT OR SELLER
SELECT
    'order_items_to_products' AS relationship_check,
    COUNT(*) AS unmatched_rows
FROM olist_order_items_dataset AS i
LEFT JOIN olist_products_dataset AS p
    ON i.product_id = p.product_id
WHERE p.product_id IS NULL
UNION ALL
SELECT
    'order_items_to_sellers',
    COUNT(*)
FROM olist_order_items_dataset AS i
LEFT JOIN olist_sellers_dataset AS s
    ON i.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

-- 21. ORDERS WITHOUT ITEMS, PAYMENTS, OR REVIEWS
-- Missing child records are not automatically errors; order status and the
-- optional nature of reviews must be considered.
SELECT
    'orders_without_items' AS check_name,
    COUNT(*) AS affected_orders
FROM olist_orders_dataset AS o
LEFT JOIN olist_order_items_dataset AS i
    ON o.order_id = i.order_id
WHERE i.order_id IS NULL
UNION ALL
SELECT
    'orders_without_payments',
    COUNT(*)
FROM olist_orders_dataset AS o
LEFT JOIN olist_order_payments_dataset AS p
    ON o.order_id = p.order_id
WHERE p.order_id IS NULL
UNION ALL
SELECT
    'orders_without_reviews',
    COUNT(*)
FROM olist_orders_dataset AS o
LEFT JOIN olist_order_reviews_dataset AS r
    ON o.order_id = r.order_id
WHERE r.order_id IS NULL;

-- 22. STATUS OF ORDERS WITHOUT ITEM RECORDS
-- Observed: 767 of 775 are unavailable or canceled, and none are delivered.
SELECT
    o.order_status,
    COUNT(*) AS orders_without_items
FROM olist_orders_dataset AS o
LEFT JOIN olist_order_items_dataset AS i
    ON o.order_id = i.order_id
WHERE i.order_id IS NULL
GROUP BY o.order_status
ORDER BY orders_without_items DESC;

-- 23. ORDER WITHOUT A PAYMENT RECORD
-- Observed: one delivered order from 2016-09-15 has no payment record. It is
-- retained in order counts but cannot contribute to payment-based metrics.
SELECT
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp
FROM olist_orders_dataset AS o
LEFT JOIN olist_order_payments_dataset AS p
    ON o.order_id = p.order_id
WHERE p.order_id IS NULL;

-- 24. STATUS OF ORDERS WITHOUT REVIEW RECORDS
-- A missing review is not assigned a score of zero; reviews are optional.
SELECT
    o.order_status,
    COUNT(*) AS orders_without_reviews
FROM olist_orders_dataset AS o
LEFT JOIN olist_order_reviews_dataset AS r
    ON o.order_id = r.order_id
WHERE r.order_id IS NULL
GROUP BY o.order_status
ORDER BY orders_without_reviews DESC;

