import 'dotenv/config';
import express, { Request, Response } from 'express';
import cors from 'cors';
import path from 'path';
import crypto from 'crypto';
import bcrypt from 'bcryptjs';
import { PrismaClient } from '@prisma/client';
import { generateToken, requireAuth, requireAdmin, optionalAuth } from './middleware/auth';
import { upload, UPLOAD_DIR } from './middleware/upload';

const prisma = new PrismaClient();
const app = express();

const allowedOrigins = (process.env.CORS_ORIGIN || 'https://chustone.uz')
  .split(',')
  .map((origin) => origin.trim())
  .filter(Boolean);

app.use(cors({
  origin: allowedOrigins,
  credentials: true,
}));
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));
app.use('/uploads', express.static(UPLOAD_DIR));

// Ensure Initial Settings Seed
async function initSeed() {
  try {
    const settingCount = await prisma.appSetting.count();
    if (settingCount === 0) {
      await prisma.appSetting.create({
        data: {
          id: '1',
          onboardingTitleUz: 'Kelajagingizni biz bilan yarating!',
          onboardingSubtitleUz: 'Zamonaviy kasblarni o\'rganing, ko\'nikmalaringizni rivojlantiring va muvaffaqiyat sari qadam qo\'ying.',
          onboardingImageUrl: 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?auto=format&fit=crop&w=800&q=80',
          onboardingCtaTextUz: 'Boshlash',
          onboardingSecondaryUz: 'Kirish',

          heroTitleUz: 'Bilim bilan kelajagingni yor!',
          heroSubtitleUz: 'Zamonaviy kasblarga ega bo\'ling va orzularingizni amalga oshiring.',
          heroBannerImage: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=400&q=80',
          heroCtaTextUz: 'Kurslarni ko\'rish',

          locationTitleUz: 'BIZNING YANGI MANZILIMIZ:',
          buildingImageUrl: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=600&q=80',
          addressLandmarkUz: 'Book Kafee yonida, Ilhom Travel binosida.',
          addressCityUz: 'Manzil: Chust shahrida:',
          mapImageUrl: 'https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?auto=format&fit=crop&w=600&q=80',
          mapLocationUrl: 'https://yandex.com/maps/?text=Chust+One+Academy',
          contactHeaderUz: 'Ro\'yxatdan o\'tish uchun:',

          mainPhone: '+998 (99) 972 52 22',
          telegramUser: '@Kompyuter_Kursi15',
          telegramContact: '@Kayumkhadjayev',
          instagramUser: '@Chust_One_Academy',
        },
      });
      console.log('✅ Initial AppSetting Seed created.');
    }
  } catch (err) {
    console.error('Seed Error:', err);
  }
}
initSeed();

// Health Check
app.get('/health', (req: Request, res: Response) => {
  res.json({ status: 'ok', service: 'Chust One Academy API', version: '1.0.0' });
});

const PUBLIC_USER_SELECT = {
  id: true,
  firstName: true,
  lastName: true,
  phoneNumber: true,
  email: true,
  role: true,
  avatarUrl: true,
  city: true,
  age: true,
  address: true,
  isVerified: true,
  createdAt: true,
};

