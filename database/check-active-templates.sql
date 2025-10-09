-- Check all active email templates
SELECT
    id,
    template_type,
    name,
    subject,
    is_active,
    created_at,
    updated_at
FROM pumpkin_patch_email_templates
WHERE is_active = true
ORDER BY template_type, created_at DESC;

-- Check for duplicate template_types
SELECT
    template_type,
    COUNT(*) as count,
    STRING_AGG(name, ', ') as template_names
FROM pumpkin_patch_email_templates
WHERE is_active = true
GROUP BY template_type
HAVING COUNT(*) > 1;
