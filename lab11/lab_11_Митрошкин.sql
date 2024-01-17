USE master;
ALTER DATABASE [lab_11_db] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE [lab_11_db];
GO
-- Создание БД
CREATE DATABASE lab_11_db
ON 
( 
	NAME = lab_11_dat,
	FILENAME = 'C:\data-base-course\lab11dat.mdf',
	SIZE = 5, 
	MAXSIZE = UNLIMITED, 
	FILEGROWTH = 5
)
LOG
ON 
( 
	NAME = lab_11_log,
	FILENAME = 'C:\data-base-course\lab11log.log',
	SIZE = 5,
	MAXSIZE = UNLIMITED,
	FILEGROWTH = 5
);
GO

/*
1. Создать базу данных, спроектированную в рамках лабораторной работы №4, используя изученные в лабораторных работах
5-10 средства SQL Server 2012:
- поддержания создания и физической организации базы данных;
- различных категорий целостности;
- представления и индексы;
- хранимые процедуры, функции и триггеры;

2. Создание объектов базы данных должно осуществляться средствами DDL (CREATE/ALTER/DROP), в обязательном порядке
иллюстрирующих следующие аспекты:
- добавление и изменение полей;
- назначение типов данных;
- назначение ограничений целостности (PRIMARY KEY, NULL/NOT NULL/UNIQUE, CHECK и т.п.);
- определение значений по умолчанию;
*/
USE lab_11_db;

IF  EXISTS (SELECT *
FROM sys.objects
WHERE object_id = OBJECT_ID(N'[dbo].[Event]') AND type in (N'U'))
DROP TABLE [dbo].[Event]

IF  EXISTS (SELECT *
FROM sys.objects
WHERE object_id = OBJECT_ID(N'[dbo].[Hardatons]') AND type in (N'U'))
DROP TABLE [dbo].[Hardatons]

IF  EXISTS (SELECT *
FROM sys.objects
WHERE object_id = OBJECT_ID(N'[dbo].[ClassicEvent]') AND type in (N'U'))
DROP TABLE [dbo].[ClassicEvent]


IF  EXISTS (SELECT *
FROM sys.objects
WHERE object_id = OBJECT_ID(N'[dbo].[Partner]') AND type in (N'U'))
DROP TABLE [dbo].[Partner]



IF  EXISTS (SELECT *
FROM sys.objects
WHERE object_id = OBJECT_ID(N'[dbo].[EventPartner]') AND type in (N'U'))
DROP TABLE [dbo].[EventPartner]


IF  EXISTS (SELECT *
FROM sys.objects
WHERE object_id = OBJECT_ID(N'[dbo].[Project]') AND type in (N'U'))
DROP TABLE [dbo].[Project]

IF  EXISTS (SELECT *
FROM sys.objects
WHERE object_id = OBJECT_ID(N'[dbo].[Team]') AND type in (N'U'))
DROP TABLE [dbo].[Team]

IF  EXISTS (SELECT *
FROM sys.objects
WHERE object_id = OBJECT_ID(N'[dbo].[Participant]') AND type in (N'U'))
DROP TABLE [dbo].[Participant]

IF  EXISTS (SELECT *
FROM sys.objects
WHERE object_id = OBJECT_ID(N'[dbo].[TeamEvent]') AND type in (N'U'))
DROP TABLE [dbo].[TeamEvent]


DROP TRIGGER IF EXISTS trg_insert_classicEvent;

DROP TRIGGER IF EXISTS trg_update_classicEvent

DROP TRIGGER IF EXISTS trg_delete_classicEvent

DROP TRIGGER IF EXISTS trg_insert_hardaton;

DROP TRIGGER IF EXISTS trg_update_hardaton;

DROP TRIGGER IF EXISTS trg_delete_hardaton;
CREATE TABLE Event
(
    EventId INTEGER PRIMARY KEY NOT NULL,
    Name NVARCHAR(150) UNIQUE NOT NULL,
    Description NVARCHAR(1000) NOT NULL,
    PhotoAlbumLink NVARCHAR(2048) NOT NULL,
    DocumentsLink NVARCHAR(2048) NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    MediaMentionLink NVARCHAR(2048) DEFAULT 'cmr.bmstu.ru',
    Venue NVARCHAR(2048) NOT NULL,
    CONSTRAINT CHK_StartEndDates CHECK (StartDate <= EndDate),
    CONSTRAINT CHK_ValidStartDate CHECK (StartDate BETWEEN '2023-01-01' AND '2999-12-31'),
    CONSTRAINT CHK_ValidEndDate CHECK (EndDate BETWEEN '2023-01-01' AND '2999-12-31')
);

