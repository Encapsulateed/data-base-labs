
USE master;
ALTER DATABASE [lab_8_db] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE [lab_8_db];

GO
-- Создание БД
CREATE DATABASE lab_8_db
ON 
( 
	NAME = lab_8_dat,
	FILENAME = 'C:\data-base-course\lab8dat.mdf',
	SIZE = 5, 
	MAXSIZE = UNLIMITED, 
	FILEGROWTH = 5
)
LOG
ON 
( 
	NAME = lab_8_log,
	FILENAME = 'C:\data-base-course\lab8log.log',
	SIZE = 5,
	MAXSIZE = UNLIMITED,
	FILEGROWTH = 5
);
GO

USE lab_8_db;

IF  EXISTS (SELECT *
FROM sys.objects
WHERE object_id = OBJECT_ID(N'[dbo].[events]') AND type in (N'U'))
DROP TABLE [dbo].[events]

CREATE TABLE events
(
    eventId INT PRIMARY KEY,
    title VARCHAR(255) NOT NULL DEFAULT 'нет названия',
    descr VARCHAR(1000) NOT NULL DEFAULT 'нет описания',
    phots_url VARCHAR (255) NOT NULL DEFAULT 'https://www.google.ru/',
    documents_url VARCHAR (255) NOT NULL DEFAULT 'https://www.google.ru/',
    event_place VARCHAR (255) NOT NULL DEFAULT 'https://www.google.ru/',
);

INSERT INTO events
    (eventId,title,descr)
VALUES
    (1, 'Хакатон', 'Крутой хакатон')
INSERT INTO events
    (eventId,title,descr)
VALUES
    (2, 'Митап', 'Крутой Митап')
INSERT INTO events
    (eventId,title,descr)
VALUES
    (3, 'Велозаезд', 'Крутой Велозаезд')

INSERT INTO events
    (eventId)
VALUES
    (4)

DROP PROCEDURE IF EXISTS GetEventData
-- Создать курсор для выборки 
GO
-- Создаем хранимую процедуру
CREATE PROCEDURE GetEventData
AS
BEGIN
    -- Объявляем курсор
    DECLARE @EventCursor CURSOR;

    -- Создаем курсор, который будет хранить результат выборки
    SET @EventCursor = CURSOR FOR
    SELECT eventId, title, descr
    FROM events;

    -- Открываем курсор
    OPEN @EventCursor;

    -- Объявляем переменные для хранения данных курсора
    DECLARE @EventID INT, @Title NVARCHAR(255), @Descr NVARCHAR(255);

    -- Инициализируем курсор
    FETCH NEXT FROM @EventCursor INTO @EventID, @Title, @Descr;

    -- Перебираем результаты и выводим на экран
    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT 'EventID: ' + CAST(@EventID AS NVARCHAR(10)) + ', Title: ' + @Title + ', Descr: ' + @Descr;
        FETCH NEXT FROM @EventCursor INTO @EventID, @Title, @Descr;
    END;

    -- Закрываем курсор
    CLOSE @EventCursor;

    -- Удаляем курсор
    DEALLOCATE @EventCursor;
END;
GO

EXEC GetEventData;

/*
 2. Модифицировать хранимую процедуру п.1. таким
 образом, чтобы выборка осуществлялась с
 формированием столбца, значение которого
 формируется пользовательской функцией.
 */

DROP FUNCTION IF EXISTS dbo.makeHTML
DROP PROCEDURE IF EXISTS GetEventDataWithHtml

GO
CREATE FUNCTION dbo.makeHTML(@title NVARCHAR(255),@descr NVARCHAR(255)) 
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @result NVARCHAR(1024);

    -- Выполняем конкатенацию строк
    SET @result = '<div> <h1>' + @title + '</h1>' +'<p> ' +@descr+ '</p></div>';

    -- Возвращаем результат
    RETURN @result;
END;
GO

