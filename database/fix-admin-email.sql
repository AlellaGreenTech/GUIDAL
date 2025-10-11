-- Fix incorrect admin email in notification settings
-- Change martin@guidal.org to mwpicard@gmail.com

UPDATE admin_notification_settings
SET admin_email = 'mwpicard@gmail.com'
WHERE admin_email = 'martin@guidal.org';

-- Verify the update
SELECT * FROM admin_notification_settings;
