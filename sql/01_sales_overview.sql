/*
===============================================================================
E-commerce Sales Overview
Database: synthetic_ecommerce
Purpose : Establish baseline sales KPIs and describe revenue patterns for an
          e-commerce operations audience.
Author  : Charlie Wang
===============================================================================

Business questions:
1. What are total revenue, total orders, and average order value?
2. What period does the order data cover?
3. How do revenue, order volume, and order value change by month?
4. How is revenue distributed across customer countries?
5. How is revenue distributed across payment methods?

Metric definitions:
- Revenue = SUM(orders.total_amount)
- Total orders = COUNT(DISTINCT orders.order_id)
- Average order value = revenue / total orders
- Revenue share = group revenue / total revenue

Scope and limitations:
- Monetary fields have no specified currency, so no currency symbol is used.
- The dataset has no order-status field; cancellations and refunds cannot be
  identified or excluded.
- Order-level queries use all 8,000,000 orders, including 655,925 orders that
  have no item records, because orders.total_amount remains available.
- Product-level analyses must exclude orders without item records.
- Monthly values should be interpreted alongside observed days because the
  first calendar month is incomplete and month lengths differ.
- Country means customer residence, not order shipping destination.
- Congo and Korea have potentially ambiguous labels and should not be presented
  as proven top-performing markets.
- The synthetic data is highly uniform, limiting real-world conclusions.

Execution note:
- Run each SELECT statement separately in DBeaver (Command + Enter on macOS).
===============================================================================
*/

USE synthetic_ecommerce;

-- 1. OVERALL SALES KPIs
SELECT
    ROUND(SUM(total_amount), 2) AS total_revenue,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(total_amount) / NULLIF(COUNT(DISTINCT order_id), 0), 2)
        AS average_order_value
FROM orders;

-- 2. ORDER-DATE COVERAGE
-- Confirms whether the first and last calendar months are complete.
SELECT
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date,
    COUNT(DISTINCT order_date) AS observed_order_dates
FROM orders;

-- 3. MONTHLY SALES TREND
-- Daily averages distinguish real changes from differences in month length.
SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS sales_month,
    COUNT(DISTINCT order_date) AS observed_days,
    ROUND(SUM(total_amount), 2) AS monthly_revenue,
    COUNT(DISTINCT order_id) AS monthly_orders,
    ROUND(SUM(total_amount) / NULLIF(COUNT(DISTINCT order_id), 0), 2)
        AS monthly_average_order_value,
    ROUND(SUM(total_amount) / NULLIF(COUNT(DISTINCT order_date), 0), 2)
        AS average_daily_revenue,
    ROUND(COUNT(DISTINCT order_id)
          / NULLIF(COUNT(DISTINCT order_date), 0), 2)
        AS average_daily_orders
FROM orders
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY sales_month;

-- 4. SALES BY CUSTOMER COUNTRY
-- Interpret revenue differences together with customer allocation.
SELECT
    COALESCE(c.country, 'Unknown') AS country,
    ROUND(SUM(o.total_amount), 2) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(o.total_amount) / NULLIF(COUNT(DISTINCT o.order_id), 0), 2)
        AS average_order_value,
    ROUND(100.0 * SUM(o.total_amount)
          / NULLIF(SUM(SUM(o.total_amount)) OVER (), 0), 2)
        AS revenue_share_pct
FROM orders AS o
LEFT JOIN customers AS c ON o.customer_id = c.customer_id
GROUP BY COALESCE(c.country, 'Unknown')
ORDER BY total_revenue DESC;

-- 5. SALES BY PAYMENT METHOD
SELECT
    COALESCE(payment_method, 'Unknown') AS payment_method,
    ROUND(SUM(total_amount), 2) AS total_revenue,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(total_amount) / NULLIF(COUNT(DISTINCT order_id), 0), 2)
        AS average_order_value,
    ROUND(100.0 * SUM(total_amount)
          / NULLIF(SUM(SUM(total_amount)) OVER (), 0), 2)
        AS revenue_share_pct
FROM orders
GROUP BY COALESCE(payment_method, 'Unknown')
ORDER BY total_revenue DESC;
