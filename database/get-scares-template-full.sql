-- Get the full Scares template to see the layout issues
SELECT
    name,
    template_type,
    subject,
    html_body
FROM pumpkin_patch_email_templates
WHERE name = 'Scares purchase';
