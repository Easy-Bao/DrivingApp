import { EmailService } from './email.service.ts';

export class OneTimePasswordStoreService {
  private static readonly oneTimePasswordStore = new Map<string, { code: string; expiresAt: number }>();
  private static readonly ONE_TIME_PASSWORD_TTL_MILLISECONDS = 10 * 60 * 1000;

  static async generateOneTimePasswordCode(
    emailAddress: string,
    action: 'verification' | 'reset' = 'verification'
  ): Promise<string> {
    const normalizedEmailAddress = emailAddress.toLowerCase().trim();
    const generatedCode = Math.floor(100000 + Math.random() * 900000).toString();
    const expirationTimestamp = Date.now() + OneTimePasswordStoreService.ONE_TIME_PASSWORD_TTL_MILLISECONDS;
    OneTimePasswordStoreService.oneTimePasswordStore.set(normalizedEmailAddress, {
      code: generatedCode,
      expiresAt: expirationTimestamp,
    });

    await EmailService.sendOneTimePasswordEmail(normalizedEmailAddress, generatedCode, action);

    return generatedCode;
  }

  static verifyOneTimePasswordCode(emailAddress: string, verificationCode: string): boolean {
    const normalizedEmailAddress = emailAddress.toLowerCase().trim();
    const storedRecord = OneTimePasswordStoreService.oneTimePasswordStore.get(normalizedEmailAddress);
    if (!storedRecord) {
      throw new Error('No verification code record found for this email address');
    }
    if (storedRecord.code !== verificationCode) {
      throw new Error('Invalid verification code');
    }
    if (Date.now() > storedRecord.expiresAt) {
      OneTimePasswordStoreService.oneTimePasswordStore.delete(normalizedEmailAddress);
      throw new Error('Verification code has expired');
    }
    OneTimePasswordStoreService.oneTimePasswordStore.delete(normalizedEmailAddress);
    return true;
  }

  static retrieveOneTimePasswordCodeForTesting(emailAddress: string): string | undefined {
    return OneTimePasswordStoreService.oneTimePasswordStore.get(emailAddress.toLowerCase().trim())?.code;
  }
}
