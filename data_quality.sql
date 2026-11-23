-- Each check returns the number of violating rows. All should be 0.
SELECT 'order_items without a valid order'   AS check_name, COUNT(*) AS violations
FROM order_items oi LEFT JOIN orders o ON o.order_id = oi.order_id WHERE o.order_id IS NULL
UNION ALL
SELECT 'orders with no line items', COUNT(*)
FROM orders o WHERE NOT EXISTS (SELECT 1 FROM order_items oi WHERE oi.order_id = o.order_id)
UNION ALL
SELECT 'orders placed before customer signup', COUNT(*)
FROM orders o JOIN customers c ON c.customer_id = o.customer_id WHERE o.order_date < c.signup_date
UNION ALL
SELECT 'sale price differs from list price by >50%', COUNT(*)
FROM order_items oi JOIN products p ON p.product_id = oi.product_id
WHERE ABS(oi.unit_price - p.unit_price) > 0.5 * p.unit_price
UNION ALL
SELECT 'duplicate customer emails (case-insensitive)', COUNT(*) FROM (
    SELECT LOWER(email) FROM customers GROUP BY LOWER(email) HAVING COUNT(*) > 1
);
