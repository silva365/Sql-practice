-- Business question: How long do customers wait between orders, by city? (Useful for timing re-engagement emails.)
-- Techniques: LAG() per customer, julianday date math, median via ROW_NUMBER/COUNT windows
WITH gaps AS (
    SELECT c.city,
           julianday(o.order_date)
             - julianday(LAG(o.order_date) OVER (PARTITION BY o.customer_id ORDER BY o.order_date)) AS gap_days
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.status = 'completed'
),
ordered AS (
    SELECT city, gap_days,
           ROW_NUMBER() OVER (PARTITION BY city ORDER BY gap_days) AS rn,
           COUNT(*)     OVER (PARTITION BY city)                   AS n
    FROM gaps
    WHERE gap_days IS NOT NULL
)
SELECT city,
       MAX(n)                                              AS repeat_orders,
       ROUND(AVG(gap_days), 1)                             AS avg_gap_days,
       AVG(CASE WHEN rn IN ((n + 1) / 2, (n + 2) / 2) THEN gap_days END) AS median_gap_days
FROM ordered
GROUP BY city
ORDER BY median_gap_days;
