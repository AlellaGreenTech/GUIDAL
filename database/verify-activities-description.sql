-- Verify activities table has Tony's text in descriptions

SELECT
    id,
    title,
    description
FROM activities
WHERE title LIKE '%Halloween%Party%'
ORDER BY date_time;
