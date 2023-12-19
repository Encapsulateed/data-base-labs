--1. Создать в базах данных пункта 1 задания 13 связанные таблицы.
USE lab_13_1_db

IF  EXISTS (SELECT *
FROM sys.objects
WHERE object_id = OBJECT_ID(N'[dbo].[hardatons]') AND type in (N'U'))
DROP TABLE [dbo].[hardatons]

CREATE TABLE hardatons
(
    hardatonId INT PRIMARY KEY NOT NULL,
    title VARCHAR(255) NOT NULL DEFAULT 'нет названия',
);

INSERT INTO hardatons
VALUES
    (1, 'Хардатон 1'),
    (2, 'Хардатон 2 ')

USE lab_13_2_db

IF  EXISTS (SELECT *
FROM sys.objects
WHERE object_id = OBJECT_ID(N'[dbo].[projects]') AND type in (N'U'))
DROP TABLE [dbo].[projects]

CREATE TABLE projects
(
    projectId INT PRIMARY KEY NOT NULL,
    project_title VARCHAR(255) NOT NULL DEFAULT 'нет названия',
    hardatonId INT
    -- это должен был быть FK, но его нельзя создать (

);

INSERT INTO projects
VALUES
    (1, 'Проект 1', 1),
    (2, 'Проект 2', 1),
    (3, 'Проект 3', 1),
    (4, 'Проект 4', 2),
    (5, 'Проект 5', 2),
    (6, 'Проект 6', 2)



--2. Создать необходимые элементы базы данных (представления, триггеры), обеспечивающие работу
--с данными связанных таблиц (выборку, вставку, изменение, удаление).


GO
DROP VIEW IF EXISTS hardaton_partners_view
GO

CREATE VIEW hardaton_partners_view
AS
    SELECT one.hardatonId, two.projectId, one.title, two.project_title
    FROM lab_13_1_db.dbo.hardatons AS one JOIN lab_13_2_db.dbo.projects AS two
        ON one.hardatonId = two.hardatonId;

GO

DROP TRIGGER IF EXISTS insert_update_trigger;
DROP TRIGGER IF EXISTS delete_trigger;

GO

CREATE TRIGGER insert_update_trigger  ON hardaton_partners_view INSTEAD OF INSERT AS
BEGIN
    IF EXISTS (
        SELECT 1
    FROM inserted i
        LEFT JOIN lab_13_1_db.dbo.hardatons one ON i.hardatonId = one.hardatonId
    WHERE one.hardatonId IS NULL
    )
    BEGIN
        RAISERROR ('Invalid hardatonId. The referenced hardaton does not exist.', 16, 1);
        ROLLBACK;
    END
    ELSE
    BEGIN
        -- Продолжите с вставкой данных, если проверка успешна
        INSERT INTO lab_13_1_db.dbo.hardatons
            (hardatonId,title)
        SELECT hardatonId, title
        FROM inserted;

        INSERT INTO lab_13_2_db.dbo.projects
            (projectId,project_title ,hardatonId)
        SELECT projectId, project_title, hardatonId
        FROM inserted;
    END
END;

GO

CREATE TRIGGER delete_trigger
ON hardaton_partners_view
INSTEAD OF DELETE
AS
BEGIN
    DELETE FROM lab_13_2_db.dbo.projects
    WHERE hardatonId IN (SELECT deleted.hardatonId
    FROM deleted);
END;
GO


USE lab_13_2_db

INSERT INTO hardaton_partners_view
    (hardatonId,projectId,title,project_title)
VALUES
    (3, 1, '1', 'ХУЙ');


SELECT *
FROM hardaton_partners_view;

DELETE FROM hardaton_partners_view WHERE hardatonId =1;

SELECT *
FROM hardaton_partners_view;