CREATE TABLE ClassicEvent
(
    EventId INTEGER PRIMARY KEY NOT NULL,
    RegistrationLink NVARCHAR(2048) NOT NULL,
    FOREIGN KEY (EventId) REFERENCES Event(EventId) ON DELETE CASCADE
);

CREATE TABLE Hardatons
(
    EventId INTEGER PRIMARY KEY NOT NULL,
    StartDateApplications DATE NOT NULL,
    ResultAnnouncementDate DATE NOT NULL,
    OrganizerPhotoLink NVARCHAR(2048) NULL,
    OrganizerMessage NVARCHAR(MAX) NULL,
    ContestTaskLink NVARCHAR(300) NOT NULL,
    CONSTRAINT CHK_ValidDates CHECK (StartDateApplications <= ResultAnnouncementDate AND StartDateApplications BETWEEN '2023-01-01' AND '2999-12-31'),
    FOREIGN KEY (EventId) REFERENCES Event(EventId) ON DELETE CASCADE
);


GO
DROP VIEW IF EXISTS EventClassicEventView
GO

CREATE VIEW EventClassicEventView
AS
    SELECT e.EventID,
        e.Name,
        e.Description,
        e.StartDate,
        e.EndDate,
        e.MediaMentionLink,
        e.PhotoAlbumLink,
        e.DocumentsLink,
        e.Venue,
        ce.RegistrationLink
    FROM Event AS e JOIN ClassicEvent AS ce ON e.EventId = ce.EventId
GO

GO
CREATE TRIGGER trg_insert_classicEvent ON  EventClassicEventView INSTEAD OF INSERT
AS
    BEGIN
    IF EXISTS(SELECT 1
    FROM Event
    WHERE EventId IN (SELECT EventId
    FROM inserted))
    BEGIN
        RAISERROR('Такой EventId уже существует, вставка невозможна!',10,1)
        ROLLBACK;
    END;

    INSERT INTO Event
        (EventId,Name,Description, StartDate, EndDate, MediaMentionLink,PhotoAlbumLink,Venue,DocumentsLink)
    SELECT EventId, Name, Description, StartDate, EndDate, MediaMentionLink, PhotoAlbumLink, Venue, DocumentsLink
    FROM inserted;

    INSERT INTO ClassicEvent
        (EventId,RegistrationLink)
    SELECT EventId, RegistrationLink
    FROM inserted;
END 

GO
CREATE TRIGGER trg_delete_classicEvent ON EventClassicEventView INSTEAD OF DELETE
AS
BEGIN
    IF NOT EXISTS(SELECT 1
    FROM Event
    WHERE EventId IN (SELECT EventId
    FROM Event))
    BEGIN
        RAISERROR('Такой EventId не существует, удаление невозможно ',10,2)
        ROLLBACK;
    END;


    DELETE FROM Event WHERE EventId IN (SELECT EventId
    FROM deleted)
END
GO

CREATE TRIGGER trg_update_classicEvent ON EventClassicEventView INSTEAD OF UPDATE AS
BEGIN
    IF NOT EXISTS(SELECT 1
    FROM Event
    WHERE EventId IN (SELECT EventId
    FROM inserted))
    BEGIN
        RAISERROR('Такой EventId не существует, обновление невозможно ',10,2)
        ROLLBACK;
    END;

    IF(UPDATE(EventId))
    BEGIN
        RAISERROR('Поле EventId недоступно для изменения!',10,3)
        ROLLBACK;
    END;
    IF UPDATE([Name]) OR
        UPDATE([Description]) OR
        UPDATE(PhotoAlbumLink) OR
        UPDATE(StartDate) OR
        UPDATE(EndDate) OR
        UPDATE(MediaMentionLink) OR
        UPDATE(Venue)
    BEGIN
        RAISERROR('Event fields are immutable throughout the view', 16, 1);
        RETURN;
    END;

    -- Обновление данных в ClassicEvent
    WITH
        UpdatedClassicEvent
        AS
        (
            SELECT
                CE.EventId,
                CE.RegistrationLink
            FROM INSERTED I
                INNER JOIN ClassicEvent CE ON I.EventId = CE.EventId
        )
    UPDATE CE
    SET
        RegistrationLink = U.RegistrationLink
    FROM ClassicEvent CE
        INNER JOIN UpdatedClassicEvent U ON CE.EventId = U.EventId;

