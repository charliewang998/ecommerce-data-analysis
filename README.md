# E-commerce Sales & Customer Insights Analysis

## Project Overview

This project analyzes a large synthetic e-commerce relational dataset using SQL, Python, and Power BI. The objective is to simulate an end-to-end data-analysis workflow: assess data quality, define reliable metrics, identify sales and customer patterns, and communicate findings through a business-facing dashboard and report.

The analysis is designed for an e-commerce operations or management team seeking a clear view of sales performance, customer behavior, product performance, and data limitations that may affect decision-making.

## Business Questions

- What are the company's baseline sales KPIs?
- How do revenue, order volume, and average order value change over time?
- How is revenue distributed across customer countries and payment methods?
- Which customers and products contribute the most value?
- What data-quality limitations must be considered before interpreting the results?

## Dataset

Source: [Synthetic E-Commerce Relational Dataset on Kaggle](https://www.kaggle.com/datasets/naelaqel/synthetic-e-commerce-relational-dataset)

The database contains five related tables:

| Table | Rows | Description |
|---|---:|---|
| `customers` | 2,000,000 | Customer profiles and signup information |
| `orders` | 8,000,000 | Order dates, amounts, payment methods, and destinations |
| `order_items` | 20,000,000 | Products, quantities, and prices within orders |
| `products` | 20,000 | Product details, categories, prices, brands, and stock |
| `product_reviews` | 4,000,000 | Customer ratings and review information |

> The dataset is synthetically generated and does not represent a real company or real customers.

## Tools

- **MySQL / DBeaver:** data-quality auditing and business analysis
- **Python / Pandas:** planned data preparation and exploratory analysis
- **Power BI:** planned data model and interactive dashboard
- **GitHub:** project documentation and reproducible analysis files

## Project Files

- [`sql/00_data_quality_audit.sql`](sql/00_data_quality_audit.sql) — data-quality and business-rule validation
- [`sql/01_sales_overview.sql`](sql/01_sales_overview.sql) — baseline sales, monthly trends, customer-country analysis, and payment-method analysis

## Data Quality Assessment

A structured audit was completed before interpreting the business metrics. The checks covered primary-key uniqueness, missing values, referential integrity, numerical validity, date consistency, categorical consistency, and reconciliation between order totals and order-item totals.

### Key Findings

- No duplicate primary keys were identified across the five tables.
- No missing values were found in the audited key fields.
- No invalid negative amounts, prices, quantities, stock values, or out-of-range ratings were identified.
- **3,196,732 orders (39.96%) occurred before the corresponding customer signup date.**
- **655,925 orders (8.20%) had no corresponding order-item records.**
- For all **7,344,075 orders with item records**, the recorded order totals matched totals recalculated from `quantity × unit_price` within a tolerance of 0.01.
- `Congo` and `Korea` each contained approximately twice the typical customer count, suggesting that multiple geographic entities may be grouped under ambiguous country labels.

### Analytical Decisions

- The original source tables were preserved; uncertain records were not overwritten or deleted.
- All orders were retained for general order-level sales reporting because `orders.total_amount` remains available.
- Orders occurring before customer signup will be excluded from analyses requiring valid customer-lifecycle chronology.
- Orders without item records will be excluded from product-, category-, and basket-level analyses.
- Congo and Korea will not be presented as proven top-performing markets because the available labels cannot distinguish the underlying geographic entities.

## SQL Sales Overview

### Baseline KPIs

| Metric | Result |
|---|---:|
| Total recorded revenue | 15,084,012,109.31 |
| Total orders | 8,000,000 |
| Average order value | 1,885.50 |

The source does not specify a currency, so monetary values are presented without a currency symbol. The dataset also has no order-status field, meaning cancellations and refunds cannot be identified or excluded.

### Monthly Sales Pattern

Monthly revenue was broadly stable across full months. Average order value remained close to 1,885, so most monthly revenue variation was driven by order volume rather than changes in customer spending per order. February consistently showed lower totals because it contains fewer calendar days. The first displayed month contained only 5,474 orders and should be treated as an incomplete period rather than a weak-performing month.

### Customer-Country Pattern

Most country labels contributed approximately 0.40%–0.42% of revenue and had similar average order values. Congo and Korea appeared at the top of the ranking, but each also contained about twice the typical number of customers. Their higher revenue therefore appears to reflect unusual customer allocation or ambiguous labels rather than stronger customer spending.

### Payment-Method Pattern

Credit Card, PayPal, Cash, and Bank Transfer each contributed approximately 25% of both orders and revenue. Average order values were also nearly identical. The differences are too small to support a claim of meaningful customer payment preference and instead reflect the highly uniform nature of the synthetic data.

## Limitations

- The data is synthetic and highly uniform, limiting the realism of market and behavioral conclusions.
- Currency is not specified.
- Order status is unavailable, so cancellations and refunds cannot be separated.
- Approximately 40% of orders violate customer-signup chronology.
- Approximately 8.20% of orders have no item-level records.
- Some country labels may combine distinct geographic entities.

## Project Status

Work in progress. The data-quality audit and initial SQL sales overview are complete. Customer analysis, product analysis, Python exploration, and the Power BI dashboard will be added next.
