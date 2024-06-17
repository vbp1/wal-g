\set data_size 3000
\set did1 random(1, 1000)
\set did2 random(1, 1000)
\set rnd random(1, 1000000)




BEGIN;
UPDATE toast_update SET num = num + :rnd WHERE did = :did1;
UPDATE toast_update SET data = (SELECT string_agg(chr((65 + floor(random() * 25))::integer), '') FROM generate_series(1, :data_size)) WHERE did = :did2;
INSERT INTO toast_insert (num, data) VALUES (random() * 1000000, (SELECT string_agg(chr((65 + floor(random() * 25))::integer), '') FROM generate_series(1, :data_size)));
END;
