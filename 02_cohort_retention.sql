-- Business question: Of customers who first bought in a given month, what share came back 1, 2, 3 and 6 months later?
-- Techniques: multi-step CTEs, MIN() OVER for first purchase, date arithmetic, conditional aggregation (pivot)
WITH activity AS (
    SELECT DISTINCT customer_id,
           strftime('%Y', order_date) * 12 + strftime('%m', order_date) AS month_idx
    FROM orders
    WHERE status = 'completed'
),
cohorts AS (
    SELECT customer_id, month_idx,
           MIN(month_idx) OVER (PARTITION BY customer_id) AS cohort_idx
    FROM activity
),
offsets AS (
    SELECT cohort_idx, customer_id, month_idx - cohort_idx AS months_after
    FROM cohorts
)
SELECT printf('%d-%02d', (cohort_idx - 1) / 12, (cohort_idx - 1) % 12 + 1) AS cohort,
       COUNT(DISTINCT CASE WHEN months_after = 0 THEN customer_id END)    AS cohort_size,
       ROUND(100.0 * COUNT(DISTINCT CASE WHEN months_after = 1 THEN customer_id END)
             / COUNT(DISTINCT CASE WHEN months_after = 0 THEN customer_id END), 1) AS m1_pct,
       ROUND(100.0 * COUNT(DISTINCT CASE WHEN months_after = 2 THEN customer_id END)
             / COUNT(DISTINCT CASE WHEN months_after = 0 THEN customer_id END), 1) AS m2_pct,
       ROUND(100.0 * COUNT(DISTINCT CASE WHEN months_after = 3 THEN customer_id END)
             / COUNT(DISTINCT CASE WHEN months_after = 0 THEN customer_id END), 1) AS m3_pct,
       ROUND(100.0 * COUNT(DISTINCT CASE WHEN months_after = 6 THEN customer_id END)
             / COUNT(DISTINCT CASE WHEN months_after = 0 THEN customer_id END), 1) AS m6_pct
FROM offsets
GROUP BY cohort_idx
HAVING cohort < '2025-07'            -- only cohorts old enough to have a 6-month window
ORDER BY cohort_idx;
