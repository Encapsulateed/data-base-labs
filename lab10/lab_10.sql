USE master;
ALTER DATABASE [lab_10_db] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE [lab_10_db];

GO
CREATE DATABASE lab_10_db
ON 
( 
	NAME = lab_10_dat,
	FILENAME = 'C:\data-base-course\lab10dat.mdf',
	SIZE = 5, 
	MAXSIZE = UNLIMITED, 
	FILEGROWTH = 5
)
LOG
ON 
( 
	NAME = lab_10_log,
	FILENAME = 'C:\data-base-course\lab10log.log',
	SIZE = 5,
	MAXSIZE = UNLIMITED,
	FILEGROWTH = 5
);
GO


USE lab_10_db;



IF  EXISTS (SELECT *
FROM sys.objects
WHERE object_id = OBJECT_ID(N'[dbo].[events]') AND type in (N'U'))
DROP TABLE [dbo].[events]
GO

-- Создание тестовой таблицы
CREATE TABLE events
(
	eventId INT PRIMARY KEY,
	title VARCHAR(255) NOT NULL DEFAULT 'нет названия',
	descr VARCHAR(1000) NOT NULL DEFAULT 'нет описания'
);
INSERT INTO events
VALUES
	(1, 'Событие 1', 'Описание события 1'),
	(2, 'Событие 2', 'Описание события 2'),
	(3, 'Событие 3', 'Описание события 3');


-- READ UNCOMMITTED  читаем незакомиченные данные , которые могут быть изменены или удалены другой транзакцией, но еще не зафиксированы

-- READ COMMITTED читаем только закомиченные данные предотвращая грязное чтение. Однако, другие проблемы, 
-- такие как неповторяющееся чтение и фантомное чтение, могут возникнуть.

-- REPEATABLE READ предотвращает неповторяющееся чтение, гарантируя, что все считанные данные останутся неизменными в течение всей транзакции

-- SERIALIZABLE предоставляет максимальную степень изоляции, блокируя данные так, чтобы никакие другие транзакции не могли их изменить или считать

/*
-- ГРЯЗНОЕ ЧТЕНИЕ

BEGIN TRANSACTION
UPDATE events SET descr = 'Обновлённое описание 1' WHERE eventId = 1;

WAITFOR DELAY '00:00:05';

ROLLBACK;
SELECT * FROM events WHERE eventId =1 ;



-- НЕПОВТОРЯЮЩЕСЯ ЧТЕНИЕ

-- SET TRANSACTION ISOLATION LEVEL READ COMMITTED  -- получим 2 различных результата в SELECT т.к транзакция на изменение закомичена 
 SET TRANSACTION ISOLATION LEVEL REPEATABLE READ -- транзакция, которая пытается изменить данные ожидает завершения этой 
BEGIN TRANSACTION;

SELECT * 
FROM events
WHERE eventId = 1;

WAITFOR DELAY '00:00:10';

SELECT * 
FROM events
WHERE eventId = 1;

COMMIT;
*/
/**/

-- ФАНТОМНОЕ ЧТЕНИЕ 

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ -- получим 2 разных результата на SELECT, т.к вторая транзакция добавит строки
 --SET TRANSACTION ISOLATION LEVEL SERIALIZABLE  -- вторая транзакция будет ждать эту 
BEGIN TRAN;

SELECT *
FROM events;

WAITFOR DELAY '00:00:05'

SELECT *
FROM events;

COMMIT;



SELECT request_session_id, request_type, request_mode, resource_database_id FROM sys.dm_tran_locks
