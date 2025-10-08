-- Get the full UUIDs for the duplicate activities
SELECT
    id::text as full_id,
    title,
    LENGTH(id::text) as uuid_length
FROM activities
WHERE title IN (
    'Composting',
    'Composting & Soil Science',
    'Erosion Challenge',
    'Erosion Control challenge Workshop',
    'No til Planting',
    'Planting & Growing',
    'Robotic Gardening',
    'Robotic Gardening Session',
    'Wattle and Daub Construction',
    'Wattle & Daub Construction Workshop'
)
ORDER BY title;
