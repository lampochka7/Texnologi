все sql коды хрошо работают в VS Code + SQLTools/SQLite 


1.sql (исправленный для PostgreSQL)
sql
-- Запрос 5 исправлен: используем алиас diff в ORDER BY
-- Остальные запросы работают как есть

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

-- 3. Клиенты без заказов (альтернатива NOT IN -> LEFT JOIN)
SELECT 
    c.client_id,
    c.full_name,
    c.city
FROM clients c
LEFT JOIN orders o ON c.client_id = o.client_id
WHERE o.client_id IS NULL
ORDER BY c.client_id ASC;

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

-- 5. ИСПРАВЛЕН: Сумма позиций vs total_amount (ORDER BY использует алиас)
SELECT 
    o.order_id,
    o.total_amount,
    COALESCE(SUM(oi.qty * oi.price), 0) AS items_sum,
    o.total_amount - COALESCE(SUM(oi.qty * oi.price), 0) AS diff
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id, o.total_amount
ORDER BY ABS(diff) DESC NULLS LAST, o.order_id ASC;

-- 6-10 остаются без изменений (работают в PG)
-- 6. Топ товаров по количеству продаж
SELECT 
    p.product_id,
    p.product_name,
    COALESCE(SUM(oi.qty), 0) AS total_qty
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_qty DESC, p.product_id ASC;

-- 7. Выручка по товарам
SELECT 
    p.product_id,
    p.product_name,
    COALESCE(SUM(oi.qty * oi.price), 0) AS revenue
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
ORDER BY revenue DESC;

-- 8. Клиенты и количество заказов
SELECT 
    c.client_id,
    c.full_name,
    COUNT(o.order_id) AS orders_count
FROM clients c
LEFT JOIN orders o ON c.client_id = o.client_id
GROUP BY c.client_id, c.full_name
ORDER BY orders_count DESC, c.client_id ASC;

-- 9. Paid-заказы: клиенты и сумма оплаченного
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
add.sql (✅ уже корректный для PostgreSQL)
sql
-- Этот файл уже полностью готов для pgAdmin!
-- SERIAL, CHECK, CASCADE, UNIQUE - все PostgreSQL синтаксис
-- Выполните как есть
v.sql (исправления: customers→clients, добавлены тестовые данные)
sql
-- Создание недостающих таблиц для тестов
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name TEXT,
    category TEXT,
    price NUMERIC(10,2)
);

CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    created_at DATE,
    status TEXT,
    total_amount NUMERIC(10,2)
);

CREATE TABLE IF NOT EXISTS customers (
    id SERIAL PRIMARY KEY,
    full_name TEXT,
    city TEXT
);

-- Тестовые данные
INSERT INTO products (name, category, price) VALUES
('iPhone 15', 'Electronics', 120000),
('MacBook Pro', 'Electronics', 200000),
('Чай', 'Food', 500),
('Кофе', 'Food', 800);

INSERT INTO orders (created_at, status, total_amount) VALUES
('2026-01-10', 'paid', 1100),
('2026-01-12', 'canceled', 300),
('2026-01-15', 'paid', 700),
('2026-01-11', 'paid', 650),
('2026-01-20', 'shipped', 500),
('2026-02-01', 'paid', 2000);

INSERT INTO customers (full_name, city) VALUES
('Иван Петров', 'Москва'),
('Анна Сидорова', 'СПб');

-- ✅ ИСПРАВЛЕННЫЕ ЗАПРОСЫ:
-- Задание 1
SELECT '1. Топ-2 самых дорогих товара' AS task;
SELECT id, name, category, price
FROM products
ORDER BY price DESC
LIMIT 2;

-- Задание 2  
SELECT '2. Вторая страница товаров (3-4)' AS task;
SELECT id, name, price
FROM products
ORDER BY price DESC, id DESC
LIMIT 2 OFFSET 2;

-- Задание 3
SELECT '3. Топ-3 заказов по сумме' AS task;
SELECT id, created_at, status, total_amount
FROM orders
ORDER BY total_amount DESC, id DESC
LIMIT 3;

-- Задание 4
SELECT '4. Третья страница заказов' AS task;
SELECT id, created_at, total_amount
FROM orders
ORDER BY created_at DESC, total_amount DESC, id DESC
LIMIT 2 OFFSET 4;

-- Задание 5
SELECT '5. Paid заказы (1 страница)' AS task;
SELECT id, created_at, status, total_amount
FROM orders
WHERE status = 'paid'
ORDER BY created_at DESC, total_amount DESC
LIMIT 2;

-- Задание 6 (customers -> clients)
SELECT '6. Клиенты (1 страница)' AS task;
SELECT id, full_name, city
FROM clients  -- Было customers
ORDER BY id ASC
LIMIT 2;
zapros.sql (исправления имен столбцов/таблиц)
sql
-- Основные исправления:
-- clients.id → clients.client_id
-- orders.id → orders.order_id  
-- order_date → created_at
-- title → product_name
-- order_items.id → order_items.order_item_id

-- БЛОК 1. ФИЛЬТРАЦИЯ
SELECT * FROM clients WHERE city = 'Москва';

SELECT * FROM products WHERE category = 'Electronics';

SELECT * FROM products WHERE price > 5000;

SELECT * FROM orders WHERE status = 'paid' AND created_at > '2026-01-01';

SELECT * FROM products WHERE product_name LIKE '%Ноутбук%' OR product_name LIKE '%Смартфон%';

SELECT * FROM products ORDER BY price DESC LIMIT 5;

SELECT * FROM products ORDER BY id LIMIT 4 OFFSET 4;

-- БЛОК 2. JOIN
SELECT o.order_id, o.created_at, o.status, c.full_name 
FROM orders o
INNER JOIN clients c ON o.client_id = c.client_id
ORDER BY o.order_id;

SELECT oi.order_id, p.product_name, oi.qty, oi.price
FROM order_items oi
INNER JOIN products p ON oi.product_id = p.product_id
ORDER BY oi.order_id;

SELECT c.* 
FROM clients c
LEFT JOIN orders o ON c.client_id = o.client_id
WHERE o.order_id IS NULL;

-- Остальные блоки требуют точной схемы ваших таблиц
-- Используйте \d+ tablename в psql для проверки структуры
🎯 ИНСТРУКЦИЯ ПО ИСПОЛЬЗОВАНИЮ:
Сначала выполните CREATE TABLE из моего предыдущего ответа

add.sql → копи-паст в Query Tool → F5

1.sql → по одному запросу (5-й исправлен!)

v.sql → целиком (создает тестовые данные)

zapros.sql → по блокам (проверьте имена столбцов через \d)
