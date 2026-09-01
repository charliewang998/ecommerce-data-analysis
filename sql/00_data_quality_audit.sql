/*
===============================================================================
E-commerce Data Quality Audit
Database: synthetic_ecommerce
Purpose : Validate data quality and define reliable analysis rules before
          producing sales, customer, and product insights.
===============================================================================

Audit scope:
1. Table sizes
2. Primary-key uniqueness
3. Missing and blank values
4. Referential integrity and relationship completeness
5. Numerical and date validity
6. Categorical consistency and ambiguous geographic labels
7. Reconciliation of recorded order totals with order-item totals

Observed findings from the completed audit:
- No duplicate primary keys were found.
- No missing values were found in the audited key fields.
- No invalid negative values or out-of-range ratings were found.
- 3,196,732 orders (39.96%) occurred before customer signup.
- 655,925 orders (8.20%) had no corresponding order-item records.
- All 7,344,075 orders with item records passed the amount reconciliation.
- Congo and Korea each contained about twice the typical customer count,
  suggesting ambiguous geographic labels in the synthetic source data.

Analysis rules:
- Preserve the original source tables; do not overwrite uncertain values.
- Retain all orders for general order-level sales reporting.
- Exclude orders before signup from customer-lifecycle analyses.
- Exclude orders without items from product, category, and basket analyses.
- Do not interpret Congo or Korea as proven top-performing markets because the
  available country labels cannot distinguish the underlying entities.

Execution note:
- Run each SELECT statement separately in DBeaver (Command + Enter on macOS).
===============================================================================
*/

USE synthetic_ecommerce;

-- 1. TABLE SIZES
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
-- A result of 0 means that the tested primary key is unique.
SELECT 'customers.customer_id' AS field_checked,
       COUNT(*) - COUNT(DISTINCT customer_id) AS duplicate_key_rows
FROM customers
UNION ALL
SELECT 'orders.order_id', COUNT(*) - COUNT(DISTINCT order_id) FROM orders
UNION ALL
SELECT 'order_items.order_item_id', COUNT(*) - COUNT(DISTINCT order_item_id)
FROM order_items
UNION ALL
SELECT 'products.product_id', COUNT(*) - COUNT(DISTINCT product_id)
FROM products
UNION ALL
SELECT 'product_reviews.review_id', COUNT(*) - COUNT(DISTINCT review_id)
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

-- 5A. MISSING VALUES: ORDER ITEMS
SELECT
    SUM(order_item_id IS NULL) AS missing_order_item_id,
    SUM(order_id IS NULL) AS missing_order_id,
    SUM(product_id IS NULL) AS missing_product_id,
    SUM(quantity IS NULL) AS missing_quantity,
    SUM(unit_price IS NULL) AS missing_unit_price
FROM order_items;

-- 5B. MISSING VALUES: PRODUCTS
SELECT
    SUM(product_id IS NULL) AS missing_product_id,
    SUM(product_name IS NULL OR TRIM(product_name) = '')
        AS missing_product_name,
    SUM(category IS NULL OR TRIM(category) = '') AS missing_category,
    SUM(price IS NULL) AS missing_price,
    SUM(stock_quantity IS NULL) AS missing_stock_quantity,
    SUM(brand IS NULL OR TRIM(brand) = '') AS missing_brand
FROM products;

-- 5C. MISSING VALUES: PRODUCT REVIEWS
SELECT
    SUM(review_id IS NULL) AS missing_review_id,
    SUM(product_id IS NULL) AS missing_product_id,
    SUM(customer_id IS NULL) AS missing_customer_id,
    SUM(rating IS NULL) AS missing_rating,
    SUM(review_text IS NULL OR TRIM(review_text) = '') AS missing_review_text,
    SUM(review_date IS NULL) AS missing_review_date
FROM product_reviews;

-- 6. RELATIONSHIP INTEGRITY AND COMPLETENESS
-- The final check validates the reverse rule that every order has an item.
SELECT 'orders -> customers' AS relationship_checked,
       COUNT(*) AS unmatched_rows
FROM orders AS o
LEFT JOIN customers AS c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL
UNION ALL
SELECT 'order_items -> orders', COUNT(*)
FROM order_items AS oi
LEFT JOIN orders AS o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL
UNION ALL
SELECT 'order_items -> products', COUNT(*)
FROM order_items AS oi
LEFT JOIN products AS p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL
UNION ALL
SELECT 'product_reviews -> products', COUNT(*)
FROM product_reviews AS pr
LEFT JOIN products AS p ON pr.product_id = p.product_id
WHERE p.product_id IS NULL
UNION ALL
SELECT 'product_reviews -> customers', COUNT(*)
FROM product_reviews AS pr
LEFT JOIN customers AS c ON pr.customer_id = c.customer_id
WHERE c.customer_id IS NULL
UNION ALL
SELECT 'orders -> order_items (at least one item)', COUNT(*)
FROM orders AS o
LEFT JOIN order_items AS oi ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL;

