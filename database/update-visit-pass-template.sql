-- Update Visit Pass template
UPDATE pumpkin_patch_email_templates
SET html_body = '<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #28a745, #5cb85c); color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
        .qr-section { background: #fff; padding: 30px; text-align: center; border: 3px solid #28a745; border-radius: 8px; margin: 20px 0; }
        .content { background: #fff; padding: 30px; border: 1px solid #ddd; }
        .footer { background: #f8f9fa; padding: 20px; text-align: center; border-radius: 0 0 8px 8px; }
        .ticket-info { background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0; }
        .ticket-info h3 { margin-top: 0; color: #28a745; }
        .highlight { background: #d4edda; padding: 15px; border-left: 4px solid #28a745; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🎃 Pumpkin Patch Visit Pass 🎃</h1>
            <p style="font-size: 1.2em; margin: 10px 0;">Non-Party-Day Visit Confirmed!</p>
        </div>
        <div class="qr-section">
            <h2 style="color: #28a745; margin-top: 0;">Your Visit Pass</h2>
            <p style="font-weight: bold; color: #666;">Show this QR code upon arrival</p>
            <img src="{{qr_code}}" alt="Visit Pass QR Code" style="max-width: 300px; margin: 20px 0;" />
            <p style="font-size: 0.9rem; color: #999;">{{first_name}} {{last_name}} - Visit Pass</p>
        </div>
        <div class="content">
            <h2>Hello {{first_name}}!</h2>
            <p>Thank you for booking your visit to the Pumpkin Patch! Your <strong>NON-PARTY-DAY VISIT</strong> pass has been confirmed.</p>
            <div class="ticket-info">
                <h3>📋 Order Details</h3>
                <p><strong>Order Number:</strong> {{order_number}}</p>
                <p><strong>Customer:</strong> {{first_name}} {{last_name}}</p>
                <p><strong>Email:</strong> {{email}}</p>
                <p><strong>Phone:</strong> {{phone}}</p>
                <p><strong>Items Purchased:</strong><br>{{items}}</p>
                <p><strong>Total Amount:</strong> €{{total_amount}}</p>
            </div>
            <div class="highlight">
                <strong>🎃 Your Visit Includes:</strong>
                <ul>
                    <li>Access to the pumpkin patch</li>
                    <li>Pick your own pumpkins</li>
                    <li>Farm activities</li>
                    <li>Peaceful, non-party atmosphere</li>
                </ul>
            </div>
            <p><strong>Visit any day EXCEPT:</strong> October 25th & November 1st (Party Days)</p>
            <p><strong>Location:</strong> Can Picard, Alella - operated by Alella Green Tech</p>
            <p><strong>IMPORTANT:</strong> Please present the QR code above (digital or printed) upon arrival.</p>
            <p>We look forward to welcoming you! 🎃</p>
        </div>
        <div class="footer">
            <p>Questions? Contact us at <a href="mailto:info@guidal.be">info@guidal.be</a></p>
            <p>&copy; 2025 GUIDAL - The International Green Tech Foundation</p>
        </div>
    </div>
</body>
</html>',
updated_at = NOW()
WHERE template_type = 'visit_pass';
