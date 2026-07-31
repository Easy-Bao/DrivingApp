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
    return JsonWebTokenService.generateToken(userId, email, role, '7d');
  }

  /**
   * Admin sessions are intentionally shorter than passenger and driver sessions.
   */
  static generateAdminJsonWebToken(userId: string, email: string): string {
    return JsonWebTokenService.generateToken(userId, email, 'admin', '8h');
  }

  private static generateToken(
    userId: string,
    email: string,
    role: string,
    expiresIn: '7d' | '8h',
  ): string {
    const secret = JsonWebTokenService.getJwtSecret();
    return jwt.sign(
      { sub: userId, email, role },
      secret,
      { expiresIn },
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
