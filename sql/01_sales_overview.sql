/*
===============================================================================
E-commerce Sales Overview
Database: synthetic_ecommerce
Purpose : Provide a clear, portfolio-ready overview of sales performance.
Author  : Charlie Wang
===============================================================================

Business questions answered:
1. What is the total revenue?
2. How many orders have been placed?
3. What is the average order value?
4. How have revenue and order volume changed by month?
5. Which customer countries generate the most revenue?
6. Which payment methods generate the most revenue?

Expected columns used in this script:
- orders: order_id, customer_id, order_date, total_amount, payment_method
- customers: customer_id, country

Note:
- Revenue is calculated from orders.total_amount so that order revenue is not
  duplicated by joining to the order_items table.
- The queries include all orders. If the dataset contains cancelled or refunded
  orders, add the appropriate order-status filter after confirming its values.
===============================================================================
*/

USE synthetic_ecommerce;


-- 1. Overall sales KPIs
-- Gives stakeholders a quick summary of business performance.
SELECT
    ROUND(SUM(total_amount), 2) AS total_revenue,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(total_amount) / NULLIF(COUNT(DISTINCT order_id), 0), 2)
        AS average_order_value
FROM orders;


-- 2. Monthly sales trend
-- Shows changes in revenue, order volume, and average order value over time.
SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS sales_month,
    ROUND(SUM(total_amount), 2) AS monthly_revenue,
    COUNT(DISTINCT order_id) AS monthly_orders,
    ROUND(SUM(total_amount) / NULLIF(COUNT(DISTINCT order_id), 0), 2)
        AS monthly_average_order_value
FROM orders
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY sales_month;


-- 3. Sales by customer country
-- Identifies the geographic markets contributing the most revenue.
SELECT
    COALESCE(c.country, 'Unknown') AS country,
    ROUND(SUM(o.total_amount), 2) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(o.total_amount) / NULLIF(COUNT(DISTINCT o.order_id), 0), 2)
        AS average_order_value,
    ROUND(
        100.0 * SUM(o.total_amount)
        / NULLIF(SUM(SUM(o.total_amount)) OVER (), 0),
        2
    ) AS revenue_share_pct
FROM orders AS o
LEFT JOIN customers AS c
    ON o.customer_id = c.customer_id
GROUP BY COALESCE(c.country, 'Unknown')
ORDER BY total_revenue DESC;


-- 4. Sales by payment method
-- Compares customer payment preferences and their revenue contribution.
SELECT
    COALESCE(payment_method, 'Unknown') AS payment_method,
    ROUND(SUM(total_amount), 2) AS total_revenue,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(total_amount) / NULLIF(COUNT(DISTINCT order_id), 0), 2)
        AS average_order_value,
    ROUND(
        100.0 * SUM(total_amount)
        / NULLIF(SUM(SUM(total_amount)) OVER (), 0),
        2
    ) AS revenue_share_pct
FROM orders
GROUP BY COALESCE(payment_method, 'Unknown')
ORDER BY total_revenue DESC;
