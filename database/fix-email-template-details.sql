-- Fix email templates: show single party date and correct location

-- Update Entrance Ticket template
UPDATE pumpkin_patch_email_templates
SET html_body = '<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #ff6b35, #ff8c42); color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
        .qr-section { background: #fff; padding: 30px; text-align: center; border: 3px solid #ff6b35; border-radius: 8px; margin: 20px 0; }
        .content { background: #fff; padding: 30px; border: 1px solid #ddd; }
        .footer { background: #f8f9fa; padding: 20px; text-align: center; border-radius: 0 0 8px 8px; }
        .ticket-info { background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0; }
        .ticket-info h3 { margin-top: 0; color: #ff6b35; }
        .highlight { background: #fff3cd; padding: 15px; border-left: 4px solid #ff6b35; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🎃 SCARY PUMPKIN PATCH 2025 🎃</h1>
            <p style="font-size: 1.2em; margin: 10px 0;">Entrance Ticket Confirmed!</p>
        </div>

        <div class="qr-section">
            <h2 style="color: #ff6b35; margin-top: 0;">Your Entry Ticket</h2>
            <p style="font-weight: bold; color: #666;">Show this QR code at the entrance</p>
            <img src="{{qr_code}}" alt="Entry QR Code" style="max-width: 300px; margin: 20px 0;" />
            <p style="font-size: 0.9rem; color: #999;">{{first_name}} {{last_name}} - {{adult_count}} Adults, {{child_count}} Children</p>
        </div>

        <div class="content">
            <h2>Hello {{first_name}}!</h2>

            <p>Thank you for your purchase! Your entrance ticket to the <strong>SCARY PUMPKIN PATCH</strong> has been confirmed.</p>

            <div class="ticket-info">
                <h3>📋 Order Details</h3>
                <p><strong>Order Number:</strong> {{order_number}}</p>
                <p><strong>Event Date:</strong> {{party_date}}</p>
                <p><strong>Customer:</strong> {{first_name}} {{last_name}}</p>
                <p><strong>Email:</strong> {{email}}</p>
                <p><strong>Phone:</strong> {{phone}}</p>
                <p><strong>Adults:</strong> {{adult_count}}</p>
                <p><strong>Children:</strong> {{child_count}}</p>
                <p><strong>Total Amount:</strong> €{{total_amount}}</p>
            </div>

            <div class="highlight">
                <strong>🎃 What to Expect:</strong>
                <ul>
                    <li>Spooky pumpkin patch experience</li>
                    <li>Halloween activities and games</li>
                    <li>Photo opportunities</li>
                    <li>Family-friendly scares</li>
                </ul>
            </div>

            <p><strong>Event Date:</strong> {{party_date}}</p>
            <p><strong>Location:</strong> Can Picard, Alella - operated by Alella Green Tech</p>

            <p><strong>IMPORTANT:</strong> Please present the QR code above (digital or printed) at the entrance.</p>

            <p>See you at the pumpkin patch! 🎃</p>
        </div>

        <div class="footer">
            <p>Questions? Contact us at <a href="mailto:info@guidal.be">info@guidal.be</a></p>
            <p>&copy; 2025 GUIDAL - The International Green Tech Foundation</p>
        </div>
    </div>
</body>
</html>',
updated_at = NOW()
WHERE template_type = 'entrance_ticket';

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

-- Verify updates
SELECT name, template_type, updated_at
FROM pumpkin_patch_email_templates
WHERE template_type IN ('entrance_ticket', 'visit_pass');
