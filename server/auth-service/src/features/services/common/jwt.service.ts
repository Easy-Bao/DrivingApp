import jwt from 'jsonwebtoken';

export interface DecodedJwtTokenPayload {
  sub: string;
  email: string;
  role: string;
}

export class JsonWebTokenService {
  private static getJwtSecret(): string {
    const secret = process.env.JWT_SECRET;
    if (!secret || secret.trim().length === 0) {
      throw new Error('Security Configuration Error: JWT_SECRET environment variable is missing.');
    }
    return secret;
  }

  static generateJsonWebToken(userId: string, email: string, role: string): string {
    const secret = JsonWebTokenService.getJwtSecret();
    return jwt.sign(
      { sub: userId, email, role },
      secret,
      { expiresIn: '7d' },
    );
  }

  static verifyJsonWebToken(token: string): { userId: string; email: string; role: string } {
    try {
      const secret = JsonWebTokenService.getJwtSecret();
      const decoded = jwt.verify(token, secret) as unknown as DecodedJwtTokenPayload;
      if (!decoded || typeof decoded.sub !== 'string' || typeof decoded.email !== 'string') {
        throw new Error('Invalid token payload structure');
      }
      return {
        userId: decoded.sub,
        email: decoded.email,
        role: decoded.role,
      };
    } catch (_) {
      throw new Error('Invalid or expired authentication token');
    }
  }
}
