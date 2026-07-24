import { eq } from 'drizzle-orm';
import {
  RegisterPassengerInput,
  LoginPassengerInput,
} from '../../schemas/passenger/passenger.zod.ts';
import { AuthUserResponse } from '../../schemas/common/common.zod.ts';
import { OneTimePasswordStoreService } from '../common/otp_store.ts';
import { JsonWebTokenService } from '../common/jwt.service.ts';
import { passengerDb, passengersTable } from '../../../shared/drizzle.ts';

export interface PassengerSessionResult {
  token: string;
  user: AuthUserResponse;
  needsVerification: boolean;
}

export class PassengerAuthenticationService {
  static async verifyPassengerAccountState(passengerEmailAddress: string): Promise<void> {
    const normalizedEmailAddress = passengerEmailAddress.toLowerCase().trim();
    await passengerDb.update(passengersTable)
      .set({ isVerified: true })
      .where(eq(passengersTable.email, normalizedEmailAddress));
  }

  static async updatePassengerPassword(passengerEmailAddress: string, newPasswordHash: string): Promise<boolean> {
    const normalizedEmailAddress = passengerEmailAddress.toLowerCase().trim();
    const [updated] = await passengerDb.update(passengersTable)
      .set({ passwordHash: newPasswordHash })
      .where(eq(passengersTable.email, normalizedEmailAddress))
      .returning();
    return !!updated;
  }

  async registerPassengerAccount(passengerInput: RegisterPassengerInput): Promise<PassengerSessionResult> {
    const normalizedEmailAddress = passengerInput.email.toLowerCase().trim();

    const [existingAccount] = await passengerDb.select()
      .from(passengersTable)
      .where(eq(passengersTable.email, normalizedEmailAddress));

    if (existingAccount) {
      throw new Error('Passenger account with this email address already exists');
    }

    const passwordHash = await Bun.password.hash(passengerInput.password);
    const passengerId = `usr_${Math.random().toString(36).substring(2, 11)}`;

    const [createdAccount] = await passengerDb.insert(passengersTable)
      .values({
        id: passengerId,
        name: passengerInput.name,
        email: normalizedEmailAddress,
        phone: passengerInput.phone,
        preferredRideType: passengerInput.preferred_ride_type || 'solo-ride',
        passwordHash,
        isVerified: false,
      })
      .returning();

    await OneTimePasswordStoreService.generateOneTimePasswordCode(normalizedEmailAddress, 'verification');

    const authenticationToken = JsonWebTokenService.generateJsonWebToken(
      createdAccount.id,
      createdAccount.email,
      'passenger',
    );

    return {
      token: authenticationToken,
      user: {
        id: createdAccount.id,
        email: createdAccount.email,
        name: createdAccount.name,
        phone: createdAccount.phone,
        role: 'passenger',
        isVerified: createdAccount.isVerified,
        createdAt: createdAccount.createdAt,
        preferred_ride_type: createdAccount.preferredRideType || 'solo-ride',
      },
      needsVerification: true,
    };
  }

  async authenticatePassengerCredential(loginInput: LoginPassengerInput): Promise<PassengerSessionResult> {
    const normalizedEmailAddress = loginInput.email.toLowerCase().trim();

    const [existingAccount] = await passengerDb.select()
      .from(passengersTable)
      .where(eq(passengersTable.email, normalizedEmailAddress));

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
      'passenger',
    );

    return {
      token: authenticationToken,
      user: {
        id: existingAccount.id,
        email: existingAccount.email,
        name: existingAccount.name,
        phone: existingAccount.phone,
        role: 'passenger',
        isVerified: existingAccount.isVerified,
        createdAt: existingAccount.createdAt,
        preferred_ride_type: existingAccount.preferredRideType || 'solo-ride',
      },
      needsVerification: !existingAccount.isVerified,
    };
  }
}
