


USE master;
ALTER DATABASE [lab_5_db] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE [lab_5_db];


-- Создание БД

GO
CREATE DATABASE lab_5_db
ON 
( 
	NAME = lab_5_dat,
	FILENAME = 'C:\data-base-course\labdat.mdf',
	SIZE = 5, 
	MAXSIZE = UNLIMITED, 
	FILEGROWTH = 5
)
LOG
ON 
( 
	NAME = lab_5_log,
	FILENAME = 'C:\data-base-course\lablog.log',
	SIZE = 5,
	MAXSIZE = UNLIMITED,
	FILEGROWTH = 5
);
GO


USE lab_5_db;
GO

IF  EXISTS (SELECT *
FROM sys.objects
WHERE object_id = OBJECT_ID(N'[dbo].[partners]') AND type in (N'U'))
DROP TABLE [dbo].[partners]


-- Создание таблицы
CREATE TABLE partners
(
    partnerID INT PRIMARY KEY,
    title VARCHAR(255),
    photo_url VARCHAR(255),
    parnter_url VARCHAR(255)
);


-- Создание файловую группу и добавление в нее файла, чтобы она не была пустой
ALTER DATABASE lab_5_db
ADD FILEGROUP f_group;

ALTER DATABASE lab_5_db
ADD FILE
(
    NAME = file_txt,
    FILENAME = 'C:\data-base-course\file.txt',
    SIZE = 5,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10MB
)
TO FILEGROUP f_group;


-- Делаем файловой группой по умолчанию 
ALTER DATABASE lab_5_db
MODIFY FILEGROUP f_group DEFAULT;

-- Создание второй таблицы


IF  EXISTS (SELECT *
FROM sys.objects
WHERE object_id = OBJECT_ID(N'[dbo].[events]') AND type in (N'U'))
DROP TABLE [dbo].[events]

CREATE TABLE events
(
    eventId INT PRIMARY KEY,
    title VARCHAR(255),
    descr VARCHAR(1000),
    phots_url VARCHAR (255),
    documents_url VARCHAR (255),
    begin_date DATE,
    end_date DATE,
    event_place VARCHAR (255)
);

DROP TABLE events;

-- Уадление файловой группы 
USE master;
ALTER DATABASE lab_5_db
ADD FILEGROUP f_group2;
ALTER DATABASE lab_5_db
ADD FILE
(
    NAME = file_txt2,
    FILENAME = 'C:\data-base-course\file2.txt',
    SIZE = 5,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10MB
)
TO FILEGROUP f_group2;


ALTER DATABASE lab_5_db
MODIFY FILEGROUP f_group2 DEFAULT;

GO
ALTER DATABASE lab_5_db REMOVE FILE file_txt;
ALTER DATABASE lab_5_db REMOVE FILEGROUP f_group;

-- Создание схемы 
USE lab_5_db;
GO
DROP SCHEMA  IF EXISTS  my_schema 
GO

CREATE SCHEMA my_schema

GO

IF  EXISTS (SELECT *
FROM sys.objects
WHERE object_id = OBJECT_ID(N'[my_schema].[partners]') AND type in (N'U'))
DROP TABLE [my_schema].[partners]


GO
ALTER SCHEMA my_schema Transfer dbo.partners
GO
-- удаление схемы 

IF  EXISTS (SELECT *
FROM sys.objects
WHERE object_id = OBJECT_ID(N'[my_schema].[partners]') AND type in (N'U'))
DROP TABLE [my_schema].[partners]

DROP SCHEMA my_schema
GO