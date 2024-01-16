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
USE lab_11_db;

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

CREATE TABLE Event
(
    EventId INTEGER PRIMARY KEY NOT NULL,
    Name NVARCHAR(150) UNIQUE NOT NULL,
    Description NVARCHAR(1000) NOT NULL,
    PhotoAlbumLink NVARCHAR(2048) NOT NULL,
    DocumentsLink NVARCHAR(2048) NOT NULL,
    StartDate DATETIME NOT NULL CHECK (StartDate <= EndDate AND StartDate BETWEEN '2023-01-01' AND '2999-12-31'),
    EndDate DATETIME NOT NULL CHECK (StartDate <= EndDate AND EndDate BETWEEN '2023-01-01' AND '2999-12-31'),
    MediaMentionLink NVARCHAR(2048) DEFAULT 'cmr.bmstu.ru',
    Venue NVARCHAR(2048) NOT NULL
);

CREATE TABLE Hardatons
(
    EventId INTEGER PRIMARY KEY NOT NULL,
    StartDateApplications DATETIME NOT NULL CHECK (StartDateApplications <= ResultAnnouncementDate AND StartDateApplications BETWEEN '2023-01-01' AND '2999-12-31'),
    ResultAnnouncementDate DATETIME NOT NULL CHECK (StartDateApplications <= ResultAnnouncementDate AND ResultAnnouncementDate BETWEEN '2023-01-01' AND '2999-12-31'),
    OrganizerPhotoLink NVARCHAR(2048) NULL,
    OrganizerMessage NVARCHAR(MAX) NULL,
    ContestTaskLink NVARCHAR(300) NOT NULL,
    FOREIGN KEY (EventId) REFERENCES Event(EventId)
);

CREATE TABLE ClassicEvent
(
    EventId INTEGER PRIMARY KEY NOT NULL,
    RegistrationLink NVARCHAR(2048) NOT NULL,
    FOREIGN KEY (EventId) REFERENCES Event(EventId)
);


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


CREATE TABLE Participant
(
    ParticipantId INTEGER PRIMARY KEY NOT NULL,
    TeamId INTEGER,
    Nickname NVARCHAR(100) UNIQUE NOT NULL,
    FullName NVARCHAR(200) NOT NULL,
    GroupName NVARCHAR(10) NOT NULL,
    Specialization NVARCHAR(30) NULL,
    FOREIGN KEY (TeamId) REFERENCES Team(TeamId) ON DELETE SET NULL
);


CREATE TABLE Team
(
    TeamId INTEGER PRIMARY KEY NOT NULL,
    Captain INTEGER,
    Name NVARCHAR(20) UNIQUE NOT NULL,
    Motto NVARCHAR(100) NULL,
    FOREIGN KEY (Captain) REFERENCES Participant(ParticipantID) ON DELETE SET NULL
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


