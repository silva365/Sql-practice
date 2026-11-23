-- Business question: What are the top 2 products in each top-level department, and how much of the department's revenue do they drive?
-- Techniques: recursive CTE (walk category tree to its root), RANK() per partition, share-of-total window
WITH RECURSIVE category_root AS (
    SELECT category_id, category_id AS root_id, name AS root_name
    FROM categories WHERE parent_id IS NULL
    UNION ALL
    SELECT c.category_id, cr.root_id, cr.root_name
    FROM categories c
    JOIN category_root cr ON c.parent_id = cr.category_id
),
product_sales AS (
    SELECT cr.root_name AS department,
           p.name       AS product,
           SUM(oi.quantity)                  AS units,
           SUM(oi.quantity * oi.unit_price)  AS revenue
    FROM order_items oi
    JOIN orders o         ON o.order_id = oi.order_id AND o.status = 'completed'
    JOIN products p       ON p.product_id = oi.product_id
    JOIN category_root cr ON cr.category_id = p.category_id
    GROUP BY cr.root_name, p.name
),
ranked AS (
    SELECT *,
           RANK() OVER (PARTITION BY department ORDER BY revenue DESC) AS rnk,
           100.0 * revenue / SUM(revenue) OVER (PARTITION BY department) AS dept_share
    FROM product_sales
)
SELECT department, rnk, product, units, ROUND(revenue, 2) AS revenue, ROUND(dept_share, 1) AS dept_share_pct
FROM ranked
WHERE rnk <= 2
ORDER BY department, rnk;
