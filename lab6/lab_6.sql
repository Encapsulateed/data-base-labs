USE master;
ALTER DATABASE [lab_6_db] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE [lab_6_db];

GO
-- Создание БД
CREATE DATABASE lab_6_db
ON 
( 
	NAME = lab_5_dat,
	FILENAME = 'C:\data-base-course\lab6dat.mdf',
	SIZE = 5, 
	MAXSIZE = UNLIMITED, 
	FILEGROWTH = 5
)
LOG
ON 
( 
	NAME = lab_5_log,
	FILENAME = 'C:\data-base-course\lab6log.log',
	SIZE = 5,
	MAXSIZE = UNLIMITED,
	FILEGROWTH = 5
);
GO

USE lab_6_db;

GO
IF  EXISTS (SELECT *
FROM sys.objects
WHERE object_id = OBJECT_ID(N'[dbo].[events]') AND type in (N'U'))
DROP TABLE [dbo].[events]

CREATE TABLE events
(
    eventId INT IDENTITY(1,1) PRIMARY KEY,
    title VARCHAR(255) NOT NULL DEFAULT 'нет названия',
    descr VARCHAR(1000) NOT NULL DEFAULT 'нет описания',
    phots_url VARCHAR (255) NOT NULL DEFAULT 'https://www.google.ru/',
    documents_url VARCHAR (255) NOT NULL DEFAULT 'https://www.google.ru/',
    begin_date DATE NOT NULL CHECK (begin_date <= (CONVERT(date,GETDATE()))),
    end_date DATE NOT NULL,
    event_place VARCHAR (255) NOT NULL DEFAULT 'https://www.google.ru/',

    CONSTRAINT data_compare CHECK (end_date >= CONVERT(date, begin_date))

);

IF  EXISTS (SELECT *
FROM sys.objects
WHERE object_id = OBJECT_ID(N'[dbo].[partners]') AND type in (N'U'))
DROP TABLE [dbo].[partners]
CREATE TABLE partners
(
    partnerID UNIQUEIDENTIFIER PRIMARY KEY DEFAULT (NEWSEQUENTIALID()),
    title VARCHAR(255) NOT NULL,
    photo_url VARCHAR(255) NOT NULL,
    parnter_url VARCHAR(255) NOT NULL
);

IF EXISTS (SELECT *
FROM sys.sequences
WHERE NAME = N'comand_id_sequence')
DROP SEQUENCE comand_id_sequence

CREATE SEQUENCE comand_id_sequence 
	START WITH 1
	INCREMENT BY 1;

IF  EXISTS (SELECT *
FROM sys.objects
WHERE object_id = OBJECT_ID(N'[dbo].[Comands]') AND type in (N'U'))
DROP TABLE [dbo].[Comands]

CREATE TABLE Comands
(
    ComandId INT PRIMARY KEY NOT NULL DEFAULT (NEXT VALUE FOR dbo.comand_id_sequence),
    title VARCHAR(255) NOT NULL,
);

IF  EXISTS (SELECT *
FROM sys.objects
WHERE object_id = OBJECT_ID(N'[dbo].[Participants]') AND type in (N'U'))
DROP TABLE [dbo].[Participants]

CREATE TABLE Participants
(
    ParticipantID INT PRIMARY KEY,
    fio VARCHAR(255),
    comandId INT NOT NULL,

    CONSTRAINT FK_Comands FOREIGN KEY (comandId) REFERENCES Comands (ComandId)
    ON DELETE CASCADE

);

/* тесты */
INSERT INTO Comands (title)  VALUES('Боевые коты'); -- 1
INSERT INTO Comands (title)  VALUES('Боевые коты 2'); -- 2

INSERT INTO Participants (ParticipantID, fio, comandId)  VALUES(0,'Вася Пупкин',1); 
INSERT INTO Participants (ParticipantID, fio, comandId)  VALUES(1,'Владимир Владимирович',1); 

INSERT INTO Participants (ParticipantID, fio, comandId)  VALUES(2,'Алексей Алекеев Алеексевич ',2); 
INSERT INTO Participants (ParticipantID, fio, comandId)  VALUES(3,'Бояринов Роман Николавевич',2); 


DELETE FROM Comands WHERE ComandId = 2;

SELECT TOP (1000) [ComandId]
      ,[title]
  FROM [lab_6_db].[dbo].[Comands]

SELECT TOP (1000) [ParticipantID]
      ,[fio]
      ,[comandId]
  FROM [lab_6_db].[dbo].[Participants]