-- Check current admin email settings
SELECT
    id,
    admin_email,
    admin_name,
    is_active,
    notify_on_order_created,
    notify_on_order_paid
FROM admin_notification_settings;
