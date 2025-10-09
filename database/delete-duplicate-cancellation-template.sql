-- First, let's see both cancellation templates to identify which one to delete
SELECT
    id,
    name,
    subject,
    LENGTH(html_body) as body_length,
    created_at,
    updated_at
FROM pumpkin_patch_email_templates
WHERE template_type = 'cancellation'
ORDER BY created_at ASC;

-- Delete the older/shorter cancellation template (the first one created)
DELETE FROM pumpkin_patch_email_templates
WHERE template_type = 'cancellation'
  AND id = (
    SELECT id
    FROM pumpkin_patch_email_templates
    WHERE template_type = 'cancellation'
    ORDER BY created_at ASC
    LIMIT 1
  );

-- Verify only one cancellation template remains
SELECT
    template_type,
    name,
    subject,
    LENGTH(html_body) as body_length,
    created_at
FROM pumpkin_patch_email_templates
WHERE template_type = 'cancellation';
