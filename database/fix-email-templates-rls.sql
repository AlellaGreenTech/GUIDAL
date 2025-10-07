-- Fix RLS policies for email templates
-- Drop existing policies
DROP POLICY IF EXISTS "Admins can manage email templates" ON pumpkin_patch_email_templates;
DROP POLICY IF EXISTS "Admins can view email logs" ON pumpkin_patch_email_log;

-- Recreate policy using auth.email() - simpler and more reliable
CREATE POLICY "Admins can manage email templates"
    ON pumpkin_patch_email_templates
    FOR ALL
    USING (
        auth.email() = 'martin@guidal.be'
    );

-- Recreate email log policy
CREATE POLICY "Admins can view email logs"
    ON pumpkin_patch_email_log
    FOR SELECT
    USING (
        auth.email() = 'martin@guidal.be'
    );

-- Verify policies were created
SELECT schemaname, tablename, policyname
FROM pg_policies
WHERE tablename IN ('pumpkin_patch_email_templates', 'pumpkin_patch_email_log');
