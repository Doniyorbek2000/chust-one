import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting Chust One Academy database seed...');

  // 1. App Settings
  await prisma.appSetting.upsert({
    where: { id: '1' },
    update: {},
    create: {
      id: '1',
      heroTitleUz: 'Kelajagingizni biz bilan yarating!',
      heroSubtitleUz: 'Zamonaviy kasblar va kompyuter savodxonligini o\'rganing. Bilim bilan kelajagingni yorit!',
      mainPhone: '+998 (99) 972 52 22',
      isMaintenance: false,
      minAppVersion: '1.0.0',
    },
  });

  // 2. Admin User
  const adminPhone = process.env.ADMIN_PHONE || '+998990000000';
  const adminEmail = process.env.ADMIN_EMAIL || 'admin@chustone.uz';
  const adminPassword = process.env.ADMIN_PASSWORD || 'admin123';
  const passwordHash = await bcrypt.hash(adminPassword, 10);
  const adminUser = await prisma.user.upsert({
    where: { phoneNumber: adminPhone },
    update: {},
    create: {
      firstName: 'Admin',
      lastName: 'ChustOne',
      phoneNumber: adminPhone,
      email: adminEmail,
      passwordHash,
      role: 'SUPER_ADMIN',
      city: 'Chust',
      isVerified: true,
    },
  });

  // 3. Branch Location
  const branch = await prisma.branch.create({
    data: {
      nameUz: 'Chust Asosiy Filial',
      addressLandmark: 'Book Kafee yonida, Ilhom Travel binosida',
      city: 'Chust shahri',
      latitude: 41.0064,
      longitude: 71.2292,
      phonePrimary: '+998 (99) 972 52 22',
      telegramUser: '@Kompyuter_Kursi15',
      telegramContact: '@Kayumkhadjayev',
      instagramUser: '@Chust_One_Academy',
      workingHours: '08:00 – 19:00 (Dush - Shan)',
    },
  });

  // 4. Categories
  const catComputer = await prisma.courseCategory.create({
    data: {
      nameUz: 'Kompyuter va IT',
      slug: 'kompyuter-it',
      iconName: 'laptop_chromebook',
      sortOrder: 1,
    },
  });

  const catMedia = await prisma.courseCategory.create({
    data: {
      nameUz: 'Media va Kontent',
      slug: 'media-kontent',
      iconName: 'videocam',
      sortOrder: 2,
    },
  });

  const catMarketing = await prisma.courseCategory.create({
    data: {
      nameUz: 'Marketing va Target',
      slug: 'marketing-target',
      iconName: 'ads_click',
      sortOrder: 3,
    },
  });

  // 5. Main Course: Kompyuter savodxonligi
  const courseComp = await prisma.course.create({
    data: {
      categoryId: catComputer.id,
      titleUz: 'Kompyuter savodxonligi',
      subtitleUz: 'Zero dan boshlang, professionalgacha rivojlaning!',
      descriptionUz: 'Kompyuter bilan ishlashning eng muhim ko\'nikmalarini mukammal egallang. Word, Excel, PowerPoint va internet xavfsizligi darslari amaliy mashg\'ulotlar bilan o\'tiladi.',
      coverImage: 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?auto=format&fit=crop&w=800&q=80',
      price: 350000,
      discountPrice: 290000,
      durationMonths: 2,
      lessonCount: 24,
      lessonsPerWeek: 3,
      level: 'Boshlang\'ich va O\'rta',
      format: 'Oflayn / Amaliy',
      isPopular: true,
      isKompyuterKids: true,
      kidsTargetGrades: '1–5-sinf o\'quvchilari uchun',
      kidsDuration: '2 oylik Kompyuter Kids guruhlari',
      rating: 4.9,
      studentCount: 142,
    },
  });

  // Modules for Kompyuter savodxonligi
  const module1 = await prisma.courseModule.create({
    data: {
      courseId: courseComp.id,
      titleUz: 'KURS DAVOMIDA SIZ:',
      sortOrder: 1,
      topics: {
        create: [
          { titleUz: 'Word dasturida ishlash va hujjat yaratish', icon: 'article', sortOrder: 1 },
          { titleUz: 'Excel dasturida ishlash, jadval va formulalar', icon: 'table_chart', sortOrder: 2 },
          { titleUz: 'PowerPoint dasturida taqdimot tayyorlash', icon: 'slideshow', sortOrder: 3 },
          { titleUz: 'Internetdan ma\'lumot izlash va yuklab olish', icon: 'travel_explore', sortOrder: 4 },
          { titleUz: 'Printerdan foydalanish va hujjatlarni chop etish', icon: 'print', sortOrder: 5 },
          { titleUz: 'Kompyuter xavfsizligi va fayllar bilan ishlash', icon: 'security', sortOrder: 6 },
        ],
      },
    },
  });

  // Additional Featured Courses matching reference screens
  const coursesData = [
    {
      categoryId: catMedia.id,
      titleUz: 'Mobilografiya',
      subtitleUz: 'Smartfondan foydalanib professional video va foto tushiring!',
      descriptionUz: 'Telefon kamerasi imkoniyatlaridan 100% foydalanish, rakurslar, yorug\'lik bilan ishlash va Reels/TikTok kontent tayyorlash.',
      coverImage: 'https://images.unsplash.com/photo-1512499617640-c74ae3a79d37?auto=format&fit=crop&w=800&q=80',
      price: 400000,
      discountPrice: 320000,
      isPopular: true,
      rating: 4.95,
      studentCount: 98,
    },
    {
      categoryId: catMedia.id,
      titleUz: 'Videomontaj',
      subtitleUz: 'CapCut va Premiere Pro dasturlarida montaj qilishni o\'rganing!',
      descriptionUz: 'Professional videomontaj, effektlar, ranglar koreksiyasi va saund dizayn.',
      coverImage: 'https://images.unsplash.com/photo-1574717024653-61fd2cf4d44d?auto=format&fit=crop&w=800&q=80',
      price: 450000,
      discountPrice: 380000,
      isPopular: true,
      rating: 4.88,
      studentCount: 110,
    },
    {
      categoryId: catMedia.id,
      titleUz: 'Blogerlik',
      subtitleUz: 'Shaxsiy brendingizni va auditoriyangizni nol dan noldan oshiring!',
      descriptionUz: 'Kamera qarshisida erkin so\'zlash, ssenariy yozish va shaxsiy brend yaratish.',
      coverImage: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=800&q=80',
      price: 500000,
      discountPrice: 420000,
      isPopular: false,
      rating: 4.85,
      studentCount: 64,
    },
    {
      categoryId: catMarketing.id,
      titleUz: 'Instagramni to\'g\'ri yuritish',
      subtitleUz: 'Instagram sahifani to\'g\'ri dizayn qilish va algoritm sir-asrorlari!',
      descriptionUz: 'Profil vizualini yaratish, kontent plan, storis va reels orqali mijoz jalb qilish.',
      coverImage: 'https://images.unsplash.com/photo-1611162617474-5b21e879e113?auto=format&fit=crop&w=800&q=80',
      price: 380000,
      discountPrice: 300000,
      isPopular: true,
      rating: 4.92,
      studentCount: 125,
    },
    {
      categoryId: catMarketing.id,
      titleUz: 'SMM xizmatlari',
      subtitleUz: 'SMM mutaxassisi bo\'lib bizneslar uchun xizmat ko\'rsating!',
      descriptionUz: 'Biznes sahifalarni boshqarish, kopirayting va mijozlar bilan muloqot strategiyasi.',
      coverImage: 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?auto=format&fit=crop&w=800&q=80',
      price: 480000,
      discountPrice: 390000,
      isPopular: true,
      rating: 4.90,
      studentCount: 89,
    },
    {
      categoryId: catMarketing.id,
      titleUz: 'Professional target yoqish',
      subtitleUz: 'Meta Ads Manager orqali professional reklama sozlang!',
      descriptionUz: 'Facebook va Instagramda maqsadli auditoriyaga samarali reklama sozlash, piksel va analitika.',
      coverImage: 'https://images.unsplash.com/photo-1551836022-d5d88e9218df?auto=format&fit=crop&w=800&q=80',
      price: 600000,
      discountPrice: 490000,
      isPopular: true,
      rating: 4.97,
      studentCount: 156,
    },
  ];

  for (const cData of coursesData) {
    await prisma.course.create({
      data: cData,
    });
  }

  // 6. Teachers
  await prisma.teacher.createMany({
    data: [
      {
        fullName: 'Abdurahmon Kayumkhadjayev',
        specialization: 'Bosh O\'qituvchi & IT Mutaxassis',
        experienceYears: 7,
        bio: 'Kompyuter savodxonligi va zamonaviy IT bo\'yicha 1000+ shogirdlar ustoz-murabbiyi.',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
        rating: 4.98,
      },
      {
        fullName: 'Sardorbek Alimov',
        specialization: 'Mobilograf & Videomontajchi',
        experienceYears: 5,
        bio: 'Yirik brendlar uchun 500+ video loyihalar muallifi va tajribali amaliyotchi.',
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
        rating: 4.94,
      },
    ],
  });

  // 7. News
  await prisma.news.createMany({
    data: [
      {
        titleUz: 'Chust One Academy yangi o\'quv binoga ko\'chdi!',
        contentUz: 'Bizning yangi manzilimiz: Book Kafee yonida, Ilhom Travel binosida. Barcha o\'quvchilarimiz uchun zamonaviy sharoitlar yaratildi.',
        coverImage: 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?auto=format&fit=crop&w=800&q=80',
        isFeatured: true,
      },
      {
        titleUz: '1–5 sinf o\'quvchilari uchun "Kompyuter Kids" guruhi Ochildi!',
        contentUz: 'Bolalarda mantiqiy fikrlash, kompyuter ko\'nikmalari va ITga qiziqishni shakllantiruvchi 2 oylik amaliy dastur.',
        coverImage: 'https://images.unsplash.com/photo-1509062522246-3755977927d7?auto=format&fit=crop&w=800&q=80',
        isFeatured: true,
      },
    ],
  });

  console.log('✅ Chust One Academy database seeding completed successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Seeding error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
