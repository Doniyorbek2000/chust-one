import { PrismaClient } from '@prisma/client';

// Idempotent: only inserts rows the first time it runs (contentBlockCount === 0),
// so it is safe to run this alone against an already-seeded production database
// without duplicating or touching any other data (courses, categories, etc.).
export async function seedContentBlocks(prisma: PrismaClient) {
  const contentBlockCount = await prisma.contentBlock.count();
  if (contentBlockCount > 0) {
    console.log('ℹ️  ContentBlock jadvali allaqachon to\'ldirilgan, o\'tkazib yuborildi.');
    return;
  }

  await prisma.contentBlock.createMany({
    data: [
      // Nega aynan biz — check-list
      { section: 'TRUST_BULLET', sortOrder: 1, iconName: 'fa-solid fa-check', titleUz: 'Zamonaviy va amaliyotga yo\'naltirilgan o\'quv dasturi' },
      { section: 'TRUST_BULLET', sortOrder: 2, iconName: 'fa-solid fa-check', titleUz: 'Tajribali va o\'z sohasining mutaxassisi bo\'lgan o\'qituvchilar' },
      { section: 'TRUST_BULLET', sortOrder: 3, iconName: 'fa-solid fa-check', titleUz: 'Kichik guruhlarda individual yondashuv' },
      { section: 'TRUST_BULLET', sortOrder: 4, iconName: 'fa-solid fa-check', titleUz: 'Kurs yakunida sertifikat va portfolio loyihalar' },

      // Kimlar uchun
      { section: 'AUDIENCE', sortOrder: 1, iconName: 'fa-solid fa-user-graduate', titleUz: 'Maktab o\'quvchilari', bodyUz: 'Kelajakda IT yoki media sohasida rivojlanishni xohlaydigan o\'quvchilar uchun mos boshlang\'ich dastur.' },
      { section: 'AUDIENCE', sortOrder: 2, iconName: 'fa-solid fa-laptop-code', titleUz: 'Talabalar va yosh mutaxassislar', bodyUz: 'Kasbiy ko\'nikmalarini oshirib, CV va portfoliosini kuchaytirmoqchi bo\'lganlar uchun.' },
      { section: 'AUDIENCE', sortOrder: 3, iconName: 'fa-solid fa-briefcase', titleUz: 'Tadbirkorlar', bodyUz: 'O\'z biznesini ijtimoiy tarmoqlarda professional darajada olib chiqmoqchi bo\'lganlar uchun.' },
      { section: 'AUDIENCE', sortOrder: 4, iconName: 'fa-solid fa-camera-retro', titleUz: 'Frilanser va kontent-meykerlar', bodyUz: 'Mobilografiya, videomontaj va SMM orqali daromad qilishni o\'rganmoqchi bo\'lganlar uchun.' },

      // Statistika
      { section: 'STAT', sortOrder: 1, titleUz: '500+', bodyUz: 'Muvaffaqiyatli Bitiruvchilar' },
      { section: 'STAT', sortOrder: 2, titleUz: '6+', bodyUz: 'Zamonaviy Kasb Yo\'nalishlari' },
      { section: 'STAT', sortOrder: 3, titleUz: '100%', bodyUz: 'Amaliy Darslar va Loyihalar' },
      { section: 'STAT', sortOrder: 4, titleUz: '2 Bino', bodyUz: 'Zamonaviy Kompyuter Laboratoriyalari' },

      // Afzalliklarimiz
      { section: 'BENEFIT', sortOrder: 1, titleUz: 'Amaliy portfolio loyihalari', bodyUz: 'Har bir kurs davomida real loyihalar ustida ishlaysiz va kurs yakunida to\'liq portfolio bilan chiqasiz.' },
      { section: 'BENEFIT', sortOrder: 2, titleUz: 'Individual nazorat va fikr-mulohaza', bodyUz: 'Kichik guruhlarda har bir talabaning bilim darajasi alohida kuzatib boriladi.' },
      { section: 'BENEFIT', sortOrder: 3, titleUz: 'Zamonaviy kompyuter laboratoriyasi', bodyUz: 'Yangi jihozlar bilan jihozlangan 2 ta zamonaviy o\'quv binosida darslar olib boriladi.' },
      { section: 'BENEFIT', sortOrder: 4, titleUz: 'Sertifikat va ishga joylashishda yordam', bodyUz: 'Kursni muvaffaqiyatli tugatgan talabalarga sertifikat va tavsiyanoma beriladi.' },

      // Dars jadvali
      { section: 'SCHEDULE', sortOrder: 1, iconName: 'fa-solid fa-clock', titleUz: 'Dushanba, Chorshanba, Juma', bodyUz: 'Ertalabki guruh — 09:00' },
      { section: 'SCHEDULE', sortOrder: 2, iconName: 'fa-solid fa-clock', titleUz: 'Dushanba, Chorshanba, Juma', bodyUz: 'Kunduzgi guruh — 14:00' },
      { section: 'SCHEDULE', sortOrder: 3, iconName: 'fa-solid fa-clock', titleUz: 'Seshanba, Payshanba, Shanba', bodyUz: 'Kechki guruh — 18:00' },

      // Dastur xususiyatlari
      { section: 'FEATURE', sortOrder: 1, iconName: 'fa-solid fa-chalkboard-user', titleUz: 'Amaliy mashg\'ulotlar', bodyUz: 'Har bir mavzu nazariya bilan birga real kompyuterda amaliy mashq qilinadi.' },
      { section: 'FEATURE', sortOrder: 2, iconName: 'fa-solid fa-location-dot', titleUz: 'Qulay manzil', bodyUz: 'Chust markazida, Book Kafee yonida — shahar markazidan yetib borish oson.' },
      { section: 'FEATURE', sortOrder: 3, iconName: 'fa-solid fa-headset', titleUz: 'Doimiy qo\'llab-quvvatlash', bodyUz: 'Kurs tugagandan keyin ham Telegram guruh orqali savollaringizga javob olasiz.' },

      // Mijozlar fikri (YouTube videolar)
      { section: 'TESTIMONIAL', sortOrder: 1, titleUz: 'O\'quvchi fikri 1', mediaUrl: 'https://www.youtube.com/embed/lixf3bz9wJE' },
      { section: 'TESTIMONIAL', sortOrder: 2, titleUz: 'O\'quvchi fikri 2', mediaUrl: 'https://www.youtube.com/embed/eTbjAHOx98E' },
      { section: 'TESTIMONIAL', sortOrder: 3, titleUz: 'O\'quvchi fikri 3', mediaUrl: 'https://www.youtube.com/embed/ACR6Nzhp9Tw' },
      { section: 'TESTIMONIAL', sortOrder: 4, titleUz: 'O\'quvchi fikri 4', mediaUrl: 'https://www.youtube.com/embed/ChVaBcwczyQ' },
    ],
  });
  console.log('✅ ContentBlock qatorlari muvaffaqiyatli qo\'shildi.');
}

// Allow running standalone: `npx tsx src/seedContentBlocks.ts` (dev) or
// `node dist/seedContentBlocks.js` (prod, after `npm run build`).
if (require.main === module) {
  const prisma = new PrismaClient();
  seedContentBlocks(prisma)
    .catch((e) => {
      console.error('❌ ContentBlock seeding error:', e);
      process.exit(1);
    })
    .finally(async () => {
      await prisma.$disconnect();
    });
}
