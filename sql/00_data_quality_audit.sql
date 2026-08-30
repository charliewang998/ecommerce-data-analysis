/*
===============================================================================
E-commerce Data Quality Audit
Database: synthetic_ecommerce
Purpose : Assess data quality before performing business analysis.
===============================================================================

This script checks:
1. Table sizes
2. Duplicate primary keys
3. Missing values in important fields
4. Broken relationships between tables
5. Invalid numerical values and dates
6. Inconsistent categorical values
7. Differences between order totals and order-item totals
8. Business-rule issues found during the audit

Important:
- Run each numbered query separately in DBeaver (Command + Enter on macOS).
- A result of 0 in an issue-count column usually means that the check passed.
- Do not delete or replace data until the cause and business meaning of an
  issue have been reviewed.
===============================================================================
*/

USE synthetic_ecommerce;


-- 1. TABLE SIZES
-- Establishes the scale of each table and helps detect unexpectedly empty data.
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'product_reviews', COUNT(*) FROM product_reviews;


-- 2. DUPLICATE PRIMARY KEYS
-- Every result should be 0 because each primary key should be unique.
SELECT
    'customers.customer_id' AS field_checked,
    COUNT(*) - COUNT(DISTINCT customer_id) AS duplicate_key_rows
FROM customers
UNION ALL
SELECT
    'orders.order_id',
    COUNT(*) - COUNT(DISTINCT order_id)
FROM orders
UNION ALL
SELECT
    'order_items.order_item_id',
    COUNT(*) - COUNT(DISTINCT order_item_id)
FROM order_items
UNION ALL
SELECT
    'products.product_id',
    COUNT(*) - COUNT(DISTINCT product_id)
FROM products
UNION ALL
SELECT
    'product_reviews.review_id',
    COUNT(*) - COUNT(DISTINCT review_id)
FROM product_reviews;


-- 3. MISSING VALUES: CUSTOMERS
SELECT
    SUM(customer_id IS NULL) AS missing_customer_id,
    SUM(name IS NULL OR TRIM(name) = '') AS missing_name,
    SUM(email IS NULL OR TRIM(email) = '') AS missing_email,
    SUM(signup_date IS NULL) AS missing_signup_date,
    SUM(country IS NULL OR TRIM(country) = '') AS missing_country
FROM customers;


-- 4. MISSING VALUES: ORDERS
SELECT
    SUM(order_id IS NULL) AS missing_order_id,
    SUM(customer_id IS NULL) AS missing_customer_id,
    SUM(order_date IS NULL) AS missing_order_date,
    SUM(total_amount IS NULL) AS missing_total_amount,
    SUM(payment_method IS NULL OR TRIM(payment_method) = '')
        AS missing_payment_method,
    SUM(shipping_country IS NULL OR TRIM(shipping_country) = '')
        AS missing_shipping_country
FROM orders;


-- 5. MISSING VALUES: ORDER ITEMS, PRODUCTS, AND REVIEWS
-- One row is returned per field so that every result is clearly labelled.
SELECT
    'order_items' AS table_name,
    'order_item_id' AS field_name,
    SUM(order_item_id IS NULL) AS missing_count
FROM order_items
UNION ALL
SELECT
    'order_items', 'order_id', SUM(order_id IS NULL)
FROM order_items
UNION ALL
SELECT
    'order_items', 'product_id', SUM(product_id IS NULL)
FROM order_items
UNION ALL
SELECT
    'order_items', 'quantity', SUM(quantity IS NULL)
FROM order_items
UNION ALL
SELECT
    'order_items', 'unit_price', SUM(unit_price IS NULL)
FROM order_items
UNION ALL
SELECT
    'products', 'product_id', SUM(product_id IS NULL)
FROM products
UNION ALL
SELECT
    'products', 'product_name',
    SUM(product_name IS NULL OR TRIM(product_name) = '')
