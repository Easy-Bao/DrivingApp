import { describe, expect, spyOn, test } from 'bun:test';
import { EmailService } from '../src/features/services/common/email.service.ts';

describe('EmailService privacy', () => {
  test('does not log the recipient or OTP when SMTP is unavailable', async () => {
    const previousEnvironment = {
      deliveryDisabled: process.env.EMAIL_DELIVERY_DISABLED,
      host: process.env.SMTP_HOST,
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS,
    };
    const log = spyOn(console, 'log').mockImplementation(() => {});
    const recipient = 'private@example.com';
    const otp = '123456';

    delete process.env.EMAIL_DELIVERY_DISABLED;
    delete process.env.SMTP_HOST;
    delete process.env.SMTP_USER;
    delete process.env.SMTP_PASS;

    try {
      expect(await EmailService.sendOneTimePasswordEmail(recipient, otp)).toBe(false);
      const output = log.mock.calls.flat().join(' ');
      expect(output).not.toContain(recipient);
      expect(output).not.toContain(otp);
    } finally {
      log.mockRestore();
      restoreEnvironment('EMAIL_DELIVERY_DISABLED', previousEnvironment.deliveryDisabled);
      restoreEnvironment('SMTP_HOST', previousEnvironment.host);
      restoreEnvironment('SMTP_USER', previousEnvironment.user);
      restoreEnvironment('SMTP_PASS', previousEnvironment.pass);
    }
  });
});

function restoreEnvironment(name: string, value: string | undefined): void {
  if (value === undefined) {
    delete process.env[name];
    return;
  }

  process.env[name] = value;
}
