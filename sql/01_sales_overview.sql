/*
===============================================================================
Olist E-commerce Sales Overview
Database: olist_ecommerce
Purpose : Establish baseline order and payment KPIs, monthly trends, order-
          status differences, and customer payment behavior.
Author  : Charlie Wang
===============================================================================

Metric definitions and scope:
- Order count = COUNT(DISTINCT order_id).
- Recorded payment value = SUM(order_payments.payment_value).
- Completed-order payment KPIs use orders with order_status = 'delivered'.
- Payment values are not described as net revenue because refund data is not
  available and canceled orders can still have payment records.
- One delivered order has no payment record. It remains in delivered-order
  counts but cannot contribute to payment-based metrics.
- Monthly trends group delivered orders by purchase month, not delivery month.
===============================================================================
*/

USE olist_ecommerce;

-- 1. OVERALL RECORDED PAYMENT KPIs
-- Observed: 99,440 orders with payments, total payment value of 16,008,872.12,
-- and an average payment value of 160.99 per order with a payment record.
SELECT
    COUNT(DISTINCT order_id) AS orders_with_payment,
    ROUND(SUM(payment_value), 2) AS total_payment_value,
    ROUND(
        SUM(payment_value) / COUNT(DISTINCT order_id),
        2
    ) AS average_payment_per_order
FROM olist_order_payments_dataset;

-- 2. DELIVERED-ORDER PAYMENT KPIs
-- LEFT JOIN retains the one delivered order without a payment record.
-- Observed: 96,478 delivered orders, of which 96,477 have payment records.
SELECT
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    COUNT(DISTINCT p.order_id) AS delivered_orders_with_payment,
    ROUND(SUM(p.payment_value), 2) AS delivered_payment_value,
    ROUND(
        SUM(p.payment_value) / COUNT(DISTINCT p.order_id),
        2
    ) AS average_payment_per_paid_delivered_order
FROM olist_orders_dataset AS o
LEFT JOIN olist_order_payments_dataset AS p
    ON o.order_id = p.order_id
WHERE o.order_status = 'delivered';

-- 3. PAYMENT KPIs BY ORDER STATUS
-- Canceled and unavailable orders can still have payment records. Without
-- refund data, all-order payment value should not be called net revenue.
SELECT
    o.order_status,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT p.order_id) AS orders_with_payment,
    ROUND(SUM(p.payment_value), 2) AS total_payment_value,
    ROUND(
        SUM(p.payment_value) / COUNT(DISTINCT p.order_id),
        2
    ) AS average_payment_per_paid_order
FROM olist_orders_dataset AS o
LEFT JOIN olist_order_payments_dataset AS p
    ON o.order_id = p.order_id
GROUP BY o.order_status
ORDER BY total_payment_value DESC;

-- 4. MONTHLY DELIVERED-ORDER TREND
-- LEFT(timestamp, 7) extracts YYYY-MM from the imported timestamp text.
-- The 2016 data is sparse; the main comparison period is 2017-01 to 2018-08.
SELECT
    LEFT(o.order_purchase_timestamp, 7) AS order_month,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    COUNT(DISTINCT p.order_id) AS paid_delivered_orders,
    ROUND(SUM(p.payment_value), 2) AS payment_value,
    ROUND(
        SUM(p.payment_value) / COUNT(DISTINCT p.order_id),
        2
    ) AS average_payment_per_paid_order
FROM olist_orders_dataset AS o
LEFT JOIN olist_order_payments_dataset AS p
    ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY LEFT(o.order_purchase_timestamp, 7)
ORDER BY order_month;

-- 5. PAYMENT METHODS FOR DELIVERED ORDERS
-- An order can use more than one payment type, so order counts across payment
-- types should not be added together.
SELECT
    p.payment_type,
    COUNT(*) AS payment_records,
    COUNT(DISTINCT p.order_id) AS orders_using_payment_type,
    ROUND(SUM(p.payment_value), 2) AS payment_value
FROM olist_orders_dataset AS o
INNER JOIN olist_order_payments_dataset AS p
    ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY p.payment_type
ORDER BY payment_value DESC;

-- 6. CREDIT-CARD INSTALLMENT BEHAVIOR FOR DELIVERED ORDERS
-- Zero-installment records are excluded from installment-specific analysis.
-- The average represents the credit-card payment value assigned to each order,
-- not necessarily the order's full value when mixed payment types are used.
SELECT
    p.payment_installments,
    COUNT(*) AS payment_records,
    COUNT(DISTINCT p.order_id) AS orders_using_installments,
    ROUND(SUM(p.payment_value), 2) AS payment_value,
    ROUND(
        SUM(p.payment_value) / COUNT(DISTINCT p.order_id),
        2
    ) AS average_credit_card_value_per_order
FROM olist_orders_dataset AS o
INNER JOIN olist_order_payments_dataset AS p
    ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
  AND p.payment_type = 'credit_card'
  AND p.payment_installments > 0
GROUP BY p.payment_installments
ORDER BY p.payment_installments;

