# ecommerce-data-analysis
E-commerce data analysis project using SQL, Python and Power BI.

## Data Quality Assessment

A structured data-quality audit was performed before analysis, covering missing values, duplicate primary keys, referential integrity, numerical validity, date consistency, categorical consistency, and order-total reconciliation.

### Key Findings

- No duplicate primary keys or missing values were identified in the audited key fields.
- 3,196,732 orders (39.96%) occurred before the corresponding customer signup date.
- 655,925 orders (8.20%) had no corresponding order-item records.
- Recorded order totals matched item-level calculated totals for all 7,344,075 orders with available item records.

### Analytical Decisions

Orders occurring before customer signup were retained for general sales reporting but will be excluded from analyses requiring valid customer-lifecycle chronology. Orders without item records were retained for order-level reporting but will be excluded from product-, category-, and basket-level analyses.

The complete audit queries are available in [`sql/00_data_quality_audit.sql`](sql/00_data_quality_audit.sql).
