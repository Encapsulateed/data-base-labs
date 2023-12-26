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
WHERE NAME = N'user_id_sequence')
DROP SEQUENCE user_id_sequence

CREATE SEQUENCE user_id_sequence 
	START WITH 1
	INCREMENT BY 1;

IF EXISTS (SELECT *
FROM sys.sequences
WHERE NAME = N'address_id_sequence')
DROP SEQUENCE user_id_sequence

CREATE SEQUENCE address_id_sequence 
	START WITH 1
	INCREMENT BY 1;


IF  EXISTS (SELECT *
FROM sys.objects
WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND type in (N'U'))
DROP TABLE [dbo].[Users]


CREATE TABLE Users
(
	userId INT PRIMARY KEY NOT NULL DEFAULT (NEXT VALUE FOR dbo.user_id_sequence),
	fio NVARCHAR(255) NOT NULL,

);


IF  EXISTS (SELECT *
FROM sys.objects
WHERE object_id = OBJECT_ID(N'[dbo].[Addresses]') AND type in (N'U'))
DROP TABLE [dbo].[Addresses]
GO

CREATE TABLE Addresses
(
	AddressId INT PRIMARY KEY NOT NULL DEFAULT (NEXT VALUE FOR dbo.address_id_sequence),
	userId INT,
	street NVARCHAR(255),
	city NVARCHAR(255)

		FOREIGN KEY (userId) REFERENCES Users(userId)
		CONSTRAINT UC_UserId UNIQUE (userId),
	CONSTRAINT UC_uniqAdr UNIQUE (street,city)
);

-- 1. Для одной из таблиц пункта 2 задания 7 создать триггеры на вставку, удаление и обновления,
-- при выполнении заданных условий один из триггеров должен инициировать возникновение ошибки (RAISERROR / THROW).
GO
CREATE TRIGGER CheckFIO
ON Users
AFTER INSERT, UPDATE
AS
BEGIN
	IF EXISTS (
        SELECT 1
	FROM inserted
	WHERE NOT EXISTS (
            SELECT 1
	FROM STRING_SPLIT(fio, ' ')
	HAVING COUNT(value) IN (2, 3, 4)
        )
    )
    BEGIN
		RAISERROR('Некорректное ФИО!', 0, 1);
		ROLLBACK;
	END
END;

GO
CREATE TRIGGER delete_trigger
ON Users
INSTEAD OF DELETE
AS
BEGIN
	IF(NOT EXISTS(SELECT *
	FROM Users
	WHERE userId = (SELECT userId
	FROM deleted) ))
	BEGIN
		RAISERROR('Такого пользователя не сущетсвует!',0,1)
		ROLLBACK;
	END;
	UPDATE Users SET fio = '[Данные удалены]' WHERE userId = (SELECT userId
	FROM deleted)
END;

GO

-- 2. для представления пункта 2 задания 7 создать триггеры на вставку, удаление и обновление,
-- обеспечивающие возможность выполнения операций с данными непосредственно через представление.


GO
DROP VIEW IF EXISTS UserAddressView
GO

CREATE VIEW UserAddressView
AS
	SELECT u.userId, u.fio, adr.city , adr.street
	FROM Users AS u JOIN Addresses as adr ON u.userId = adr.userId
GO
-- Вставка 
CREATE TRIGGER insert_view_trigger ON UserAddressView INSTEAD OF INSERT AS
BEGIN

	DECLARE for_insert_cursor CURSOR FOR SELECT fio, street, city
	FROM inserted;
	DECLARE @fio NVARCHAR(255), @street NVARCHAR(255), @city NVARCHAR(255);


	OPEN for_insert_cursor;

	FETCH NEXT FROM for_insert_cursor INTO @fio, @street, @city;
	WHILE @@FETCH_STATUS = 0
    BEGIN
		-- Users
		INSERT INTO users
			(fio)
		VALUES(@fio)

		-- Addresses
		INSERT INTO Addresses
			(street,city,userId)
		VALUES(@street, @city, (SELECT CONVERT(INT,(SELECT current_value
					FROM sys.sequences
					WHERE name = 'user_id_sequence'))))

		FETCH NEXT FROM for_insert_cursor INTO @fio, @street, @city;
	END;

	CLOSE for_insert_cursor;
	DEALLOCATE for_insert_cursor;
END;

GO
CREATE TRIGGER update_view_tringger ON UserAddressView INSTEAD OF UPDATE AS
BEGIN
	IF(UPDATE(userId))
	BEGIN
		RAISERROR('Нельзя менять userId', 10,0)
		ROLLBACK;
	END;

	-- Users
	IF(UPDATE(fio))
	BEGIN
		UPDATE users SET fio = (SELECT fio
		FROM inserted) WHERE userId = (SELECT userId
		FROM inserted);
	END;

	-- Addresses
	IF(UPDATE(city))
	BEGIN
		UPDATE Addresses SET city = (SELECT city
		FROM inserted) WHERE userId = (SELECT userId
		FROM inserted);
	END;

	IF(UPDATE(street))
	BEGIN
		UPDATE Addresses SET street = (SELECT street
		FROM inserted) WHERE userId = (SELECT userId
		FROM inserted);
	END;

END;

GO

GO
CREATE TRIGGER delete_view_tringger ON UserAddressView INSTEAD OF DELETE AS
BEGIN
	DELETE FROM Users WHERE userId = (SELECT userId
	FROM deleted)

	DELETE FROM Addresses WHERE userId = (SELECT userId
	FROM deleted)

END;

GO


INSERT INTO UserAddressView
	(fio,city,street)
VALUES('Митрошкин Алексей Антонович', 'Москва', 'Пукшина 29'),
	('Митрошкин Алексей Антонович 2', 'Москва', 'Пукшина 30'),
	('Митрошкин Алексей Антонович 3', 'Москва', 'Пукшина 31'),
	('Митрошкин Алексей Антонович 4', 'Москва', 'Пукшина 32')


UPDATE UserAddressView SET fio = 'Токарев Иван' WHERE userId = 3;
UPDATE UserAddressView SET street = 'Yjdjjjasdjaslk0000' WHERE userId = 3;

DELETE FROM UserAddressView WHERE userId = 1;
SELECT *
FROM UserAddressView;