END

GO
DROP VIEW IF EXISTS EventHardatonView
GO

CREATE VIEW EventHardatonView
AS
    SELECT e.EventID,
        e.Name,
        e.Description,
        e.StartDate,
        e.EndDate,
        e.MediaMentionLink,
        e.PhotoAlbumLink,
        e.Venue,
        e.DocumentsLink,
        h.ContestTaskLink,
        h.OrganizerMessage,
        h.OrganizerPhotoLink,
        h.StartDateApplications,
        h.ResultAnnouncementDate
    FROM Event AS e JOIN Hardatons AS h ON e.EventId = h.EventId
GO

GO
CREATE TRIGGER trg_insert_hardaton ON  EventHardatonView INSTEAD OF INSERT
AS
    BEGIN
    IF EXISTS(SELECT 1
    FROM Event
    WHERE EventId IN (SELECT EventId
    FROM Event))
    BEGIN
        RAISERROR('Такой EventId уже существует, вставка невозможна!',10,1)
        ROLLBACK;

    END;

    INSERT INTO Event
        (EventId,[Name],[Description], StartDate, EndDate, MediaMentionLink,PhotoAlbumLink,Venue,DocumentsLink)
    SELECT EventId, [Name], [Description], StartDate, EndDate, MediaMentionLink, PhotoAlbumLink, Venue, DocumentsLink
    FROM inserted;

    INSERT INTO Hardatons
        (EventId,ContestTaskLink,OrganizerMessage,OrganizerPhotoLink,StartDateApplications,ResultAnnouncementDate)
    SELECT EventId, ContestTaskLink, OrganizerMessage, OrganizerPhotoLink, StartDateApplications, ResultAnnouncementDate
    FROM inserted;
END 

GO
CREATE TRIGGER trg_delete_hardaton ON EventHardatonView INSTEAD OF DELETE
AS
BEGIN
    IF NOT EXISTS(SELECT 1
    FROM Event
    WHERE EventId IN (SELECT EventId
    FROM Event))
    BEGIN
        RAISERROR('Такой EventId не существует, удаление невозможно ',10,2)
        ROLLBACK;
    END;


    DELETE FROM Event WHERE EventId IN (SELECT EventId
    FROM deleted)
END
GO

CREATE TRIGGER trg_update_hardaton ON EventHardatonView INSTEAD OF UPDATE AS
BEGIN
    IF NOT EXISTS(SELECT 1
    FROM Event
    WHERE EventId IN (SELECT EventId
    FROM inserted))
    BEGIN
        RAISERROR('Такой EventId не существует, обновление невозможно ',10,2)
        ROLLBACK;
    END;

    IF(UPDATE(EventId))
    BEGIN
        RAISERROR('Поле EventId недоступно для изменения!',10,3)
        ROLLBACK;
    END;

    IF UPDATE(Name) OR
        UPDATE(Description) OR
        UPDATE(PhotoAlbumLink) OR
        UPDATE(StartDate) OR
        UPDATE(EndDate) OR
        UPDATE(MediaMentionLink) OR
        UPDATE(Venue)
    BEGIN
        RAISERROR('Поля мероприятий неизменяемы во всем представлении.', 16, 1);
        RETURN;
    END;

    -- Обновление данных в Hardatons
    WITH
        UpdatedHardatons
        AS
        (
            SELECT
                H.EventId,
                H.StartDateApplications,
                H.ResultAnnouncementDate,
                H.OrganizerPhotoLink,
                H.OrganizerMessage,
                H.ContestTaskLink
            FROM INSERTED I
                INNER JOIN Hardatons H ON I.EventId = H.EventId
        )
    UPDATE H
    SET
        StartDateApplications = U.StartDateApplications,
        ResultAnnouncementDate = U.ResultAnnouncementDate,
        OrganizerPhotoLink = U.OrganizerPhotoLink,
        OrganizerMessage = U.OrganizerMessage,
        ContestTaskLink = U.ContestTaskLink
    FROM Hardatons H
        INNER JOIN UpdatedHardatons U ON H.EventId = U.EventId;

