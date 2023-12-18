

USE lab_6_db;

-- 1. Создать представление на основе одной из таблиц задания 6.
GO
DROP VIEW IF EXISTS EmptyEventsView
GO
CREATE VIEW EmptyEventsView
AS
    SELECT *
    FROM events
    WHERE events.descr = 'нет описания' AND events.title ='нет названия'
        AND events.phots_url = 'https://www.google.ru/'
        AND events.documents_url = 'https://www.google.ru/'
        AND events.event_place = 'https://www.google.ru/'; 

GO

-- 2. Создать представление на основе полей обеих связанных таблиц задания 6.

GO
DROP VIEW IF EXISTS ComandParticipantsView
GO

CREATE VIEW ComandParticipantsView
AS
    SELECT comand.title, participant.fio
    FROM Comands AS comand JOIN Participants as participant ON comand.ComandId = participant.comandId
    

GO

-- 3. Создать индекс для одной из таблиц задания 6, включив в него дополнительные неключевые поля.
DROP INDEX IF EXISTS EventIndex ON events;

CREATE INDEX EventIndex ON 
    events(eventId)
INCLUDE
    (event_place)


-- 4. Создать индексированное представление.
GO
DROP VIEW IF EXISTS FullComandsView
GO
CREATE VIEW FullComandsView
WITH
    SCHEMABINDING
-- связь таблицы и представления
AS
    
    SELECT comandId, title
    FROM dbo.Comands as com
    WHERE  com.ComandId > 3

GO
DROP INDEX IF EXISTS FullComandsView_index ON FullComandsView;
CREATE UNIQUE CLUSTERED INDEX FullComandsView_index ON FullComandsView(comandId) 