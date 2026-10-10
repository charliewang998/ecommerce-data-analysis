/*
===============================================================================
Olist E-commerce Product Analysis
Database: olist_ecommerce
Purpose : Measure delivered-item activity, compare product-category performance,
          and identify categories with relatively high recorded freight values.
Author  : Charlie Wang
===============================================================================

Metric definitions and scope:
- Analysis includes orders with order_status = 'delivered'.
- Item rows represent product occurrences in order_items, not distinct products.
- Distinct products sold = COUNT(DISTINCT product_id).
- Merchandise value = SUM(order_items.price), excluding freight.
- Freight share = freight / (merchandise value + freight).
- Freight value is the amount recorded in the dataset. It should not be treated
  as the seller's actual logistics cost or used to calculate profit.
- English category names come from the translation table. When a translation
  is unavailable, the original Portuguese category is retained; blank category
  names are labeled 'Unknown'.
===============================================================================
*/

USE olist_ecommerce;

-- 1. OVERALL DELIVERED-ITEM KPIs
-- Observed: 110,197 item rows across 96,478 delivered orders, representing
-- 32,216 distinct products. Merchandise value was 13,221,498.11 and recorded
-- freight value was 2,198,275.64.
SELECT
    COUNT(*) AS delivered_item_rows,
    COUNT(DISTINCT i.order_id) AS delivered_orders_with_items,
    COUNT(DISTINCT i.product_id) AS distinct_products_sold,
    ROUND(SUM(i.price), 2) AS merchandise_value,
    ROUND(SUM(i.freight_value), 2) AS freight_value,
    ROUND(
        SUM(i.price) + SUM(i.freight_value),
        2
    ) AS merchandise_plus_freight_value
FROM olist_order_items_dataset AS i
INNER JOIN olist_orders_dataset AS o
    ON i.order_id = o.order_id
WHERE o.order_status = 'delivered';

-- 2. LEADING PRODUCT CATEGORIES BY MERCHANDISE VALUE
-- One item row represents one product occurrence in an order. The distinct-
-- product measure counts different product IDs rather than units sold.
-- Observed: health_beauty generated the highest merchandise value, while
-- bed_bath_table had the most delivered orders and item rows among the top 15.
SELECT
    COALESCE(
        t.product_category_name_english,
        NULLIF(TRIM(p.product_category_name), ''),
        'Unknown'
    ) AS product_category,
    COUNT(DISTINCT i.order_id) AS delivered_orders,
    COUNT(*) AS item_rows,
    COUNT(DISTINCT i.product_id) AS distinct_products_sold,
    ROUND(SUM(i.price), 2) AS merchandise_value,
    ROUND(AVG(i.price), 2) AS average_item_price,
    ROUND(SUM(i.freight_value), 2) AS freight_value,
    ROUND(
        100.0 * SUM(i.freight_value)
        / NULLIF(SUM(i.price) + SUM(i.freight_value), 0),
        2
    ) AS freight_share_pct
FROM olist_order_items_dataset AS i
INNER JOIN olist_orders_dataset AS o
    ON i.order_id = o.order_id
INNER JOIN olist_products_dataset AS p
    ON i.product_id = p.product_id
LEFT JOIN product_category_name_translation AS t
    ON p.product_category_name = t.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY
    COALESCE(
        t.product_category_name_english,
        NULLIF(TRIM(p.product_category_name), ''),
        'Unknown'
    )
ORDER BY merchandise_value DESC
LIMIT 15;

-- 3. CATEGORIES WITH THE HIGHEST FREIGHT SHARE
-- HAVING filters the grouped results after aggregation. Requiring at least
-- 100 item rows reduces the influence of very small categories.
-- A high percentage and a high absolute freight value answer different
-- questions, so both measures should be considered together.
SELECT
    COALESCE(
        t.product_category_name_english,
        NULLIF(TRIM(p.product_category_name), ''),
        'Unknown'
    ) AS product_category,
    COUNT(*) AS item_rows,
    ROUND(SUM(i.price), 2) AS merchandise_value,
    ROUND(SUM(i.freight_value), 2) AS freight_value,
    ROUND(
        100.0 * SUM(i.freight_value)
        / NULLIF(SUM(i.price) + SUM(i.freight_value), 0),
        2
    ) AS freight_share_pct
FROM olist_order_items_dataset AS i
INNER JOIN olist_orders_dataset AS o
    ON i.order_id = o.order_id
INNER JOIN olist_products_dataset AS p
    ON i.product_id = p.product_id
LEFT JOIN product_category_name_translation AS t
    ON p.product_category_name = t.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY
    COALESCE(
        t.product_category_name_english,
        NULLIF(TRIM(p.product_category_name), ''),
        'Unknown'
    )
HAVING COUNT(*) >= 100
ORDER BY freight_share_pct DESC
LIMIT 15;
