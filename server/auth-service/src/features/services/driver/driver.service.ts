import argon2 from 'argon2';
import {
  RegisterDriverInput,
  LoginDriverInput,
} from '../../schemas/driver/driver.zod.ts';
import { AuthUserResponse } from '../../schemas/common/common.zod.ts';
import { OneTimePasswordStoreService } from '../common/otp_store.ts';
import { JsonWebTokenService } from '../common/jwt.service.ts';

export interface DriverSessionResult {
  token: string;
  user: AuthUserResponse;
  needsVerification: boolean;
}

export interface DriverAccountRecord {
  id: string;
  email: string;
  phone: string;
  passwordHash: string;
  role: 'driver';
  name: string;
  vehicleType: string;
  plateNumber: string;
  rating: number;
  isVerified: boolean;
  createdAt: Date;
}

export class DriverAuthenticationService {
  private static readonly driverAccountsStore = new Map<string, DriverAccountRecord>();

  static verifyDriverAccountState(driverEmailAddress: string): void {
    const normalizedEmailAddress = driverEmailAddress.toLowerCase().trim();
    const existingAccount = DriverAuthenticationService.driverAccountsStore.get(normalizedEmailAddress);
    if (existingAccount) {
      existingAccount.isVerified = true;
      DriverAuthenticationService.driverAccountsStore.set(normalizedEmailAddress, existingAccount);
    }
  }

  async registerDriverAccount(driverInput: RegisterDriverInput): Promise<DriverSessionResult> {
    const normalizedEmailAddress = driverInput.email.toLowerCase().trim();
    if (DriverAuthenticationService.driverAccountsStore.has(normalizedEmailAddress)) {
      throw new Error('Driver account with this email address already exists');
    }

    const passwordHash = await argon2.hash(driverInput.password);
    const driverId = `drv_${Math.random().toString(36).substring(2, 11)}`;
    const creationTimestamp = new Date();

    const driverAccount: DriverAccountRecord = {
      id: driverId,
      email: normalizedEmailAddress,
      phone: driverInput.phone,
      passwordHash,
      role: 'driver',
      name: driverInput.name,
      vehicleType: driverInput.vehicleType,
      plateNumber: driverInput.plateNumber,
      rating: 5.0,
      isVerified: false,
      createdAt: creationTimestamp,
    };

    DriverAuthenticationService.driverAccountsStore.set(normalizedEmailAddress, driverAccount);
    OneTimePasswordStoreService.generateOneTimePasswordCode(driverAccount.email);

    const authenticationToken = JsonWebTokenService.generateJsonWebToken(
      driverId,
      driverAccount.email,
      driverAccount.role,
    );

    return {
      token: authenticationToken,
      user: {
        id: driverAccount.id,
        email: driverAccount.email,
        name: driverAccount.name,
        phone: driverAccount.phone,
        role: driverAccount.role,
        isVerified: driverAccount.isVerified,
        createdAt: driverAccount.createdAt,
        vehicleType: driverAccount.vehicleType,
        plateNumber: driverAccount.plateNumber,
        rating: driverAccount.rating,
      },
      needsVerification: true,
    };
  }

  async authenticateDriverCredential(loginInput: LoginDriverInput): Promise<DriverSessionResult> {
    const normalizedEmailAddress = loginInput.email.toLowerCase().trim();
    const existingAccount = DriverAuthenticationService.driverAccountsStore.get(normalizedEmailAddress);

    if (!existingAccount) {
      throw new Error('Invalid email or password');
    }

    const isPasswordValid = await argon2.verify(existingAccount.passwordHash, loginInput.password);
    if (!isPasswordValid) {
      throw new Error('Invalid email or password');
    }

    const authenticationToken = JsonWebTokenService.generateJsonWebToken(
      existingAccount.id,
      existingAccount.email,
      existingAccount.role,
    );

    return {
      token: authenticationToken,
      user: {
        id: existingAccount.id,
        email: existingAccount.email,
        name: existingAccount.name,
        phone: existingAccount.phone,
        role: existingAccount.role,
        isVerified: existingAccount.isVerified,
        createdAt: existingAccount.createdAt,
        vehicleType: existingAccount.vehicleType,
        plateNumber: existingAccount.plateNumber,
        rating: existingAccount.rating,
      },
      needsVerification: !existingAccount.isVerified,
    };
  }
}
