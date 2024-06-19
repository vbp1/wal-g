\set data_size 3000
\set did1 random(1, 1000)
\set did2 random(1, 1000)
\set rnd random(1, 1000000)




BEGIN;
UPDATE toast_update SET num = num + :rnd WHERE did = :did1;
UPDATE toast_update SET data = (SELECT string_agg(chr((65 + floor(random() * 25))::integer), '') FROM generate_series(1, :data_size)) WHERE did = :did2;
INSERT INTO toast_insert (num, data) VALUES (random() * 1000000, (SELECT string_agg(chr((65 + floor(random() * 25))::integer), '') FROM generate_series(1, :data_size)));
-- обновляем значение поля в таблице с FK
UPDATE linked_table
SET value1 = value1 + (RANDOM() * 100)::BIGINT
WHERE id = (
    SELECT id
    FROM linked_table
    ORDER BY RANDOM()
    LIMIT 1
);
-- вставляем строчку в таблицу с FK
INSERT INTO linked_table (value1, toast_update_did)
VALUES (
    FLOOR(RANDOM() * 1000)::INT,
    (SELECT did FROM toast_update ORDER BY RANDOM() LIMIT 1)
);
-- обновляем FK
UPDATE linked_table
SET toast_update_did = (
    SELECT did
    FROM toast_update
    ORDER BY RANDOM()
    LIMIT 1
    )
WHERE id = (
    SELECT id
    FROM linked_table
    ORDER BY RANDOM()
    LIMIT 1
);
-- массовое обновление таблицы с FK
-- UPDATE linked_table
-- SET value1 = value1 + (RANDOM() * 100)::BIGINT
-- WHERE value1 > (RANDOM() * 100)::BIGINT;
END;
