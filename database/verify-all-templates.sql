-- Final verification: Check all active templates are correctly configured
SELECT
    template_type,
    name,
    subject,
    is_active,
    LENGTH(html_body) as body_length,
    created_at
FROM pumpkin_patch_email_templates
WHERE is_active = true
ORDER BY template_type, created_at DESC;

-- This should show:
-- cancellation: 1 template (Sorry Dracula has CANCELLED)
-- entrance_ticket: 1 template (Entrance Ticket Confirmation)
-- visit_pass: 1 template (Visit Pass Confirmation)
