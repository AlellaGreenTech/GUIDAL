-- Verify each template_type has only ONE active template
SELECT
    template_type,
    COUNT(*) as count,
    STRING_AGG(name || ' (created: ' || created_at::date::text || ')', ', ') as templates
FROM pumpkin_patch_email_templates
WHERE is_active = true
GROUP BY template_type
ORDER BY template_type;

-- Show any duplicates (should return nothing)
SELECT
    template_type,
    COUNT(*) as count
FROM pumpkin_patch_email_templates
WHERE is_active = true
GROUP BY template_type
HAVING COUNT(*) > 1;
