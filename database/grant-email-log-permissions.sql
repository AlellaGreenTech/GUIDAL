-- Grant permissions on pumpkin_patch_email_log table

-- Grant INSERT and SELECT to anon role (for public access)
GRANT INSERT, SELECT ON pumpkin_patch_email_log TO anon;

-- Grant INSERT and SELECT to authenticated users
GRANT INSERT, SELECT ON pumpkin_patch_email_log TO authenticated;

-- Verify the grants
SELECT grantee, privilege_type
FROM information_schema.role_table_grants
WHERE table_name = 'pumpkin_patch_email_log'
ORDER BY grantee, privilege_type;
