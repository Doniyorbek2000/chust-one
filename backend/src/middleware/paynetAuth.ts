import { Request, Response, NextFunction } from 'express';

const PAYNET_LOGIN = process.env.PAYNET_LOGIN;
const PAYNET_PASSWORD = process.env.PAYNET_PASSWORD;

// Paynet authenticates with HTTP Basic Auth, not our JWT scheme — this is a
// separate check from requireAuth, matched against credentials we hand Paynet
// out-of-band (their integration form), not a user account.
export function requirePaynetAuth(req: Request, res: Response, next: NextFunction) {
  if (!PAYNET_LOGIN || !PAYNET_PASSWORD) {
    return res.status(500).json({ jsonrpc: '2.0', id: req.body?.id ?? null, error: { code: -32603, message: 'Paynet credentials not configured' } });
  }

  const header = req.headers.authorization;
  if (!header || !header.startsWith('Basic ')) {
    res.set('WWW-Authenticate', 'Basic');
    return res.status(401).json({ jsonrpc: '2.0', id: req.body?.id ?? null, error: { code: -32504, message: 'Authorization required' } });
  }

  const decoded = Buffer.from(header.slice('Basic '.length), 'base64').toString('utf-8');
  const separatorIndex = decoded.indexOf(':');
  const username = separatorIndex === -1 ? decoded : decoded.slice(0, separatorIndex);
  const password = separatorIndex === -1 ? '' : decoded.slice(separatorIndex + 1);

  if (username !== PAYNET_LOGIN || password !== PAYNET_PASSWORD) {
    res.set('WWW-Authenticate', 'Basic');
    return res.status(401).json({ jsonrpc: '2.0', id: req.body?.id ?? null, error: { code: -32504, message: 'Invalid credentials' } });
  }

  next();
}
