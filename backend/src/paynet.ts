import { Router, Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { requirePaynetAuth } from './middleware/paynetAuth';

const prisma = new PrismaClient();
export const paynetRouter = Router();

const PAYNET_SERVICE_ID = process.env.PAYNET_SERVICE_ID;

// Paynet's merchant protocol is JSON-RPC 2.0, but its response "id" is not an
// echo of the request id — Paynet's own worked example returns a fresh unix
// timestamp (seconds) as the response id, so we match that instead of the
// standard JSON-RPC echo behavior.
function responseId(): number {
  return Math.floor(Date.now() / 1000);
}

function formatTimestamp(date: Date): string {
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())} ` +
    `${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(date.getSeconds())}`;
}

function parsePaynetDate(value: string): Date {
  // Accepts "yyyy-mm-dd hh:mm:ss" (Paynet's documented dateFrom/dateTo format).
  return new Date(value.replace(' ', 'T'));
}

function rpcError(id: unknown, code: number, message: string) {
  return { jsonrpc: '2.0', id, error: { code, message } };
}

function rpcResult(id: unknown, result: Record<string, unknown>) {
  return { jsonrpc: '2.0', id, result };
}

// Paynet's fields map uses whatever field_name their side configures for us
// (documented as "client_id" in our integration form) — rather than hardcode
// that key, we read the single key/value pair Paynet sends and treat its
// value as our Enrollment id, since that's what the mobile/web app shows the
// student as their "payment code" after enrolling.
function extractFieldValue(fields: unknown): string | undefined {
  if (!fields || typeof fields !== 'object') return undefined;
  const values = Object.values(fields as Record<string, unknown>);
  return values.length > 0 ? String(values[0]) : undefined;
}

async function handleGetInformation(id: unknown, params: any, res: Response) {
  const enrollmentId = extractFieldValue(params?.fields);
  if (!enrollmentId) {
    return res.json(rpcError(id, 302, 'Mijoz topilmadi'));
  }

  const enrollment = await prisma.enrollment.findUnique({
    where: { id: enrollmentId },
    include: { course: true, user: true, payments: { where: { status: 'APPROVED' } } },
  });

  if (!enrollment) {
    return res.json(rpcError(id, 302, 'Mijoz topilmadi'));
  }
  if (enrollment.payments.length > 0 || enrollment.status === 'PAID') {
    return res.json(rpcError(id, 304, 'Ushbu ariza uchun to\'lov allaqachon amalga oshirilgan'));
  }

  const amount = Math.round((enrollment.course.discountPrice ?? enrollment.course.price) * 100);
  return res.json(rpcResult(id, {
    status: 0,
    timestamp: formatTimestamp(new Date()),
    fields: {
      balance: amount,
      name: `${enrollment.user.firstName} ${enrollment.user.lastName}`.trim(),
      course: enrollment.course.titleUz,
    },
  }));
}

async function handlePerformTransaction(id: unknown, params: any, res: Response) {
  const transactionId = String(params?.transactionId ?? '');
  const enrollmentId = extractFieldValue(params?.fields);
  const amount = Number(params?.amount);

  if (!transactionId || !enrollmentId || !Number.isFinite(amount)) {
    return res.json(rpcError(id, 302, 'Mijoz topilmadi'));
  }

  const existing = await prisma.paynetTransaction.findUnique({ where: { paynetTrnId: transactionId } });
  if (existing) {
    return res.json(rpcError(id, 201, 'Tranzaksiya allaqachon mavjud'));
  }

  const enrollment = await prisma.enrollment.findUnique({
    where: { id: enrollmentId },
    include: { course: true, payments: { where: { status: 'APPROVED' } } },
  });
  if (!enrollment) {
    return res.json(rpcError(id, 302, 'Mijoz topilmadi'));
  }
  if (enrollment.payments.length > 0 || enrollment.status === 'PAID') {
    return res.json(rpcError(id, 304, 'Ushbu ariza uchun to\'lov allaqachon amalga oshirilgan'));
  }

  const expectedAmount = Math.round((enrollment.course.discountPrice ?? enrollment.course.price) * 100);
  if (amount !== expectedAmount) {
    return res.json(rpcError(id, 413, 'Noto\'g\'ri summa'));
  }

  const now = new Date();
  const payment = await prisma.payment.create({
    data: {
      enrollmentId: enrollment.id,
      userId: enrollment.userId,
      amount: amount / 100,
      method: 'Paynet',
      status: 'APPROVED',
      notes: `Paynet transactionId: ${transactionId}`,
    },
  });
  const paynetTrn = await prisma.paynetTransaction.create({
    data: {
      paynetTrnId: transactionId,
      enrollmentId: enrollment.id,
      paymentId: payment.id,
      amount: amount / 100,
      state: 1,
      performedAt: now,
    },
  });
  await prisma.enrollment.update({ where: { id: enrollment.id }, data: { status: 'PAID' } });

  return res.json(rpcResult(id, {
    providerTrnId: paynetTrn.providerTrnId,
    timestamp: formatTimestamp(now),
    fields: { enrollment_id: enrollment.id },
  }));
}

async function handleCheckTransaction(id: unknown, params: any, res: Response) {
  const transactionId = String(params?.transactionId ?? '');
  const trn = await prisma.paynetTransaction.findUnique({ where: { paynetTrnId: transactionId } });
  if (!trn) {
    return res.json(rpcError(id, 301, 'Tranzaksiya topilmadi'));
  }
  return res.json(rpcResult(id, {
    transactionState: trn.state,
    timestamp: formatTimestamp(trn.performedAt ?? trn.createdAt),
    providerTrnId: trn.providerTrnId,
  }));
}

async function handleCancelTransaction(id: unknown, params: any, res: Response) {
  const transactionId = String(params?.transactionId ?? '');
  const trn = await prisma.paynetTransaction.findUnique({ where: { paynetTrnId: transactionId } });
  if (!trn) {
    return res.json(rpcError(id, 301, 'Tranzaksiya topilmadi'));
  }
  if (trn.state === 2) {
    return res.json(rpcError(id, 202, 'Tranzaksiya allaqachon bekor qilingan'));
  }

  const now = new Date();
  await prisma.$transaction([
    prisma.paynetTransaction.update({ where: { id: trn.id }, data: { state: 2, cancelledAt: now } }),
    ...(trn.paymentId ? [prisma.payment.update({ where: { id: trn.paymentId }, data: { status: 'CANCELLED' } })] : []),
    prisma.enrollment.update({ where: { id: trn.enrollmentId }, data: { status: 'TOLOV_KUTILMOQDA' } }),
  ]);

  return res.json(rpcResult(id, {
    providerTrnId: trn.providerTrnId,
    timestamp: formatTimestamp(now),
    transactionState: 2,
  }));
}

async function handleGetStatement(id: unknown, params: any, res: Response) {
  const dateFrom = parsePaynetDate(String(params?.dateFrom ?? ''));
  const dateTo = parsePaynetDate(String(params?.dateTo ?? ''));

  const transactions = await prisma.paynetTransaction.findMany({
    where: { state: 1, performedAt: { gte: dateFrom, lte: dateTo } },
    orderBy: { performedAt: 'asc' },
  });

  return res.json(rpcResult(id, {
    statements: transactions.map((t) => ({
      amount: Math.round(t.amount * 100),
      providerTrnId: t.providerTrnId,
      transactionId: t.paynetTrnId,
      timestamp: formatTimestamp(t.performedAt ?? t.createdAt),
    })),
  }));
}

// Single JSON-RPC 2.0 endpoint Paynet calls for every method — dispatches on
// body.method the way their protocol expects (one URL, not one per verb).
paynetRouter.post('/', requirePaynetAuth, async (req: Request, res: Response) => {
  const { id, method, params } = req.body ?? {};

  if (PAYNET_SERVICE_ID && String(params?.serviceId ?? '') !== PAYNET_SERVICE_ID) {
    return res.json(rpcError(id ?? responseId(), 302, 'Noto\'g\'ri serviceId'));
  }

  try {
    switch (method) {
      case 'GetInformation':
        return await handleGetInformation(responseId(), params, res);
      case 'PerformTransaction':
        return await handlePerformTransaction(responseId(), params, res);
      case 'CheckTransaction':
        return await handleCheckTransaction(responseId(), params, res);
      case 'CancelTransaction':
        return await handleCancelTransaction(responseId(), params, res);
      case 'GetStatement':
        return await handleGetStatement(responseId(), params, res);
      default:
        return res.status(400).json(rpcError(id ?? responseId(), -32601, 'Method not found'));
    }
  } catch (err) {
    return res.status(500).json(rpcError(id ?? responseId(), -32603, (err as Error).message));
  }
});
