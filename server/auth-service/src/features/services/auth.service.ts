import argon2 from 'argon2';
import jwt from 'jsonwebtoken';
import {
  RegisterPassengerInput,
  RegisterDriverInput,
  LoginAuthInput,
  VerifyOtpAuthInput,
  AuthUserResponse,
} from '../schemas/auth.zod.ts';

export interface AuthSessionResult {
  token: string;
  user: AuthUserResponse;
  needsVerification: boolean;
}

interface BaseAccount {
  id: string;
  email: string;
  phone: string;
  passwordHash: string;
  name: string;
  isVerified: boolean;
  createdAt: Date;
}

export interface DriverAccountRecord extends BaseAccount {
  role: 'driver';
  vehicleType: string;
  plateNumber: string;
  rating: number;
}

export interface PassengerAccountRecord extends BaseAccount {
  role: 'passenger';
  preferred_ride_type?: string;
}

export type AccountRecord = DriverAccountRecord | PassengerAccountRecord;

export class AuthService {
  private static readonly JWT_SECRET = process.env.JWT_SECRET || 'dev_jwt_secret_key_12345';
  private static readonly JWT_EXPIRES_IN = '7d';

  // In-memory fallback account store for testing/service isolation
  private static readonly inMemoryAccounts = new Map<string, AccountRecord>();

  private static readonly inMemoryOtps = new Map<string, { code: string; expiresAt: number }>();

  static getOtpForTest(email: string): string | undefined {
    return AuthService.inMemoryOtps.get(email.toLowerCase().trim())?.code;
  }

  async registerPassenger(input: RegisterPassengerInput): Promise<AuthSessionResult> {
    const emailKey = `passenger:${input.email.toLowerCase().trim()}`;
    if (AuthService.inMemoryAccounts.has(emailKey)) {
      throw new Error('Passenger account with this email already exists');
    }

    const passwordHash = await argon2.hash(input.password);
    const userId = `usr_${Math.random().toString(36).substring(2, 11)}`;
    const now = new Date();

    const account: PassengerAccountRecord = {
      id: userId,
      email: input.email.toLowerCase().trim(),
      phone: input.phone,
      passwordHash,
      role: 'passenger',
      name: input.name,
      preferred_ride_type: input.preferred_ride_type,
      isVerified: false,
      createdAt: now,
    };

    AuthService.inMemoryAccounts.set(emailKey, account);

    const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = Date.now() + 10 * 60 * 1000;
    AuthService.inMemoryOtps.set(account.email, { code: otpCode, expiresAt });

    console.log(`[PASSENGER OTP DISPATCH] Email: ${account.email} | Code: ${otpCode}`);

    const token = this.generateJwt(userId, account.email, account.role);

    return {
      token,
      user: {
        id: account.id,
        email: account.email,
        name: account.name,
        phone: account.phone,
        role: account.role,
        isVerified: account.isVerified,
        createdAt: account.createdAt,
        preferred_ride_type: account.preferred_ride_type,
      },
      needsVerification: true,
    };
  }

  async registerDriver(input: RegisterDriverInput): Promise<AuthSessionResult> {
    const emailKey = `driver:${input.email.toLowerCase().trim()}`;
    if (AuthService.inMemoryAccounts.has(emailKey)) {
      throw new Error('Driver account with this email already exists');
    }

    const passwordHash = await argon2.hash(input.password);
    const userId = `drv_${Math.random().toString(36).substring(2, 11)}`;
    const now = new Date();

    const account: DriverAccountRecord = {
      id: userId,
      email: input.email.toLowerCase().trim(),
      phone: input.phone,
      passwordHash,
      role: 'driver',
      name: input.name,
      vehicleType: input.vehicleType || 'Bao Bao',
      plateNumber: input.plateNumber || 'ABC 1234',
      rating: 5.0,
      isVerified: false,
      createdAt: now,
    };

    AuthService.inMemoryAccounts.set(emailKey, account);

    const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = Date.now() + 10 * 60 * 1000;
    AuthService.inMemoryOtps.set(account.email, { code: otpCode, expiresAt });

    console.log(`[DRIVER OTP DISPATCH] Email: ${account.email} | Code: ${otpCode}`);

    const token = this.generateJwt(userId, account.email, account.role);

    return {
      token,
      user: {
        id: account.id,
        email: account.email,
        name: account.name,
        phone: account.phone,
        role: account.role,
        isVerified: account.isVerified,
        createdAt: account.createdAt,
        vehicleType: account.vehicleType,
        plateNumber: account.plateNumber,
        rating: account.rating,
      },
      needsVerification: true,
    };
  }

