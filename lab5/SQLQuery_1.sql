

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


-- Создание таблицы 
CREATE TABLE partners
(
    partnerID INT PRIMARY KEY,
    title VARCHAR(255),
    photo_url VARCHAR(255),
    parnter_url VARCHAR(255)
);
GO

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
GO

-- Делаем файловой группой по умолчанию 
ALTER DATABASE lab_5_db
MODIFY FILEGROUP f_group DEFAULT;

-- Создание второй таблицы
GO

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

-- Уадление файловой группы 
GO

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

GO
ALTER DATABASE lab_5_db
MODIFY FILEGROUP f_group2 DEFAULT;


ALTER DATABASE lab_5_db
REMOVE FILE f_group;

ALTER DATABASE lab_5_db
REMOVE FILEGROUP f_group;

-- Создание схемы 
GO
CREATE SCHEMA my_shechema

GO
ALTER SCHEMA my_shechema Transfer dbo.partners
-- удаление схемы 
DROP SCHEMA my_shechema
GO