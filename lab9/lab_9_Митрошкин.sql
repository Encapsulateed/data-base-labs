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






IF  EXISTS (SELECT *
FROM sys.objects
WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND type in (N'U'))
DROP TABLE [dbo].[Users]


CREATE TABLE Users
(
	userId INT PRIMARY KEY,
	fio NVARCHAR(255) NOT NULL,

	CONSTRAINT U_ID UNIQUE (userId),


);


IF  EXISTS (SELECT *
FROM sys.objects
WHERE object_id = OBJECT_ID(N'[dbo].[Addresses]') AND type in (N'U'))
DROP TABLE [dbo].[Addresses]
GO

CREATE TABLE Addresses
(
	userId INT,
	street NVARCHAR(255),
	city NVARCHAR(255),

	FOREIGN KEY (userId) REFERENCES Users(userId),
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
		RAISERROR('Некорректное ФИО!', 14, 3);
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
		RAISERROR('Такого пользователя не сущетсвует!',15,4)
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
DROP TRIGGER IF EXISTS insert_view_trigger
GO

DROP TRIGGER IF EXISTS update_view_tringger
GO

DROP TRIGGER IF EXISTS delete_view_tringger
GO

CREATE VIEW UserAddressView
AS
	SELECT u.userId, u.fio, adr.city , adr.street
	FROM Users AS u JOIN Addresses as adr ON u.userId = adr.userId
GO
-- Вставка 
CREATE TRIGGER insert_view_trigger ON UserAddressView INSTEAD OF INSERT AS
BEGIN

	IF EXISTS (SELECT 1
	FROM inserted
	WHERE userId IN (SELECT userId
	FROM users))
	BEGIN
		RAISERROR('Пользователь с таким id уже существует',16,5)
		ROLLBACK;
	END

	INSERT INTO users
		(userId, fio)
	SELECT userId, fio
	FROM inserted

	INSERT INTO Addresses
		(userId,street,city)
	SELECT userId, street, city
	FROM inserted

END;
GO
CREATE TRIGGER update_view_tringger ON UserAddressView INSTEAD OF UPDATE AS
BEGIN
	IF NOT EXISTS (SELECT 1
	FROM inserted
	WHERE userId IN (SELECT userId
	FROM users))
	BEGIN
		RAISERROR('Такого пользователя не сущетсвует!',10,6)
	END;


	IF(UPDATE(userId))
	BEGIN
		RAISERROR('Нельзя менять userId', 12,2)
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
	IF(UPDATE(city) )
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

	WITH
		DeletedAddresses
		AS
		(
			SELECT a.userId, a.street, a.city
			FROM deleted AS d
				INNER JOIN Addresses AS a ON d.userId = a.userId
		)
    DELETE FROM Addresses
    WHERE EXISTS (
        SELECT *
	FROM DeletedAddresses AS da
	WHERE Addresses.userId = da.userId
		AND Addresses.street = da.street
		AND Addresses.city = da.city
    );

	DELETE FROM Users
    WHERE EXISTS (
        SELECT *
	FROM deleted AS d
	WHERE Users.userId = d.userId
    );


END;

GO

/*
*/
INSERT INTO UserAddressView
	(userId,fio,city,street)
VALUES(1, 'Митрошкин Алексей Антонович', 'Москва', 'Пукшина 29'),
	(2, 'Митрошкин Алексей Антонович 2', 'Москва', 'Пукшина 30'),
	(3, 'Митрошкин Алексей Антонович 3', 'Москва', 'Пукшина 31'),
	(4, 'Митрошкин Алексей Антонович 4', 'Москва', 'Пукшина 32')





DELETE FROM UserAddressView WHERE userId = 2;

UPDATE UserAddressView SET fio = 'еблан ебланский гей' WHERE userId = 2;

-- 
SELECT *
FROM UserAddressView;


-- Select rows from a Table or View '[users]' in schema '[dbo]'
-- SELECT * FROM Users;