  async authenticateUser(input: LoginAuthInput, role: 'passenger' | 'driver'): Promise<AuthSessionResult> {
    const emailKey = `${role}:${input.email.toLowerCase().trim()}`;
    let account = AuthService.inMemoryAccounts.get(emailKey);

    if (!account) {
      // Auto-provision demo account with Argon2 for seamless development flow
      const passwordHash = await argon2.hash(input.password);
      const userId = `${role === 'driver' ? 'drv' : 'usr'}_${Math.random().toString(36).substring(2, 11)}`;
      const now = new Date();
      if (role === 'driver') {
        account = {
          id: userId,
          email: input.email.toLowerCase().trim(),
          phone: '+639170000000',
          passwordHash,
          role: 'driver',
          name: input.email.split('@')[0],
          vehicleType: 'Bao Bao',
          plateNumber: 'ABC 1234',
          rating: 5.0,
          isVerified: true,
          createdAt: now,
        } as DriverAccountRecord;
      } else {
        account = {
          id: userId,
          email: input.email.toLowerCase().trim(),
          phone: '+639170000000',
          passwordHash,
          role: 'passenger',
          name: input.email.split('@')[0],
          preferred_ride_type: 'solo-ride',
          isVerified: true,
          createdAt: now,
        } as PassengerAccountRecord;
      }
      AuthService.inMemoryAccounts.set(emailKey, account);
    } else {
      // Argon2 password verification
      const isValid = await argon2.verify(account.passwordHash, input.password);
      if (!isValid) {
        throw new Error('Invalid email or password');
      }
    }

    const token = this.generateJwt(account.id, account.email, account.role);

    const baseUserResponse: AuthUserResponse = {
      id: account.id,
      email: account.email,
      name: account.name,
      phone: account.phone,
      role: account.role,
      isVerified: account.isVerified,
      createdAt: account.createdAt,
    };

    if (account.role === 'driver') {
      baseUserResponse.vehicleType = (account as DriverAccountRecord).vehicleType;
      baseUserResponse.plateNumber = (account as DriverAccountRecord).plateNumber;
      baseUserResponse.rating = (account as DriverAccountRecord).rating;
    } else {
      baseUserResponse.preferred_ride_type = (account as PassengerAccountRecord).preferred_ride_type;
    }

    return {
      token,
      user: baseUserResponse,
      needsVerification: !account.isVerified,
    };
  }

  async sendForgotPasswordOtp(email: string): Promise<{ success: boolean }> {
    const normalizedEmail = email.toLowerCase().trim();
    const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = Date.now() + 10 * 60 * 1000;
    AuthService.inMemoryOtps.set(normalizedEmail, { code: otpCode, expiresAt });
    console.log(`[PASSWORD RESET OTP DISPATCH] Email: ${normalizedEmail} | Code: ${otpCode}`);
    return { success: true };
  }

  async verifyOtpCode(input: VerifyOtpAuthInput): Promise<{ verified: boolean }> {
    const normalizedEmail = input.email.toLowerCase().trim();
    const record = AuthService.inMemoryOtps.get(normalizedEmail);

    if (!record || record.code !== input.code || Date.now() > record.expiresAt) {
      throw new Error('Invalid or expired verification code');
    }

    AuthService.inMemoryOtps.delete(normalizedEmail);

    // Mark account verified
    for (const [key, account] of AuthService.inMemoryAccounts.entries()) {
      if (account.email === normalizedEmail) {
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
