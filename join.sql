USE master;
DROP DATABASE IF EXISTS lab_J_db;

-- Создание БД
CREATE DATABASE lab_J_db
ON 
( 
	NAME = lab_J_dat,
	FILENAME = 'C:\data-base-course\labJdat.mdf',
	SIZE = 5, 
	MAXSIZE = UNLIMITED, 
	FILEGROWTH = 5
)
LOG
ON 
( 
	NAME = lab_J_log,
	FILENAME = 'C:\data-base-course\labJlog.log',
	SIZE = 5,
	MAXSIZE = UNLIMITED,
	FILEGROWTH = 5
);
go
USE lab_J_db;
IF  EXISTS (SELECT *
FROM sys.objects
WHERE object_id = OBJECT_ID(N'[dbo].[T1]') AND type in (N'U'))
DROP TABLE [dbo].[T1]

IF  EXISTS (SELECT *
FROM sys.objects
WHERE object_id = OBJECT_ID(N'[dbo].[T2]') AND type in (N'U'))
DROP TABLE [dbo].[T2]

CREATE TABLE T1
(
    C1 INTEGER,
    C2 NVARCHAR(2048) NOT NULL,
);

CREATE TABLE T2
(
    C3 NVARCHAR(2048),
    C4 INTEGER,


);

INSERT INTO T1
    (C1,C2)
VALUES
    (1, 'a'),
    (2, 'a'),
    (3, 'b'),
    (4, 'c'),
    (4, 'd')

INSERT INTO T2
    (C4,C3)
VALUES
    (2, 'a'),
    (7, 'b'),
    (5, 'b'),
    (8, 'c'),
    (9, 'd')


SELECT * FROM T1 INNER JOIN T2 ON t1.C2=t2.C3;

SELECT *FROM T1 LEFT OUTER JOIN T2 ON t1.C2=t2.C3;

SELECT*FROM T1 RIGHT OUTER JOIN T2 ON t1.C2=t2.C3;

SELECT *FROM T1 FULL OUTER JOIN T2 ON t1.C2=t2.C3
