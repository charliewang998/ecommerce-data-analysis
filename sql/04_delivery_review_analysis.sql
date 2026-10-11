/*
===============================================================================
Olist E-commerce Delivery and Review Analysis
Database: olist_ecommerce
Purpose : Measure delivery speed and on-time performance, summarize customer
          reviews, and examine the relationship between delays and ratings.
Author  : Charlie Wang
===============================================================================

Metric definitions and scope:
- Delivery KPIs use orders with order_status = 'delivered'.
- Delivery time = actual customer delivery timestamp - purchase timestamp.
- An order is on time when its actual delivery date is on or before its
  estimated delivery date. Time of day is ignored for this comparison.
- Eight delivered orders have no actual customer delivery date and therefore
  cannot enter delivery-time or on-time calculations.
- Review comparisons first average multiple review rows to one score per order,
  preventing orders with multiple reviews from receiving extra weight.
- Missing reviews are not assigned a score of zero.
- Observed relationships between delivery and ratings show association, not
  proof that delivery performance alone caused a particular review score.
===============================================================================
*/

USE olist_ecommerce;

-- 1. OVERALL DELIVERY-TIME KPIs
-- Delivery time covers the full period from purchase to customer receipt,
-- including approval, preparation, dispatch, and transportation.
-- Observed: 96,470 delivered orders had a delivery date, with an average
-- delivery time of 12.09 days and a range of 0 to 209 complete days.
SELECT
    COUNT(*) AS delivered_orders_with_delivery_date,
    ROUND(
        AVG(
            TIMESTAMPDIFF(
                DAY,
                order_purchase_timestamp,
                order_delivered_customer_date
            )
        ),
        2
    ) AS average_delivery_days,
    MIN(
        TIMESTAMPDIFF(
            DAY,
            order_purchase_timestamp,
            order_delivered_customer_date
        )
    ) AS minimum_delivery_days,
    MAX(
        TIMESTAMPDIFF(
            DAY,
            order_purchase_timestamp,
            order_delivered_customer_date
        )
    ) AS maximum_delivery_days
FROM olist_orders_dataset
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;

-- 2. LONGEST DELIVERY TIMES: DIAGNOSTIC CHECK
-- Several extreme records share the same delivery date. They are retained,
-- but should be interpreted cautiously because they may reflect operational
-- backlogs, exceptional cases, or later date entry.
SELECT
    order_id,
    order_purchase_timestamp,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    TIMESTAMPDIFF(
        DAY,
        order_purchase_timestamp,
        order_delivered_customer_date
    ) AS delivery_days
FROM olist_orders_dataset
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
ORDER BY delivery_days DESC
LIMIT 10;

-- 3. ON-TIME DELIVERY RATE
-- DATE removes the time component so delivery at any time on the estimated
-- date is classified as on time.
-- Observed: 89,936 of 96,470 comparable orders were on time, producing an
-- on-time delivery rate of 93.23%.
SELECT
    COUNT(*) AS delivered_orders_with_comparable_dates,
    SUM(
        CASE
            WHEN DATE(order_delivered_customer_date)
                 <= DATE(order_estimated_delivery_date)
            THEN 1
            ELSE 0
        END
    ) AS on_time_orders,
    SUM(
        CASE
            WHEN DATE(order_delivered_customer_date)
                 > DATE(order_estimated_delivery_date)
            THEN 1
            ELSE 0
        END
    ) AS late_orders,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN DATE(order_delivered_customer_date)
                     <= DATE(order_estimated_delivery_date)
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS on_time_delivery_rate_pct
FROM olist_orders_dataset
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;

-- 4. REVIEW-SCORE DISTRIBUTION
-- This describes review records rather than unique orders because a small
-- number of orders have more than one review row.
-- Observed: 4- and 5-star reviews represented 77.07% of review records.
SELECT
    review_score,
    COUNT(*) AS review_records,
    ROUND(
        100.0 * COUNT(*)
        / (
            SELECT COUNT(*)
            FROM olist_order_reviews_dataset
        ),
        2
    ) AS review_share_pct
FROM olist_order_reviews_dataset
GROUP BY review_score
ORDER BY review_score;

-- 5. REVIEW SCORES FOR ON-TIME VERSUS LATE ORDERS
-- The CTE produces one review score per order before joining to orders.
-- Observed: on-time orders averaged 4.29, compared with 2.27 for late orders.
WITH order_level_reviews AS (
    SELECT
        order_id,
        AVG(review_score) AS order_review_score
    FROM olist_order_reviews_dataset
    GROUP BY order_id
)

SELECT
    CASE
        WHEN DATE(o.order_delivered_customer_date)
             <= DATE(o.order_estimated_delivery_date)
        THEN 'On time'
        ELSE 'Late'
    END AS delivery_status,
    COUNT(*) AS reviewed_delivered_orders,
    ROUND(
        AVG(
            TIMESTAMPDIFF(
                DAY,
                o.order_purchase_timestamp,
                o.order_delivered_customer_date
            )
        ),
        2
    ) AS average_delivery_days,
    ROUND(AVG(r.order_review_score), 2) AS average_review_score
FROM olist_orders_dataset AS o
INNER JOIN order_level_reviews AS r
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY
    CASE
        WHEN DATE(o.order_delivered_customer_date)
             <= DATE(o.order_estimated_delivery_date)
        THEN 'On time'
        ELSE 'Late'
    END
ORDER BY average_review_score DESC;

-- 6. REVIEW SCORES BY DELAY SEVERITY
-- Scores decline sharply when orders arrive late. Orders delayed by 8 to 30
-- days received the lowest average ratings, at approximately 1.6 to 1.7.
WITH order_level_reviews AS (
    SELECT
        order_id,
        AVG(review_score) AS order_review_score
    FROM olist_order_reviews_dataset
    GROUP BY order_id
)

SELECT
    CASE
        WHEN DATEDIFF(
            o.order_delivered_customer_date,
            o.order_estimated_delivery_date
        ) <= 0
        THEN 'On time'
        WHEN DATEDIFF(
            o.order_delivered_customer_date,
            o.order_estimated_delivery_date
        ) BETWEEN 1 AND 7
        THEN '1-7 days late'
        WHEN DATEDIFF(
            o.order_delivered_customer_date,
            o.order_estimated_delivery_date
        ) BETWEEN 8 AND 14
        THEN '8-14 days late'
        WHEN DATEDIFF(
            o.order_delivered_customer_date,
            o.order_estimated_delivery_date
        ) BETWEEN 15 AND 30
        THEN '15-30 days late'
        ELSE 'More than 30 days late'
    END AS delivery_delay_group,
    COUNT(*) AS reviewed_delivered_orders,
    ROUND(AVG(r.order_review_score), 2) AS average_review_score
FROM olist_orders_dataset AS o
INNER JOIN order_level_reviews AS r
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY delivery_delay_group
ORDER BY
    MIN(
        DATEDIFF(
            o.order_delivered_customer_date,
            o.order_estimated_delivery_date
        )
    );
