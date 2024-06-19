CREATE TABLE toast_update (
    did BIGSERIAL PRIMARY KEY,
    num bigint,
    data text
);


CREATE TABLE toast_insert (
    did BIGSERIAL PRIMARY KEY,
    num bigint,
    data text
);

CREATE TABLE linked_table (
    id SERIAL PRIMARY KEY,
    value1 BIGINT,
    toast_update_did BIGINT,
    FOREIGN KEY (toast_update_did) REFERENCES toast_update(did)
);



DO $$
DECLARE 
    i bigint := 1;
    num_rows int := 1000;
    data_size int := 3000;
    random_num bigint;
    random_string text;
BEGIN
    WHILE i <= num_rows LOOP
        random_num := (SELECT floor(random() * 1000000 + 1)::bigint);
        random_string := (
            SELECT string_agg(chr((65 + floor(random() * 25))::integer), '')
            FROM generate_series(1, data_size)
        );
        EXECUTE format('INSERT INTO toast_update (num, data) VALUES (%L, %L)', random_num, random_string);
        i := i + 1;
    END LOOP;
END
$$;

DO $$
DECLARE
    random_did BIGINT;
BEGIN
    FOR i IN 1..10000 LOOP
        SELECT did INTO random_did
        FROM toast_update
        ORDER BY RANDOM()
        LIMIT 1;
        INSERT INTO linked_table (value1, toast_update_did)
        VALUES (
            FLOOR(RANDOM() * 1000)::INT,
            random_did
        );
    END LOOP;
END $$;

CREATE INDEX idx_linked_table_value1
ON linked_table (value1);

CREATE INDEX idx_linked_table_toast_update_did
ON linked_table (toast_update_did);

