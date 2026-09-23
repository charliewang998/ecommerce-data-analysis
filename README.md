# Olist Brazilian E-Commerce Analysis

## Project Overview

This project analyzes the Brazilian E-Commerce Public Dataset provided by Olist. The dataset contains anonymized commercial order data from Brazilian marketplaces and covers orders recorded between September 2016 and October 2018.

The project demonstrates an end-to-end junior data-analysis workflow using SQL, Python, and Power BI. The analysis begins with data-quality validation and will then examine sales performance, customer behavior, product performance, delivery operations, and customer reviews.

## Business Questions

The project will address the following questions:

1. What are the main order and payment KPIs?
2. How do order volume and recorded payment value change over time?
3. Which product categories contribute the most sales value?
4. Where are customers and sellers located?
5. How frequently do customers make repeat purchases?
6. How do delivery performance and review scores relate to customer experience?

## Dataset

**Source:** [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

The dataset contains nine related CSV files:

| Table | Rows | Description |
|---|---:|---|
| `olist_customers_dataset` | 99,441 | Customer identifiers and customer locations |
| `olist_geolocation_dataset` | 1,000,163 | Brazilian postal-code coordinates |
| `olist_order_items_dataset` | 112,650 | Products, sellers, prices, and freight values within orders |
| `olist_order_payments_dataset` | 103,886 | Payment methods, installments, and payment values |
| `olist_order_reviews_dataset` | 99,224 | Review scores, comments, and review dates |
| `olist_orders_dataset` | 99,441 | Order status and purchase, approval, delivery, and estimated dates |
| `olist_products_dataset` | 32,951 | Product categories and product attributes |
| `olist_sellers_dataset` | 3,095 | Seller identifiers and seller locations |
| `product_category_name_translation` | 71 | Portuguese-to-English product-category translations |

The observed order period is **2016-09-04 to 2018-10-17**. The first and last calendar months are incomplete and should not be compared directly with complete months.

## Tools

- **MySQL / DBeaver:** data-quality checks and business analysis
- **Python / Pandas:** planned exploratory analysis and validation
- **Power BI:** planned data model and interactive dashboard
- **GitHub:** project documentation and reproducible analysis files

## Data Quality Assessment

The following checks have been completed before beginning the business analysis:

- All nine CSV files were imported successfully, and their row counts match the source files.
- Order, customer, product, and seller IDs contain no duplicates.
- The composite keys for order items, payments, and reviews contain no duplicate combinations.
- Critical order identifiers, order statuses, and purchase timestamps contain no missing values.
- Product prices and freight values contain no missing or negative values.
- Payment values and installment fields contain no missing values.
- Review scores contain no missing values and fall within the expected range of 1 to 5.
- All order-item, payment, and review records match an order.
- All order-item records match a product and a seller.

### Identified Data Limitations

- 610 of 32,951 products have no product-category name.
- 13 products across two categories have no English category translation: `pc_gamer` and `portateis_cozinha_e_preparadores_de_alimentos`.
- Nine payment rows have a payment value of zero.
- Two positive credit-card payment rows record zero installments.
- 775 orders have no item records; 767 of these orders are unavailable or canceled, and none are delivered.
- One delivered order has no corresponding payment record.
- 768 orders have no review record, including 646 delivered orders.
- The review table is not one row per order or one row per review ID; the combination of `review_id` and `order_id` uniquely identifies a review row.

## Analytical Decisions

- Original source records are retained; uncertain values are not overwritten or deleted without supporting evidence.
- Orders without item records will not enter product- or category-level analysis.
- The delivered order without a payment record will remain in order counts but cannot contribute to payment-based metrics.
- Missing product categories will be labeled `Unknown` during category analysis.
- Product categories without an English translation will retain their original Portuguese names.
- Zero-installment records will be excluded from installment-specific calculations or identified as unknown.
- Missing reviews will not be assigned a score of zero because no review is different from a negative review.

## Repository Structure

```text
ecommerce-data-analysis/
├── README.md
└── sql/
    └── 00_data_quality_checks.sql
```

## Project Status

- [x] Import and validate the Olist source tables
- [x] Complete the SQL data-quality checks
- [ ] Complete the SQL sales overview
- [ ] Complete customer analysis
- [ ] Complete product and delivery analysis
- [ ] Perform Python exploratory analysis
- [ ] Build the Power BI dashboard
- [ ] Add final business findings and recommendations

