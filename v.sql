-- =============================================
-- Задания по пагинации, сортировке и фильтрации данных
-- Студент: Величко А.С.
-- Дата: 27.03.2026
-- =============================================

-- =============================================
-- Задание 1. Топ-2 самых дорогих товара
-- Вывести: id, name, category, price
-- Сортировка: по price по убыванию
-- =============================================

SELECT 
    id,
    name,
    category,
    price
FROM products
ORDER BY price DESC
LIMIT 2;

-- =============================================
-- Задание 2. "Вторая страница" товаров (по 2 товара на страницу)
-- Вывести: id, name, price
-- Сортировка: price DESC, id DESC
-- Показать страницу 2 (товары 3–4 по порядку)
-- =============================================

SELECT 
    id,
    name,
    price
FROM products
ORDER BY price DESC, id DESC
LIMIT 2 OFFSET 2;

-- =============================================
-- Задание 3. Топ-3 заказов по сумме
-- Вывести: id, created_at, status, total_amount
-- Сортировка: total_amount DESC, id DESC
-- Взять первые 3 строки
-- =============================================

SELECT 
    id,
    created_at,
    status,
    total_amount
FROM orders
ORDER BY total_amount DESC, id DESC
LIMIT 3;

-- =============================================
-- Задание 4. "Третья страница" заказов (по 2 заказа на страницу)
-- Вывести: id, created_at, total_amount
-- Сортировка: created_at DESC, total_amount DESC, id DESC
-- Показать страницу 3 (OFFSET 4, LIMIT 2)
-- =============================================

SELECT 
    id,
    created_at,
    total_amount
FROM orders
ORDER BY created_at DESC, total_amount DESC, id DESC
LIMIT 2 OFFSET 4;

-- =============================================
-- Задание 5. Заказы со статусом paid: первая страница (по 2)
-- Вывести: id, created_at, status, total_amount
-- Фильтр: status = 'paid'
-- Сортировка: created_at DESC, total_amount DESC
-- Показать первую страницу (2 строки)
-- =============================================

SELECT 
    id,
    created_at,
    status,
    total_amount
FROM orders
WHERE status = 'paid'
ORDER BY created_at DESC, total_amount DESC
LIMIT 2;

-- =============================================
-- Задание 6. Пагинация клиентов (по 2 на страницу)
-- Вывести: id, full_name, city
-- Сортировка: id ASC
-- Показать первую страницу
-- =============================================

SELECT 
    id,
    full_name,
    city
FROM customers
ORDER BY id ASC
LIMIT 2;

-- =============================================
-- Конец скрипта
-- =============================================

-- =============================================
-- Единый скрипт с использованием CTE для наглядности
-- =============================================

-- Задание 1
SELECT '1. Топ-2 самых дорогих товара' AS task;
SELECT id, name, category, price
FROM products
ORDER BY price DESC
LIMIT 2;

-- Задание 2
SELECT '2. Вторая страница товаров (товары 3-4)' AS task;
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
SELECT '4. Третья страница заказов (заказы 5-6)' AS task;
SELECT id, created_at, total_amount
FROM orders
ORDER BY created_at DESC, total_amount DESC, id DESC
LIMIT 2 OFFSET 4;

-- Задание 5
SELECT '5. Заказы со статусом paid (первая страница)' AS task;
SELECT id, created_at, status, total_amount
FROM orders
WHERE status = 'paid'
ORDER BY created_at DESC, total_amount DESC
LIMIT 2;

-- Задание 6
SELECT '6. Пагинация клиентов (первая страница)' AS task;
SELECT id, full_name, city
FROM customers
ORDER BY id ASC
LIMIT 2;
