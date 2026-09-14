import { Router, Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import crypto from 'crypto';

const prisma = new PrismaClient();
export const clickRouter = Router();

const CLICK_SERVICE_ID = process.env.CLICK_SERVICE_ID;
const CLICK_SECRET_KEY = process.env.CLICK_SECRET_KEY;

// Click's Shop API error codes — same table their own PHP/Laravel/Yii2
// integration packages use. 0 is the only "success" value; everything else
// is returned in the `error` field of our response, never as an HTTP status.
const ClickError = {
  SUCCESS: 0,
  SIGN_CHECK_FAILED: -1,
  INCORRECT_AMOUNT: -2,
  ACTION_NOT_FOUND: -3,
  ALREADY_PAID: -4,
  USER_NOT_FOUND: -5,
  TRANSACTION_NOT_FOUND: -6,
  FAILED_TO_UPDATE: -7,
  BAD_REQUEST: -8,
  TRANSACTION_CANCELLED: -9,
} as const;

const ClickErrorNote: Record<number, string> = {
  [ClickError.SUCCESS]: 'Success',
  [ClickError.SIGN_CHECK_FAILED]: 'SIGN CHECK FAILED',
  [ClickError.INCORRECT_AMOUNT]: 'Incorrect parameter amount',
  [ClickError.ACTION_NOT_FOUND]: 'Action not found',
  [ClickError.ALREADY_PAID]: 'Already paid',
  [ClickError.USER_NOT_FOUND]: 'User does not exist',
  [ClickError.TRANSACTION_NOT_FOUND]: 'Transaction does not exist',
  [ClickError.FAILED_TO_UPDATE]: 'Failed to update user',
  [ClickError.BAD_REQUEST]: 'Error in request from Click',
  [ClickError.TRANSACTION_CANCELLED]: 'Transaction cancelled',
};

function reply(res: Response, extra: Record<string, unknown>, error: number) {
  return res.json({ ...extra, error, error_note: ClickErrorNote[error] ?? 'Error' });
}

// Click signs Prepare and Complete differently: Complete's sign_string adds
// merchant_prepare_id (which doesn't exist yet when Prepare is signed)
// between merchant_trans_id and amount. Passing it as undefined for Prepare
// keeps this one function correct for both.
function buildSignString(fields: {
  clickTransId: unknown;
  serviceId: unknown;
  merchantTransId: unknown;
  merchantPrepareId?: unknown;
  amount: unknown;
  action: unknown;
  signTime: unknown;
}): string {
  const parts = [
    fields.clickTransId,
    fields.serviceId,
    CLICK_SECRET_KEY,
    fields.merchantTransId,
    ...(fields.merchantPrepareId !== undefined ? [fields.merchantPrepareId] : []),
    fields.amount,
    fields.action,
    fields.signTime,
  ];
  return crypto.createHash('md5').update(parts.join('')).digest('hex');
}

function amountsMatch(a: number, b: number): boolean {
  return Math.abs(a - b) < 0.01;
}

clickRouter.post('/prepare', async (req: Request, res: Response) => {
  const body = req.body ?? {};
  const {
    click_trans_id: clickTransId,
    service_id: serviceId,
    merchant_trans_id: merchantTransId,
    amount,
    action,
    sign_time: signTime,
    sign_string: signString,
  } = body;

  if (!clickTransId || !serviceId || !merchantTransId || amount === undefined || action === undefined || !signTime || !signString) {
    return reply(res, { click_trans_id: clickTransId, merchant_trans_id: merchantTransId }, ClickError.BAD_REQUEST);
  }
  if (String(action) !== '0') {
    return reply(res, { click_trans_id: clickTransId, merchant_trans_id: merchantTransId }, ClickError.ACTION_NOT_FOUND);
  }
  if (!CLICK_SECRET_KEY || (CLICK_SERVICE_ID && String(serviceId) !== CLICK_SERVICE_ID)) {
    return reply(res, { click_trans_id: clickTransId, merchant_trans_id: merchantTransId }, ClickError.SIGN_CHECK_FAILED);
  }

  const expectedSign = buildSignString({ clickTransId, serviceId, merchantTransId, amount, action, signTime });
  if (expectedSign !== String(signString)) {
    return reply(res, { click_trans_id: clickTransId, merchant_trans_id: merchantTransId }, ClickError.SIGN_CHECK_FAILED);
  }

  // Click may retry Prepare if it never saw our response — return the same
  // merchant_prepare_id again instead of creating a second row.
  const existing = await prisma.clickTransaction.findUnique({ where: { clickTransId: String(clickTransId) } });
  if (existing) {
    return reply(res, {
      click_trans_id: clickTransId,
      merchant_trans_id: merchantTransId,
      merchant_prepare_id: existing.merchantPrepareId,
    }, ClickError.SUCCESS);
  }

  const enrollment = await prisma.enrollment.findUnique({
    where: { id: String(merchantTransId) },
    include: { course: true, payments: { where: { status: 'APPROVED' } } },
  });
  if (!enrollment) {
    return reply(res, { click_trans_id: clickTransId, merchant_trans_id: merchantTransId }, ClickError.USER_NOT_FOUND);
  }

  // Order matches Click's own reference implementation (click-integration-django):
  // amount is checked before "already paid", and a negative incoming `error`
  // (Click reporting its own cancellation) is checked last, after everything else.
  const expectedAmount = enrollment.course.discountPrice ?? enrollment.course.price;
  if (!amountsMatch(Number(amount), expectedAmount)) {
    return reply(res, { click_trans_id: clickTransId, merchant_trans_id: merchantTransId }, ClickError.INCORRECT_AMOUNT);
  }
  if (enrollment.payments.length > 0 || enrollment.status === 'PAID') {
    return reply(res, { click_trans_id: clickTransId, merchant_trans_id: merchantTransId }, ClickError.ALREADY_PAID);
  }
  if (Number(body.error) < 0) {
    return reply(res, { click_trans_id: clickTransId, merchant_trans_id: merchantTransId }, ClickError.TRANSACTION_CANCELLED);
  }

  const trx = await prisma.clickTransaction.create({
    data: {
      clickTransId: String(clickTransId),
      enrollmentId: enrollment.id,
      amount: Number(amount),
      state: 0,
      preparedAt: new Date(),
    },
  });

  return reply(res, {
    click_trans_id: clickTransId,
    merchant_trans_id: merchantTransId,
    merchant_prepare_id: trx.merchantPrepareId,
  }, ClickError.SUCCESS);
});

clickRouter.post('/complete', async (req: Request, res: Response) => {
  const body = req.body ?? {};
  const {
    click_trans_id: clickTransId,
    service_id: serviceId,
    merchant_trans_id: merchantTransId,
    merchant_prepare_id: merchantPrepareId,
    amount,
    action,
    error: clickSideError,
    sign_time: signTime,
    sign_string: signString,
  } = body;

  if (!clickTransId || !serviceId || !merchantTransId || merchantPrepareId === undefined || amount === undefined || action === undefined || !signTime || !signString) {
    return reply(res, { click_trans_id: clickTransId, merchant_trans_id: merchantTransId }, ClickError.BAD_REQUEST);
  }
  if (String(action) !== '1') {
    return reply(res, { click_trans_id: clickTransId, merchant_trans_id: merchantTransId }, ClickError.ACTION_NOT_FOUND);
  }
  if (!CLICK_SECRET_KEY || (CLICK_SERVICE_ID && String(serviceId) !== CLICK_SERVICE_ID)) {
    return reply(res, { click_trans_id: clickTransId, merchant_trans_id: merchantTransId }, ClickError.SIGN_CHECK_FAILED);
  }

  const expectedSign = buildSignString({ clickTransId, serviceId, merchantTransId, merchantPrepareId, amount, action, signTime });
  if (expectedSign !== String(signString)) {
    return reply(res, { click_trans_id: clickTransId, merchant_trans_id: merchantTransId }, ClickError.SIGN_CHECK_FAILED);
  }

  const trx = await prisma.clickTransaction.findUnique({ where: { merchantPrepareId: Number(merchantPrepareId) } });
  if (!trx || trx.clickTransId !== String(clickTransId)) {
    return reply(res, { click_trans_id: clickTransId, merchant_trans_id: merchantTransId }, ClickError.TRANSACTION_NOT_FOUND);
  }

  // Order matches Click's own reference implementation (click-integration-django):
  // amount, then already-paid, then a negative incoming `error` (Click
  // reporting its own cancellation) last — and that case must echo back
  // error -9, not 0, since -9 is what tells Click we recorded the cancellation.
  const expectedAmount = trx.amount;
  if (!amountsMatch(Number(amount), expectedAmount)) {
    return reply(res, { click_trans_id: clickTransId, merchant_trans_id: merchantTransId }, ClickError.INCORRECT_AMOUNT);
  }
  if (trx.state === 1) {
    return reply(res, {
      click_trans_id: clickTransId,
      merchant_trans_id: merchantTransId,
      merchant_confirm_id: trx.merchantPrepareId,
    }, ClickError.ALREADY_PAID);
  }
  if (trx.state === -9 || Number(clickSideError) < 0) {
    if (trx.state !== -9) {
      await prisma.clickTransaction.update({ where: { id: trx.id }, data: { state: -9, cancelledAt: new Date() } });
    }
    return reply(res, { click_trans_id: clickTransId, merchant_trans_id: merchantTransId }, ClickError.TRANSACTION_CANCELLED);
  }

  const enrollment = await prisma.enrollment.findUnique({ where: { id: trx.enrollmentId } });
  if (!enrollment) {
    return reply(res, { click_trans_id: clickTransId, merchant_trans_id: merchantTransId }, ClickError.USER_NOT_FOUND);
  }

  const payment = await prisma.payment.create({
    data: {
      enrollmentId: enrollment.id,
      userId: enrollment.userId,
      amount: trx.amount,
      method: 'Click',
      status: 'APPROVED',
      notes: `Click transactionId: ${clickTransId}`,
    },
  });
  await prisma.clickTransaction.update({
    where: { id: trx.id },
    data: { state: 1, performedAt: new Date(), paymentId: payment.id },
  });
  await prisma.enrollment.update({ where: { id: enrollment.id }, data: { status: 'PAID' } });

  return reply(res, {
    click_trans_id: clickTransId,
    merchant_trans_id: merchantTransId,
    merchant_confirm_id: trx.merchantPrepareId,
  }, ClickError.SUCCESS);
});
