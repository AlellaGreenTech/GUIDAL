-- Verify Halloween party descriptions include Tony's text

SELECT
    title,
    LEFT(description, 100) as description_start,
    RIGHT(description, 100) as description_end,
    CASE
        WHEN description LIKE '%Tony''s From New York%' THEN '✅ Has Tony''s text'
        ELSE '❌ Missing Tony''s text'
    END as tony_check
FROM activities
WHERE title LIKE '%Halloween%Party%'
ORDER BY date_time;
