USE lab_10_db;



-- ГРЯЗНОЕ ЧТЕНИЕ

/*

 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED -- считали данные из незакомиченной транзакции, но ведь оно НИКОГДА не запишется в БД из-за ролбека
-- SET TRANSACTION ISOLATION LEVEL READ COMMITTED -- чтение запрещено т.к Транзакция 1 не закомичена

BEGIN TRANSACTION

SELECT * FROM events WHERE eventId =1 ;

COMMIT TRANSACTION;



-- НЕПОВТОРЯЮЩЕСЯ ЧТЕНИЕ


BEGIN TRANSACTION;

UPDATE events 
SET descr = 'НЕПОВТОРНОЕ ЧТЕНИЕ ОБНОВЛЕНИЕ'
WHERE eventId = 1;

COMMIT TRANSACTION
*/

-- ФАНТОМНОЕ ЧТЕНИЕ;


BEGIN TRAN;

INSERT INTO events VALUES (4, 'Событие 4', 'Описание события 4'), (5, 'Событие 5', 'Описание события 5');

COMMIT TRAN;
