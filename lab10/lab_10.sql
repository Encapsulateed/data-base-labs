
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

-- Очистка результатов предыдущих запусков
DBCC FREEPROCCACHE;
DBCC FREESYSTEMCACHE ('ALL');
DBCC FREESESSIONCACHE;


-- Создание тестовой таблицы
CREATE TABLE events (
    eventId INT PRIMARY KEY,
    title VARCHAR(255) NOT NULL DEFAULT 'нет названия',
    descr VARCHAR(1000) NOT NULL DEFAULT 'нет описания'
);

-- Заполнение тестовой таблицы данными
INSERT INTO events VALUES (1, 'Событие 1', 'Описание события 1'), (2, 'Событие 2', 'Описание события 2'), (3, 'Событие 3', 'Описание события 3');


-- Уровень изоляции: READ UNCOMMITTED
-- позволяет транзакции читать незафиксированные данные
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN TRANSACTION;
    SELECT * FROM events;
    SELECT request_session_id, request_type, request_mode, resource_database_id FROM sys.dm_tran_locks
COMMIT TRANSACTION;

-- Уровень изоляции: READ COMMITTED
-- гарантирует, что транзакция читает только зафиксированные данные, предотвращая грязное чтение
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION;
    SELECT * FROM events;
    SELECT request_session_id, request_type, request_mode, resource_database_id FROM sys.dm_tran_locks
COMMIT TRANSACTION;

-- Уровень изоляции: REPEATABLE READ
-- предотвращает неповторяющееся чтение, гарантируя, что все считанные данные останутся неизменными в течение всей транзакции
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;
    SELECT * FROM events;
    SELECT * FROM sys.dm_tran_locks WHERE request_session_id = @@SPID;
COMMIT TRANSACTION;

-- Уровень изоляции: SERIALIZABLE
-- блокирует данные так, чтобы никакие другие транзакции не могли их изменить или считать
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION;
    SELECT * FROM events;
    SELECT request_session_id, request_type, request_mode, resource_database_id FROM sys.dm_tran_locks
COMMIT TRANSACTION;
