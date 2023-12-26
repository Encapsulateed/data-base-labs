USE master;
ALTER DATABASE [lab_9_db] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE [lab_9_db];
GO
-- Создание БД
CREATE DATABASE lab_9_db
ON 
( 
	NAME = lab_9_dat,
	FILENAME = 'C:\data-base-course\lab9dat.mdf',
	SIZE = 5, 
	MAXSIZE = UNLIMITED, 
	FILEGROWTH = 5
)
LOG
ON 
( 
	NAME = lab_9_log,
	FILENAME = 'C:\data-base-course\lab9log.log',
	SIZE = 5,
	MAXSIZE = UNLIMITED,
	FILEGROWTH = 5
);
GO

USE lab_9_db;


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
GO

CREATE TABLE Participants
(
	ParticipantID INT IDENTITY(1,1) PRIMARY KEY ,
	fio NVARCHAR(255),
	comandId INT NOT NULL,
	CONSTRAINT FK_Comand FOREIGN KEY (comandId) REFERENCES Comands (ComandId)
    ON DELETE CASCADE
);


GO
DROP VIEW IF EXISTS ComandParticipantsView
GO

CREATE VIEW ComandParticipantsView
AS
	SELECT comand.ComandId, participant.ParticipantID, comand.title, participant.fio
	FROM Comands AS comand JOIN Participants as participant ON comand.ComandId = participant.comandId
GO

-- 1. Для одной из таблиц пункта 2 задания 7 создать триггеры на вставку, удаление и обновления,
-- при выполнении заданных условий один из триггеров должен инициировать возникновение ошибки (RAISERROR / THROW).

DROP TRIGGER IF EXISTS CheckFIO;
DROP TRIGGER IF EXISTS delete_participant_trigger;
DROP TRIGGER IF EXISTS update_view_tringger;
DROP TRIGGER IF EXISTS delete_view_tringger;

GO

CREATE TRIGGER CheckFIO
ON Participants
AFTER INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	IF EXISTS (
        SELECT 1
	FROM INSERTED
	WHERE NOT EXISTS (
            SELECT 1
	FROM STRING_SPLIT(fio, ' ')
	HAVING COUNT(value) IN (2, 3, 4)
        )
    )
    BEGIN
		RAISERROR('Некорректное ФИО!', 16, 1);
		ROLLBACK;
	END
END;
GO
CREATE TRIGGER delete_trigger
ON Participants
FOR DELETE
AS
BEGIN
	DECLARE @fio NVARCHAR(255);
	SET NOCOUNT ON;

	DECLARE delete_cursor CURSOR FOR
    SELECT fio
	FROM deleted;

	OPEN delete_cursor;

	FETCH NEXT FROM delete_cursor INTO @fio;

	WHILE @@FETCH_STATUS = 0
    BEGIN
		PRINT 'Участник [' + @fio + '] удалён!';
		FETCH NEXT FROM delete_cursor INTO @fio;
	END

	CLOSE delete_cursor;
	DEALLOCATE delete_cursor;

END;

GO



-- 2. для представления пункта 2 задания 7 создать триггеры на вставку, удаление и обновление,
-- обеспечивающие возможность выполнения операций с данными непосредственно через представление.

-- Вставка 
GO
CREATE TRIGGER insert_view_tringger ON ComandParticipantsView INSTEAD OF INSERT AS 
BEGIN
	INSERT INTO Comands
		(title)
	SELECT title
	FROM inserted

	INSERT INTO Participants
		(fio,comandId )
	SELECT fio, CONVERT(INT,(SELECT current_value
		FROM sys.sequences
		WHERE name = 'comand_id_sequence'))
	from inserted;
END
GO

-- Обновление 
GO
CREATE TRIGGER update_view_tringger ON ComandParticipantsView INSTEAD OF UPDATE AS 
BEGIN
	IF(UPDATE(comandId) OR UPDATE(ParticipantID))
	BEGIN
		RAISERROR('запрещено обновлять ID!',10,0)
		ROLLBACK;
	END;

	UPDATE Comands
    SET title = (SELECT title
	FROM inserted) WHERE ComandId = (SELECT ComandId
	FROM inserted);

	UPDATE Participants
    SET fio = (SELECT fio
	FROM inserted) WHERE ParticipantID = (SELECT ParticipantID
	FROM inserted);

END
GO

-- Удаление 
CREATE TRIGGER delete_view_tringger ON ComandParticipantsView INSTEAD OF DELETE AS 
BEGIN

	print (SELECT * FROM deleted)
	DELETE FROM Comands WHERE ComandId IN (SELECT ComandId
	FROM deleted)

END

GO

INSERT INTO Comands
	(title)
VALUES('Команда 1');
-- 1
INSERT INTO Comands
	(title)
VALUES('Команда 2');


INSERT INTO Participants
	( fio, comandId)
VALUES('Митрошкин Алексей', 1);
INSERT INTO Participants
	( fio, comandId)
VALUES('Токарев Иван', 1);


INSERT INTO Participants
	( fio, comandId)
VALUES('Василий Пупкин', 2);
INSERT INTO Participants
	( fio, comandId)
VALUES('Дмитрий Дмитриев', 2);

/*
INSERT INTO Participants
	( fio, comandId)
VALUES('Гречко', 1);
*/
-- Выдаст ошибку по триггеру на вставку 

--DELETE FROM Participants WHERE ParticipantID >0;

--DELETE FROM ComandParticipantsView WHERE ComandId = 2;
DELETE FROM ComandParticipantsView WHERE ParticipantID = 4;

SELECT *
FROM ComandParticipantsView;

