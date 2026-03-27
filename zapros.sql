

---

## Файл 2: `all_queries.sql`

```sql
-- =====================================================
-- САМОСТОЯТЕЛЬНАЯ РАБОТА
-- Тема: Сложные запросы к данным в PostgreSQL
-- Студент: Величко АС
-- Группа: ИСПП 23-09 01
-- =====================================================

-- =====================================================
-- БЛОК 1. ФИЛЬТРАЦИЯ И СОРТИРОВКА
-- =====================================================

-- Задание 1. Вывести всех клиентов из Москвы.
SELECT * FROM clients WHERE city = 'Москва';

-- Задание 2. Вывести все товары категории Electronics.
SELECT * FROM products WHERE category = 'Electronics';

-- Задание 3. Найти товары дороже 5000 рублей.
SELECT * FROM products WHERE price > 5000;

-- Задание 4. Вывести оплаченные заказы после 2026-01-01.
SELECT * FROM orders WHERE status = 'paid' AND order_date > '2026-01-01';

-- Задание 5. Найти товары, название которых содержит слово Ноутбук или Смартфон.
SELECT * FROM products WHERE title LIKE '%Ноутбук%' OR title LIKE '%Смартфон%';

-- Задание 6. Вывести 5 самых дорогих товаров.
SELECT * FROM products ORDER BY price DESC LIMIT 5;

-- Задание 7. Реализовать постраничный вывод товаров: вторая страница по 4 товара.
SELECT * FROM products ORDER BY id LIMIT 4 OFFSET 4;

-- =====================================================
-- БЛОК 2. JOIN
-- =====================================================

-- Задание 8. Вывести список заказов: номер заказа, дата заказа, статус, имя клиента.
SELECT o.id AS order_id, o.order_date, o.status, c.full_name 
FROM orders o
INNER JOIN clients c ON o.client_id = c.id
ORDER BY o.id;

-- Задание 9. Вывести состав заказов: номер заказа, название товара, количество, цена позиции.
SELECT oi.order_id, p.title AS product_name, oi.quantity, oi.price
FROM order_items oi
INNER JOIN products p ON oi.product_id = p.id
ORDER BY oi.order_id;

-- Задание 10. Найти всех клиентов, которые не сделали ни одного заказа.
SELECT c.* 
FROM clients c
LEFT JOIN orders o ON c.id = o.client_id
WHERE o.id IS NULL;

-- Задание 11. Вывести все товары и количество раз, которое они встречались в заказах, включая товары без продаж.
SELECT p.id, p.title, COUNT(oi.product_id) AS times_ordered
FROM products p
LEFT JOIN order_items oi ON p.id = oi.product_id
GROUP BY p.id, p.title
ORDER BY times_ordered DESC;

-- =====================================================
-- БЛОК 3. АГРЕГАЦИЯ И ГРУППИРОВКА
-- =====================================================

-- Задание 12. Посчитать общее количество заказов в таблице orders.
SELECT COUNT(*) AS total_orders FROM orders;

-- Задание 13. Посчитать общую сумму всех оплаченных заказов.
SELECT SUM(total_amount) AS total_paid_sum FROM orders WHERE status = 'paid';

-- Задание 14. Вывести количество заказов по каждому клиенту.
SELECT c.id, c.full_name, COUNT(o.id) AS orders_count
FROM clients c
LEFT JOIN orders o ON c.id = o.client_id
GROUP BY c.id, c.full_name
ORDER BY orders_count DESC;

-- Задание 15. Вывести среднюю сумму заказа по каждому клиенту.
SELECT c.id, c.full_name, AVG(o.total_amount) AS avg_order_amount
FROM clients c
LEFT JOIN orders o ON c.id = o.client_id
GROUP BY c.id, c.full_name
HAVING AVG(o.total_amount) IS NOT NULL
ORDER BY avg_order_amount DESC;

-- Задание 16. Найти клиентов, у которых больше 2 заказов.
SELECT c.id, c.full_name, COUNT(o.id) AS orders_count
FROM clients c
INNER JOIN orders o ON c.id = o.client_id
GROUP BY c.id, c.full_name
HAVING COUNT(o.id) > 2;

-- Задание 17. Вывести категории товаров и максимальную цену в каждой категории.
SELECT category, MAX(price) AS max_price
FROM products
GROUP BY category
ORDER BY max_price DESC;

-- =====================================================
-- БЛОК 4. FILTER
-- =====================================================

-- Задание 18. Для каждого клиента посчитать: общее число заказов, число оплаченных, число отменённых.
SELECT 
    c.id, 
    c.full_name,
    COUNT(o.id) AS total_orders,
    COUNT(o.id) FILTER (WHERE o.status = 'paid') AS paid_orders,
    COUNT(o.id) FILTER (WHERE o.status = 'canceled') AS canceled_orders
FROM clients c
LEFT JOIN orders o ON c.id = o.client_id
GROUP BY c.id, c.full_name
ORDER BY total_orders DESC;

-- Задание 19. Для каждого клиента вывести сумму оплаченных и сумму отменённых заказов.
SELECT 
    c.id, 
    c.full_name,
    COALESCE(SUM(o.total_amount) FILTER (WHERE o.status = 'paid'), 0) AS paid_sum,
    COALESCE(SUM(o.total_amount) FILTER (WHERE o.status = 'canceled'), 0) AS canceled_sum
FROM clients c
LEFT JOIN orders o ON c.id = o.client_id
GROUP BY c.id, c.full_name
ORDER BY paid_sum DESC;

-- =====================================================
-- БЛОК 5. ПОДЗАПРОСЫ И EXISTS
-- =====================================================

-- Задание 20. Найти клиентов, у которых есть хотя бы один оплаченный заказ.
SELECT * FROM clients c
WHERE EXISTS (
    SELECT 1 FROM orders o 
    WHERE o.client_id = c.id AND o.status = 'paid'
);

-- Задание 21. Найти товары, которые ни разу не встречались в заказах.
SELECT * FROM products p
WHERE NOT EXISTS (
    SELECT 1 FROM order_items oi 
    WHERE oi.product_id = p.id
);

-- Задание 22. Вывести клиентов, сумма заказов которых больше средней суммы заказов по всем клиентам.
SELECT c.id, c.full_name, SUM(o.total_amount) AS total_spent
FROM clients c
INNER JOIN orders o ON c.id = o.client_id
GROUP BY c.id, c.full_name
HAVING SUM(o.total_amount) > (
    SELECT AVG(client_total) FROM (
        SELECT SUM(total_amount) AS client_total
        FROM orders
        GROUP BY client_id
    ) AS client_totals
);

-- Задание 23. Найти заказы, в которых есть товары категории Electronics.
SELECT DISTINCT o.* 
FROM orders o
WHERE EXISTS (
    SELECT 1 
    FROM order_items oi
    INNER JOIN products p ON oi.product_id = p.id
    WHERE oi.order_id = o.id AND p.category = 'Electronics'
);

-- =====================================================
-- БЛОК 6. CTE (Common Table Expressions)
-- =====================================================

-- Задание 24. С помощью WITH создать временный набор оплаченных заказов и вывести по ним сумму заказов по клиентам.
WITH paid_orders AS (
    SELECT * FROM orders WHERE status = 'paid'
)
SELECT client_id, SUM(total_amount) AS total_paid
FROM paid_orders
GROUP BY client_id
ORDER BY total_paid DESC;

-- Задание 25. С помощью CTE найти клиентов, у которых более 1 оплаченного заказа, и вывести их средний чек.
WITH client_paid_stats AS (
    SELECT 
        client_id,
        COUNT(*) AS paid_orders_count,
        AVG(total_amount) AS avg_check
    FROM orders
    WHERE status = 'paid'
    GROUP BY client_id
)
SELECT c.id, c.full_name, cps.paid_orders_count, cps.avg_check
FROM clients c
INNER JOIN client_paid_stats cps ON c.id = cps.client_id
WHERE cps.paid_orders_count > 1
ORDER BY cps.avg_check DESC;

-- Задание 26. Разбить сложный запрос на несколько этапов через несколько CTE.
-- Найти клиентов, у которых сумма оплаченных заказов больше средней суммы всех оплаченных заказов
WITH paid_orders_summary AS (
    SELECT 
        client_id,
        SUM(total_amount) AS total_paid,
        COUNT(*) AS orders_count
    FROM orders
    WHERE status = 'paid'
    GROUP BY client_id
),
overall_stats AS (
    SELECT AVG(total_paid) AS avg_total_paid
    FROM paid_orders_summary
)
SELECT 
    c.id,
    c.full_name,
    pos.total_paid,
    pos.orders_count
FROM clients c
INNER JOIN paid_orders_summary pos ON c.id = pos.client_id
CROSS JOIN overall_stats os
WHERE pos.total_paid > os.avg_total_paid
ORDER BY pos.total_paid DESC;

-- =====================================================
-- БЛОК 7. VIEW (Представления)
-- =====================================================

-- Задание 27. Создать представление v_order_details.
CREATE OR REPLACE VIEW v_order_details AS
SELECT 
    o.id AS order_id,
    c.full_name,
    o.order_date,
    o.status,
    p.title AS product_name,
    oi.quantity,
    oi.price,
    (oi.quantity * oi.price) AS line_total
FROM orders o
INNER JOIN clients c ON o.client_id = c.id
INNER JOIN order_items oi ON o.id = oi.order_id
INNER JOIN products p ON oi.product_id = p.id;

-- Задание 28. Выполнить запрос к представлению и вывести все товары, купленные конкретным клиентом.
SELECT * FROM v_order_details WHERE full_name = 'Иван Петров';

-- =====================================================
-- БЛОК 8. АНАЛИТИКА
-- =====================================================

-- Задание 29. Итоговый аналитический запрос.
SELECT 
    c.full_name,
    COUNT(o.id) FILTER (WHERE o.status = 'paid') AS paid_orders_count,
    COALESCE(SUM(o.total_amount) FILTER (WHERE o.status = 'paid'), 0) AS paid_total_sum,
    COALESCE(AVG(o.total_amount) FILTER (WHERE o.status = 'paid'), 0) AS paid_avg_check
FROM clients c
LEFT JOIN orders o ON c.id = o.client_id
GROUP BY c.id, c.full_name
HAVING COALESCE(SUM(o.total_amount) FILTER (WHERE o.status = 'paid'), 0) > 5000
ORDER BY paid_total_sum DESC;
