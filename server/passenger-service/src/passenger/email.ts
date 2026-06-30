/// Email Helper: manages SMTP nodemailer configuration and real/mock email delivery.
import nodemailer from 'nodemailer';

export async function sendEmail({ to, subject, text }: { to: string; subject: string; text: string }) {
  const host = process.env.SMTP_HOST;
  const port = parseInt(process.env.SMTP_PORT || '587');
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;

  console.log(`[EMAIL DISPATCHING] To: ${to} | Subject: ${subject}`);

  if (!user || !pass) {
    console.log(`[EMAIL LOG FALLBACK (No SMTP config)] To: ${to} | Subject: ${subject} | Message: ${text}`);
    return;
  }

  const transporter = nodemailer.createTransport({
    host: host || 'smtp.gmail.com',
    port: port,
    secure: port === 465,
    auth: {
      user: user,
      pass: pass,
    },
  });

  try {
    await transporter.sendMail({
      from: `"EasyRide Support" <${user}>`,
      to,
      subject,
      text,
    });
    console.log(`[EMAIL SENT SUCCESS] To: ${to}`);
  } catch (error) {
    console.error(`[EMAIL SEND ERROR] Failed to send email to ${to}:`, error);
  }
}