FROM products
UNION ALL
SELECT
    'products', 'category',
    SUM(category IS NULL OR TRIM(category) = '')
FROM products
UNION ALL
SELECT
    'products', 'price', SUM(price IS NULL)
FROM products
UNION ALL
SELECT
    'products', 'stock_quantity', SUM(stock_quantity IS NULL)
FROM products
UNION ALL
SELECT
    'product_reviews', 'review_id', SUM(review_id IS NULL)
FROM product_reviews
UNION ALL
SELECT
    'product_reviews', 'product_id', SUM(product_id IS NULL)
FROM product_reviews
UNION ALL
SELECT
    'product_reviews', 'customer_id', SUM(customer_id IS NULL)
FROM product_reviews
UNION ALL
SELECT
    'product_reviews', 'rating', SUM(rating IS NULL)
FROM product_reviews
UNION ALL
SELECT
    'product_reviews', 'review_text',
    SUM(review_text IS NULL OR TRIM(review_text) = '')
FROM product_reviews
UNION ALL
SELECT
    'product_reviews', 'review_date', SUM(review_date IS NULL)
FROM product_reviews
ORDER BY table_name, field_name;


-- 6. BROKEN FOREIGN-KEY RELATIONSHIPS
-- Detects child records that do not have a matching parent record.
SELECT
    'orders -> customers' AS relationship_checked,
    COUNT(*) AS unmatched_rows
FROM orders AS o
LEFT JOIN customers AS c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL

UNION ALL

SELECT
    'order_items -> orders',
    COUNT(*)
FROM order_items AS oi
LEFT JOIN orders AS o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL

SELECT
    'order_items -> products',
    COUNT(*)
FROM order_items AS oi
LEFT JOIN products AS p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL

UNION ALL

SELECT
    'product_reviews -> products',
    COUNT(*)
FROM product_reviews AS pr
LEFT JOIN products AS p
    ON pr.product_id = p.product_id
WHERE p.product_id IS NULL

UNION ALL

SELECT
    'product_reviews -> customers',
    COUNT(*)
FROM product_reviews AS pr
LEFT JOIN customers AS c
    ON pr.customer_id = c.customer_id
WHERE c.customer_id IS NULL

UNION ALL

-- This reverse-direction check was added after the initial audit.
SELECT
    'orders -> order_items (at least one item)',
    COUNT(*)
FROM orders AS o
LEFT JOIN order_items AS oi
    ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL;


-- 7. INVALID NUMERICAL VALUES
-- Prices and quantities should not be negative; order quantities should be > 0;
-- product ratings should be between 1 and 5.
SELECT
    'orders.total_amount < 0' AS rule_checked,
    COUNT(*) AS invalid_rows
FROM orders
WHERE total_amount < 0
UNION ALL
SELECT
    'order_items.quantity <= 0',
    COUNT(*)
FROM order_items
WHERE quantity <= 0
UNION ALL
SELECT
    'order_items.unit_price < 0',
    COUNT(*)
FROM order_items
WHERE unit_price < 0
UNION ALL
SELECT
    'products.price < 0',
    COUNT(*)
FROM products
WHERE price < 0
UNION ALL
SELECT
    'products.stock_quantity < 0',
    COUNT(*)
FROM products
WHERE stock_quantity < 0
UNION ALL
SELECT
    'product_reviews.rating outside 1-5',
    COUNT(*)
FROM product_reviews
WHERE rating NOT BETWEEN 1 AND 5;


-- 8. DATE VALIDITY
-- Future dates may indicate a problem, depending on when the dataset was built.
SELECT
    'customers.signup_date in future' AS rule_checked,
    COUNT(*) AS suspicious_rows
FROM customers
WHERE signup_date > CURRENT_DATE()
UNION ALL
SELECT
    'orders.order_date in future',
    COUNT(*)
FROM orders
WHERE order_date > CURRENT_DATE()
UNION ALL
SELECT
    'product_reviews.review_date in future',
    COUNT(*)
