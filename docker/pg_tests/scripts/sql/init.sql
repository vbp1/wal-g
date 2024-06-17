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
