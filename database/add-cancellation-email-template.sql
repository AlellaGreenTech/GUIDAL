-- Add cancellation email template for pumpkin patch orders

INSERT INTO pumpkin_patch_email_templates (
    template_type,
    name,
    subject,
    html_body,
    is_active
) VALUES (
    'cancellation',
    'Order Cancellation',
    '❌ Order Cancelled - {{order_number}}',
    '<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #dc3545 0%, #c82333 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .header h1 { margin: 0; font-size: 2rem; }
        .content { background: white; padding: 30px; border: 1px solid #eee; border-top: none; }
        .order-box { background: #f8f9fa; padding: 20px; border-radius: 8px; border-left: 4px solid #dc3545; margin: 20px 0; }
        .order-box h3 { margin-top: 0; color: #dc3545; }
        .info-row { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #eee; }
        .info-row:last-child { border-bottom: none; }
        .items-list { background: white; padding: 15px; margin: 15px 0; }
        .item-row { display: flex; justify-content: space-between; padding: 10px 0; border-bottom: 1px solid #eee; }
        .item-row:last-child { border-bottom: none; }
        .total-row { display: flex; justify-content: space-between; padding: 15px 0; font-size: 1.2em; font-weight: bold; color: #dc3545; border-top: 2px solid #dc3545; margin-top: 10px; }
        .button { display: inline-block; background: #ff6b35; color: white; padding: 15px 30px; text-decoration: none; border-radius: 8px; margin: 20px 0; font-weight: bold; font-size: 1.1rem; }
        .button:hover { background: #e55a28; }
        .alert { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; border-radius: 4px; }
        .alert strong { color: #856404; }
        .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; border-top: 1px solid #eee; margin-top: 30px; }
        .whatsapp-links { display: flex; gap: 10px; justify-content: center; flex-wrap: wrap; margin-top: 15px; }
        .whatsapp-link { background: #25D366; color: white; padding: 10px 20px; text-decoration: none; border-radius: 6px; font-weight: bold; display: inline-block; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>❌ Order Cancelled</h1>
            <p style="margin: 10px 0 0 0; font-size: 1.1rem;">SCARY PUMPKIN PATCH</p>
        </div>

        <div class="content">
            <h2 style="color: #dc3545;">Your Order Has Been Cancelled</h2>

            <p>Hi {{first_name}},</p>

            <p>We wanted to let you know that your order for the SCARY PUMPKIN PATCH has been cancelled.</p>

            <div class="order-box">
                <h3>📋 Cancelled Order Details</h3>
                <div class="info-row">
                    <span><strong>Order Number:</strong></span>
                    <span>{{order_number}}</span>
                </div>
                <div class="info-row">
                    <span><strong>Customer Name:</strong></span>
                    <span>{{first_name}} {{last_name}}</span>
                </div>
                <div class="info-row">
                    <span><strong>Email:</strong></span>
                    <span>{{email}}</span>
                </div>
                <div class="info-row">
                    <span><strong>Visit Date:</strong></span>
                    <span>{{visit_date}}</span>
                </div>
                <div class="info-row">
                    <span><strong>Cancellation Date:</strong></span>
                    <span>{{cancellation_date}}</span>
                </div>
            </div>

            <div class="items-list">
                <h3 style="margin-top: 0;">🛒 Cancelled Items:</h3>
                {{items_list}}
                <div class="total-row">
                    <span>Total Amount:</span>
                    <span>€{{total_amount}}</span>
                </div>
            </div>

            <div class="alert">
                <strong>💰 Refund Information:</strong><br>
                {{refund_info}}
            </div>

            <div style="text-align: center; margin: 30px 0;">
                <h3 style="color: #ff6b35;">🎃 Want to Rebook?</h3>
                <p>You can still join us for the SCARY PUMPKIN PATCH! Book your new visit below:</p>
                <a href="https://guidal.org/events/pumpkin-patch-checkout.html" class="button">
                    📅 Book Again
                </a>
            </div>

            <div style="background: #d1f2eb; padding: 20px; border-radius: 8px; margin: 20px 0; text-align: center;">
                <h3 style="margin-top: 0; color: #0c5460;">📞 Need Help?</h3>
                <p>If you have any questions about your cancellation or want to discuss alternatives, please contact us:</p>
                <div class="whatsapp-links">
                    <a href="https://chat.whatsapp.com/HnWhcfwNLenGKXMFOR6JUG" class="whatsapp-link">
                        💬 Visit Questions
                    </a>
                    <a href="https://chat.whatsapp.com/GYQmIVwu3fID0VcW4QmUM2" class="whatsapp-link">
                        💬 Party Questions
                    </a>
                </div>
            </div>

            <p>We hope to see you at GUIDAL soon!</p>

            <p style="margin-top: 30px;">
                Best regards,<br>
                <strong>The GUIDAL Team</strong><br>
                Alella Green Tech Foundation
            </p>
        </div>

        <div class="footer">
            <p>© 2025 GUIDAL - Alella Green Tech Foundation</p>
            <p><a href="https://guidal.org" style="color: #667eea;">guidal.org</a></p>
            <p style="font-size: 11px; color: #999; margin-top: 10px;">
                This email was sent regarding your SCARY PUMPKIN PATCH order cancellation.<br>
                Order Number: {{order_number}} | Cancelled: {{cancellation_date}}
            </p>
        </div>
    </div>
</body>
</html>',
    true
);

COMMENT ON TABLE pumpkin_patch_email_templates IS 'Email templates for pumpkin patch order communications (includes cancellation template)';
