import { eq } from 'drizzle-orm';
import {
  RegisterDriverInput,
  LoginDriverInput,
} from '../../schemas/driver/driver.zod.ts';
import { AuthUserResponse } from '../../schemas/common/common.zod.ts';
import { OneTimePasswordStoreService } from '../common/otp_store.ts';
import { JsonWebTokenService } from '../common/jwt.service.ts';
import { driverDb, driversTable } from '../../../shared/drizzle.ts';

export interface DriverSessionResult {
  token: string;
  user: AuthUserResponse;
  needsVerification: boolean;
}

export class DriverAuthenticationService {
  static async verifyDriverAccountState(driverEmailAddress: string): Promise<void> {
    const normalizedEmailAddress = driverEmailAddress.toLowerCase().trim();
    await driverDb.update(driversTable)
      .set({ isVerified: true })
      .where(eq(driversTable.email, normalizedEmailAddress));
  }

  static async updateDriverPassword(driverEmailAddress: string, newPasswordHash: string): Promise<boolean> {
    const normalizedEmailAddress = driverEmailAddress.toLowerCase().trim();
    const [updated] = await driverDb.update(driversTable)
      .set({ passwordHash: newPasswordHash })
      .where(eq(driversTable.email, normalizedEmailAddress))
      .returning();
    return !!updated;
  }

  async registerDriverAccount(driverInput: RegisterDriverInput): Promise<DriverSessionResult> {
    const normalizedEmailAddress = driverInput.email.toLowerCase().trim();

    const [existingAccount] = await driverDb.select()
      .from(driversTable)
      .where(eq(driversTable.email, normalizedEmailAddress));

    if (existingAccount) {
      throw new Error('Driver account with this email address already exists');
    }

    const passwordHash = await Bun.password.hash(driverInput.password);
    const driverId = `drv_${Math.random().toString(36).substring(2, 11)}`;

    const [createdAccount] = await driverDb.insert(driversTable)
      .values({
        id: driverId,
        name: driverInput.name,
        email: normalizedEmailAddress,
        phone: driverInput.phone,
        vehicleType: driverInput.vehicleType,
        plateNumber: driverInput.plateNumber,
        passwordHash,
        isVerified: false,
      })
      .returning();

    await OneTimePasswordStoreService.generateOneTimePasswordCode(normalizedEmailAddress, 'verification');

    const authenticationToken = JsonWebTokenService.generateJsonWebToken(
      createdAccount.id,
      createdAccount.email,
      'driver',
    );

    return {
      token: authenticationToken,
      user: {
        id: createdAccount.id,
        email: createdAccount.email,
        name: createdAccount.name,
        phone: createdAccount.phone,
        role: 'driver',
        isVerified: createdAccount.isVerified,
        createdAt: createdAccount.createdAt,
        vehicleType: createdAccount.vehicleType,
        plateNumber: createdAccount.plateNumber,
        rating: createdAccount.rating,
      },
      needsVerification: true,
    };
  }

  async authenticateDriverCredential(loginInput: LoginDriverInput): Promise<DriverSessionResult> {
    const normalizedEmailAddress = loginInput.email.toLowerCase().trim();

    const [existingAccount] = await driverDb.select()
      .from(driversTable)
      .where(eq(driversTable.email, normalizedEmailAddress));

    if (!existingAccount) {
      throw new Error('Invalid email or password');
    }

    const isPasswordValid = await Bun.password.verify(loginInput.password, existingAccount.passwordHash);
    if (!isPasswordValid) {
      throw new Error('Invalid email or password');
    }

    const authenticationToken = JsonWebTokenService.generateJsonWebToken(
      existingAccount.id,
      existingAccount.email,
      'driver',
    );

    return {
      token: authenticationToken,
      user: {
        id: existingAccount.id,
        email: existingAccount.email,
        name: existingAccount.name,
        phone: existingAccount.phone,
        role: 'driver',
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
