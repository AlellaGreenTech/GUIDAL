-- Check the Scares purchase template
SELECT
    id,
    template_type,
    name,
    subject,
    is_active,
    LENGTH(html_body) as body_length,
    created_at
FROM pumpkin_patch_email_templates
WHERE name LIKE '%Scare%' OR template_type LIKE '%scare%'
ORDER BY created_at DESC;

-- Show a sample of the HTML body
SELECT
    name,
    template_type,
    LEFT(html_body, 500) as html_preview
FROM pumpkin_patch_email_templates
WHERE name LIKE '%Scare%' OR template_type LIKE '%scare%';