END

GO

CREATE TABLE Partner
(
    PartnerID INTEGER PRIMARY KEY NOT NULL,
    Name NVARCHAR(100) UNIQUE NOT NULL,
    Photo NVARCHAR(2048) NOT NULL,
    WebsiteLink NVARCHAR(2048) NOT NULL
);

CREATE TABLE EventPartner
(
    EventID INTEGER,
    PartnerID INTEGER,
    PRIMARY KEY (EventID, PartnerID),
    FOREIGN KEY (EventID) REFERENCES Event(EventID) ON DELETE CASCADE,
    FOREIGN KEY (PartnerID) REFERENCES Partner(PartnerID) ON DELETE CASCADE
);

DROP TRIGGER IF EXISTS trg_update_eventPartnert

GO
CREATE TRIGGER trg_update_eventPartnert ON EventPartner FOR UPDATE 
AS 
BEGIN
    IF(UPDATE(EventID) OR UPDATE(PartnerID))
    BEGIN
        RAISERROR('Эти поля недопступны для изменения',5,2);
        ROLLBACK;
    END;
END
GO

CREATE TABLE Team
(
    TeamId INTEGER PRIMARY KEY NOT NULL,
    Captain INTEGER,
    Name NVARCHAR(20) UNIQUE NOT NULL,
    Motto NVARCHAR(100) NULL,

);

CREATE TABLE Participant
(
    ParticipantId INTEGER PRIMARY KEY NOT NULL,
    TeamId INTEGER,
    Nickname NVARCHAR(100) UNIQUE NOT NULL,
    FullName NVARCHAR(200) NOT NULL,
    GroupName NVARCHAR(10) NOT NULL,
    Specialization NVARCHAR(30) NULL,
);

ALTER TABLE Team
ADD CONSTRAINT FK_Team_Captain
FOREIGN KEY (Captain) REFERENCES Participant(ParticipantId) ON DELETE SET NULL;

ALTER TABLE Participant
ADD CONSTRAINT FK_Participant_Team
FOREIGN KEY (TeamId) REFERENCES Team(TeamId) ON DELETE SET NULL;

CREATE TABLE TeamEvent
(
    TeamId INTEGER,
    EventId INTEGER,
    PRIMARY KEY (TeamId, EventId),
    FOREIGN KEY (TeamId) REFERENCES Team(TeamId) ON DELETE CASCADE,
    FOREIGN KEY (EventId) REFERENCES Event(EventId) ON DELETE CASCADE
);

GO
use lab_11_db;
CREATE TABLE Project
(
    ProjectId INTEGER PRIMARY KEY NOT NULL,
    EventId INTEGER,
    TeamId INTEGER,
    Name NVARCHAR(100) UNIQUE NOT NULL,
    Description NVARCHAR(500) NOT NULL,
    Photo NVARCHAR(2048) NULL,
    FOREIGN KEY (EventId) REFERENCES Event(EventId) on DELETE CASCADE,
    FOREIGN KEY (TeamId) REFERENCES Team(TeamId) ON DELETE CASCADE
);

DROP TRIGGER IF EXISTS trg_update_project

GO

DROP TRIGGER IF EXISTS trg_update_teamEvent 

GO
CREATE TRIGGER trg_update_teamEvent ON TeamEvent FOR UPDATE
AS 
BEGIN
    IF(UPDATE(TeamId) OR UPDATE(EventId))
    BEGIN
        RAISERROR('Эти поля недопступны для изменения',5,2);
        ROLLBACK;
    END;
END
GO


-- ТЕСТЫ 
/*
3. В рассматриваемой базе данных должны быть тем или иным образом (в рамках объектов базы данных или дополнительно)
созданы запросы DML для:
- выборки записей (команда SELECT);
- добавления новых записей (команда INSERT), как с помощью непосредственного указания значений, так и с помощью команды
SELECT;
- модификации записей (команда UPDATE);
- удаления записей (команда DELETE);
*/


INSERT INTO EventHardatonView
    (EventID, Name,[Description],PhotoAlbumLink,DocumentsLink,StartDate,EndDate,MediaMentionLink,Venue,StartDateApplications,ResultAnnouncementDate,OrganizerPhotoLink,OrganizerMessage,ContestTaskLink)
