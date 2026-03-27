-- =============================================
-- Блок DDL: Создание таблиц
-- =============================================

-- Удаление таблиц, если они существуют (для чистоты выполнения скрипта)
DROP TABLE IF EXISTS Application;
DROP TABLE IF EXISTS Vacancy;
DROP TABLE IF EXISTS Candidate;
DROP TABLE IF EXISTS Interview_Stage;

-- 1. Справочник этапов собеседований
CREATE TABLE Interview_Stage (
    id SERIAL PRIMARY KEY,
    stage_name VARCHAR(100) NOT NULL UNIQUE,
    order_num INT NOT NULL -- Порядок прохождения этапов
);

-- 2. Таблица вакансий
CREATE TABLE Vacancy (
    id SERIAL PRIMARY KEY,
    title VARCHAR(150) NOT NULL,
    description TEXT,
    department VARCHAR(100),
    status VARCHAR(50) NOT NULL DEFAULT 'Open'
    -- Ограничение на допустимые статусы (Check Constraint)
    CONSTRAINT chk_vacancy_status CHECK (status IN ('Open', 'Closed', 'Frozen'))
);

-- 3. Таблица кандидатов
CREATE TABLE Candidate (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    phone VARCHAR(20) UNIQUE,
    email VARCHAR(100) UNIQUE NOT NULL,
    resume_link TEXT
);

-- 4. Таблица откликов (связующая)
CREATE TABLE Application (
    id SERIAL PRIMARY KEY,
    vacancy_id INT NOT NULL,
    candidate_id INT NOT NULL,
    stage_id INT NOT NULL,
    applied_date DATE NOT NULL DEFAULT CURRENT_DATE,
    interview_date DATE,
    feedback TEXT,
    
    -- Внешние ключи с политиками удаления/обновления
    CONSTRAINT fk_application_vacancy FOREIGN KEY (vacancy_id) 
        REFERENCES Vacancy(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_application_candidate FOREIGN KEY (candidate_id) 
        REFERENCES Candidate(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_application_stage FOREIGN KEY (stage_id) 
        REFERENCES Interview_Stage(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    
    -- Уникальность: один кандидат не может дважды откликнуться на одну вакансию
    CONSTRAINT unique_vacancy_candidate UNIQUE (vacancy_id, candidate_id)
);

-- =============================================
-- Блок DML: Наполнение таблиц (Демо-данные)
-- =============================================

-- Заполнение справочника этапов
INSERT INTO Interview_Stage (stage_name, order_num) VALUES
('Скрининг резюме', 1),
('Телефонное интервью', 2),
('Техническое интервью', 3),
('HR Интервью', 4),
('Оффер', 5),
('Резерв', 6);

-- Заполнение вакансий
INSERT INTO Vacancy (title, description, department, status) VALUES
('Senior Java Developer', 'Разработка высоконагруженных систем, знание Spring, Kafka.', 'IT Department', 'Open'),
('Product Manager', 'Управление продуктом, аналитика, опыт в FinTech.', 'Product Management', 'Open'),
('HR Generalist', 'Полный цикл найма, адаптация, кадровое делопроизводство.', 'HR Department', 'Closed'),
('DevOps Engineer', 'CI/CD, Kubernetes, AWS.', 'IT Department', 'Frozen');

-- Заполнение кандидатов
INSERT INTO Candidate (full_name, phone, email, resume_link) VALUES
('Иванов Иван Иванович', '+7-999-123-4567', 'ivan.ivanov@example.com', 'https://resumes.ru/ivanov.pdf'),
('Петрова Анна Сергеевна', '+7-999-234-5678', 'anna.petrova@example.com', 'https://resumes.ru/petrova.pdf'),
('Сидоров Алексей Владимирович', '+7-999-345-6789', 'alex.sidorov@example.com', 'https://resumes.ru/sidorov.pdf'),
('Козлова Екатерина Дмитриевна', '+7-999-456-7890', 'ekaterina.kozlova@example.com', 'https://resumes.ru/kozlova.pdf'),
('Николаев Дмитрий Петрович', '+7-999-567-8901', 'dmitry.nikolaev@example.com', 'https://resumes.ru/nikolaev.pdf');

-- Заполнение откликов (связей)
INSERT INTO Application (vacancy_id, candidate_id, stage_id, applied_date, interview_date, feedback) VALUES
-- Иванов откликнулся на Java Dev, сейчас на этапе Технического интервью
(1, 1, 3, '2024-03-10', '2024-03-18', 'Хорошее резюме, назначено тех. собеседование'),
-- Петрова откликнулась на Java Dev, получила оффер
(1, 2, 5, '2024-02-15', '2024-03-01', 'Отличный опыт, отправлен оффер'),
-- Сидоров откликнулся на Product Manager, прошел телефонное интервью, ждет следующее
(2, 3, 2, '2024-03-12', '2024-03-15', 'Коммуникабельный, передан на техническую часть'),
-- Козлова откликнулась на HR Generalist (вакансия закрыта, но отклик остался в истории)
(3, 4, 4, '2024-01-20', '2024-01-25', 'Собеседование пройдено, но вакансия заморожена'),
-- Николаев откликнулся на DevOps, сейчас на скрининге
(4, 5, 1, '2024-03-14', NULL, 'Ожидает проверки резюме'),
-- Дополнительная связь: Иванов также откликнулся на Product Manager (чтобы показать M:N)
(2, 1, 4, '2024-03-05', '2024-03-12', 'Рассматриваем как PM');

-- =============================================
-- Блок DQL: Проверочные запросы
-- =============================================

-- Запрос 1: Список активных вакансий с количеством откликнувшихся кандидатов
SELECT 
    v.title AS "Должность",
    v.department AS "Отдел",
    COUNT(a.id) AS "Кол-во кандидатов"
FROM Vacancy v
LEFT JOIN Application a ON v.id = a.vacancy_id
WHERE v.status = 'Open'
GROUP BY v.id, v.title, v.department
ORDER BY "Кол-во кандидатов" DESC;

-- Запрос 2: Воронка найма (количество кандидатов на каждом этапе для конкретной вакансии)
SELECT 
    s.stage_name AS "Этап собеседования",
    COUNT(a.id) AS "Количество кандидатов"
FROM Interview_Stage s
LEFT JOIN Application a ON s.id = a.stage_id
LEFT JOIN Vacancy v ON a.vacancy_id = v.id
WHERE v.title = 'Senior Java Developer' -- Фильтр по вакансии
GROUP BY s.id, s.stage_name
ORDER BY s.order_num;

-- Запрос 3: Детальная информация по кандидатам и их текущим этапам (с сортировкой по дате отклика)
SELECT 
    c.full_name AS "Кандидат",
    v.title AS "Вакансия",
    s.stage_name AS "Текущий этап",
    a.applied_date AS "Дата отклика",
    a.interview_date AS "Дата собеседования"
FROM Application a
JOIN Candidate c ON a.candidate_id = c.id
JOIN Vacancy v ON a.vacancy_id = v.id
JOIN Interview_Stage s ON a.stage_id = s.id
ORDER BY a.applied_date DESC;

-- Запрос 4: Кандидаты, которые проходят более одного собеседования (откликались на несколько вакансий)
SELECT 
    c.full_name AS "Кандидат",
    c.email AS "Email",
    COUNT(a.id) AS "Количество откликов"
FROM Candidate c
JOIN Application a ON c.id = a.candidate_id
GROUP BY c.id, c.full_name, c.email
HAVING COUNT(a.id) > 1;
