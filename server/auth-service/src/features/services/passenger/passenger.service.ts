import {
  RegisterPassengerInput,
  LoginPassengerInput,
} from '../../schemas/passenger/passenger.zod.ts';
import { AuthUserResponse } from '../../schemas/common/common.zod.ts';
import { OneTimePasswordStoreService } from '../common/otp_store.ts';
import { JsonWebTokenService } from '../common/jwt.service.ts';

export interface PassengerSessionResult {
  token: string;
  user: AuthUserResponse;
  needsVerification: boolean;
}

export interface PassengerAccountRecord {
  id: string;
  email: string;
  phone: string;
  passwordHash: string;
  role: 'passenger';
  name: string;
  preferred_ride_type: string;
  isVerified: boolean;
  createdAt: Date;
}

export class PassengerAuthenticationService {
  private static readonly passengerAccountsStore = new Map<string, PassengerAccountRecord>();

  static verifyPassengerAccountState(passengerEmailAddress: string): void {
    const normalizedEmailAddress = passengerEmailAddress.toLowerCase().trim();
    const existingAccount = PassengerAuthenticationService.passengerAccountsStore.get(normalizedEmailAddress);
    if (existingAccount) {
      existingAccount.isVerified = true;
      PassengerAuthenticationService.passengerAccountsStore.set(normalizedEmailAddress, existingAccount);
    }
  }

  static updatePassengerPassword(passengerEmailAddress: string, newPasswordHash: string): boolean {
    const normalizedEmailAddress = passengerEmailAddress.toLowerCase().trim();
    const existingAccount = PassengerAuthenticationService.passengerAccountsStore.get(normalizedEmailAddress);
    if (existingAccount) {
      existingAccount.passwordHash = newPasswordHash;
      PassengerAuthenticationService.passengerAccountsStore.set(normalizedEmailAddress, existingAccount);
      return true;
    }
    return false;
  }

  async registerPassengerAccount(passengerInput: RegisterPassengerInput): Promise<PassengerSessionResult> {
    const normalizedEmailAddress = passengerInput.email.toLowerCase().trim();
    if (PassengerAuthenticationService.passengerAccountsStore.has(normalizedEmailAddress)) {
      throw new Error('Passenger account with this email address already exists');
    }

    const passwordHash = await Bun.password.hash(passengerInput.password);
    const passengerId = `usr_${Math.random().toString(36).substring(2, 11)}`;
    const creationTimestamp = new Date();

    const passengerAccount: PassengerAccountRecord = {
      id: passengerId,
      email: normalizedEmailAddress,
      phone: passengerInput.phone,
      passwordHash,
      role: 'passenger',
      name: passengerInput.name,
      preferred_ride_type: passengerInput.preferred_ride_type,
      isVerified: false,
      createdAt: creationTimestamp,
    };

    PassengerAuthenticationService.passengerAccountsStore.set(normalizedEmailAddress, passengerAccount);
    await OneTimePasswordStoreService.generateOneTimePasswordCode(passengerAccount.email, 'verification');

    const authenticationToken = JsonWebTokenService.generateJsonWebToken(
      passengerId,
      passengerAccount.email,
      passengerAccount.role,
    );

    return {
      token: authenticationToken,
      user: {
        id: passengerAccount.id,
        email: passengerAccount.email,
        name: passengerAccount.name,
        phone: passengerAccount.phone,
        role: passengerAccount.role,
        isVerified: passengerAccount.isVerified,
        createdAt: passengerAccount.createdAt,
        preferred_ride_type: passengerAccount.preferred_ride_type,
      },
      needsVerification: true,
    };
  }

  async authenticatePassengerCredential(loginInput: LoginPassengerInput): Promise<PassengerSessionResult> {
    const normalizedEmailAddress = loginInput.email.toLowerCase().trim();
    const existingAccount = PassengerAuthenticationService.passengerAccountsStore.get(normalizedEmailAddress);

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
        preferred_ride_type: existingAccount.preferred_ride_type,
      },
      needsVerification: !existingAccount.isVerified,
    };
  }
}
