import nodemailer from 'nodemailer';

export class EmailService {
  static async sendOneTimePasswordEmail(
    toEmail: string,
    otpCode: string,
    action: 'verification' | 'reset' = 'verification'
  ): Promise<boolean> {
    const smtpHost = process.env.SMTP_HOST;
    const smtpPort = process.env.SMTP_PORT ? parseInt(process.env.SMTP_PORT, 10);
    const smtpUser = process.env.SMTP_USER;
    const smtpPass = process.env.SMTP_PASS;

    const subject = action === 'verification'
      ? 'Verify Your DriveApp Account'
      : 'Reset Your DriveApp Password';

    const textContent = action === 'verification'
      ? `Your DriveApp email verification code is: ${otpCode}. This code will expire in 10 minutes.`
      : `Your DriveApp password reset code is: ${otpCode}. This code will expire in 10 minutes.`;

    const htmlContent = `
      <div style="font-family: Arial, sans-serif; padding: 20px; color: #333;">
        <h2 style="color: #2563eb;">DriveApp ${action === 'verification' ? 'Email Verification' : 'Password Reset'}</h2>
        <p>Your 6-digit verification code is:</p>
        <div style="font-size: 32px; font-weight: bold; letter-spacing: 6px; color: #1e293b; padding: 12px; background: #f1f5f9; border-radius: 8px; width: fit-content;">
          ${otpCode}
        </div>
        <p style="margin-top: 16px; color: #64748b; font-size: 14px;">This code will expire in 10 minutes. If you did not request this code, please ignore this email.</p>
      </div>
    `;

    if (!smtpHost || !smtpUser || !smtpPass) {
      console.log(`[EMAIL DISPATCH SKIPPED (Missing SMTP_HOST/SMTP_USER/SMTP_PASS in env)] To: ${toEmail} | Code: ${otpCode}`);
      return false;
    }

    try {
      const transporter = nodemailer.createTransport({
        host: smtpHost,
        port: smtpPort,
        secure: smtpPort === 465,
        auth: {
          user: smtpUser,
          pass: smtpPass,
        },
      });

      await transporter.sendMail({
        from: process.env.SMTP_FROM || `"DriveApp Support" <${smtpUser}>`,
        to: toEmail,
        subject,
        text: textContent,
        html: htmlContent,
      });

      console.log(`[EMAIL SENT SUCCESS] Real OTP email successfully delivered to ${toEmail}`);
      return true;
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      console.error(`[EMAIL DISPATCH ERROR] Failed to send email to ${toEmail}: ${errorMessage}`);
      return false;
    }
  }
}