// -------------------------------------------------------------
// AUTH ENDPOINTS
// -------------------------------------------------------------
app.post('/api/v1/auth/register', async (req: Request, res: Response) => {
  try {
    const { firstName, lastName, phoneNumber, password, age, address, city } = req.body;
    if (!firstName || !phoneNumber || !password) {
      return res.status(400).json({ success: false, error: 'Ism, telefon va parol talab qilinadi' });
    }
    const existing = await prisma.user.findUnique({ where: { phoneNumber } });
    if (existing) {
      return res.status(409).json({ success: false, error: 'Bu telefon raqam bilan foydalanuvchi allaqachon ro\'yxatdan o\'tgan' });
    }
    const passwordHash = await bcrypt.hash(password, 10);
    const user = await prisma.user.create({
      data: {
        firstName,
        lastName: lastName || '',
        phoneNumber,
        passwordHash,
        age: age ? Number(age) : undefined,
        address: address || undefined,
        city: city || undefined,
        role: 'STUDENT',
      },
      select: PUBLIC_USER_SELECT,
    });
    const token = generateToken({ id: user.id, role: user.role });
    res.json({ success: true, data: { token, user } });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

app.post('/api/v1/auth/login', async (req: Request, res: Response) => {
  try {
    const { phoneNumber, password } = req.body;
    if (!phoneNumber || !password) {
      return res.status(400).json({ success: false, error: 'Telefon va parol talab qilinadi' });
    }
    const user = await prisma.user.findUnique({ where: { phoneNumber } });
    if (!user) {
      return res.status(401).json({ success: false, error: 'Telefon raqam yoki parol noto\'g\'ri' });
    }
    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) {
      return res.status(401).json({ success: false, error: 'Telefon raqam yoki parol noto\'g\'ri' });
    }
    const token = generateToken({ id: user.id, role: user.role });
    const { passwordHash, ...publicUser } = user;
    res.json({ success: true, data: { token, user: publicUser } });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

app.get('/api/v1/auth/me', requireAuth, async (req: Request, res: Response) => {
  try {
    const user = await prisma.user.findUnique({ where: { id: req.user!.id }, select: PUBLIC_USER_SELECT });
    if (!user) return res.status(404).json({ success: false, error: 'Foydalanuvchi topilmadi' });
    res.json({ success: true, data: user });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

app.patch('/api/v1/auth/profile', requireAuth, async (req: Request, res: Response) => {
  try {
    const { firstName, lastName, city, age, address, avatarUrl } = req.body;
    const user = await prisma.user.update({
      where: { id: req.user!.id },
      data: {
        ...(firstName !== undefined && { firstName }),
        ...(lastName !== undefined && { lastName }),
        ...(city !== undefined && { city }),
        ...(age !== undefined && { age: age === null ? null : Number(age) }),
        ...(address !== undefined && { address }),
        ...(avatarUrl !== undefined && { avatarUrl }),
      },
      select: PUBLIC_USER_SELECT,
    });
    res.json({ success: true, data: user });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

// Account deletion (Apple/Google policy requires in-app self-service deletion
// for apps that support in-app account creation). We anonymize personal data
// and lock the account out instead of a hard delete, so Enrollment/Payment
// history stays intact for accounting/reporting.
app.delete('/api/v1/auth/account', requireAuth, async (req: Request, res: Response) => {
  try {
    const { password } = req.body;
    if (!password) {
      return res.status(400).json({ success: false, error: 'Hisobni o\'chirish uchun joriy parolni kiriting' });
    }
    const user = await prisma.user.findUnique({ where: { id: req.user!.id } });
    if (!user) return res.status(404).json({ success: false, error: 'Foydalanuvchi topilmadi' });

    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) {
      return res.status(401).json({ success: false, error: 'Parol noto\'g\'ri' });
    }

    const unusablePasswordHash = await bcrypt.hash(crypto.randomUUID(), 10);
    await prisma.user.update({
      where: { id: user.id },
      data: {
        firstName: 'O\'chirilgan',
        lastName: 'foydalanuvchi',
        phoneNumber: `deleted_${user.id}`,
        email: null,
        passwordHash: unusablePasswordHash,
        avatarUrl: null,
        city: null,
        age: null,
        address: null,
        deletedAt: new Date(),
      },
    });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

// -------------------------------------------------------------
// UPLOAD ENDPOINT
// -------------------------------------------------------------
app.post('/api/v1/upload', requireAuth, upload.single('file'), async (req: Request, res: Response) => {
  if (!req.file) {
    return res.status(400).json({ success: false, error: 'Fayl topilmadi' });
  }
  const base = process.env.PUBLIC_BASE_URL || `${req.headers['x-forwarded-proto'] || req.protocol}://${req.get('host')}`;
  const url = `${base}/uploads/${req.file.filename}`;
  res.json({ success: true, data: { url } });
});

// -------------------------------------------------------------
// APP SETTINGS CMS ENDPOINTS
// -------------------------------------------------------------
app.get('/api/v1/settings', async (req: Request, res: Response) => {
  try {
    let settings = await prisma.appSetting.findUnique({ where: { id: '1' } });
    if (!settings) {
      settings = await prisma.appSetting.create({ data: { id: '1' } });
    }
    res.json({ success: true, data: settings });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

app.patch('/api/v1/admin/settings', requireAuth, requireAdmin, async (req: Request, res: Response) => {
  try {
    const updated = await prisma.appSetting.upsert({
      where: { id: '1' },
      update: req.body,
      create: { id: '1', ...req.body },
    });
    res.json({ success: true, data: updated });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

// -------------------------------------------------------------
// CATEGORIES ENDPOINTS
// -------------------------------------------------------------
app.get('/api/v1/categories', async (req: Request, res: Response) => {
  try {
    const categories = await prisma.courseCategory.findMany({ orderBy: { sortOrder: 'asc' } });
    res.json({ success: true, data: categories });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

app.post('/api/v1/admin/categories', requireAuth, requireAdmin, async (req: Request, res: Response) => {
  try {
    const { nameUz, slug, iconName, sortOrder } = req.body;
    if (!nameUz || !slug) {
      return res.status(400).json({ success: false, error: 'Nomi va slug talab qilinadi' });
    }
    const category = await prisma.courseCategory.create({
      data: {
        nameUz,
        slug,
        iconName: iconName || 'category',
        sortOrder: sortOrder ?? 0,
      },
    });
    res.json({ success: true, data: category });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

app.patch('/api/v1/admin/categories/:id', requireAuth, requireAdmin, async (req: Request, res: Response) => {
  try {
    const { nameUz, slug, iconName, sortOrder } = req.body;
    const category = await prisma.courseCategory.update({
      where: { id: req.params.id },
      data: {
        ...(nameUz !== undefined && { nameUz }),
        ...(slug !== undefined && { slug }),
        ...(iconName !== undefined && { iconName }),
        ...(sortOrder !== undefined && { sortOrder }),
      },
    });
    res.json({ success: true, data: category });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

app.delete('/api/v1/admin/categories/:id', requireAuth, requireAdmin, async (req: Request, res: Response) => {
  try {
    await prisma.courseCategory.delete({ where: { id: req.params.id } });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

// -------------------------------------------------------------
// CONTENT BLOCKS ENDPOINTS (public landing page section content)
// -------------------------------------------------------------
app.get('/api/v1/content-blocks', async (req: Request, res: Response) => {
  try {
    const { section } = req.query;
    const blocks = await prisma.contentBlock.findMany({
      where: {
        isActive: true,
        ...(section ? { section: String(section) } : {}),
      },
      orderBy: { sortOrder: 'asc' },
    });
    res.json({ success: true, data: blocks });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

app.get('/api/v1/admin/content-blocks', requireAuth, requireAdmin, async (req: Request, res: Response) => {
  try {
    const { section } = req.query;
    const blocks = await prisma.contentBlock.findMany({
      where: section ? { section: String(section) } : {},
      orderBy: { sortOrder: 'asc' },
    });
    res.json({ success: true, data: blocks });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

app.post('/api/v1/admin/content-blocks', requireAuth, requireAdmin, async (req: Request, res: Response) => {
  try {
    const { section, sortOrder, iconName, titleUz, bodyUz, mediaUrl, isActive } = req.body;
    if (!section) {
      return res.status(400).json({ success: false, error: 'Bo\'lim (section) talab qilinadi' });
    }
    const block = await prisma.contentBlock.create({
      data: {
        section,
        sortOrder: sortOrder ?? 0,
        iconName: iconName || null,
        titleUz: titleUz || null,
        bodyUz: bodyUz || null,
        mediaUrl: mediaUrl || null,
        isActive: isActive ?? true,
      },
    });
    res.json({ success: true, data: block });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

app.patch('/api/v1/admin/content-blocks/:id', requireAuth, requireAdmin, async (req: Request, res: Response) => {
  try {
    const { section, sortOrder, iconName, titleUz, bodyUz, mediaUrl, isActive } = req.body;
    const block = await prisma.contentBlock.update({
      where: { id: req.params.id },
      data: {
        ...(section !== undefined && { section }),
        ...(sortOrder !== undefined && { sortOrder }),
        ...(iconName !== undefined && { iconName }),
        ...(titleUz !== undefined && { titleUz }),
        ...(bodyUz !== undefined && { bodyUz }),
        ...(mediaUrl !== undefined && { mediaUrl }),
        ...(isActive !== undefined && { isActive }),
      },
    });
    res.json({ success: true, data: block });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

app.delete('/api/v1/admin/content-blocks/:id', requireAuth, requireAdmin, async (req: Request, res: Response) => {
  try {
    await prisma.contentBlock.delete({ where: { id: req.params.id } });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

// -------------------------------------------------------------
// COURSES ENDPOINTS
// -------------------------------------------------------------
app.get('/api/v1/courses', async (req: Request, res: Response) => {
  try {
    const courses = await prisma.course.findMany({
      include: { category: true, modules: { include: { topics: true } } },
      orderBy: { createdAt: 'desc' },
    });
    res.json({ success: true, data: courses });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

app.get('/api/v1/courses/:id', async (req: Request, res: Response) => {
  try {
    const course = await prisma.course.findUnique({
      where: { id: req.params.id },
      include: { category: true, modules: { include: { topics: true } } },
    });
    if (!course) return res.status(404).json({ success: false, error: 'Kurs topilmadi' });
    res.json({ success: true, data: course });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

function courseWriteData(body: Record<string, unknown>) {
  const pick = (v: unknown) => (v === undefined ? undefined : v);
  return {
    categoryId: pick(body.categoryId),
    titleUz: pick(body.titleUz),
    subtitleUz: pick(body.subtitleUz),
    targetAudienceUz: pick(body.targetAudienceUz),
    descriptionUz: pick(body.descriptionUz),
    coverImage: pick(body.coverImage),
    price: body.price !== undefined ? Number(body.price) : undefined,
    discountPrice: body.discountPrice !== undefined ? (body.discountPrice === null ? null : Number(body.discountPrice)) : undefined,
    durationMonths: body.durationMonths !== undefined ? Number(body.durationMonths) : undefined,
    lessonCount: body.lessonCount !== undefined ? Number(body.lessonCount) : undefined,
    lessonsPerWeek: body.lessonsPerWeek !== undefined ? Number(body.lessonsPerWeek) : undefined,
    scheduleInfo: pick(body.scheduleInfo),
    level: pick(body.level),
    format: pick(body.format),
    isPopular: pick(body.isPopular),
    isKompyuterKids: pick(body.isKompyuterKids),
    kidsTargetGrades: pick(body.kidsTargetGrades),
    kidsDuration: pick(body.kidsDuration),
  };
}

app.post('/api/v1/admin/courses', requireAuth, requireAdmin, async (req: Request, res: Response) => {
  try {
    const { categoryId, titleUz, descriptionUz, coverImage, price } = req.body;
    if (!categoryId || !titleUz || !descriptionUz || !coverImage || price === undefined) {
      return res.status(400).json({ success: false, error: 'Kategoriya, nomi, tavsifi, rasmi va narxi talab qilinadi' });
    }
    const data = courseWriteData(req.body) as Record<string, unknown>;
    const course = await prisma.course.create({ data: data as any, include: { category: true } });
    res.json({ success: true, data: course });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

app.patch('/api/v1/admin/courses/:id', requireAuth, requireAdmin, async (req: Request, res: Response) => {
  try {
    const data = courseWriteData(req.body);
    const course = await prisma.course.update({
      where: { id: req.params.id },
      data: data as any,
      include: { category: true },
    });
    res.json({ success: true, data: course });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

app.delete('/api/v1/admin/courses/:id', requireAuth, requireAdmin, async (req: Request, res: Response) => {
  try {
    await prisma.course.delete({ where: { id: req.params.id } });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

// -------------------------------------------------------------
// NEWS ENDPOINTS
// -------------------------------------------------------------
app.get('/api/v1/news', async (req: Request, res: Response) => {
  try {
    const news = await prisma.news.findMany({
      orderBy: { createdAt: 'desc' },
    });
    res.json({ success: true, data: news });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

app.post('/api/v1/admin/news', requireAuth, requireAdmin, async (req: Request, res: Response) => {
  try {
    const { titleUz, contentUz, coverImage, isFeatured } = req.body;
    const newNews = await prisma.news.create({
      data: {
        titleUz: titleUz || 'Yangi e\'lon',
        contentUz: contentUz || '',
        coverImage: coverImage || 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?auto=format&fit=crop&w=600&q=80',
        isFeatured: Boolean(isFeatured),
      },
    });
    res.json({ success: true, data: newNews });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

app.patch('/api/v1/admin/news/:id', requireAuth, requireAdmin, async (req: Request, res: Response) => {
  try {
    const { titleUz, contentUz, coverImage, isFeatured } = req.body;
    const updated = await prisma.news.update({
      where: { id: req.params.id },
      data: {
        ...(titleUz !== undefined && { titleUz }),
        ...(contentUz !== undefined && { contentUz }),
        ...(coverImage !== undefined && { coverImage }),
        ...(isFeatured !== undefined && { isFeatured: Boolean(isFeatured) }),
      },
    });
    res.json({ success: true, data: updated });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

app.delete('/api/v1/admin/news/:id', requireAuth, requireAdmin, async (req: Request, res: Response) => {
  try {
    await prisma.news.delete({ where: { id: req.params.id } });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

// -------------------------------------------------------------
// ENROLLMENTS (KURSGA YOZILISH) ENDPOINTS
// -------------------------------------------------------------
app.get('/api/v1/admin/enrollments', requireAuth, requireAdmin, async (req: Request, res: Response) => {
  try {
    const enrollments = await prisma.enrollment.findMany({
      include: { user: { select: PUBLIC_USER_SELECT }, course: true, payments: true },
      orderBy: { createdAt: 'desc' },
    });
    res.json({ success: true, data: enrollments });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

app.get('/api/v1/my/enrollments', requireAuth, async (req: Request, res: Response) => {
  try {
    const enrollments = await prisma.enrollment.findMany({
      where: { userId: req.user!.id },
      include: { course: true, payments: true },
      orderBy: { createdAt: 'desc' },
    });
    res.json({ success: true, data: enrollments });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

app.post('/api/v1/enrollments', optionalAuth, async (req: Request, res: Response) => {
  try {
    const { studentName, phone, courseId, preferredTime, applicantAge, address, comment } = req.body;

    if (!courseId) {
      return res.status(400).json({ success: false, error: 'Kurs tanlanishi shart' });
    }

    let user;
    if (req.user) {
      user = await prisma.user.findUnique({ where: { id: req.user.id } });
    } else {
      if (!studentName || !phone) {
        return res.status(400).json({ success: false, error: 'Ism va telefon raqam talab qilinadi' });
      }
      user = await prisma.user.findFirst({ where: { phoneNumber: phone } });
      if (!user) {
        const nameParts = String(studentName).trim().split(' ');
        user = await prisma.user.create({
          data: {
            firstName: nameParts[0] || 'Talaba',
            lastName: nameParts.slice(1).join(' ') || '',
            phoneNumber: phone,
            passwordHash: await bcrypt.hash(Math.random().toString(36), 10),
          },
        });
      }
    }

    if (!user) {
      return res.status(401).json({ success: false, error: 'Foydalanuvchi topilmadi' });
    }

    const enrollment = await prisma.enrollment.create({
      data: {
        userId: user.id,
        courseId,
        preferredTime: preferredTime || 'Kelishilgan holda',
        applicantAge: applicantAge ? Number(applicantAge) : undefined,
        address: address || undefined,
        comment: comment || undefined,
        status: 'NEW',
      },
      include: { course: true },
    });

    res.json({ success: true, message: 'Arizangiz muvaffaqiyatli qabul qilindi!', data: enrollment });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

app.patch('/api/v1/admin/enrollments/:id', requireAuth, requireAdmin, async (req: Request, res: Response) => {
  try {
    const { status } = req.body;
    const enrollment = await prisma.enrollment.update({
      where: { id: req.params.id },
      data: { status },
      include: { user: { select: PUBLIC_USER_SELECT }, course: true },
    });
    res.json({ success: true, data: enrollment });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

// -------------------------------------------------------------
// PAYMENTS ENDPOINTS
// -------------------------------------------------------------
app.post('/api/v1/payments', requireAuth, async (req: Request, res: Response) => {
  try {
    const { enrollmentId, amount, method, receiptUrl, notes } = req.body;
    if (!enrollmentId || !method) {
      return res.status(400).json({ success: false, error: 'Ariza va to\'lov turi talab qilinadi' });
    }
    const payment = await prisma.payment.create({
      data: {
        enrollmentId,
        userId: req.user!.id,
        amount: amount ? Number(amount) : 0,
        method,
        receiptUrl: receiptUrl || undefined,
        notes: notes || undefined,
        status: 'PENDING',
      },
    });
    await prisma.enrollment.update({ where: { id: enrollmentId }, data: { status: 'TOLOV_KUTILMOQDA' } }).catch(() => {});
    res.json({ success: true, data: payment });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

app.get('/api/v1/admin/payments', requireAuth, requireAdmin, async (req: Request, res: Response) => {
  try {
    const payments = await prisma.payment.findMany({
      include: {
        user: { select: PUBLIC_USER_SELECT },
        enrollment: { include: { course: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
    res.json({ success: true, data: payments });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

app.patch('/api/v1/admin/payments/:id', requireAuth, requireAdmin, async (req: Request, res: Response) => {
  try {
    const { status } = req.body;
    const payment = await prisma.payment.update({
      where: { id: req.params.id },
      data: { status },
    });
    if (status === 'APPROVED') {
      await prisma.enrollment.update({ where: { id: payment.enrollmentId }, data: { status: 'PAID' } }).catch(() => {});
    }
    res.json({ success: true, data: payment });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

// -------------------------------------------------------------
// NOTIFICATIONS ENDPOINTS
// -------------------------------------------------------------
app.get('/api/v1/notifications', requireAuth, async (req: Request, res: Response) => {
  try {
    const notifications = await prisma.notification.findMany({
      where: { userId: req.user!.id },
      orderBy: { createdAt: 'desc' },
    });
    res.json({ success: true, data: notifications });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

app.patch('/api/v1/notifications/:id/read', requireAuth, async (req: Request, res: Response) => {
  try {
    const notification = await prisma.notification.update({
      where: { id: req.params.id },
      data: { isRead: true },
    });
    res.json({ success: true, data: notification });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

app.get('/api/v1/admin/notifications', requireAuth, requireAdmin, async (req: Request, res: Response) => {
  try {
    const broadcasts = await prisma.notificationBroadcast.findMany({
      orderBy: { createdAt: 'desc' },
      include: {
        _count: { select: { notifications: true } },
        notifications: { where: { isRead: true }, select: { id: true } },
      },
    });
    const data = broadcasts.map((b) => ({
      id: b.id,
      title: b.title,
      body: b.body,
      type: b.type,
      createdAt: b.createdAt,
      recipientCount: b._count.notifications,
      readCount: b.notifications.length,
    }));
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

app.post('/api/v1/admin/notifications/broadcast', requireAuth, requireAdmin, async (req: Request, res: Response) => {
  try {
    const { title, body, type } = req.body;
    if (!title || !body) {
      return res.status(400).json({ success: false, error: 'Sarlavha va matn talab qilinadi' });
    }
    const users = await prisma.user.findMany({ select: { id: true } });
    const broadcast = await prisma.notificationBroadcast.create({
      data: { title, body, type: type || 'SYSTEM' },
    });
    await prisma.notification.createMany({
      data: users.map((u) => ({ userId: u.id, broadcastId: broadcast.id, title, body, type: type || 'SYSTEM' })),
    });
    res.json({
      success: true,
      message: `${users.length} ta foydalanuvchiga yuborildi`,
      data: { id: broadcast.id, title: broadcast.title, body: broadcast.body, type: broadcast.type, createdAt: broadcast.createdAt, recipientCount: users.length, readCount: 0 },
    });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

app.patch('/api/v1/admin/notifications/:id', requireAuth, requireAdmin, async (req: Request, res: Response) => {
  try {
    const { title, body } = req.body;
    if (!title || !body) {
      return res.status(400).json({ success: false, error: 'Sarlavha va matn talab qilinadi' });
    }
    const broadcast = await prisma.notificationBroadcast.update({
      where: { id: req.params.id },
      data: { title, body },
    });
    await prisma.notification.updateMany({
      where: { broadcastId: req.params.id },
      data: { title, body },
    });
    res.json({ success: true, data: broadcast });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

app.delete('/api/v1/admin/notifications/:id', requireAuth, requireAdmin, async (req: Request, res: Response) => {
  try {
    await prisma.notificationBroadcast.delete({ where: { id: req.params.id } });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

// -------------------------------------------------------------
// USERS / STUDENTS ENDPOINTS (admin only — was previously public and leaked passwordHash)
// -------------------------------------------------------------
app.get('/api/v1/users', requireAuth, requireAdmin, async (req: Request, res: Response) => {
  try {
    const users = await prisma.user.findMany({
      select: { ...PUBLIC_USER_SELECT, _count: { select: { enrollments: true } } },
      orderBy: { createdAt: 'desc' },
    });
    res.json({ success: true, data: users });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

// -------------------------------------------------------------
// ADMIN DASHBOARD STATS
// -------------------------------------------------------------
app.get('/api/v1/admin/stats', requireAuth, requireAdmin, async (req: Request, res: Response) => {
  try {
    const startOfMonth = new Date();
    startOfMonth.setDate(1);
    startOfMonth.setHours(0, 0, 0, 0);

    const [totalUsers, totalEnrollments, newEnrollments, paidEnrollments, pendingPayments, newThisMonth] = await Promise.all([
      prisma.user.count(),
      prisma.enrollment.count(),
      prisma.enrollment.count({ where: { status: 'NEW' } }),
      prisma.enrollment.count({ where: { status: 'PAID' } }),
      prisma.payment.count({ where: { status: 'PENDING' } }),
      prisma.user.count({ where: { createdAt: { gte: startOfMonth } } }),
    ]);

    res.json({
      success: true,
      data: { totalUsers, totalEnrollments, newEnrollments, paidEnrollments, pendingPayments, newThisMonth },
    });
  } catch (err) {
    res.status(500).json({ success: false, error: (err as Error).message });
  }
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🚀 Chust One Academy Backend REST API running on port ${PORT}`);
});
