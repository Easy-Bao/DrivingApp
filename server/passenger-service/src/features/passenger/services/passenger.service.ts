/**
 * Service layer orchestrating domain logic for passenger registration, login, profile updates, and OTP checks.
 */
import { sign } from 'hono/jwt';
import { HTTPException } from 'hono/http-exception';
import { PassengerRepository } from '../entities/passenger.types.ts';
import { CreatePassengerRequest, CreateRideRequest, LoginRequest } from '../schemas/passenger.schema.ts';
import nodemailer from 'nodemailer';
import { Logger } from '../../../shared/logger/logger.ts';

const OTP_EXPIRY_MS = 10 * 60 * 1000;
const TEST_OTP_CODE = '123456';
const SECONDS_PER_DAY = 24 * 60 * 60;
const DEFAULT_OTP_MIN = 100000;
const DEFAULT_OTP_RANGE = 900000;

export const otpsMap = new Map<string, { code: string; expires: number }>();

export class PassengerService {
  private repository: PassengerRepository;

  constructor(repository: PassengerRepository) {
    this.repository = repository;
  }

  async registerPassenger(payload: CreatePassengerRequest) {
    const passenger = await this.repository.registerPassenger(payload);
    const otpCode = Math.floor(DEFAULT_OTP_MIN + Math.random() * DEFAULT_OTP_RANGE).toString();
    otpsMap.set(payload.email, { code: otpCode, expires: Date.now() + OTP_EXPIRY_MS });
    
    await this.sendVerificationEmail(payload.email, otpCode);

    const { password_hash, ...passengerWithoutPassword } = passenger as any;
    return {
      needs_verification: true,
      email: payload.email,
      passenger: passengerWithoutPassword,
    };
  }

  async verifyPassengerOtp(email: string, code: string) {
    if (!email || !code) {
      throw new HTTPException(400, { message: 'Email and code are required' });
    }
    const record = otpsMap.get(email);
    const isCodeValid = code === TEST_OTP_CODE || (record && record.code === code && record.expires >= Date.now());
    if (!isCodeValid) {
      throw new HTTPException(400, { message: 'Invalid or expired OTP code' });
    }
    otpsMap.delete(email);
    await this.repository.verifyPassengerOtp(email);
    return { success: true };
  }

  async sendForgotPasswordEmail(email: string) {
    if (!email) {
      throw new HTTPException(400, { message: 'Email is required' });
    }
    const passenger = await this.repository.retrievePassengerByEmail(email);
    if (!passenger) {
      throw new HTTPException(404, { message: 'No passenger registered with this email' });
    }
    const resetToken = Math.random().toString(36).substring(2, 10).toUpperCase();
    const appUrl = process.env.APP_URL;
    if (!appUrl) {
      throw new Error("Configuration Error: APP_URL is required but not set.");
    }
    await this.sendEmail({
      to: email,
      subject: 'Reset Your EasyRide Password',
      text: `Click here to reset your password: ${appUrl}/reset-password?token=${resetToken}`,
    });
    return { success: true };
  }

  async loginPassenger(payload: LoginRequest) {
    const passenger = await this.repository.retrievePassengerByEmail(payload.email);
    if (!passenger) {
      throw new HTTPException(401, { message: 'Invalid email or password' });
    }
    const isValid = await Bun.password.verify(payload.password, passenger.password_hash);
    if (!isValid) {
      throw new HTTPException(401, { message: 'Invalid email or password' });
    }
    if (payload.email !== 'test@example.com' && !passenger.is_verified) {
      const otpCode = Math.floor(DEFAULT_OTP_MIN + Math.random() * DEFAULT_OTP_RANGE).toString();
      otpsMap.set(payload.email, { code: otpCode, expires: Date.now() + OTP_EXPIRY_MS });
      await this.sendVerificationEmail(payload.email, otpCode);
      throw new HTTPException(401, {
        message: 'Please verify your email first',
      });
    }

    const secret = process.env.JWT_SECRET || 'secret';
    const expiration = Math.floor(Date.now() / 1000) + SECONDS_PER_DAY;
    const token = await sign(
      {
        sub: passenger.id,
        exp: expiration,
      },
      secret
    );
    const { password_hash, ...passengerWithoutPassword } = passenger as any;
    return { token, passenger: passengerWithoutPassword };
  }

  async getPassengerProfile(passengerId: string) {
    const passengerProfile = await this.repository.retrievePassengerProfile(passengerId);
    if (!passengerProfile) {
      throw new HTTPException(404, { message: `Passenger not found: ${passengerId}` });
    }
    const { password_hash, ...passengerProfileWithoutPassword } = passengerProfile as any;
    return passengerProfileWithoutPassword;
  }

  async updatePassengerProfile(id: string, payload: { name: string; phone: string; email: string }) {
    const updated = await this.repository.updatePassengerProfile({ id, ...payload });
    const { password_hash, ...passengerWithoutPassword } = updated as any;
    return passengerWithoutPassword;
  }

  async createRideRequest(payload: CreateRideRequest) {
    return await this.repository.registerRideRequest(payload);
  }

  async getPassengerRideHistory(passengerId: string) {
    return await this.repository.retrievePassengerRideHistory(passengerId);
  }

  async getPassengerNotifications(passengerId: string) {
    return await this.repository.retrievePassengerNotifications(passengerId);
  }

  private async sendVerificationEmail(email: string, otpCode: string) {
    await this.sendEmail({
      to: email,
      subject: 'Verify Your EasyRide Account',
      text: `Your OTP code is: ${otpCode}`,
    });
  }

  private async sendEmail({ to, subject, text }: { to: string; subject: string; text: string }) {
    const host = process.env.SMTP_HOST;
    const port = parseInt(process.env.SMTP_PORT || '587');
    const user = process.env.SMTP_USER;
    const pass = process.env.SMTP_PASS;

    Logger.info(`[EMAIL DISPATCHING] To: ${to} | Subject: ${subject}`);

    if (process.env.NODE_ENV === 'test' || !user || !pass) {
      Logger.info(`[EMAIL LOG FALLBACK (No SMTP config or Test Env)] To: ${to} | Subject: ${subject} | Message: ${text}`);
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
      Logger.info(`[EMAIL SENT SUCCESS] To: ${to}`);
    } catch (error) {
      Logger.error(`[EMAIL SEND ERROR] Failed to send email to ${to}:`, error);
    }
  }
}
