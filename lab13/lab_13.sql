USE master;
ALTER DATABASE [lab_13_1_db] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE [lab_13_1_db];

ALTER DATABASE [lab_13_2_db] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE [lab_13_2_db];


GO
CREATE DATABASE lab_13_1_db
ON 
( 
	NAME = lab_10_dat,
	FILENAME = 'C:\data-base-course\lab131dat.mdf',
	SIZE = 5, 
	MAXSIZE = UNLIMITED, 
	FILEGROWTH = 5
)
LOG
ON 
( 
	NAME = lab_10_log,
	FILENAME = 'C:\data-base-course\lab131log.log',
	SIZE = 5,
	MAXSIZE = UNLIMITED,
	FILEGROWTH = 5
);
GO

GO
CREATE DATABASE lab_13_2_db
ON 
( 
	NAME = lab_10_dat,
	FILENAME = 'C:\data-base-course\lab132dat.mdf',
	SIZE = 5, 
	MAXSIZE = UNLIMITED, 
	FILEGROWTH = 5
)
LOG
ON 
( 
	NAME = lab_10_log,
	FILENAME = 'C:\data-base-course\lab132log.log',
	SIZE = 5,
	MAXSIZE = UNLIMITED,
	FILEGROWTH = 5
);


--2. Создать в базах данных п.1. горизонтально фрагментированные таблицы.

USE lab_13_1_db
IF  EXISTS (SELECT *
FROM sys.objects
WHERE object_id = OBJECT_ID(N'[dbo].[events]') AND type in (N'U'))
DROP TABLE [dbo].[events]
GO

CREATE TABLE events
(
	eventId INT PRIMARY KEY CHECK (eventId < 5),
	title VARCHAR(255) NOT NULL DEFAULT 'нет названия',
	descr VARCHAR(1000) NOT NULL DEFAULT 'нет описания'
);



GO

USE lab_13_2_db
IF  EXISTS (SELECT *
FROM sys.objects
WHERE object_id = OBJECT_ID(N'[dbo].[events]') AND type in (N'U'))
DROP TABLE [dbo].[events]
GO

CREATE TABLE events
(
	eventId INT PRIMARY KEY CHECK (eventId >= 5),
	title VARCHAR(255) NOT NULL DEFAULT 'нет названия',
	descr VARCHAR(1000) NOT NULL DEFAULT 'нет описания'
);



--3. Создать секционированные представления, обеспечивающие работу с данными таблиц
--(выборку, вставку, изменение, удаление).

GO
DROP VIEW IF EXISTS my_events_vies
GO

EXEC sp_serveroption 'DESKTOP-N89AMNR', 'lazy schema validation', 'true';
GO
CREATE VIEW my_events_vies
AS
			SELECT *
		FROM lab_13_1_db.dbo.events
	UNION ALL
		SELECT *
		FROM lab_13_2_db.dbo.events;
GO

INSERT INTO my_events_vies
VALUES
	(1, 'Событие 1', 'Описание события 1 1'),
	(2, 'Событие 2', 'Описание события 3 1'),
	(3, 'новое событие 3', 'УРА СОБЫТИЕ 2'),
	(4, 'Событие 4', 'Описание события 1 1'),
	(5, 'Событие 5', 'Описание события 3 1'),
	(6, 'новое событие 6', 'УРА СОБЫТИЕ 2'),
	(7, 'Событие 7', 'Описание события 1 1'),
	(8, 'Событие 8', 'Описание события 3 1'),
	(9, 'новое событие 9', 'УРА СОБЫТИЕ 2')


-- SELECT * FROM my_events_vies;

UPDATE my_events_vies SET descr = 'ЭТО СОБЫТИЕ БЫЛО УДАЛЕНО ИЗ-ЗА НАРУШЕНИЯ АВТОРСКИХ ПРАВ!' WHERE eventId = 1;
UPDATE my_events_vies SET title = '[ДАННЫЕ УДАЛЕНЫ]' WHERE eventId = 1;
UPDATE my_events_vies SET eventId = 10 WHERE eventId = 1;



-- SELECT * FROM my_events_vies;

DELETE FROM lab_13_1_db.dbo.events WHERE eventId = 5;

SELECT *
FROM lab_13_1_db.dbo.events;

SELECT *
FROM lab_13_2_db.dbo.events;

SELECT *
FROM my_events_vies;