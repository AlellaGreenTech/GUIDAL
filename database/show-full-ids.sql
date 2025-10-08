-- Show full UUIDs in a way that won't truncate
SELECT
    CONCAT('Composting: ', id) as composting_id
FROM activities
WHERE title = 'Composting'
UNION ALL
SELECT
    CONCAT('Composting & Soil Science: ', id)
FROM activities
WHERE title = 'Composting & Soil Science'
UNION ALL
SELECT
    CONCAT('Erosion Challenge: ', id)
FROM activities
WHERE title = 'Erosion Challenge'
UNION ALL
SELECT
    CONCAT('Erosion Control challenge Workshop: ', id)
FROM activities
WHERE title = 'Erosion Control challenge Workshop'
UNION ALL
SELECT
    CONCAT('No til Planting: ', id)
FROM activities
WHERE title = 'No til Planting'
UNION ALL
SELECT
    CONCAT('Planting & Growing: ', id)
FROM activities
WHERE title = 'Planting & Growing'
UNION ALL
SELECT
    CONCAT('Robotic Gardening: ', id)
FROM activities
WHERE title = 'Robotic Gardening'
UNION ALL
SELECT
    CONCAT('Robotic Gardening Session: ', id)
FROM activities
WHERE title = 'Robotic Gardening Session'
UNION ALL
SELECT
    CONCAT('Wattle and Daub Construction: ', id)
FROM activities
WHERE title = 'Wattle and Daub Construction'
UNION ALL
SELECT
    CONCAT('Wattle & Daub Construction Workshop: ', id)
FROM activities
WHERE title = 'Wattle & Daub Construction Workshop';