-- 7. INVALID NUMERICAL VALUES
SELECT 'orders.total_amount < 0' AS rule_checked, COUNT(*) AS invalid_rows
FROM orders WHERE total_amount < 0
UNION ALL
SELECT 'order_items.quantity <= 0', COUNT(*)
FROM order_items WHERE quantity <= 0
UNION ALL
SELECT 'order_items.unit_price < 0', COUNT(*)
FROM order_items WHERE unit_price < 0
UNION ALL
SELECT 'products.price < 0', COUNT(*)
FROM products WHERE price < 0
UNION ALL
SELECT 'products.stock_quantity < 0', COUNT(*)
FROM products WHERE stock_quantity < 0
UNION ALL
SELECT 'product_reviews.rating outside 1-5', COUNT(*)
FROM product_reviews WHERE rating NOT BETWEEN 1 AND 5;

-- 8. DATE VALIDITY
SELECT 'customers.signup_date in future' AS rule_checked,
       COUNT(*) AS suspicious_rows
FROM customers WHERE signup_date > CURRENT_DATE()
UNION ALL
SELECT 'orders.order_date in future', COUNT(*)
FROM orders WHERE order_date > CURRENT_DATE()
UNION ALL
SELECT 'product_reviews.review_date in future', COUNT(*)
FROM product_reviews WHERE review_date > CURRENT_DATE()
UNION ALL
SELECT 'orders before customer signup', COUNT(*)
FROM orders AS o
INNER JOIN customers AS c ON o.customer_id = c.customer_id
WHERE o.order_date < c.signup_date;

-- 9A. IMPACT OF ORDERS BEFORE CUSTOMER SIGNUP
SELECT
    COUNT(*) AS total_orders_checked,
    SUM(o.order_date < c.signup_date) AS orders_before_signup,
    ROUND(100.0 * SUM(o.order_date < c.signup_date)
          / NULLIF(COUNT(*), 0), 2) AS percentage_before_signup
FROM orders AS o
INNER JOIN customers AS c ON o.customer_id = c.customer_id;

-- 9B. SAMPLE FOR MANUAL DATE VERIFICATION
SELECT
    o.order_id,
    o.customer_id,
    c.signup_date,
    o.order_date,
    DATEDIFF(o.order_date, c.signup_date) AS days_after_signup
FROM orders AS o
INNER JOIN customers AS c ON o.customer_id = c.customer_id
WHERE o.order_date < c.signup_date
ORDER BY days_after_signup
LIMIT 20;

-- 10. STRICT CATEGORY CONSISTENCY
-- BINARY is case-sensitive; HEX exposes invisible characters.
-- Run these three statements separately.
SELECT payment_method, HEX(payment_method) AS text_bytes,
       COUNT(*) AS order_count
FROM orders
GROUP BY BINARY payment_method, HEX(payment_method)
ORDER BY payment_method;

SELECT shipping_country, HEX(shipping_country) AS text_bytes,
       COUNT(*) AS order_count
FROM orders
GROUP BY BINARY shipping_country, HEX(shipping_country)
ORDER BY shipping_country;

SELECT category, HEX(category) AS text_bytes, COUNT(*) AS product_count
FROM products
GROUP BY BINARY category, HEX(category)
ORDER BY category;

-- 11. CUSTOMER COUNTRY-LABEL DISTRIBUTION
-- Congo and Korea returned about twice the typical customer count.
SELECT country, COUNT(*) AS customer_count
FROM customers
GROUP BY country
ORDER BY customer_count DESC
LIMIT 10;

-- 12. ORDER-TOTAL RECONCILIATION
-- Only orders with item records can be recalculated and compared.
WITH item_totals AS (
    SELECT order_id, SUM(quantity * unit_price) AS calculated_item_total
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
INNER JOIN item_totals AS it ON o.order_id = it.order_id;

-- 13. SAMPLE OF MISMATCHED ORDERS
-- Correctly returns zero rows when no difference exceeds 0.01.
WITH item_totals AS (
    SELECT order_id, SUM(quantity * unit_price) AS calculated_item_total
    FROM order_items
    GROUP BY order_id
)
SELECT
    o.order_id,
    ROUND(o.total_amount, 2) AS recorded_order_total,
    ROUND(it.calculated_item_total, 2) AS calculated_item_total,
    ROUND(o.total_amount - it.calculated_item_total, 2) AS difference
FROM orders AS o
INNER JOIN item_totals AS it ON o.order_id = it.order_id
WHERE ABS(o.total_amount - it.calculated_item_total) > 0.01
ORDER BY ABS(o.total_amount - it.calculated_item_total) DESC
LIMIT 20;
