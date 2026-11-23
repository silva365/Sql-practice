# Sql-practice

ShopLens: SQL analytics for an online store
ShopLens is a portfolio project that answers real business questions with SQL. It builds an SQLite database for an online store (2,000 customers and about 5,500 orders over 2024–2025), runs six analyses, and checks the data's integrity.

You only need Python 3. SQLite is built in

Analyses
#	Business question	SQL techniques
01	How is revenue trending month over month?	CTE, LAG(), running SUM() OVER (PARTITION BY year)
02	What share of each signup cohort comes back after 1, 2, 3 and 6 months?	Cohort analysis, MIN() OVER, date math, pivot with conditional aggregation
03	Who are our champions, and who is slipping away?	RFM scoring with NTILE(), CASE segmentation, share of total
04	What are the top products in each department?	Recursive CTE over the category tree, RANK() per partition
05	How long do customers wait between orders, by city?	LAG() per customer, median via ROW_NUMBER()/COUNT() windows
06	Which raw import rows are clean enough to load?	Text cleaning, multi-format date parsing, validation, dedupe with ROW_NUMBER()
Data quality checks live in tests/data_quality.sql: no orphaned rows, no orders before signup, no duplicate emails, and so on.

Key findings
Champions are 21% of customers but bring in 45% of revenue. At Risk customers (352 of them) still account for 20% of revenue, so they are the best win-back target.
The 2-Person Tent alone is 46% of Outdoors revenue, which means that department depends heavily on one product.
The median gap between orders is about 62–67 days in every city, so a re-engagement email around day 55 would arrive just before most customers would reorder anyway.
December revenue jumps about 36% over November, which is the seasonal peak to plan inventory around.
