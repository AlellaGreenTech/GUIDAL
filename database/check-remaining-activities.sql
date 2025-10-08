-- Check what activities remain and if there are any duplicates
SELECT title, COUNT(*) as count
FROM activities
GROUP BY title
ORDER BY title;
