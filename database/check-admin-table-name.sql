-- Check which admin notification table actually exists

SELECT
  tablename,
  schemaname
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename LIKE '%admin%notification%'
ORDER BY tablename;

-- Also check for any data in these tables
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT tablename
    FROM pg_tables
    WHERE schemaname = 'public'
      AND tablename LIKE '%admin%notification%'
  LOOP
    RAISE NOTICE 'Table: %', r.tablename;
    EXECUTE format('SELECT COUNT(*) FROM %I', r.tablename);
  END LOOP;
END $$;