FROM product_reviews
WHERE review_date > CURRENT_DATE()
UNION ALL
SELECT
    'orders before customer signup',
    COUNT(*)
FROM orders AS o
INNER JOIN customers AS c
    ON o.customer_id = c.customer_id
WHERE o.order_date < c.signup_date;


-- 9. ORDERS BEFORE CUSTOMER SIGNUP: IMPACT AND SAMPLE
-- Quantifies the issue as a percentage of matched orders.
SELECT
    COUNT(*) AS total_orders_checked,
    SUM(o.order_date < c.signup_date) AS orders_before_signup,
    ROUND(
        100.0 * SUM(o.order_date < c.signup_date) / NULLIF(COUNT(*), 0),
        2
    ) AS percentage_before_signup
FROM orders AS o
INNER JOIN customers AS c
    ON o.customer_id = c.customer_id;

-- Shows examples for manual verification. Run separately from the query above.
SELECT
    o.order_id,
    o.customer_id,
    c.signup_date,
    o.order_date,
    DATEDIFF(o.order_date, c.signup_date) AS days_after_signup
FROM orders AS o
INNER JOIN customers AS c
    ON o.customer_id = c.customer_id
WHERE o.order_date < c.signup_date
ORDER BY days_after_signup
LIMIT 20;


-- 10. CATEGORY CONSISTENCY
-- BINARY makes grouping case-sensitive, helping expose hidden capitalization
-- differences. HEX helps reveal invisible spaces. Run each SELECT separately.
SELECT
    payment_method,
    HEX(payment_method) AS text_bytes,
    COUNT(*) AS order_count
FROM orders
GROUP BY BINARY payment_method, HEX(payment_method)
ORDER BY payment_method;

SELECT
    shipping_country,
    HEX(shipping_country) AS text_bytes,
    COUNT(*) AS order_count
FROM orders
GROUP BY BINARY shipping_country, HEX(shipping_country)
ORDER BY shipping_country;

SELECT
    category,
    HEX(category) AS text_bytes,
    COUNT(*) AS product_count
FROM products
GROUP BY BINARY category, HEX(category)
ORDER BY category;


-- 11. ORDER-TOTAL RECONCILIATION
-- Compares orders.total_amount with quantity * unit_price from order_items.
-- Small differences may be caused by rounding. Large or widespread differences
-- may mean that discounts, taxes, or shipping fees are included in total_amount.
WITH item_totals AS (
    SELECT
        order_id,
        SUM(quantity * unit_price) AS calculated_item_total
    FROM order_items
    GROUP BY order_id
)
SELECT
    COUNT(*) AS orders_compared,
    SUM(ABS(o.total_amount - it.calculated_item_total) > 0.01)
        AS mismatched_orders,
    ROUND(AVG(ABS(o.total_amount - it.calculated_item_total)), 2)
        AS average_absolute_difference,
    ROUND(MAX(ABS(o.total_amount - it.calculated_item_total)), 2)
        AS maximum_absolute_difference
FROM orders AS o
INNER JOIN item_totals AS it
    ON o.order_id = it.order_id;


-- 12. SAMPLE OF MISMATCHED ORDERS
-- Run this only if the previous check reports mismatches.
WITH item_totals AS (
    SELECT
        order_id,
        SUM(quantity * unit_price) AS calculated_item_total
    FROM order_items
    GROUP BY order_id
)
SELECT
    o.order_id,
    ROUND(o.total_amount, 2) AS recorded_order_total,
    ROUND(it.calculated_item_total, 2) AS calculated_item_total,
    ROUND(o.total_amount - it.calculated_item_total, 2) AS difference
FROM orders AS o
INNER JOIN item_totals AS it
    ON o.order_id = it.order_id
WHERE ABS(o.total_amount - it.calculated_item_total) > 0.01
ORDER BY ABS(o.total_amount - it.calculated_item_total) DESC
LIMIT 20;
