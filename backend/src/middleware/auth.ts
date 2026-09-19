import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

const rawJwtSecret = process.env.JWT_SECRET;
if (!rawJwtSecret) {
  throw new Error('JWT_SECRET is not set. Define it in backend/.env before starting the server.');
}
const JWT_SECRET: string = rawJwtSecret;
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';

export interface AuthUser {
  id: string;
  role: string;
}

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      user?: AuthUser;
    }
  }
}

export function generateToken(user: AuthUser): string {
  return jwt.sign({ id: user.id, role: user.role }, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN } as jwt.SignOptions);
}

// Short-lived token proving a phone number was just OTP-verified, handed to
// the client between "code confirmed" and "registration form submitted" so
// the server doesn't need to keep server-side session state for that gap.
const REGISTRATION_TOKEN_EXPIRES_IN = '15m';

export function generateRegistrationToken(phoneNumber: string): string {
  return jwt.sign({ phoneNumber, purpose: 'REGISTRATION' }, JWT_SECRET, { expiresIn: REGISTRATION_TOKEN_EXPIRES_IN });
}

export function verifyRegistrationToken(token: string): string {
  const decoded = jwt.verify(token, JWT_SECRET) as { phoneNumber?: string; purpose?: string };
  if (decoded.purpose !== 'REGISTRATION' || !decoded.phoneNumber) {
    throw new Error('Invalid registration token');
  }
  return decoded.phoneNumber;
}

export function requireAuth(req: Request, res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ success: false, error: 'Avtorizatsiya talab qilinadi' });
  }
  try {
    const token = header.slice('Bearer '.length);
    const decoded = jwt.verify(token, JWT_SECRET) as AuthUser;
    req.user = { id: decoded.id, role: decoded.role };
    next();
  } catch {
    return res.status(401).json({ success: false, error: 'Token yaroqsiz yoki muddati o\'tgan' });
  }
}

export function optionalAuth(req: Request, res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (header && header.startsWith('Bearer ')) {
    try {
      const token = header.slice('Bearer '.length);
      const decoded = jwt.verify(token, JWT_SECRET) as AuthUser;
      req.user = { id: decoded.id, role: decoded.role };
    } catch {
      // ignore invalid token for optional auth
    }
  }
  next();
}

export function requireAdmin(req: Request, res: Response, next: NextFunction) {
  if (!req.user || !['ADMIN', 'SUPER_ADMIN'].includes(req.user.role)) {
    return res.status(403).json({ success: false, error: 'Admin huquqi talab qilinadi' });
  }
  next();
}
