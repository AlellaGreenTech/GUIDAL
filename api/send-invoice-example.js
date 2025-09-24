// Example backend API for sending invoice emails
// This would typically be implemented in Node.js, Python, or your preferred backend

// Example using Node.js with Express and Nodemailer

/*
npm install express nodemailer pdf-lib

const express = require('express');
const nodemailer = require('nodemailer');
const { PDFDocument, rgb } = require('pdf-lib');

const app = express();
app.use(express.json());

// Configure your email transport
const transporter = nodemailer.createTransporter({
    service: 'gmail', // or your email service
    auth: {
        user: 'your-email@guidal.com',
        pass: 'your-email-password' // Use app passwords for Gmail
    }
});

app.post('/api/send-invoice', async (req, res) => {
    try {
        const { visitId, recipient, message, invoiceData } = req.body;

        // Generate PDF invoice
        const pdfBytes = await generateInvoicePDF(invoiceData);

        // Prepare email
        const mailOptions = {
            from: 'invoices@guidal.com',
            to: recipient,
            subject: `Invoice for Educational Visit - ${invoiceData.visit.school_name}`,
            html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px;">
                    <div style="text-align: center; margin-bottom: 2rem;">
                        <h2 style="color: #1565c0;">🌱 GUIDAL</h2>
                        <p>Educational Visits & Sustainability Learning</p>
                    </div>

                    <div style="background: #f8f9fa; padding: 1.5rem; border-radius: 8px; margin-bottom: 2rem;">
                        <h3>Invoice for Educational Visit</h3>
                        <p><strong>School:</strong> ${invoiceData.visit.school_name}</p>
                        <p><strong>Visit Date:</strong> ${new Date(invoiceData.visit.preferred_date).toLocaleDateString()}</p>
                        <p><strong>Students:</strong> ${invoiceData.visit.student_count}</p>
                        <p><strong>Total Amount:</strong> €${invoiceData.totals.total.toFixed(2)}</p>
                    </div>

                    <div style="margin-bottom: 2rem;">
                        ${message.replace(/\n/g, '<br>')}
                    </div>

                    <p>Please find the detailed invoice attached as a PDF.</p>

                    <div style="border-top: 1px solid #ddd; padding-top: 1rem; margin-top: 2rem; color: #666; font-size: 0.9rem;">
                        <p>Best regards,<br>
                        GUIDAL Team<br>
                        📧 info@guidal.com<br>
                        🌐 www.guidal.com</p>
                    </div>
                </div>
            `,
            attachments: [
                {
                    filename: `GUIDAL-Invoice-${visitId}.pdf`,
                    content: pdfBytes,
                    contentType: 'application/pdf'
                }
            ]
        };

        // Send email
        await transporter.sendMail(mailOptions);

        // Log the email send in your database
        await logEmailSent(visitId, recipient, 'invoice');

        res.json({ success: true, message: 'Invoice sent successfully' });

    } catch (error) {
        console.error('Error sending invoice:', error);
        res.status(500).json({ success: false, error: 'Failed to send invoice' });
    }
});

async function generateInvoicePDF(invoiceData) {
    const pdfDoc = await PDFDocument.create();
    const page = pdfDoc.addPage([612, 792]); // US Letter size

    // Add invoice content to PDF
    const { visit, lineItems, totals } = invoiceData;

    page.drawText('GUIDAL', {
        x: 50,
        y: 750,
        size: 24,
        color: rgb(0.08, 0.4, 0.75)
    });

    page.drawText('Educational Visit Invoice', {
        x: 50,
        y: 720,
        size: 14
    });

    // Add more invoice details...
    let yPosition = 680;

    page.drawText(`School: ${visit.school_name}`, {
        x: 50,
        y: yPosition,
        size: 12
    });

    yPosition -= 20;
    page.drawText(`Visit Date: ${new Date(visit.preferred_date).toLocaleDateString()}`, {
        x: 50,
        y: yPosition,
        size: 12
    });

    // Add line items
    yPosition -= 40;
    page.drawText('Invoice Items:', {
        x: 50,
        y: yPosition,
        size: 14
    });

    yPosition -= 30;
    lineItems.forEach(item => {
        page.drawText(`${item.description} - Qty: ${item.quantity} - €${item.total.toFixed(2)}`, {
            x: 70,
            y: yPosition,
            size: 10
        });
        yPosition -= 15;
    });

    // Add totals
    yPosition -= 20;
    page.drawText(`Total: €${totals.total.toFixed(2)}`, {
        x: 50,
        y: yPosition,
        size: 14,
        color: rgb(0.08, 0.4, 0.75)
    });

    return await pdfDoc.save();
}

async function logEmailSent(visitId, recipient, type) {
    // Log email send to your database
    // This would use your database connection
    console.log(`Email sent: ${type} to ${recipient} for visit ${visitId}`);
}

app.listen(3000, () => {
    console.log('Invoice API running on port 3000');
});

module.exports = app;
*/

// Alternative: Using Supabase Edge Functions (TypeScript/Deno)
// Create this as a Supabase Edge Function

export interface InvoiceEmailRequest {
    visitId: string;
    recipient: string;
    message: string;
    invoiceData: {
        visit: any;
        lineItems: any[];
        totals: any;
    };
}

// supabase/functions/send-invoice/index.ts
/*
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { SmtpClient } from "https://deno.land/x/smtp@v0.7.0/mod.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { visitId, recipient, message, invoiceData }: InvoiceEmailRequest = await req.json()

    // Configure SMTP
    const client = new SmtpClient()
    await client.connectTLS({
      hostname: "smtp.gmail.com",
      port: 587,
      username: Deno.env.get("SMTP_USERNAME")!,
      password: Deno.env.get("SMTP_PASSWORD")!,
    })

    // Generate email content
    const emailHtml = generateEmailHTML(invoiceData, message)

    await client.send({
      from: "invoices@guidal.com",
      to: recipient,
      subject: `Invoice - Educational Visit - ${invoiceData.visit.school_name}`,
      content: emailHtml,
      html: true,
    })

    await client.close()

    return new Response(
      JSON.stringify({ success: true, message: 'Invoice sent successfully' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    )
  }
})

function generateEmailHTML(invoiceData: any, customMessage: string): string {
  return `
    <div style="font-family: Arial, sans-serif; max-width: 600px;">
      <div style="text-align: center; margin-bottom: 2rem;">
        <h2 style="color: #1565c0;">🌱 GUIDAL</h2>
        <p>Educational Visits & Sustainability Learning</p>
      </div>

      <div style="background: #f8f9fa; padding: 1.5rem; border-radius: 8px; margin-bottom: 2rem;">
        <h3>Invoice for Educational Visit</h3>
        <p><strong>School:</strong> ${invoiceData.visit.school_name}</p>
        <p><strong>Visit Date:</strong> ${new Date(invoiceData.visit.preferred_date).toLocaleDateString()}</p>
        <p><strong>Students:</strong> ${invoiceData.visit.student_count}</p>
        <p><strong>Total Amount:</strong> €${invoiceData.totals.total.toFixed(2)}</p>
      </div>

      <div style="margin-bottom: 2rem; line-height: 1.6;">
        ${customMessage.replace(/\n/g, '<br>')}
      </div>

      <div style="border-top: 1px solid #ddd; padding-top: 1rem; margin-top: 2rem; color: #666; font-size: 0.9rem;">
        <p>Best regards,<br>
        GUIDAL Team<br>
        📧 info@guidal.com<br>
        🌐 www.guidal.com</p>
      </div>
    </div>
  `
}
*/