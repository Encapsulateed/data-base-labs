
USE lab_10_db;

/*
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
*/

-- dirty read

-- Транзакция 1
-- Изменение данных, но не зафиксировано
BEGIN TRANSACTION;
    UPDATE events SET title = 'Новое событие 1' WHERE eventId = 1;

    -- Пауза, чтобы другая транзакция могла прочитать данные
    WAITFOR DELAY '00:00:01';

-- Транзакция 2
-- Чтение данных из транзакции 1 (грязное чтение)
-- Она видит изменения, которые еще не были зафиксированы
-- Запрос блокируется, пока транзакция 1 не завершится
SELECT * FROM events;

-- Завершение транзакции 1 (фиксация изменений)
COMMIT TRANSACTION;


-- phantom read
-- Транзакция 1
-- Чтение данных из таблицы
BEGIN TRANSACTION;
    SELECT * FROM events;

    -- ждём, чтобы другая транзакция могла вставить новые строки
    WAITFOR DELAY '00:00:05';

-- Транзакция 2
-- Вставка новых строк
BEGIN TRANSACTION;
    INSERT INTO events VALUES (4, 'Событие 4', 'Описание события 4');
    INSERT INTO events VALUES (5, 'Событие 5', 'Описание события 5');
COMMIT TRANSACTION;

-- Завершение транзакции 1
COMMIT TRANSACTION;

-- Транзакция 3
-- Чтение данных из таблицы после вставки новых строк в транзакции 2 (фантомное чтение)
SELECT * FROM events;


-- nonrepeatable read

-- Транзакция 1
-- Чтение данных из таблицы
BEGIN TRANSACTION;
    SELECT * FROM events;

-- Транзакция 2
-- Изменение данных, читаемых первой транзакцией
BEGIN TRANSACTION;
    UPDATE events SET title = 'Новое событие 1' WHERE eventId = 1;
COMMIT TRANSACTION;

-- Завершение транзакции 1
COMMIT TRANSACTION;

-- Чтение данных из таблицы после изменения в транзакции 2 (неповторяющееся чтение)
SELECT * FROM events;

-- Очистка: Удаление таблицы events
DROP TABLE events;
