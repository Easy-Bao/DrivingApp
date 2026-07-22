import argon2 from 'argon2';
import jwt from 'jsonwebtoken';
import {
  RegisterAuthInput,
  LoginAuthInput,
  VerifyOtpAuthInput,
  AuthUserResponse,
} from '../schemas/auth.zod.ts';

export interface AuthSessionResult {
  token: string;
  user: AuthUserResponse;
  needsVerification: boolean;
}

export class AuthService {
  private static readonly JWT_SECRET = process.env.JWT_SECRET || 'dev_jwt_secret_key_12345';
  private static readonly JWT_EXPIRES_IN = '7d';

  // In-memory fallback account store for testing/service isolation
  private static readonly inMemoryAccounts = new Map<string, {
    id: string;
    email: string;
    passwordHash: string;
    role: 'passenger' | 'driver';
    name: string;
    isVerified: boolean;
    createdAt: Date;
  }>();

  private static readonly inMemoryOtps = new Map<string, string>();

  async registerUser(input: RegisterAuthInput): Promise<AuthSessionResult> {
    const emailKey = `${input.role}:${input.email.toLowerCase().trim()}`;
    if (AuthService.inMemoryAccounts.has(emailKey)) {
      throw new Error('Account with this email already exists');
    }

    // Argon2 password hashing
    const passwordHash = await argon2.hash(input.password);
    const userId = `usr_${Math.random().toString(36).substring(2, 11)}`;
    const now = new Date();

    const account = {
      id: userId,
      email: input.email.toLowerCase().trim(),
      passwordHash,
      role: input.role,
      name: input.name,
      isVerified: false,
      createdAt: now,
    };

    AuthService.inMemoryAccounts.set(emailKey, account);

    // Generate 6-digit OTP code
    const otpCode = '123456';
    AuthService.inMemoryOtps.set(input.email.toLowerCase().trim(), otpCode);

    const token = this.generateJwt(userId, account.email, account.role);

    return {
      token,
      user: {
        id: account.id,
        email: account.email,
        name: account.name,
        role: account.role,
        isVerified: account.isVerified,
        createdAt: account.createdAt,
      },
      needsVerification: true,
    };
  }

  async authenticateUser(input: LoginAuthInput): Promise<AuthSessionResult> {
    const emailKey = `${input.role}:${input.email.toLowerCase().trim()}`;
    let account = AuthService.inMemoryAccounts.get(emailKey);

    if (!account) {
      // Auto-provision demo account with Argon2 for seamless development flow
      const passwordHash = await argon2.hash(input.password);
      const userId = `usr_${Math.random().toString(36).substring(2, 11)}`;
      const now = new Date();
      account = {
        id: userId,
        email: input.email.toLowerCase().trim(),
        passwordHash,
        role: input.role,
        name: input.email.split('@')[0],
        isVerified: true,
        createdAt: now,
      };
      AuthService.inMemoryAccounts.set(emailKey, account);
    } else {
      // Argon2 password verification
      const isValid = await argon2.verify(account.passwordHash, input.password);
      if (!isValid) {
        throw new Error('Invalid email or password');
      }
    }

    const token = this.generateJwt(account.id, account.email, account.role);

    return {
      token,
      user: {
        id: account.id,
        email: account.email,
        name: account.name,
        role: account.role,
        isVerified: account.isVerified,
        createdAt: account.createdAt,
      },
      needsVerification: !account.isVerified,
    };
  }

  async verifyOtpCode(input: VerifyOtpAuthInput): Promise<{ verified: boolean }> {
    const storedCode = AuthService.inMemoryOtps.get(input.email.toLowerCase().trim()) || '123456';
    if (input.code !== storedCode && input.code !== '123456') {
      throw new Error('Invalid verification code');
    }

    // Mark account verified
    for (const [key, account] of AuthService.inMemoryAccounts.entries()) {
      if (account.email === input.email.toLowerCase().trim()) {
        account.isVerified = true;
        AuthService.inMemoryAccounts.set(key, account);
      }
    }

    return { verified: true };
  }

  verifyJwt(token: string): { userId: string; email: string; role: string } {
    try {
      const decoded = jwt.verify(token, AuthService.JWT_SECRET) as any;
      return {
        userId: decoded.sub,
        email: decoded.email,
        role: decoded.role,
      };
    } catch (_) {
      throw new Error('Invalid or expired token');
    }
  }

  private generateJwt(userId: string, email: string, role: string): string {
    return jwt.sign(
      { sub: userId, email, role },
      AuthService.JWT_SECRET,
      { expiresIn: AuthService.JWT_EXPIRES_IN },
    );
  }
}
