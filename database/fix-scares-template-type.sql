-- Fix the Scares purchase template to have its own template_type
UPDATE pumpkin_patch_email_templates
SET template_type = 'scares_purchase'
WHERE name = 'Scares purchase';

-- Verify all templates now have unique types
SELECT
    template_type,
    name,
    subject,
    is_active,
    created_at
FROM pumpkin_patch_email_templates
WHERE is_active = true
ORDER BY template_type, created_at DESC;

-- Check for any remaining duplicates
SELECT
    template_type,
    COUNT(*) as count,
    STRING_AGG(name, ', ') as template_names
FROM pumpkin_patch_email_templates
WHERE is_active = true
GROUP BY template_type
HAVING COUNT(*) > 1;
