// Thin client for the Eskiz.uz SMS gateway (https://notify.eskiz.uz/api).
// Used to deliver the 4-digit phone-verification codes for login/registration.
//
// Eskiz issues a bearer token from /auth/login that's valid for ~30 days; we
// cache it in memory and only re-authenticate when a call comes back 401, so
// normal operation costs zero extra requests per SMS sent.

const ESKIZ_BASE_URL = process.env.ESKIZ_BASE_URL || 'https://notify.eskiz.uz/api';
const ESKIZ_EMAIL = process.env.ESKIZ_EMAIL;
const ESKIZ_PASSWORD = process.env.ESKIZ_PASSWORD;
// Sender name ("nickname") shown to recipients. Set this to the nickname
// approved under the Eskiz contract; the shared "4546" sender is the
// unmoderated fallback and only works with the fixed test message below.
const ESKIZ_SENDER = process.env.ESKIZ_SENDER || '4546';
const ESKIZ_TEST_MODE = process.env.ESKIZ_TEST_MODE === 'true';
const ESKIZ_TIMEOUT_MS = 10_000;

let cachedToken: string | null = null;
let loginInFlight: Promise<string> | null = null;

if (ESKIZ_TEST_MODE && process.env.NODE_ENV === 'production') {
  console.warn('ESKIZ_TEST_MODE is on in production — users will receive "This is test from Eskiz" instead of their code.');
}

async function login(): Promise<string> {
  if (!ESKIZ_EMAIL || !ESKIZ_PASSWORD) {
    throw new Error('ESKIZ_EMAIL / ESKIZ_PASSWORD is not set. Define them in backend/.env.');
  }
  // Several sends can hit an expired token at once; share a single login call.
  if (loginInFlight) return loginInFlight;
  loginInFlight = (async () => {
    const res = await fetch(`${ESKIZ_BASE_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: ESKIZ_EMAIL, password: ESKIZ_PASSWORD }),
      signal: AbortSignal.timeout(ESKIZ_TIMEOUT_MS),
    });
    if (!res.ok) {
      throw new Error(`Eskiz login failed: ${res.status} ${await res.text()}`);
    }
    const json = await res.json() as { data?: { token?: string } };
    const token = json.data?.token;
    if (!token) throw new Error('Eskiz login did not return a token');
    cachedToken = token;
    return token;
  })().finally(() => {
    loginInFlight = null;
  });
  return loginInFlight;
}

async function sendRaw(mobilePhone: string, message: string, retry = true): Promise<void> {
  const token = cachedToken || (await login());
  const res = await fetch(`${ESKIZ_BASE_URL}/message/sms/send`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      mobile_phone: mobilePhone,
      message,
      from: ESKIZ_SENDER,
    }),
    signal: AbortSignal.timeout(ESKIZ_TIMEOUT_MS),
  });
  if (res.status === 401 && retry) {
    cachedToken = null;
    return sendRaw(mobilePhone, message, false);
  }
  if (!res.ok) {
    throw new Error(`Eskiz send failed: ${res.status} ${await res.text()}`);
  }
}

// Eskiz requires the phone without a leading "+" (e.g. "998901234567").
function toEskizFormat(phoneNumber: string): string {
  return phoneNumber.replace(/^\+/, '');
}

export async function sendSms(phoneNumber: string, message: string): Promise<void> {
  const mobilePhone = toEskizFormat(phoneNumber);
  // Unmoderated Eskiz accounts can only deliver this exact sentence. Keep
  // ESKIZ_TEST_MODE off once the contract's sender nickname and message
  // template are approved.
  const body = ESKIZ_TEST_MODE ? 'This is test from Eskiz' : message;
  await sendRaw(mobilePhone, body);
}

// Eskiz only delivers text matching a template approved in its dashboard.
// This is approved template #90709 ("%d" = the code) — note the double space
// after "Academyga", it's part of the approved wording. Changing anything here
// without getting a new template approved makes Eskiz reject the send.
export function buildOtpMessage(code: string): string {
  return `Kodni hech kimga bermang! Chust One Academyga  kirish uchun tasdiqlash kodi: ${code}`;
}
