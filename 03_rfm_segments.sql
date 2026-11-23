-- Business question: Which customers are our champions, and which are slipping away?
-- Techniques: RFM scoring with NTILE(), CASE-based segmentation, aggregate over segments
WITH base AS (
    SELECT o.customer_id,
           julianday('2025-12-31') - julianday(MAX(o.order_date)) AS recency_days,
           COUNT(DISTINCT o.order_id)                             AS frequency,
           SUM(oi.quantity * oi.unit_price)                       AS monetary
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'completed'
    GROUP BY o.customer_id
),
scored AS (
    SELECT *,
           NTILE(5) OVER (ORDER BY recency_days DESC) AS r,   -- 5 = most recent
           NTILE(5) OVER (ORDER BY frequency)         AS f,
           NTILE(5) OVER (ORDER BY monetary)          AS m
    FROM base
),
segmented AS (
    SELECT *,
           CASE
               WHEN r >= 4 AND f >= 4               THEN 'Champions'
               WHEN r >= 3 AND f >= 3               THEN 'Loyal'
               WHEN r >= 4 AND f <= 2               THEN 'New / Promising'
               WHEN r <= 2 AND f >= 3               THEN 'At Risk'
               ELSE                                      'Hibernating'
           END AS segment
    FROM scored
)
SELECT segment,
       COUNT(*)                                   AS customers,
       ROUND(AVG(recency_days))                   AS avg_recency_days,
       ROUND(AVG(frequency), 1)                   AS avg_orders,
       ROUND(AVG(monetary), 2)                    AS avg_spend,
       ROUND(100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER (), 1) AS pct_of_revenue
FROM segmented
GROUP BY segment
ORDER BY pct_of_revenue DESC;
