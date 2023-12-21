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

DROP VIEW IF EXISTS hardaton_project_view;
GO
CREATE VIEW hardaton_project_view
AS
    SELECT h.hardatonId, h.title, p.projectId, p.project_title
    FROM projects AS p JOIN lab_13_1_db.dbo.hardatons AS h ON p.hardatonId = h.hardatonId;

GO

DROP TRIGGER IF EXISTS update_hardaton;
DROP TRIGGER IF EXISTS delete_hardaton;

USE lab_13_1_db;
GO
CREATE TRIGGER update_hardaton ON hardatons AFTER UPDATE AS
BEGIN
    IF(UPDATE(hardatonId))
    BEGIN
        RAISERROR('Я запрещаю вам обновляться',10,10);
        ROLLBACK;
    END;
END;
GO
CREATE TRIGGER delete_hardaton ON hardatons INSTEAD OF DELETE AS
BEGIN
    -- Сначала удалим все дочерние проекты 
    DELETE FROM lab_13_2_db.dbo.projects WHERE hardatonId =(SELECT hardatonId
    FROM deleted);

    DELETE FROM lab_13_1_db.dbo.hardatons WHERE hardatonId =(SELECT hardatonId
    FROM deleted);
END;
GO


USE lab_13_2_db;
DROP TRIGGER IF EXISTS insert_project;
DROP TRIGGER IF EXISTS update_project;



GO
CREATE TRIGGER insert_project ON projects AFTER INSERT AS
BEGIN
    IF(NOT EXISTS (SELECT *
    FROM lab_13_1_db.dbo.hardatons
    WHERE hardatonId = (SELECT hardatonId
    FROM inserted)))
    BEGIN
        RAISERROR('Такого хардатона не существует !',10,10);
        ROLLBACK;
    END;
END;
GO

GO
CREATE TRIGGER update_project ON projects AFTER UPDATE AS
BEGIN
    IF(UPDATE(hardatonId))
    BEGIN
        RAISERROR('Я запрещаю вам обновляться',10,10);
        ROLLBACK;
    END;
END
GO


/*
INSERT INTO projects
VALUES
    (18, 'Проект 18', 10)
*/

--DELETE FROM projects WHERE projectId = 1;

USE lab_13_1_db;

--DELETE FROM hardatons WHERE hardatonId = 2;
--UPDATE hardatons SET title = 'Title 2' WHERE hardatonId =2;


USE lab_13_2_db;
SELECT *
from hardaton_project_view;