VALUES(
        1, 'Хардатон 2024. Весна', 'Весенее инженерное соревнование', 'https://github.com/Encapsulateed', 'https://github.com/Encapsulateed',
        '2024-05-01', '2024-05-29', 'https://github.com/Encapsulateed', 'БАУМАНКА ГЗ', '2024-05-10', '2024-05-20', 'https://github.com/Encapsulateed', 'Удачи вам ребята!', 'https://github.com/Encapsulateed'

    ),
    (
        2, 'Хардатон 2024. Зима', 'Зимнее инженерное соревнование', 'https://github.com/Encapsulateed', 'https://github.com/Encapsulateed',
        '2024-12-01', '2024-12-29', 'https://github.com/Encapsulateed', 'БАУМАНКА УЛК', '2024-12-10', '2024-12-20', 'https://github.com/Encapsulateed', 'Удачи вам ребята!', 'https://github.com/Encapsulateed'

    ),
    (
        3, 'Хардатон 2025. Весна', 'Весенее инженерное соревнование', 'https://github.com/Encapsulateed', 'https://github.com/Encapsulateed',
        '2025-05-01', '2025-05-29', 'https://github.com/Encapsulateed', 'БАУМАНКА ГЗ', '2025-05-10', '2025-05-20', 'https://github.com/Encapsulateed', 'Удачи вам ребята!', 'https://github.com/Encapsulateed'

    ),
    (
        4, 'Хардатон 2025. Зима', 'Зимнее инженерное соревнование', 'https://github.com/Encapsulateed', 'https://github.com/Encapsulateed',
        '2025-12-01', '2025-12-29', 'https://github.com/Encapsulateed', 'БАУМАНКА УЛК', '2025-12-10', '2025-12-20', 'https://github.com/Encapsulateed', 'Удачи вам ребята!', 'https://github.com/Encapsulateed'

    )


INSERT INTO EventClassicEventView
    (EventID, Name,[Description],PhotoAlbumLink,DocumentsLink,StartDate,EndDate,MediaMentionLink,Venue,RegistrationLink)
VALUES(
        5, 'Митап программистов C#', 'Весенений митап C# разработчиков', 'https://github.com/Encapsulateed', 'https://github.com/Encapsulateed',
        '2024-05-01', '2024-05-29', 'https://github.com/Encapsulateed', 'БАУМАНКА ГЗ', 'https://github.com/Encapsulateed'
    ),
    (
        6, 'Митап программистов Python', 'Весенений митап Python разработчиков', 'https://github.com/Encapsulateed', 'https://github.com/Encapsulateed',
        '2024-05-01', '2024-05-29', 'https://github.com/Encapsulateed', 'БАУМАНКА ГЗ', 'https://github.com/Encapsulateed'
    ),
    (
        7, 'Митап программистов', 'Весенений митап GoLang разработчиков', 'https://github.com/Encapsulateed', 'https://github.com/Encapsulateed',
        '2024-05-01', '2024-05-29', 'https://github.com/Encapsulateed', 'БАУМАНКА ГЗ', 'https://github.com/Encapsulateed'
    ),
    (
        8, 'Митап программистов Dart', 'Весенений митап Dart разработчиков', 'https://github.com/Encapsulateed', 'https://github.com/Encapsulateed',
        '2024-05-01', '2024-05-29', 'https://github.com/Encapsulateed', 'БАУМАНКА ГЗ', 'https://github.com/Encapsulateed'
    ),
    (
        9, 'Митап программистов FTL', 'Весенений митап любителей ТФЯ', 'https://github.com/Encapsulateed', 'https://github.com/Encapsulateed',
        '2024-05-01', '2024-05-29', 'https://github.com/Encapsulateed', 'БАУМАНКА ГЗ', 'https://github.com/Encapsulateed'
    )


INSERT INTO Partner
    (PartnerID,Name,Photo,WebsiteLink)
VALUES(1, 'Рос Нефть', 'https://github.com/Encapsulateed', 'https://github.com/Encapsulateed'),
    (2, 'Рос Телеком', 'https://github.com/Encapsulateed', 'https://github.com/Encapsulateed'),
    (3, 'Рос Авиация', 'https://github.com/Encapsulateed', 'https://github.com/Encapsulateed'),
    (4, 'Рос Тех', 'https://github.com/Encapsulateed', 'https://github.com/Encapsulateed')


INSERT INTO EventPartner
    (EventID,PartnerID)
