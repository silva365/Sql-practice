-- Business question: How is revenue trending month over month, and what is the year-to-date total?
-- Techniques: CTE, aggregation, LAG() window, running SUM() partitioned by year
WITH monthly AS (
    SELECT strftime('%Y-%m', o.order_date)          AS month,
           COUNT(DISTINCT o.order_id)                AS orders,
           ROUND(SUM(oi.quantity * oi.unit_price), 2) AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'completed'
    GROUP BY 1
)
SELECT month,
       orders,
       revenue,
       ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
                   / LAG(revenue) OVER (ORDER BY month), 1)            AS mom_growth_pct,
       ROUND(SUM(revenue) OVER (PARTITION BY substr(month, 1, 4)
                                ORDER BY month), 2)                     AS ytd_revenue
FROM monthly
ORDER BY month;
