-- Create or update the Scares purchase template with proper HTML layout
-- First, update the template_type to avoid conflicts
UPDATE pumpkin_patch_email_templates
SET template_type = 'scares_purchase'
WHERE name = 'Scares purchase';

-- Now update the HTML with proper layout
UPDATE pumpkin_patch_email_templates
SET html_body = '<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #dc3545, #c82333); color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
        .qr-section { background: #fff; padding: 30px; text-align: center; border: 3px solid #dc3545; border-radius: 8px; margin: 20px 0; }
        .content { background: #fff; padding: 30px; border: 1px solid #ddd; }
        .footer { background: #f8f9fa; padding: 20px; text-align: center; border-radius: 0 0 8px 8px; }
        .ticket-info { background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0; }
        .ticket-info h3 { margin-top: 0; color: #dc3545; }
        .highlight { background: #fff3cd; padding: 15px; border-left: 4px solid #dc3545; margin: 20px 0; }
        .scary-box { background: #2d2d2d; color: #fff; padding: 20px; border-radius: 8px; text-align: center; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>💀 SCARES PURCHASE CONFIRMED! 💀</h1>
            <p style="font-size: 1.2em; margin: 10px 0;">I have horrifying news!</p>
        </div>
        <div class="scary-box">
            <h2 style="margin-top: 0; color: #ff6b35;">👻 You have purchased an evil quantity of SCARES! 👻</h2>
            <p style="font-size: 1.1em;">Get ready for some spooky fun!</p>
        </div>
        <div class="qr-section">
            <h2 style="color: #dc3545; margin-top: 0;">Your SCARES Token</h2>
            <p style="font-weight: bold; color: #666;">Show this QR code to redeem your SCARES</p>
            <img src="{{qr_code}}" alt="SCARES QR Code" style="max-width: 300px; margin: 20px 0;" />
            <p style="font-size: 0.9rem; color: #999;">{{first_name}} {{last_name}}</p>
        </div>
        <div class="content">
            <h2>Hello {{first_name}}!</h2>
            <p>Thank you for purchasing <strong>SCARES</strong> for the <strong>SCARY PUMPKIN PATCH</strong>!</p>
            <div class="ticket-info">
                <h3>📋 Purchase Details</h3>
                <p><strong>Order Number:</strong> {{order_number}}</p>
                <p><strong>Event Date:</strong> {{party_date}}</p>
                <p><strong>Customer:</strong> {{first_name}} {{last_name}}</p>
                <p><strong>Email:</strong> {{email}}</p>
                <p><strong>Phone:</strong> {{phone}}</p>
                <p><strong>Items Purchased:</strong><br>{{items}}</p>
                <p><strong>Total Amount:</strong> €{{total_amount}}</p>
            </div>
            <div class="highlight">
                <strong>💀 How to Use Your SCARES:</strong>
                <ul>
                    <li>Each SCARE can be used for food, drinks, or activities at the pumpkin patch</li>
                    <li>Show your QR code at any vendor or activity station</li>
                    <li>SCARES are valid only on your event date: {{party_date}}</li>
                    <li>Unused SCARES cannot be refunded or carried over</li>
                </ul>
            </div>
            <p><strong>Event Date:</strong> {{party_date}}</p>
            <p><strong>Location:</strong> Can Picard, Alella - operated by Alella Green Tech</p>
            <p><strong>IMPORTANT:</strong> Please present the QR code above (digital or printed) to redeem your SCARES.</p>
            <p>See you at the pumpkin patch! 🎃</p>
        </div>
        <div class="footer">
            <p>Questions? Contact us at <a href="mailto:info@guidal.be">info@guidal.be</a></p>
            <p>&copy; 2025 GUIDAL - The International Green Tech Foundation</p>
        </div>
    </div>
</body>
</html>',
subject = 'Confirming your SCARES purchase - {{order_number}}',
updated_at = NOW()
WHERE name = 'Scares purchase';

-- Verify the update
SELECT
    name,
    template_type,
    subject,
    is_active,
    LENGTH(html_body) as body_length
FROM pumpkin_patch_email_templates
WHERE name = 'Scares purchase';
