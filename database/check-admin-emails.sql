-- Check current admin notification settings
SELECT * FROM admin_notification_settings;

-- Check if there's an incorrect email stored
SELECT * FROM admin_notification_settings WHERE admin_email LIKE '%martin%' OR admin_email LIKE '%guidal%';

-- Update incorrect admin email if found
-- UPDATE admin_notification_settings
-- SET admin_email = 'mwpicard@gmail.com'
-- WHERE admin_email = 'martin@guidal.org';
