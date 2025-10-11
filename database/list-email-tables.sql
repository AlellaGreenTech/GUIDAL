-- List all tables with 'email' or 'log' in their name
SELECT table_name, table_type
FROM information_schema.tables
WHERE table_schema = 'public'
  AND (table_name LIKE '%email%' OR table_name LIKE '%log%')
ORDER BY table_name;
