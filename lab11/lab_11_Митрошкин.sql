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
    StartDateApplications DATETIME NOT NULL,
    ResultAnnouncementDate DATETIME NOT NULL,
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
    FROM Event))
    BEGIN
        RAISERROR('Такой EventId уже существует, вставка невозможна!',10,1)
        ROLLBACK;
    END;

    INSERT INTO Event
        (EventId,Name,Description, StartDate, EndDate, MediaMentionLink,PhotoAlbumLink,Venue)
    SELECT EventId, Name, Description, StartDate, EndDate, MediaMentionLink, PhotoAlbumLink, Venue
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
     IF UPDATE(Name) OR
       UPDATE(Description) OR
       UPDATE(PhotoAlbumLink) OR
       UPDATE(DocumentsLink) OR
       UPDATE(StartDate) OR
       UPDATE(EndDate) OR
       UPDATE(MediaMentionLink) OR
       UPDATE(Venue)
    BEGIN
        RAISERROR('Event fields are immutable throughout the view', 16, 1);
        RETURN;
    END;

    -- Обновление данных в ClassicEvent
    WITH UpdatedClassicEvent AS (
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
        e.StartDate, e.EndDate,
        e.MediaMentionLink, e.PhotoAlbumLink,
        e.Venue,
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
        (EventId,Name,Description, StartDate, EndDate, MediaMentionLink,PhotoAlbumLink,Venue)
    SELECT EventId, Name, Description, StartDate, EndDate, MediaMentionLink, PhotoAlbumLink, Venue
    FROM inserted;

    INSERT INTO Hardatons
        (EventId,ContestTaskLink,OrganizerMessage,OrganizerPhotoLink,StartDateApplications,ResultAnnouncementDate)
    SELECT ContestTaskLink, OrganizerMessage, OrganizerPhotoLink, StartDateApplications, ResultAnnouncementDate
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
        UPDATE(DocumentsLink) OR
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
    FOREIGN KEY (EventID) REFERENCES Event(EventID),
    FOREIGN KEY (PartnerID) REFERENCES Partner(PartnerID)
);


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


CREATE TABLE TeamEvent
(
    TeamId INTEGER,
    EventId INTEGER,
    PRIMARY KEY (TeamId, EventId),
    FOREIGN KEY (TeamId) REFERENCES Team(TeamId),
    FOREIGN KEY (EventId) REFERENCES Event(EventId)
);

CREATE TABLE Project
(
    ProjectId INTEGER PRIMARY KEY NOT NULL,
    EventId INTEGER,
    TeamId INTEGER,
    Name NVARCHAR(100) UNIQUE NOT NULL,
    Description NVARCHAR(500) NOT NULL,
    Photo NVARCHAR(2048) NULL,
    FOREIGN KEY (EventId) REFERENCES Event(EventId),
    FOREIGN KEY (TeamId) REFERENCES Team(TeamId)
);


ALTER TABLE Team
ADD CONSTRAINT FK_Team_Captain
FOREIGN KEY (Captain) REFERENCES Participant(ParticipantId) ON DELETE SET NULL;

ALTER TABLE Participant
ADD CONSTRAINT FK_Participant_Team
FOREIGN KEY (TeamId) REFERENCES Team(TeamId);


INSERT INTO Event
    (EventId,Name,Description,PhotoAlbumLink,DocumentsLink,StartDate,EndDate,Venue)
VALUES(
        1, 'ГЕЙ ТУСА', 'gaY PARTYY YEAH', 'WWW.GAY.RU', 'GAY.DOC', '2023-01-12', '2023-01-12', 'гей бар')


INSERT INTO ClassicEvent
    (EventId,RegistrationLink)
VALUES
    (1, 'геи.reg')

DELETE FROM ClassicEvent WHERE EventId = 1;

SELECT *
FROM Event;

SELECT *
from ClassicEvent;