CREATE PROCEDURE GetEventDataWithHTML
AS
BEGIN
    -- Объявляем курсор
    DECLARE @EventCursor CURSOR;

    -- Создаем курсор, который будет хранить результат выборки
    SET @EventCursor = CURSOR FOR
    SELECT eventId, title, dbo.makeHTML(title,descr) AS html
    FROM events;

    -- Открываем курсор
    OPEN @EventCursor;

    -- Объявляем переменные для хранения данных курсора
    DECLARE @EventID INT, @Title NVARCHAR(255), @html NVARCHAR(255);

    -- Инициализируем курсор
    FETCH NEXT FROM @EventCursor INTO @EventID, @Title, @html;

    -- Перебираем результаты и выводим на экран
    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT 'EventID: ' + CAST(@EventID AS NVARCHAR(10)) + ', Title: ' + @Title + ', html: ' + @html;
        FETCH NEXT FROM @EventCursor INTO @EventID, @Title, @html;
    END;

    -- Закрываем курсор
    CLOSE @EventCursor;

    -- Удаляем курсор
    DEALLOCATE @EventCursor;
END;
GO

EXEC GetEventDataWithHTML;


/*
 3. Создать хранимую процедуру, вызывающую процедуру
 п.1., осуществляющую прокрутку возвращаемого
 курсора и выводящую сообщения, сформированные из
 записей при выполнении условия, заданного еще одной
 пользовательской функцией.
*/

DROP FUNCTION IF EXISTS dbo.isEmpty
DROP PROCEDURE IF EXISTS PrintNotEmptyEnvents
GO

CREATE FUNCTION dbo.isEmpty(@title NVARCHAR(255),@descr NVARCHAR(255)) 
RETURNS BIT
AS
BEGIN
    DECLARE @result NVARCHAR(1024);
    SET @result = 0;

    IF @title = 'нет названия' AND @descr = 'нет описания'
       SET @result = 1;
    -- Возвращаем результат
    RETURN @result;
END;

GO
CREATE PROCEDURE PrintNotEmptyEnvents
AS
BEGIN
    -- Объявляем курсор
    DECLARE @EventCursor CURSOR;

    -- Создаем курсор, который будет хранить результат выборки
    SET @EventCursor = CURSOR FOR
    SELECT eventId, title, descr
    FROM events;

    -- Открываем курсор
    OPEN @EventCursor;

    -- Объявляем переменные для хранения данных курсора
    DECLARE @EventID INT, @Title NVARCHAR(255), @Descr NVARCHAR(255);

    -- Инициализируем курсор
    FETCH NEXT FROM @EventCursor INTO @EventID, @Title, @Descr;

    -- Перебираем результаты и выводим на экран
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF(dbo.isEmpty(@Title,@Descr) = 0)
        PRINT 'EventID: ' + CAST(@EventID AS NVARCHAR(10)) + ', Title: ' + @Title + ', Descr: ' + @Descr;
        FETCH NEXT FROM @EventCursor INTO @EventID, @Title, @Descr;
    END;

    -- Закрываем курсор
    CLOSE @EventCursor;

    -- Удаляем курсор
    DEALLOCATE @EventCursor;
END;
GO
EXEC PrintNotEmptyEnvents;

-- 4. Модифицировать хранимую процедуру п.2. таким
-- образом, чтобы выборка формировалась с помощью
-- табличной функции.

DROP FUNCTION IF EXISTS dbo.IdCompare
DROP PROCEDURE IF EXISTS PrintEventEvents

GO

CREATE FUNCTION dbo.GetEvenEvents ()
RETURNS table AS
RETURN (
	SELECT eventId, title, descr FROM events WHERE eventId % 2 = 0
)

GO
CREATE PROCEDURE PrintEventEvents
AS
BEGIN
    -- Объявляем курсор
    DECLARE @EventCursor CURSOR;

    -- Создаем курсор, который будет хранить результат выборки
    SET @EventCursor =  CURSOR FORWARD_ONLY STATIC FOR
        SELECT *
        FROM dbo.GetEvenEvents();


    -- Открываем курсор
    OPEN @EventCursor;

    -- Объявляем переменные для хранения данных курсора
    DECLARE @EventID INT, @Title NVARCHAR(255), @Descr NVARCHAR(255);

    -- Инициализируем курсор
    FETCH NEXT FROM @EventCursor INTO @EventID, @Title, @Descr;

    -- Перебираем результаты и выводим на экран
    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT 'EventID: ' + CAST(@EventID AS NVARCHAR(10)) + ', Title: ' + @Title + ', Descr: ' + @Descr;
        FETCH NEXT FROM @EventCursor INTO @EventID, @Title, @Descr;
    END;

    -- Закрываем курсор
    CLOSE @EventCursor;

    -- Удаляем курсор
    DEALLOCATE @EventCursor;
END;
GO

EXEC PrintEventEvents;