import { PrismaClient } from '@prisma/client';

// Uzbekistan has used a single fixed UTC+5 offset (no DST) since 1992, so a
// plain constant is enough here — no timezone database needed.
const TASHKENT_UTC_OFFSET_HOURS = 5;
const CHECK_INTERVAL_MS = 60 * 60 * 1000; // hourly is enough for a once-a-day job
const GREETING_HOUR_TASHKENT = 9;

function tashkentNow(): Date {
  return new Date(Date.now() + TASHKENT_UTC_OFFSET_HOURS * 60 * 60 * 1000);
}

function greetingTitleAndBody(fullName: string): { title: string; body: string } {
  return {
    title: "🎉 Tug'ilgan kuningiz bilan!",
    body: `Hurmatli ${fullName}, tug'ilgan kuningiz muborak bo'lsin! Chust One Academy jamoasi sizga baxt, sog'liq va yangi bilim cho'qqilarini tilaydi!`,
  };
}

async function sendTodaysBirthdayGreetings(prisma: PrismaClient): Promise<void> {
  const tNow = tashkentNow();
  // Only act inside the target hour's window; running the check every hour
  // means this still fires at most once per user per year (guarded below).
  if (tNow.getUTCHours() !== GREETING_HOUR_TASHKENT) return;

  const todayMonth = tNow.getUTCMonth();
  const todayDate = tNow.getUTCDate();
  const currentYear = tNow.getUTCFullYear();

  const candidates = await prisma.user.findMany({
    where: { birthDate: { not: null }, deletedAt: null },
    select: { id: true, firstName: true, lastName: true, birthDate: true, lastBirthdayGreetedYear: true },
  });

  const toGreet = candidates.filter((u) => {
    if (!u.birthDate) return false;
    if (u.lastBirthdayGreetedYear === currentYear) return false;
    return u.birthDate.getUTCMonth() === todayMonth && u.birthDate.getUTCDate() === todayDate;
  });

  for (const user of toGreet) {
    const { title, body } = greetingTitleAndBody(`${user.firstName} ${user.lastName}`.trim());
    try {
      await prisma.$transaction([
        prisma.notification.create({
          data: { userId: user.id, title, body, type: 'BIRTHDAY' },
        }),
        prisma.user.update({
          where: { id: user.id },
          data: { lastBirthdayGreetedYear: currentYear },
        }),
      ]);
    } catch (err) {
      console.error(`Birthday greeting failed for user ${user.id}:`, err);
    }
  }
}

export function scheduleBirthdayGreetings(prisma: PrismaClient): void {
  const run = () => {
    sendTodaysBirthdayGreetings(prisma).catch((err) => console.error('Birthday greeting job failed:', err));
  };
  run();
  setInterval(run, CHECK_INTERVAL_MS);
}
