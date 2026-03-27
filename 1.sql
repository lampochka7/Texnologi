-- 1. Заказы и клиенты (INNER JOIN)
SELECT 
    o.order_id,
    o.created_at,
    o.status,
    o.total_amount,
    c.client_id,
    c.full_name,
    c.city
FROM orders o
INNER JOIN clients c ON o.client_id = c.client_id
ORDER BY o.order_id ASC;

-- 2. Все клиенты и их заказы (LEFT JOIN)
SELECT 
    c.client_id,
    c.full_name,
    o.order_id,
    o.created_at,
    o.status,
    o.total_amount
FROM clients c
LEFT JOIN orders o ON c.client_id = o.client_id
ORDER BY c.client_id ASC, o.order_id ASC;

-- 3. Клиенты без заказов (LEFT JOIN + IS NULL)
SELECT 
    client_id,
    full_name,
    city
FROM clients
WHERE client_id NOT IN (SELECT DISTINCT client_id FROM orders WHERE client_id IS NOT NULL)
ORDER BY client_id ASC;

-- 4. Детализация позиций заказов (JOIN 4 таблицы)
SELECT 
    o.order_id,
    o.created_at,
    c.full_name,
    p.product_id,
    p.product_name,
    oi.qty,
    oi.price,
    (oi.qty * oi.price) AS line_sum
FROM orders o
INNER JOIN clients c ON o.client_id = c.client_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
INNER JOIN products p ON oi.product_id = p.product_id
ORDER BY o.order_id ASC, p.product_name ASC;

-- 5. Сумма позиций vs total_amount (проверка)
SELECT 
    o.order_id,
    o.total_amount,
    COALESCE(SUM(oi.qty * oi.price), 0) AS items_sum,
    o.total_amount - COALESCE(SUM(oi.qty * oi.price), 0) AS diff
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id, o.total_amount
ORDER BY ABS(o.total_amount - COALESCE(SUM(oi.qty * oi.price), 0)) DESC, o.order_id ASC;

-- 6. Топ товаров по количеству продаж (GROUP BY + JOIN)
SELECT 
    p.product_id,
    p.product_name,
    COALESCE(SUM(oi.qty), 0) AS total_qty
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_qty DESC, p.product_id ASC;

-- 7. Выручка по товарам (GROUP BY + JOIN)
SELECT 
    p.product_id,
    p.product_name,
    COALESCE(SUM(oi.qty * oi.price), 0) AS revenue
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
ORDER BY revenue DESC;

-- 8. Клиенты и количество заказов (LEFT JOIN + GROUP BY)
SELECT 
    c.client_id,
    c.full_name,
    COUNT(o.order_id) AS orders_count
FROM clients c
LEFT JOIN orders o ON c.client_id = o.client_id
GROUP BY c.client_id, c.full_name
ORDER BY orders_count DESC, c.client_id ASC;

-- 9. Paid-заказы: клиенты и сумма оплаченного (LEFT JOIN с фильтром в ON)
SELECT 
    c.client_id,
    c.full_name,
    COALESCE(SUM(o.total_amount), 0) AS paid_sum
FROM clients c
LEFT JOIN orders o ON c.client_id = o.client_id AND o.status = 'paid'
GROUP BY c.client_id, c.full_name
ORDER BY paid_sum DESC;

-- 10. Заказы без позиций
SELECT 
    o.order_id,
    o.created_at,
    o.status,
    o.total_amount
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
WHERE oi.order_item_id IS NULL
ORDER BY o.order_id ASC;
