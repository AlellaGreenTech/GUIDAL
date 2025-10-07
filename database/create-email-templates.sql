-- Create email templates table for pumpkin patch order confirmations
CREATE TABLE IF NOT EXISTS pumpkin_patch_email_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    subject VARCHAR(500) NOT NULL,
    html_body TEXT NOT NULL,
    template_type VARCHAR(50) NOT NULL, -- 'entrance_ticket' or 'visit_pass'
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add RLS policies
ALTER TABLE pumpkin_patch_email_templates ENABLE ROW LEVEL SECURITY;

-- Admin can do everything
CREATE POLICY "Admins can manage email templates"
    ON pumpkin_patch_email_templates
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.user_type IN ('admin', 'staff')
        )
    );

-- Create email log table to track sent emails
CREATE TABLE IF NOT EXISTS pumpkin_patch_email_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES pumpkin_patch_orders(id) ON DELETE CASCADE,
    template_id UUID REFERENCES pumpkin_patch_email_templates(id),
    recipient_email VARCHAR(255) NOT NULL,
    subject VARCHAR(500) NOT NULL,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status VARCHAR(50) DEFAULT 'sent', -- 'sent', 'failed', 'bounced'
    error_message TEXT
);

-- Add RLS policies for email log
ALTER TABLE pumpkin_patch_email_log ENABLE ROW LEVEL SECURITY;

-- Admin can view email logs
CREATE POLICY "Admins can view email logs"
    ON pumpkin_patch_email_log
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.user_type IN ('admin', 'staff')
        )
    );

-- Insert default templates
INSERT INTO pumpkin_patch_email_templates (name, subject, template_type, html_body) VALUES
(
    'Entrance Ticket Confirmation',
    'Your SCARY PUMPKIN PATCH Entrance Ticket - {{order_number}}',
    'entrance_ticket',
    '<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #ff6b35, #ff8c42); color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
        .content { background: #fff; padding: 30px; border: 1px solid #ddd; border-top: none; }
        .footer { background: #f8f9fa; padding: 20px; text-align: center; border-radius: 0 0 8px 8px; }
        .ticket-info { background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0; }
        .ticket-info h3 { margin-top: 0; color: #ff6b35; }
        .highlight { background: #fff3cd; padding: 15px; border-left: 4px solid #ff6b35; margin: 20px 0; }
        .button { display: inline-block; background: #ff6b35; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; margin: 10px 0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🎃 SCARY PUMPKIN PATCH 2025 🎃</h1>
            <p style="font-size: 1.2em; margin: 10px 0;">Entrance Ticket Confirmed!</p>
        </div>

        <div class="content">
            <h2>Hello {{first_name}}!</h2>

            <p>Thank you for your purchase! Your entrance ticket to the <strong>SCARY PUMPKIN PATCH</strong> has been confirmed.</p>

            <div class="ticket-info">
                <h3>📋 Order Details</h3>
                <p><strong>Order Number:</strong> {{order_number}}</p>
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

            <p><strong>Event Dates:</strong> October 25th & November 1st, 2025</p>
            <p><strong>Location:</strong> GUIDAL Farm, Belgium</p>

            <p>Please present this email (digital or printed) at the entrance.</p>

            <p>See you at the pumpkin patch! 🎃</p>
        </div>

        <div class="footer">
            <p>Questions? Contact us at <a href="mailto:info@guidal.be">info@guidal.be</a></p>
            <p>&copy; 2025 GUIDAL - The International Green Tech Foundation</p>
        </div>
    </div>
</body>
</html>'
),
(
    'Visit Pass Confirmation',
    'Your Pumpkin Patch Visit Pass - {{order_number}}',
    'visit_pass',
    '<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #28a745, #5cb85c); color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
        .content { background: #fff; padding: 30px; border: 1px solid #ddd; border-top: none; }
        .footer { background: #f8f9fa; padding: 20px; text-align: center; border-radius: 0 0 8px 8px; }
        .ticket-info { background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0; }
        .ticket-info h3 { margin-top: 0; color: #28a745; }
        .highlight { background: #d4edda; padding: 15px; border-left: 4px solid #28a745; margin: 20px 0; }
        .button { display: inline-block; background: #28a745; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; margin: 10px 0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🎃 Pumpkin Patch Visit Pass 🎃</h1>
            <p style="font-size: 1.2em; margin: 10px 0;">Non-Party-Day Visit Confirmed!</p>
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
                <p><strong>Adults:</strong> {{adult_count}}</p>
                <p><strong>Children:</strong> {{child_count}}</p>
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
            <p><strong>Location:</strong> GUIDAL Farm, Belgium</p>

            <p>Please present this email (digital or printed) upon arrival.</p>

            <p>We look forward to welcoming you! 🎃</p>
        </div>

        <div class="footer">
            <p>Questions? Contact us at <a href="mailto:info@guidal.be">info@guidal.be</a></p>
            <p>&copy; 2025 GUIDAL - The International Green Tech Foundation</p>
        </div>
    </div>
</body>
</html>'
);

-- Add comment
COMMENT ON TABLE pumpkin_patch_email_templates IS 'Email templates for pumpkin patch order confirmations';
COMMENT ON TABLE pumpkin_patch_email_log IS 'Log of all emails sent for pumpkin patch orders';