VALUES
    (1, 1),
    (1, 2),
    (1, 3),
    (1, 4),

    (2, 1),
    (2, 2),
    (2, 3),
    (2, 4),

    (3, 1),
    (3, 2),
    (3, 3),
    (3, 4),

    (4, 1),
    (4, 2),
    (4, 3),
    (4, 4),

    (5, 1),
    (5, 2),
    (5, 3),
    (5, 4),

    (6, 1),
    (6, 2),
    (6, 3),
    (6, 4),

    (7, 1),
    (7, 2),
    (7, 3),
    (7, 4),

    (8, 1),
    (8, 2),
    (8, 3),
    (8, 4)

INSERT INTO Team
    (TeamId,Name,Motto)
VALUES
    (1, 'Команда 1', 'Мы команда номер раз, всех победим!'),
    ( 2, 'Команда 2', 'Мы команда номер два, всех победим!')
INSERT INTO Participant
    (ParticipantId,TeamId,Nickname,FullName,GroupName,Specialization)
VALUES
    (1, 1, 'rideua', 'Куйвашев Дмитрий', 'Иу9-51Б', 'Программист'),
    (2, 1, 'rideua1', 'Куйвашев Дмитрий', 'Иу9-51Б', 'Программист1'),
    (3, 2, 'rideua2', 'Куйвашев Дмитрий', 'Иу9-51Б', 'Программист2'),
    (4, 2, 'rideua3', 'Куйвашев Дмитрий', 'Иу9-51Б', 'Программист3')


INSERT INTO Participant
    (ParticipantId,Nickname,FullName,GroupName,Specialization)
VALUES
    (5, 'encaps', 'Митрошкин Алексей', 'Иу9-51Б', 'Программист'),
    (6, 'encaps2', 'Митрошкин Алексей', 'Иу9-51Б', 'Программист1')


INSERT INTO Project
    (ProjectId,EventId,TeamId,Name,[Description],Photo)
VALUES
    (1, 1, 1, 'Проект 1', 'Супер проект', 'https://github.com/Encapsulateed'),
    (2, 1, 1, 'Проект 2', 'Супер проект 2', 'https://github.com/Encapsulateed'),
    (3, 3, 2, 'Проект 3', 'Супер проект 3', 'https://github.com/Encapsulateed'),
    (4, 4, 2, 'Проект 4', 'Супер проект 4', 'https://github.com/Encapsulateed')

INSERT INTO TeamEvent
    (TeamId,EventId)
VALUES(
        1, 1
),
    (2, 4)

--SELECT *FROM EvenяClassicEventView
--SELECT * FROM Partner



-- 4. Запросы, созданные в рамках пп.2,3 должны иллюстрировать следующие возможности языка:

GO
-- выбор, упорядочивание и именование полей (создание псевдонимов для полей и таблиц / представлений);
SELECT
    name AS n,
    Photo AS ph
FROM Partner;

GO
-- соединение таблиц JOIN

SELECT e.name, p.name
FROM Event AS e JOIN Project AS p ON e.EventId = p.EventId

GO
-- условия выбора записей (в том числе, условия / LIKE / BETWEEN / IN / EXISTS);

SELECT name
FROM Event
WHERE Name LIKE 'Хардатон%'

SELECT name
FROM Event
WHERE StartDate BETWEEN '2025-01-01' AND '2026-01-01'

SELECT name
From Team AS T
WHERE EXISTS(SELECT 1
FROM Project AS p
where T.TeamId = p.TeamId)


-- сортировка записей (ORDER BY - ASC, DESC);

SELECT *
FROM EventHardatonView
ORDER BY StartDate DESC;

-- группировка записей (GROUP BY + HAVING, использование функций агрегирования COUNT / AVG / SUM / MIN / MAX);

SELECT T.Name AS TeamName, COUNT(P.ParticipantId) AS ParticipantCount
FROM Team T
    JOIN Participant P ON T.TeamId = P.TeamId
GROUP BY T.TeamId, T.Name
HAVING COUNT(P.ParticipantId) >= 2
ORDER BY T.Name;


-- объединение результатов нескольких запросов (UNION / UNION ALL / EXCEPT / INTERSECT);

    SELECT Nickname
    FROM Participant AS p
    WHERE p.TeamId IS NULL
UNION ALL
    SELECT Name
    FROM Project AS p 