/*
===============================================================================
Olist E-commerce Customer Analysis
Database: olist_ecommerce
Purpose : Measure the completed-purchase customer base, repeat purchasing,
          geographic concentration, and recorded customer payment value.
Author  : Charlie Wang
===============================================================================

Metric definitions and scope:
- A customer is identified by customer_unique_id, not customer_id.
- A completed purchase is an order with order_status = 'delivered'.
- A repeat customer has more than one delivered order.
- Payment-based customer metrics exclude the one delivered order that has no
  payment record.
- Recorded payment value is not described as net revenue because refund data
  is unavailable.
===============================================================================
*/

USE olist_ecommerce;

-- 1. CUSTOMER TABLE GRAIN
-- customer_id identifies an order-level customer record. customer_unique_id
-- identifies the same shopper across different orders.
-- Observed: 99,441 customer records and 96,096 unique customers.
SELECT
    COUNT(*) AS customer_records,
    COUNT(DISTINCT customer_id) AS unique_customer_ids,
    COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM olist_customers_dataset;

-- 2. CUSTOMERS WITH DELIVERED ORDERS
-- Observed: 93,358 customers completed 96,478 delivered orders.
SELECT
    COUNT(DISTINCT c.customer_unique_id)
        AS customers_with_delivered_orders,
    COUNT(DISTINCT o.order_id) AS delivered_orders
FROM olist_orders_dataset AS o
INNER JOIN olist_customers_dataset AS c
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered';

-- 3. CUSTOMERS WITH THE MOST DELIVERED ORDERS
-- Order frequency alone does not measure customer payment value.
SELECT
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id) AS delivered_orders
FROM olist_orders_dataset AS o
INNER JOIN olist_customers_dataset AS c
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id
ORDER BY delivered_orders DESC, c.customer_unique_id
LIMIT 20;

-- 4. DELIVERED-ORDER FREQUENCY DISTRIBUTION
WITH customer_order_counts AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS delivered_orders
    FROM olist_orders_dataset AS o
    INNER JOIN olist_customers_dataset AS c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)

SELECT
    delivered_orders,
    COUNT(*) AS customer_count
FROM customer_order_counts
GROUP BY delivered_orders
ORDER BY delivered_orders;

-- 5. REPEAT-CUSTOMER KPIs
-- Observed: 90,557 one-time customers, 2,801 repeat customers, and a repeat
-- customer rate of 3.00% among customers with delivered orders.
WITH customer_order_counts AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS delivered_orders
    FROM olist_orders_dataset AS o
    INNER JOIN olist_customers_dataset AS c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)

SELECT
    COUNT(*) AS purchasing_customers,
    SUM(
        CASE
            WHEN delivered_orders = 1 THEN 1
            ELSE 0
        END
    ) AS one_time_customers,
    SUM(
        CASE
            WHEN delivered_orders > 1 THEN 1
            ELSE 0
        END
    ) AS repeat_customers,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN delivered_orders > 1 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS repeat_customer_rate_pct,
    ROUND(AVG(delivered_orders), 2)
        AS average_delivered_orders_per_customer
FROM customer_order_counts;

-- 6. COMPLETED-ORDER PERFORMANCE BY CUSTOMER STATE
-- A customer who uses addresses in different states can be counted once in
-- each state, so state-level unique-customer counts should not be added.
SELECT
    c.customer_state,
    COUNT(DISTINCT c.customer_unique_id) AS unique_customers,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    COUNT(DISTINCT p.order_id) AS paid_delivered_orders,
    ROUND(SUM(p.payment_value), 2) AS payment_value,
    ROUND(
        SUM(p.payment_value) / COUNT(DISTINCT p.order_id),
        2
    ) AS average_payment_per_paid_order
FROM olist_orders_dataset AS o
INNER JOIN olist_customers_dataset AS c
    ON o.customer_id = c.customer_id
LEFT JOIN olist_order_payments_dataset AS p
    ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY payment_value DESC;

-- 7. CUSTOMERS WITH THE HIGHEST RECORDED PAYMENT VALUE
-- Most customers in the top 20 generated their value from one high-value
-- order rather than frequent repeat purchasing.
SELECT
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id) AS paid_delivered_orders,
    ROUND(SUM(p.payment_value), 2) AS total_payment_value,
    ROUND(
        SUM(p.payment_value) / COUNT(DISTINCT o.order_id),
        2
    ) AS average_payment_per_order
FROM olist_orders_dataset AS o
INNER JOIN olist_customers_dataset AS c
    ON o.customer_id = c.customer_id
INNER JOIN olist_order_payments_dataset AS p
    ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id
ORDER BY total_payment_value DESC
LIMIT 20;

-- 8. ONE-TIME VERSUS REPEAT CUSTOMER VALUE
-- Observed: repeat customers have higher cumulative payment value per customer
-- but lower average payment value per order than one-time customers.
WITH customer_value AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS delivered_orders,
        SUM(p.payment_value) AS total_payment_value
    FROM olist_orders_dataset AS o
    INNER JOIN olist_customers_dataset AS c
        ON o.customer_id = c.customer_id
    INNER JOIN olist_order_payments_dataset AS p
        ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)

SELECT
    CASE
        WHEN delivered_orders = 1 THEN 'One-time customer'
        ELSE 'Repeat customer'
    END AS customer_segment,
    COUNT(*) AS customers_with_payment,
    SUM(delivered_orders) AS delivered_orders,
    ROUND(SUM(total_payment_value), 2) AS payment_value,
    ROUND(AVG(total_payment_value), 2)
        AS average_payment_per_customer,
    ROUND(
        SUM(total_payment_value) / SUM(delivered_orders),
        2
    ) AS average_payment_per_order
FROM customer_value
GROUP BY customer_segment
ORDER BY payment_value DESC;

