USE lab_13_1_db
IF  EXISTS (SELECT *
FROM sys.objects
WHERE object_id = OBJECT_ID(N'[dbo].[partners]') AND type in (N'U'))
DROP TABLE [dbo].[partners]
GO

CREATE TABLE partners
(
	partnerId INT PRIMARY KEY NOT NULL,
	title VARCHAR(255) NOT NULL DEFAULT 'нет названия',
);

INSERT INTO partners
VALUES
	(1, 'Партнёр 1 1'),
	(2, 'Партнёр 2 1'),
	(3, 'Партнёр 3 1')


USE lab_13_2_db
IF  EXISTS (SELECT *
FROM sys.objects
WHERE object_id = OBJECT_ID(N'[dbo].[partners]') AND type in (N'U'))
DROP TABLE [dbo].[partners]
GO

CREATE TABLE partners
(
	partnerId INT PRIMARY KEY NOT NULL,
	link VARCHAR(300) NOT NULL DEFAULT 'goole.com'
);

INSERT INTO partners
VALUES
	(1, 'https://t.me/parnter12'),
	(2, 'https://t.me/parnter22'),
	(3, 'https://t.me/parnter32')


--2. Создать необходимые элементы базы данных (представления, триггеры), обеспечивающие работу
--с данными вертикально фрагментированных таблиц (выборку, вставку, изменение, удаление).

GO
DROP VIEW IF EXISTS my_parnters_view
GO

CREATE VIEW my_parnters_view
AS
	SELECT one.partnerId, one.title, two.link
	FROM lab_13_1_db.dbo.partners AS one JOIN lab_13_2_db.dbo.partners AS two
		ON one.partnerId = two.partnerId;

GO



DROP TRIGGER IF EXISTS insert_trigger;
DROP TRIGGER IF EXISTS update_trigger;
DROP TRIGGER IF EXISTS delete_trigger;

GO

CREATE TRIGGER insert_trigger  ON my_parnters_view INSTEAD OF INSERT AS 
BEGIN
	INSERT INTO lab_13_1_db.dbo.partners
	SELECT partnerId, title
	FROM inserted;

	INSERT INTO lab_13_2_db.dbo.partners
	SELECT partnerId, link
	FROM inserted;

END
GO

CREATE TRIGGER update_trigger  ON my_parnters_view INSTEAD OF UPDATE AS 
BEGIN
	IF (UPDATE(title))
	BEGIN
		UPDATE lab_13_1_db.dbo.partners SET title = (SELECT title
		FROM inserted
		WHERE inserted.partnerId = lab_13_1_db.dbo.partners.partnerId)
				  WHERE (EXISTS (SELECT *
		FROM inserted
		WHERE (lab_13_1_db.dbo.partners.partnerId = inserted.partnerId AND link IS NOT NULL)));
	END;

	IF (UPDATE(link))
	BEGIN
		UPDATE lab_13_2_db.dbo.partners SET link = (SELECT link
		FROM inserted
		WHERE inserted.partnerId = lab_13_2_db.dbo.partners.partnerId)

		WHERE (EXISTS (SELECT *
		FROM inserted
		WHERE (lab_13_2_db.dbo.partners.partnerId = inserted.partnerId AND title IS NOT NULL)));
	END;

END
GO

CREATE TRIGGER delete_trigger  ON my_parnters_view INSTEAD OF DELETE AS 
BEGIN
	DELETE lab_13_1_db.dbo.partners WHERE EXISTS(SELECT*
	FROM deleted
	WHERE lab_13_1_db.dbo.partners.partnerId = deleted.partnerId)

	DELETE lab_13_2_db.dbo.partners WHERE EXISTS(SELECT*
	FROM deleted
	WHERE lab_13_2_db.dbo.partners.partnerId = deleted.partnerId)
END
GO




INSERT my_parnters_view
	(partnerId,title,link)
VALUES
	(5, 'новый партнёр ', 'новый партнёр.com')

UPDATE my_parnters_view SET link = 'upd.link.com' WHERE partnerId = 5;


SELECT *
FROM my_parnters_view;

DELETE FROM my_parnters_view WHERE partnerId = 5;


SELECT *
FROM my_parnters_view