-- проверяем использование toast

select count(*) from toast_update;
select count(*) from toast_insert;

vacuum;


SELECT 
    a.attname AS column_name,
    t.relname AS toast_table
FROM 
    pg_attribute a
JOIN 
    pg_class c ON a.attrelid = c.oid
LEFT JOIN 
    pg_class t ON c.reltoastrelid = t.oid
WHERE 
    c.relname = 'toast_update'
    AND a.attname = 'data';

SELECT 
    c.relname AS table_name, 
    c.relpages AS table_pages, 
    t.relname AS toast_table_name, 
    t.relpages AS toast_table_pages 
FROM 
    pg_class c
LEFT JOIN 
    pg_class t ON c.reltoastrelid = t.oid
WHERE 
    c.relname = 'toast_update'
    OR c.relname = 'toast_insert';

