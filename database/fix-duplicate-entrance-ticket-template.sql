-- Fix: The "Sorry Dracula has CANCELLED" template has wrong template_type
-- It should be 'cancellation' not 'entrance_ticket'

-- Option 1: Change the cancellation template's type to 'cancellation'
UPDATE pumpkin_patch_email_templates
SET template_type = 'cancellation'
WHERE name LIKE '%CANCELLED%'
  AND template_type = 'entrance_ticket';

-- Verify the fix
SELECT
    template_type,
    name,
    subject,
    is_active,
    created_at
FROM pumpkin_patch_email_templates
WHERE is_active = true
ORDER BY template_type, created_at DESC;
