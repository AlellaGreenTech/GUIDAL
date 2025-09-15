-- Update BFIS description only
-- Safe script to update just the Benjamin Franklin activity description

UPDATE public.activities
SET description = 'See science in action, build sustainably, create fertile soil...and plant veggies!'
WHERE slug = 'benjamin-franklin-sept-2025';

-- Verify the update
SELECT title, description FROM public.activities
WHERE slug = 'benjamin-franklin-sept-2025';