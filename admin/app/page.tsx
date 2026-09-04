"use client";

import React, { useState, useEffect, ChangeEvent } from 'react';
import { api, setAuthToken, getAuthToken, uploadUrl } from '../lib/api';

// Accepts any YouTube link format (watch?v=, youtu.be/, shorts/, already-embed)
// and normalizes it to the /embed/ form YouTube requires for iframe embedding —
// pasting a non-embed link is why saved testimonial videos rendered blank on the site.
function toYoutubeEmbedUrl(url: string): string {
  const trimmed = url.trim();
  if (!trimmed) return trimmed;
  const idMatch =
    trimmed.match(/[?&]v=([a-zA-Z0-9_-]{11})/) ||
    trimmed.match(/youtu\.be\/([a-zA-Z0-9_-]{11})/) ||
    trimmed.match(/youtube\.com\/shorts\/([a-zA-Z0-9_-]{11})/) ||
    trimmed.match(/youtube\.com\/embed\/([a-zA-Z0-9_-]{11})/);
  return idMatch ? `https://www.youtube.com/embed/${idMatch[1]}` : trimmed;
}

interface AppSettings {
  onboardingTitleUz: string;
  onboardingSubtitleUz: string;
  onboardingImageUrl: string;
  onboardingCtaTextUz: string;
  onboardingSecondaryUz: string;

  heroTitleUz: string;
  heroSubtitleUz: string;
  heroBannerImage: string;
  heroCtaTextUz: string;

  aboutTagUz: string;
  aboutTitleUz: string;
  aboutIntroUz: string;
  aboutImageUrl: string;
  aboutBadgeNumberUz: string;
  aboutBadgeLabelUz: string;
  aboutButtonTextUz: string;

  audienceTagUz: string;
  audienceTitleUz: string;
  benefitsTagUz: string;
  benefitsTitleUz: string;
  scheduleTagUz: string;
  scheduleTitleUz: string;
  featuresTagUz: string;
  featuresTitleUz: string;
  testimonialsTagUz: string;
  testimonialsTitleUz: string;

  locationTitleUz: string;
  buildingImageUrl: string;
  addressLandmarkUz: string;
  addressCityUz: string;
  mapImageUrl: string;
  mapLocationUrl: string;
  mapLatitude?: number | null;
  mapLongitude?: number | null;
  contactHeaderUz: string;

  mainPhone: string;
  telegramUser: string;
  telegramContact: string;
  instagramUser: string;

  popupTitleUz: string;
  popupBodyUz: string;
  popupImageUrl: string;
  isPopupActive: boolean;
  isMaintenance: boolean;
  minAppVersion: string;
  forceUpdate: boolean;
  termsAndPrivacyUrl: string;
}

interface Category {
  id: string;
  nameUz: string;
  slug: string;
  iconName: string;
  sortOrder: number;
}

interface CourseItem {
  id: string;
  categoryId: string;
  category?: { id: string; nameUz: string };
  titleUz: string;
  subtitleUz?: string | null;
  targetAudienceUz?: string | null;
  descriptionUz: string;
  coverImage: string;
  price: number;
  discountPrice?: number | null;
  studentCount: number;
  isPopular?: boolean;
}

interface NewsItem {
  id: string;
  titleUz: string;
  contentUz: string;
  coverImage: string;
  isFeatured: boolean;
  createdAt: string;
}

interface ContentBlockItem {
  id: string;
  section: string;
  sortOrder: number;
  iconName?: string | null;
  titleUz?: string | null;
  bodyUz?: string | null;
  mediaUrl?: string | null;
  isActive: boolean;
}

interface UserItem {
  id: string;
  firstName: string;
  lastName: string;
  phoneNumber: string;
  email?: string | null;
  city?: string | null;
  role: string;
  avatarUrl?: string | null;
  createdAt: string;
  _count?: { enrollments: number };
}

interface EnrollmentItem {
  id: string;
  status: string;
  preferredTime: string;
  applicantAge?: number | null;
  address?: string | null;
  createdAt: string;
  user: { firstName: string; lastName: string; phoneNumber: string };
  course: { titleUz: string };
}

interface PaymentItem {
  id: string;
  amount: number;
  method: string;
  status: string;
  receiptUrl?: string | null;
  createdAt: string;
  user: { firstName: string; lastName: string; phoneNumber: string };
  enrollment: { course: { titleUz: string } };
}

interface Stats {
  totalUsers: number;
  totalEnrollments: number;
  newEnrollments: number;
  paidEnrollments: number;
  pendingPayments: number;
  newThisMonth: number;
}

const ENROLLMENT_STATUSES = ['NEW', 'CONTACTED', 'APPROVED', 'TOLOV_KUTILMOQDA', 'PAID', 'ENROLLED', 'REJECTED'];

const DEFAULT_SETTINGS: AppSettings = {
  onboardingTitleUz: 'Kelajagingizni biz bilan yarating!',
  onboardingSubtitleUz: 'Zamonaviy kasblarni o\'rganing va muvaffaqiyat sari qadam qo\'ying.',
  onboardingImageUrl: 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?auto=format&fit=crop&w=800&q=80',
  onboardingCtaTextUz: 'Boshlash',
  onboardingSecondaryUz: 'Kirish',

  heroTitleUz: 'Bilim bilan kelajagingni yor!',
  heroSubtitleUz: 'Zamonaviy kasblarga ega bo\'ling va orzularingizni amalga oshiring.',
  heroBannerImage: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=400&q=80',
  heroCtaTextUz: 'Kurslarni ko\'rish',

  aboutTagUz: 'NEGA AYNAN BIZ',
  aboutTitleUz: 'Nega Aynan Chust One Academy?',
  aboutIntroUz: 'Biz Chust shahridagi zamonaviy IT va media ta\'lim markazlaridan biri sifatida, nazariyadan ko\'ra amaliyotga ko\'proq vaqt ajratamiz. Har bir talaba individual e\'tibor va real loyihalar ustida ishlash imkoniyatiga ega bo\'ladi.',
  aboutImageUrl: 'https://images.unsplash.com/photo-1571260899304-425eee4c7efc?auto=format&fit=crop&w=700&q=80',
  aboutBadgeNumberUz: '500+',
  aboutBadgeLabelUz: 'Muvaffaqiyatli bitiruvchilar',
  aboutButtonTextUz: 'Kurslar bilan tanishish',

  audienceTagUz: 'KIMLAR UCHUN',
  audienceTitleUz: 'Ushbu Kurslar Kimlar Uchun Mos?',
  benefitsTagUz: 'AFZALLIKLARIMIZ',
  benefitsTitleUz: 'Nima Uchun Bizning Kurslarni Tanlashadi?',
  scheduleTagUz: 'DARS JADVALI',
  scheduleTitleUz: 'Sizga Qulay Vaqtni Tanlang',
  featuresTagUz: 'DASTUR XUSUSIYATLARI',
  featuresTitleUz: 'O\'quv Jarayonining Afzalliklari',
  testimonialsTagUz: 'MIJOZLAR FIKRI',
  testimonialsTitleUz: 'O\'quvchilarimiz Nima Deydi?',

  locationTitleUz: 'BIZNING YANGI MANZILIMIZ:',
  buildingImageUrl: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=600&q=80',
  addressLandmarkUz: 'Book Kafee yonida, Ilhom Travel binosida.',
  addressCityUz: 'Manzil: Chust shahrida:',
  mapImageUrl: 'https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?auto=format&fit=crop&w=600&q=80',
  mapLocationUrl: 'https://yandex.com/maps/?text=Chust+One+Academy',
  mapLatitude: 41.0064,
  mapLongitude: 71.2292,
  contactHeaderUz: 'Ro\'yxatdan o\'tish uchun:',

  mainPhone: '+998 (99) 972 52 22',
  telegramUser: '@Kompyuter_Kursi15',
  telegramContact: '@Kayumkhadjayev',
  instagramUser: '@Chust_One_Academy',

  popupTitleUz: 'Yangi Qabul Boshlandi!',
  popupBodyUz: 'Chust One Academy da 50% gacha chegirmalar mavjud.',
  popupImageUrl: 'https://images.unsplash.com/photo-1531482615713-2afd69097998?auto=format&fit=crop&w=600&q=80',
  isPopupActive: false,
  isMaintenance: false,
  minAppVersion: '1.0.0',
  forceUpdate: false,
  termsAndPrivacyUrl: 'https://chustone.uz/privacy',
};

const EMPTY_COURSE_FORM: Partial<CourseItem> = {
  id: '',
  categoryId: '',
  titleUz: '',
  subtitleUz: '',
  targetAudienceUz: '',
  descriptionUz: '',
  coverImage: 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?auto=format&fit=crop&w=800&q=80',
  price: 300000,
  discountPrice: undefined,
};

const EMPTY_CATEGORY_FORM: Partial<Category> = { nameUz: '', slug: '', iconName: 'category', sortOrder: 0 };

const EMPTY_NEWS_FORM: Partial<NewsItem> = {
  titleUz: '',
  contentUz: '',
  coverImage: 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?auto=format&fit=crop&w=600&q=80',
  isFeatured: false,
};

const CONTENT_SECTIONS: { key: string; label: string; icon: string }[] = [
  { key: 'TRUST_BULLET', label: "Nega aynan biz — check-list", icon: '✅' },
  { key: 'AUDIENCE', label: 'Kimlar uchun', icon: '👤' },
  { key: 'STAT', label: 'Statistika', icon: '📊' },
  { key: 'BENEFIT', label: 'Afzalliklarimiz', icon: '⭐' },
  { key: 'SCHEDULE', label: 'Dars jadvali', icon: '🕒' },
  { key: 'FEATURE', label: 'Dastur xususiyatlari', icon: '🧩' },
  { key: 'TESTIMONIAL', label: 'Mijozlar fikri (video)', icon: '🎬' },
];

const EMPTY_BLOCK_FORM: Partial<ContentBlockItem> = {
  section: 'TRUST_BULLET',
  sortOrder: 0,
  iconName: '',
  titleUz: '',
  bodyUz: '',
  mediaUrl: '',
  isActive: true,
};

function money(n?: number | null) {
  if (n == null || isNaN(n)) return '0 so\'m';
  return n.toLocaleString('uz-UZ') + ' so\'m';
}

function statusBadge(status: string) {
  const map: Record<string, string> = {
    NEW: 'bg-amber-500/20 text-amber-400',
    CONTACTED: 'bg-sky-500/20 text-sky-400',
    APPROVED: 'bg-emerald-500/20 text-emerald-400',
    TOLOV_KUTILMOQDA: 'bg-amber-500/20 text-amber-400',
    PAID: 'bg-emerald-500/20 text-emerald-400',
    ENROLLED: 'bg-emerald-500/20 text-emerald-400',
    REJECTED: 'bg-red-500/20 text-red-400',
    PENDING: 'bg-amber-500/20 text-amber-400',
  };
  return map[status] || 'bg-slate-500/20 text-slate-300';
}

// Native <input type="file"> button labels ("Choose File", "Выберите файл", etc.)
// are rendered by the browser using the visitor's OS/browser language and can't
// be overridden via CSS. This wraps a hidden input in our own styled label so
// the button always reads in Uzbek regardless of the visitor's browser locale.
function FileUploadButton({ id, onChange, hint }: { id: string; onChange: (e: ChangeEvent<HTMLInputElement>) => void; hint?: string }) {
  return (
    <div>
      <label
        htmlFor={id}
        className="cursor-pointer inline-flex items-center text-xs font-semibold bg-[#C6F432] text-[#041426] rounded-xl px-4 py-2.5 hover:bg-[#b0de28] transition-colors"
      >
        Rasm tanlash
        <input id={id} type="file" accept="image/*" onChange={onChange} className="hidden" />
      </label>
      {hint && <p className="text-[11px] text-[#64748B] mt-1.5 max-w-xs">{hint}</p>}
    </div>
  );
}

export default function AdminDashboard() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [authChecking, setAuthChecking] = useState(true);
  const [adminPhone, setAdminPhone] = useState('+998999725222');
  const [adminPassword, setAdminPassword] = useState('');
  const [loginError, setLoginError] = useState('');
  const [loginLoading, setLoginLoading] = useState(false);

  type Tab = 'cms' | 'categories' | 'sections' | 'courses' | 'news' | 'enrollments' | 'payments' | 'students' | 'notifications';
  const [activeTab, setActiveTab] = useState<Tab>('cms');
  const [savedMessage, setSavedMessage] = useState('');
  const [loadingData, setLoadingData] = useState(false);
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);

  const [isCourseModalOpen, setIsCourseModalOpen] = useState(false);
  const [courseForm, setCourseForm] = useState<Partial<CourseItem>>(EMPTY_COURSE_FORM);

  const [isCategoryModalOpen, setIsCategoryModalOpen] = useState(false);
  const [categoryForm, setCategoryForm] = useState<Partial<Category>>(EMPTY_CATEGORY_FORM);

  const [isNewsModalOpen, setIsNewsModalOpen] = useState(false);
  const [newsForm, setNewsForm] = useState<Partial<NewsItem>>(EMPTY_NEWS_FORM);

  const [settings, setSettings] = useState<AppSettings>(DEFAULT_SETTINGS);
  const [categories, setCategories] = useState<Category[]>([]);
  const [contentBlocks, setContentBlocks] = useState<ContentBlockItem[]>([]);
  const [activeSection, setActiveSection] = useState<string>('TRUST_BULLET');
  const [isBlockModalOpen, setIsBlockModalOpen] = useState(false);
  const [blockForm, setBlockForm] = useState<Partial<ContentBlockItem>>(EMPTY_BLOCK_FORM);
  const [courses, setCourses] = useState<CourseItem[]>([]);
  const [news, setNews] = useState<NewsItem[]>([]);
  const [students, setStudents] = useState<UserItem[]>([]);
  const [enrollments, setEnrollments] = useState<EnrollmentItem[]>([]);
  const [payments, setPayments] = useState<PaymentItem[]>([]);
  const [stats, setStats] = useState<Stats | null>(null);

  const [notifTitle, setNotifTitle] = useState('');
  const [notifBody, setNotifBody] = useState('');
  const [notifSending, setNotifSending] = useState(false);
  const [notifResult, setNotifResult] = useState('');

  const fetchAll = async () => {
    setLoadingData(true);
    const [s, c, cb, cr, n, u, e, p, st] = await Promise.allSettled([
      api.get('/settings'),
      api.get('/categories'),
      api.get('/admin/content-blocks'),
      api.get('/courses'),
      api.get('/news'),
      api.get('/users'),
      api.get('/admin/enrollments'),
      api.get('/admin/payments'),
      api.get('/admin/stats'),
    ]);
    if (s.status === 'fulfilled' && s.value.data?.data) setSettings((prev) => ({ ...prev, ...s.value.data.data }));
    if (c.status === 'fulfilled' && Array.isArray(c.value.data?.data)) setCategories(c.value.data.data);
    if (cb.status === 'fulfilled' && Array.isArray(cb.value.data?.data)) setContentBlocks(cb.value.data.data);
    if (cr.status === 'fulfilled' && Array.isArray(cr.value.data?.data)) setCourses(cr.value.data.data);
    if (n.status === 'fulfilled' && Array.isArray(n.value.data?.data)) setNews(n.value.data.data);
    if (u.status === 'fulfilled' && Array.isArray(u.value.data?.data)) setStudents(u.value.data.data);
    if (e.status === 'fulfilled' && Array.isArray(e.value.data?.data)) setEnrollments(e.value.data.data);
    if (p.status === 'fulfilled' && Array.isArray(p.value.data?.data)) setPayments(p.value.data.data);
    if (st.status === 'fulfilled' && st.value.data?.data) setStats(st.value.data.data);
    setLoadingData(false);
  };

  useEffect(() => {
    const token = getAuthToken();
    if (!token) {
      setAuthChecking(false);
      return;
    }
    api.get('/auth/me')
      .then(() => {
        setIsAuthenticated(true);
        fetchAll();
      })
      .catch(() => setAuthToken(null))
      .finally(() => setAuthChecking(false));
  }, []);

  const handleAdminLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoginLoading(true);
    setLoginError('');
    try {
      const res = await api.post('/auth/login', { phoneNumber: adminPhone, password: adminPassword });
      const { token, user } = res.data.data;
      if (!['ADMIN', 'SUPER_ADMIN'].includes(user.role)) {
        setLoginError('❌ Bu hisobda admin huquqi yo\'q');
        setLoginLoading(false);
        return;
      }
      setAuthToken(token);
      setIsAuthenticated(true);
      await fetchAll();
    } catch (err: any) {
      setLoginError('❌ ' + (err?.response?.data?.error || 'Telefon yoki parol noto\'g\'ri'));
    } finally {
      setLoginLoading(false);
    }
  };

  const handleAdminLogout = () => {
    setAuthToken(null);
    setIsAuthenticated(false);
  };

  const flash = (msg: string) => {
    setSavedMessage(msg);
    setTimeout(() => setSavedMessage(''), 3000);
  };

  const handleSaveSettings = async () => {
    try {
      await api.patch('/admin/settings', settings);
      flash('✅ Barcha o\'zgarishlar muvaffaqiyatli saqlandi!');
    } catch {
      flash('❌ Saqlashda xatolik yuz berdi');
    }
  };

  const handleFileUpload = (fieldKey: keyof AppSettings) => async (e: ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    try {
      const url = await uploadUrl(file);
      setSettings((prev) => ({ ...prev, [fieldKey]: url }));
    } catch {
      flash('❌ Rasm yuklashda xatolik');
    }
  };

  // ---------------- Category handlers ----------------
  const handleOpenAddCategory = () => {
    setCategoryForm(EMPTY_CATEGORY_FORM);
    setIsCategoryModalOpen(true);
  };
  const handleEditCategory = (cat: Category) => {
    setCategoryForm(cat);
    setIsCategoryModalOpen(true);
  };
  const handleSaveCategory = async () => {
    if (!categoryForm.nameUz || !categoryForm.slug) return alert('Nomi va slug talab qilinadi!');
    try {
      if (categoryForm.id) {
        const res = await api.patch(`/admin/categories/${categoryForm.id}`, categoryForm);
        setCategories((prev) => prev.map((c) => (c.id === categoryForm.id ? res.data.data : c)));
      } else {
        const res = await api.post('/admin/categories', categoryForm);
        setCategories((prev) => [...prev, res.data.data]);
      }
      setIsCategoryModalOpen(false);
      flash('✅ Kategoriya saqlandi!');
    } catch (err: any) {
      alert('Xatolik: ' + (err?.response?.data?.error || 'Nomalum xatolik'));
    }
  };
  const handleDeleteCategory = async (id: string) => {
    if (!confirm('Rostdan ham ushbu kategoriyani o\'chirmoqchimisiz?')) return;
    try {
      await api.delete(`/admin/categories/${id}`);
      setCategories((prev) => prev.filter((c) => c.id !== id));
    } catch (err: any) {
      alert('Xatolik: ' + (err?.response?.data?.error || 'Bu kategoriyada kurslar mavjud bo\'lishi mumkin'));
    }
  };

  // ---------------- Content block (site sections) handlers ----------------
  const handleOpenAddBlock = () => {
    const inSection = contentBlocks.filter((b) => b.section === activeSection);
    setBlockForm({ ...EMPTY_BLOCK_FORM, section: activeSection, sortOrder: inSection.length + 1 });
    setIsBlockModalOpen(true);
  };
  const handleEditBlock = (block: ContentBlockItem) => {
    setBlockForm(block);
    setIsBlockModalOpen(true);
  };
  const handleSaveBlock = async () => {
    try {
      const payload = { ...blockForm };
      if (payload.section === 'TESTIMONIAL' && payload.mediaUrl) {
        payload.mediaUrl = toYoutubeEmbedUrl(payload.mediaUrl);
      }
      if (blockForm.id) {
        const res = await api.patch(`/admin/content-blocks/${blockForm.id}`, payload);
        setContentBlocks((prev) => prev.map((b) => (b.id === blockForm.id ? res.data.data : b)));
      } else {
        const res = await api.post('/admin/content-blocks', payload);
        setContentBlocks((prev) => [...prev, res.data.data]);
      }
      setIsBlockModalOpen(false);
      flash('✅ Bo\'lim saqlandi!');
    } catch (err: any) {
      alert('Xatolik: ' + (err?.response?.data?.error || 'Nomalum xatolik'));
    }
  };
  const handleDeleteBlock = async (id: string) => {
    if (!confirm('Rostdan ham ushbu elementni o\'chirmoqchimisiz?')) return;
    try {
      await api.delete(`/admin/content-blocks/${id}`);
      setContentBlocks((prev) => prev.filter((b) => b.id !== id));
    } catch (err: any) {
      alert('Xatolik: ' + (err?.response?.data?.error || 'Nomalum xatolik'));
    }
  };

  // ---------------- Course handlers ----------------
  const handleOpenAddCourse = () => {
    setCourseForm({ ...EMPTY_COURSE_FORM, categoryId: categories[0]?.id || '' });
    setIsCourseModalOpen(true);
  };
  const handleEditCourse = (course: CourseItem) => {
    setCourseForm(course);
    setIsCourseModalOpen(true);
  };
  const handleCourseImageUpload = async (e: ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    try {
      const url = await uploadUrl(file);
      setCourseForm((prev) => ({ ...prev, coverImage: url }));
    } catch {
      flash('❌ Rasm yuklashda xatolik');
    }
  };
  const handleSaveCourse = async () => {
    if (!courseForm.titleUz) return alert('Kurs nomini kiriting!');
    if (!courseForm.categoryId) return alert('Kategoriyani tanlang!');
    try {
      if (courseForm.id) {
        const res = await api.patch(`/admin/courses/${courseForm.id}`, courseForm);
        setCourses((prev) => prev.map((c) => (c.id === courseForm.id ? res.data.data : c)));
      } else {
        const res = await api.post('/admin/courses', courseForm);
        setCourses((prev) => [res.data.data, ...prev]);
      }
      setIsCourseModalOpen(false);
      flash('✅ Kurs saqlandi!');
    } catch (err: any) {
      alert('Xatolik: ' + (err?.response?.data?.error || 'Nomalum xatolik'));
    }
  };
  const handleDeleteCourse = async (id: string) => {
    if (!confirm('Rostdan ham ushbu kursni o\'chirmoqchimisiz?')) return;
    try {
      await api.delete(`/admin/courses/${id}`);
      setCourses((prev) => prev.filter((c) => c.id !== id));
    } catch (err: any) {
      alert('Xatolik: ' + (err?.response?.data?.error || 'Nomalum xatolik'));
    }
  };

  // ---------------- News handlers ----------------
  const handleOpenAddNews = () => {
    setNewsForm(EMPTY_NEWS_FORM);
    setIsNewsModalOpen(true);
  };
  const handleNewsImageUpload = async (e: ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    try {
      const url = await uploadUrl(file);
      setNewsForm((prev) => ({ ...prev, coverImage: url }));
    } catch {
      flash('❌ Rasm yuklashda xatolik');
    }
  };
  const handleSaveNews = async () => {
    if (!newsForm.titleUz) return alert('Yangilik sarlavhasini kiriting!');
    try {
      if (newsForm.id) {
        const res = await api.patch(`/admin/news/${newsForm.id}`, newsForm);
        setNews((prev) => prev.map((n) => (n.id === newsForm.id ? res.data.data : n)));
      } else {
        const res = await api.post('/admin/news', newsForm);
        setNews((prev) => [res.data.data, ...prev]);
      }
      setIsNewsModalOpen(false);
      flash('✅ Yangilik saqlandi!');
    } catch {
      flash('❌ Saqlashda xatolik');
    }
  };
  const handleDeleteNews = async (id: string) => {
    if (!confirm('E\'lonni o\'chirmoqchimisiz?')) return;
    try {
      await api.delete(`/admin/news/${id}`);
      setNews((prev) => prev.filter((n) => n.id !== id));
    } catch {
      flash('❌ O\'chirishda xatolik');
    }
  };

  // ---------------- Enrollment handlers ----------------
  const handleEnrollmentStatusChange = async (id: string, newStatus: string) => {
    try {
      await api.patch(`/admin/enrollments/${id}`, { status: newStatus });
      setEnrollments((prev) => prev.map((e) => (e.id === id ? { ...e, status: newStatus } : e)));
    } catch {
      flash('❌ Holatni o\'zgartirishda xatolik');
    }
  };

  // ---------------- Payment handlers ----------------
  const handlePaymentStatus = async (id: string, newStatus: string) => {
    try {
      await api.patch(`/admin/payments/${id}`, { status: newStatus });
      setPayments((prev) => prev.map((p) => (p.id === id ? { ...p, status: newStatus } : p)));
      flash(newStatus === 'APPROVED' ? '✅ To\'lov tasdiqlandi!' : 'To\'lov rad etildi');
    } catch {
      flash('❌ Xatolik yuz berdi');
    }
  };

  // ---------------- Notifications ----------------
  const handleSendBroadcast = async () => {
    if (!notifTitle || !notifBody) return alert('Sarlavha va matnni kiriting!');
    setNotifSending(true);
    setNotifResult('');
    try {
      const res = await api.post('/admin/notifications/broadcast', { title: notifTitle, body: notifBody });
      setNotifResult('✅ ' + res.data.message);
      setNotifTitle('');
      setNotifBody('');
    } catch {
      setNotifResult('❌ Yuborishda xatolik yuz berdi');
    } finally {
      setNotifSending(false);
    }
  };

  if (authChecking) {
    return <div className="min-h-screen bg-[#041426] flex items-center justify-center text-white text-sm">Yuklanmoqda...</div>;
  }

  if (!isAuthenticated) {
    return (
      <div className="min-h-screen bg-[#041426] flex items-center justify-center p-4">
        <div className="w-full max-w-md bg-[#0A1D33] border border-[#1E3A5F] rounded-3xl p-8 shadow-2xl">
          <div className="flex flex-col items-center justify-center mb-6">
            <img src="/admin/logo.png" alt="Chust One Academy" width={68} height={68} />
            <h1 className="text-2xl font-bold text-white mt-4">Chust One Academy</h1>
            <p className="text-xs text-slate-400 mt-1">Admin Panel Tizimiga Kirish</p>
          </div>

          <form onSubmit={handleAdminLogin} className="space-y-4">
            {loginError && (
              <div className="bg-red-500/20 border border-red-500 text-red-300 text-xs p-3 rounded-xl text-center">
                {loginError}
              </div>
            )}

            <div>
              <label className="block text-xs font-semibold text-slate-300 mb-1">Admin Telefon Raqami</label>
              <input
                type="text"
                value={adminPhone}
                onChange={e => setAdminPhone(e.target.value)}
                className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-3 text-sm text-white focus:outline-none focus:border-[#C6F432]"
                placeholder="+998 99 972 52 22"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-300 mb-1">Admin Paroli</label>
              <input
                type="password"
                value={adminPassword}
                onChange={e => setAdminPassword(e.target.value)}
                className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-3 text-sm text-white focus:outline-none focus:border-[#C6F432]"
                placeholder="••••••••"
              />
            </div>

            <button
              type="submit"
              disabled={loginLoading}
              className="w-full bg-[#C6F432] hover:bg-[#b0de28] text-[#041426] font-bold py-3.5 px-4 rounded-xl transition duration-200 shadow-lg text-sm disabled:opacity-60"
            >
              {loginLoading ? 'Kirilmoqda...' : '🔒 Admin Panelga Kirish'}
            </button>
          </form>
        </div>
      </div>
    );
  }

  const handleTabSelect = (tab: Tab) => {
    setActiveTab(tab);
    setIsSidebarOpen(false);
  };

  return (
    <div className="min-h-screen bg-[#041426] text-white lg:flex">
      {/* Mobile/Tablet Sidebar Backdrop */}
      {isSidebarOpen && (
        <div
          className="fixed inset-0 bg-black/60 z-30 lg:hidden"
          onClick={() => setIsSidebarOpen(false)}
          aria-hidden="true"
        />
      )}

      {/* Sidebar */}
      <aside
        className={`fixed inset-y-0 left-0 z-40 w-72 bg-[#0A1D33] border-r border-[#1E3A5F] flex flex-col transform transition-transform duration-300 lg:static lg:z-auto lg:w-64 lg:translate-x-0 ${
          isSidebarOpen ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        <div className="p-6 border-b border-[#1E3A5F] flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <img src="/admin/logo.png" alt="Chust One Academy" width={36} height={36} />
            <div>
              <span className="font-bold text-lg text-white block">Chust One</span>
              <span className="text-[10px] text-[#C6F432] font-bold tracking-widest">ADMIN PANEL</span>
            </div>
          </div>
          <button
            onClick={handleAdminLogout}
            title="Tizimdan chiqish"
            className="text-red-400 hover:text-red-300 p-1.5 rounded-lg hover:bg-red-500/10 transition"
          >
            🚪
          </button>
        </div>

        <nav className="flex-1 p-4 space-y-1 overflow-y-auto">
          {([
            ['cms', '🖼️', 'App Welcome CMS'],
            ['categories', '🏷️', `Kategoriyalar (${categories.length})`],
            ['sections', '🧱', `Sayt bo'limlari (${contentBlocks.length})`],
            ['courses', '📚', `Kurslar (${courses.length})`],
            ['news', '📰', `Yangiliklar (${news.length})`],
            ['students', '👥', `Talabalar (${students.length})`],
            ['enrollments', '📋', `Arizalar (${enrollments.length})`],
            ['payments', '💳', `To'lovlar (${payments.length})`],
            ['notifications', '🔔', 'Bildirishnomalar'],
          ] as [Tab, string, string][]).map(([tab, icon, label]) => (
            <button
              key={tab}
              onClick={() => handleTabSelect(tab)}
              className={`w-full flex items-center space-x-3 px-4 py-3 rounded-xl font-semibold text-sm transition ${
                activeTab === tab ? 'bg-[#C6F432] text-[#041426]' : 'text-slate-300 hover:bg-[#1E3A5F]'
              }`}
            >
              <span>{icon}</span>
              <span>{label}</span>
            </button>
          ))}
        </nav>

        <div className="p-4 border-t border-[#1E3A5F] flex items-center justify-between text-xs text-slate-400">
          <span>Tizim holati:</span>
          <span className="text-[#C6F432] font-bold">{loadingData ? '🟡 Yuklanmoqda' : '🟢 Online (v1.0)'}</span>
        </div>
      </aside>

      {/* Main Content Area */}
      <main className="flex-1 p-4 sm:p-6 lg:p-8 overflow-y-auto min-w-0">
        <header className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 mb-6">
          <div className="flex items-center gap-3">
            <button
              onClick={() => setIsSidebarOpen(true)}
              aria-label="Menyuni ochish"
              className="lg:hidden flex-shrink-0 w-10 h-10 flex items-center justify-center rounded-xl bg-[#0A1D33] border border-[#1E3A5F] text-white hover:border-[#C6F432] transition"
            >
              ☰
            </button>
            <div>
              <h1 className="text-xl sm:text-2xl font-bold">Boshqaruv Paneli</h1>
              <p className="text-xs text-slate-400">Chust One Academy mobil ilovasini va kontentini tahrirlash</p>
            </div>
          </div>

          <div className="flex items-center gap-3 flex-wrap">
            {savedMessage && (
              <span className="text-xs bg-emerald-500/20 border border-emerald-500 text-emerald-400 px-3 py-1.5 rounded-lg">
                {savedMessage}
              </span>
            )}
            {activeTab === 'cms' && (
              <button
                onClick={handleSaveSettings}
                className="bg-[#C6F432] hover:bg-[#b0de28] text-[#041426] font-bold px-5 py-2.5 rounded-xl transition shadow-lg text-sm"
              >
                💾 Barchasini Saqlash
              </button>
            )}
          </div>
        </header>

        {/* Dashboard KPI row */}
        {stats && (
          <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-4 mb-8">
            {[
              ['Ro\'yxatdan o\'tganlar', stats.totalUsers, '👥'],
              ['Shu oy yangi', stats.newThisMonth, '🆕'],
              ['Yangi arizalar', stats.newEnrollments, '📋'],
              ['To\'langan arizalar', stats.paidEnrollments, '✅'],
              ['Kutilayotgan to\'lovlar', stats.pendingPayments, '💳'],
            ].map(([label, value, icon]) => (
              <div key={label as string} className="bg-[#0A1D33] border border-[#1E3A5F] rounded-2xl p-4">
                <div className="text-2xl mb-1">{icon}</div>
                <div className="text-2xl font-bold text-[#C6F432]">{value as number}</div>
                <div className="text-[11px] text-slate-400 mt-1">{label as string}</div>
              </div>
            ))}
          </div>
        )}

        {/* Tab 1: CMS Settings */}
        {activeTab === 'cms' && (
          <div className="space-y-6">
            <div className="bg-[#0A1D33] border border-[#1E3A5F] rounded-2xl p-6">
              <h2 className="text-lg font-bold mb-4 text-[#C6F432] flex items-center space-x-2">
                <span>📱</span>
                <span>Screen 1: Welcome & Onboarding Ekrani</span>
              </h2>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1">Bosh Sarlavha (Uzbek)</label>
                  <input
                    type="text"
                    value={settings.onboardingTitleUz}
                    onChange={e => setSettings({ ...settings, onboardingTitleUz: e.target.value })}
                    className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#C6F432]"
                  />
                </div>

                <div>
                  <label className="block text-[#94A3B8] text-xs font-semibold mb-1">Kichik Tavsif Matni</label>
                  <textarea
                    rows={2}
                    value={settings.onboardingSubtitleUz}
                    onChange={e => setSettings({ ...settings, onboardingSubtitleUz: e.target.value })}
                    className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2 text-sm text-white focus:outline-none focus:border-[#C6F432]"
                  />
                </div>

                <div className="col-span-2">
                  <label className="block text-xs font-semibold text-slate-300 mb-1">Screen 1 Asosiy Rasmi (Upload)</label>
                  <div className="flex items-center space-x-4">
                    <img src={settings.onboardingImageUrl} alt="Preview" className="w-24 h-24 object-cover rounded-xl border border-[#1E3A5F]" />
                    <FileUploadButton id="upload-onboarding-image" onChange={handleFileUpload('onboardingImageUrl')} hint="Tavsiya: 1080×1350 px (vertikal, 4:5), JPG yoki PNG format, hajmi 2 MB dan oshmasin." />
                  </div>
                </div>
              </div>
            </div>

            <div className="bg-[#0A1D33] border border-[#1E3A5F] rounded-2xl p-6">
              <h2 className="text-lg font-bold mb-4 text-[#C6F432] flex items-center space-x-2">
                <span>🏠</span>
                <span>Bosh Sahifa (Hero Banner)</span>
              </h2>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1">Hero Sarlavha</label>
                  <input
                    type="text"
                    value={settings.heroTitleUz}
                    onChange={e => setSettings({ ...settings, heroTitleUz: e.target.value })}
                    className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#C6F432]"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1">Hero Tavsifi</label>
                  <input
                    type="text"
                    value={settings.heroSubtitleUz}
                    onChange={e => setSettings({ ...settings, heroSubtitleUz: e.target.value })}
                    className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#C6F432]"
                  />
                </div>
                <div className="col-span-2">
                  <label className="block text-xs font-semibold text-slate-300 mb-1">Hero Banner Rasmi (Upload)</label>
                  <div className="flex items-center space-x-4">
                    <img src={settings.heroBannerImage} alt="Preview" className="w-24 h-24 object-cover rounded-xl border border-[#1E3A5F]" />
                    <FileUploadButton id="upload-hero-banner" onChange={handleFileUpload('heroBannerImage')} hint="Tavsiya: 1200×800 px (gorizontal, 3:2), JPG yoki PNG format, hajmi 2 MB dan oshmasin." />
                  </div>
                </div>
              </div>
            </div>

            <div className="bg-[#0A1D33] border border-[#1E3A5F] rounded-2xl p-6">
              <h2 className="text-lg font-bold mb-4 text-[#C6F432] flex items-center space-x-2">
                <span>🤝</span>
                <span>"Nega Aynan Biz" Bo'limi</span>
              </h2>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1">Yorliq (tag)</label>
                  <input
                    type="text"
                    value={settings.aboutTagUz}
                    onChange={e => setSettings({ ...settings, aboutTagUz: e.target.value })}
                    className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#C6F432]"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1">Katta sarlavha</label>
                  <input
                    type="text"
                    value={settings.aboutTitleUz}
                    onChange={e => setSettings({ ...settings, aboutTitleUz: e.target.value })}
                    className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#C6F432]"
                  />
                </div>
                <div className="col-span-2">
                  <label className="block text-xs font-semibold text-slate-300 mb-1">Kirish matni</label>
                  <textarea
                    rows={3}
                    value={settings.aboutIntroUz}
                    onChange={e => setSettings({ ...settings, aboutIntroUz: e.target.value })}
                    className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#C6F432]"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1">Tugma matni</label>
                  <input
                    type="text"
                    value={settings.aboutButtonTextUz}
                    onChange={e => setSettings({ ...settings, aboutButtonTextUz: e.target.value })}
                    className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#C6F432]"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1">Значок raqami (masalan: 500+)</label>
                  <input
                    type="text"
                    value={settings.aboutBadgeNumberUz}
                    onChange={e => setSettings({ ...settings, aboutBadgeNumberUz: e.target.value })}
                    className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#C6F432]"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1">Значок matni</label>
                  <input
                    type="text"
                    value={settings.aboutBadgeLabelUz}
                    onChange={e => setSettings({ ...settings, aboutBadgeLabelUz: e.target.value })}
                    className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#C6F432]"
                  />
                </div>
                <div className="col-span-2">
                  <label className="block text-xs font-semibold text-slate-300 mb-1">Bo'lim rasmi (Upload)</label>
                  <div className="flex items-center space-x-4">
                    <img src={settings.aboutImageUrl} alt="Preview" className="w-24 h-24 object-cover rounded-xl border border-[#1E3A5F]" />
                    <FileUploadButton id="upload-about-image" onChange={handleFileUpload('aboutImageUrl')} hint="Tavsiya: 700×380 px (gorizontal), JPG yoki PNG format, hajmi 2 MB dan oshmasin." />
                  </div>
                </div>
              </div>
              <p className="text-[11px] text-slate-500 mt-4 pt-4 border-t border-[#1E3A5F]">Check-list bandlarini "🧱 Sayt bo'limlari" tabidagi "Nega aynan biz — check-list" bo'limidan tahrirlang.</p>
            </div>

            <div className="bg-[#0A1D33] border border-[#1E3A5F] rounded-2xl p-6">
              <h2 className="text-lg font-bold mb-4 text-[#C6F432] flex items-center space-x-2">
                <span>🏷️</span>
                <span>Bo'lim Sarlavhalari (Yorliq va Katta Sarlavha)</span>
              </h2>
              <div className="space-y-4">
                {([
                  ['Kimlar uchun', 'audienceTagUz', 'audienceTitleUz'],
                  ['Afzalliklarimiz', 'benefitsTagUz', 'benefitsTitleUz'],
                  ['Dars jadvali', 'scheduleTagUz', 'scheduleTitleUz'],
                  ['Dastur xususiyatlari', 'featuresTagUz', 'featuresTitleUz'],
                  ['Mijozlar fikri', 'testimonialsTagUz', 'testimonialsTitleUz'],
                ] as [string, keyof AppSettings, keyof AppSettings][]).map(([label, tagKey, titleKey]) => (
                  <div key={label} className="grid grid-cols-1 md:grid-cols-3 gap-4 items-end pb-4 border-b border-[#1E3A5F] last:border-b-0 last:pb-0">
                    <div className="text-xs font-bold text-slate-400">{label}</div>
                    <div>
                      <label className="block text-xs font-semibold text-slate-300 mb-1">Yorliq (tag)</label>
                      <input
                        type="text"
                        value={settings[tagKey] as string}
                        onChange={e => setSettings({ ...settings, [tagKey]: e.target.value })}
                        className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#C6F432]"
                      />
                    </div>
                    <div>
                      <label className="block text-xs font-semibold text-slate-300 mb-1">Katta sarlavha</label>
                      <input
                        type="text"
                        value={settings[titleKey] as string}
                        onChange={e => setSettings({ ...settings, [titleKey]: e.target.value })}
                        className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#C6F432]"
                      />
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <div className="bg-[#0A1D33] border border-[#1E3A5F] rounded-2xl p-6">
              <h2 className="text-lg font-bold mb-4 text-[#C6F432] flex items-center space-x-2">
                <span>📍</span>
                <span>Manzil, Bino va Onlayn Xarita CMS</span>
              </h2>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1">Mo'ljal va Manzil</label>
                  <input
                    type="text"
                    value={settings.addressLandmarkUz}
                    onChange={e => setSettings({ ...settings, addressLandmarkUz: e.target.value })}
                    className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#C6F432]"
                  />
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1">Google Maps / Yandex Maps URL Linki</label>
                  <input
                    type="text"
                    value={settings.mapLocationUrl}
                    onChange={e => setSettings({ ...settings, mapLocationUrl: e.target.value })}
                    className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#C6F432]"
                  />
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1">Bino rasmi (Upload)</label>
                  <div className="flex items-center space-x-4">
                    <img src={settings.buildingImageUrl} alt="Preview" className="w-24 h-24 object-cover rounded-xl border border-[#1E3A5F]" />
                    <FileUploadButton id="upload-building-image" onChange={handleFileUpload('buildingImageUrl')} hint="Tavsiya: 1200×900 px (gorizontal, 4:3), JPG yoki PNG format, hajmi 2 MB dan oshmasin." />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-xs font-semibold text-slate-300 mb-1">Kenglik (Latitude)</label>
                    <input
                      type="number"
                      step="0.0001"
                      value={settings.mapLatitude ?? ''}
                      onChange={e => setSettings({ ...settings, mapLatitude: e.target.value === '' ? null : parseFloat(e.target.value) })}
                      className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#C6F432]"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-semibold text-slate-300 mb-1">Uzunlik (Longitude)</label>
                    <input
                      type="number"
                      step="0.0001"
                      value={settings.mapLongitude ?? ''}
                      onChange={e => setSettings({ ...settings, mapLongitude: e.target.value === '' ? null : parseFloat(e.target.value) })}
                      className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#C6F432]"
                    />
                  </div>
                </div>

                {settings.mapLatitude != null && settings.mapLongitude != null && (
                  <div className="col-span-2">
                    <label className="block text-xs font-semibold text-slate-300 mb-1">Xarita ko'rinishi (Live Preview)</label>
                    <iframe
                      title="map-preview"
                      className="w-full h-64 rounded-xl border border-[#1E3A5F]"
                      src={`https://www.openstreetmap.org/export/embed.html?bbox=${settings.mapLongitude - 0.01}%2C${settings.mapLatitude - 0.01}%2C${settings.mapLongitude + 0.01}%2C${settings.mapLatitude + 0.01}&layer=mapnik&marker=${settings.mapLatitude}%2C${settings.mapLongitude}`}
                    />
                  </div>
                )}
              </div>
            </div>

            <div className="bg-[#0A1D33] border border-[#1E3A5F] rounded-2xl p-6">
              <h2 className="text-lg font-bold mb-4 text-[#C6F432] flex items-center space-x-2">
                <span>☎️</span>
                <span>Aloqa Ma'lumotlari</span>
              </h2>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1">Telefon raqami</label>
                  <input
                    type="text"
                    value={settings.mainPhone}
                    onChange={e => setSettings({ ...settings, mainPhone: e.target.value })}
                    className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#C6F432]"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1">Telegram (guruh)</label>
                  <input
                    type="text"
                    value={settings.telegramUser}
                    onChange={e => setSettings({ ...settings, telegramUser: e.target.value })}
                    className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#C6F432]"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1">Instagram</label>
                  <input
                    type="text"
                    value={settings.instagramUser}
                    onChange={e => setSettings({ ...settings, instagramUser: e.target.value })}
                    className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#C6F432]"
                  />
                </div>
                <div className="flex items-center space-x-3 pt-6">
                  <input
                    type="checkbox"
                    checked={settings.isMaintenance}
                    onChange={e => setSettings({ ...settings, isMaintenance: e.target.checked })}
                    className="w-4 h-4"
                  />
                  <label className="text-xs font-semibold text-slate-300">Texnik profilaktika rejimi (ilovani vaqtincha o'chirish)</label>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Tab: Categories */}
        {activeTab === 'categories' && (
          <div className="space-y-4">
            <div className="flex justify-between items-center">
              <h2 className="text-lg font-bold">🏷️ Kurs Kategoriyalari</h2>
              <button
                onClick={handleOpenAddCategory}
                className="bg-[#C6F432] text-[#041426] font-bold px-4 py-2 rounded-xl text-sm hover:bg-[#b0de28] transition"
              >
                + Yangi Kategoriya
              </button>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
              {categories.map(cat => (
                <div key={cat.id} className="bg-[#0A1D33] border border-[#1E3A5F] rounded-2xl p-4 space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="text-2xl">🏷️</span>
                    <span className="text-[10px] text-slate-400">#{cat.sortOrder}</span>
                  </div>
                  <h3 className="font-bold text-sm text-white">{cat.nameUz}</h3>
                  <p className="text-[11px] text-slate-400">{cat.slug}</p>
                  <div className="flex items-center space-x-2 pt-2">
                    <button onClick={() => handleEditCategory(cat)} className="flex-1 bg-[#1E3A5F] hover:bg-[#2A4D7B] text-white py-1.5 rounded-lg text-xs font-semibold transition">✏️ Tahrirlash</button>
                    <button onClick={() => handleDeleteCategory(cat.id)} className="bg-red-500/20 hover:bg-red-500/40 text-red-400 px-3 py-1.5 rounded-lg text-xs font-semibold transition">🗑️</button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Tab: Site Sections (Content Blocks) */}
        {activeTab === 'sections' && (
          <div className="space-y-4">
            <div className="flex flex-wrap gap-2">
              {CONTENT_SECTIONS.map(sec => (
                <button
                  key={sec.key}
                  onClick={() => setActiveSection(sec.key)}
                  className={`px-4 py-2 rounded-xl text-xs font-semibold transition ${
                    activeSection === sec.key ? 'bg-[#C6F432] text-[#041426]' : 'bg-[#0A1D33] border border-[#1E3A5F] text-slate-300 hover:border-[#C6F432]'
                  }`}
                >
                  {sec.icon} {sec.label}
                </button>
              ))}
            </div>

            <div className="flex justify-between items-center">
              <h2 className="text-lg font-bold">
                {CONTENT_SECTIONS.find(s => s.key === activeSection)?.icon} {CONTENT_SECTIONS.find(s => s.key === activeSection)?.label}
              </h2>
              <button
                onClick={handleOpenAddBlock}
                className="bg-[#C6F432] text-[#041426] font-bold px-4 py-2 rounded-xl text-sm hover:bg-[#b0de28] transition"
              >
                + Yangi Element
              </button>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
              {contentBlocks.filter(b => b.section === activeSection).sort((a, b) => a.sortOrder - b.sortOrder).map(block => (
                <div key={block.id} className={`bg-[#0A1D33] border rounded-2xl p-4 space-y-2 ${block.isActive ? 'border-[#1E3A5F]' : 'border-red-500/40 opacity-60'}`}>
                  <div className="flex items-center justify-between">
                    <span className="text-2xl">{activeSection === 'TESTIMONIAL' ? '🎬' : (block.iconName ? <i className={block.iconName} /> : '🔹')}</span>
                    <span className="text-[10px] text-slate-400">#{block.sortOrder} {!block.isActive && '· yashirilgan'}</span>
                  </div>
                  {activeSection === 'STAT' ? (
                    <>
                      <h3 className="font-bold text-xl text-[#C6F432]">{block.titleUz}</h3>
                      <p className="text-[11px] text-slate-400">{block.bodyUz}</p>
                    </>
                  ) : activeSection === 'TESTIMONIAL' ? (
                    <>
                      <h3 className="font-bold text-sm text-white">{block.titleUz}</h3>
                      <p className="text-[11px] text-slate-400 break-all">{block.mediaUrl}</p>
                    </>
                  ) : (
                    <>
                      <h3 className="font-bold text-sm text-white">{block.titleUz}</h3>
                      <p className="text-[11px] text-slate-400 line-clamp-3">{block.bodyUz}</p>
                    </>
                  )}
                  <div className="flex items-center space-x-2 pt-2">
                    <button onClick={() => handleEditBlock(block)} className="flex-1 bg-[#1E3A5F] hover:bg-[#2A4D7B] text-white py-1.5 rounded-lg text-xs font-semibold transition">✏️ Tahrirlash</button>
                    <button onClick={() => handleDeleteBlock(block.id)} className="bg-red-500/20 hover:bg-red-500/40 text-red-400 px-3 py-1.5 rounded-lg text-xs font-semibold transition">🗑️</button>
                  </div>
                </div>
              ))}
              {contentBlocks.filter(b => b.section === activeSection).length === 0 && (
                <p className="text-xs text-slate-500 col-span-full">Hozircha element yo'q. "+ Yangi Element" tugmasini bosing.</p>
              )}
            </div>
          </div>
        )}

        {/* Tab 2: Courses */}
        {activeTab === 'courses' && (
          <div className="space-y-4">
            <div className="flex justify-between items-center">
              <h2 className="text-lg font-bold">📚 Kurslar Katalogi</h2>
              <button
                onClick={handleOpenAddCourse}
                className="bg-[#C6F432] text-[#041426] font-bold px-4 py-2 rounded-xl text-sm hover:bg-[#b0de28] transition"
              >
                + Yangi Kurs Qo'shish
              </button>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
              {courses.map(course => (
                <div key={course.id} className="bg-[#0A1D33] border border-[#1E3A5F] rounded-2xl overflow-hidden p-4 space-y-2 relative group">
                  <img src={course.coverImage} alt={course.titleUz} className="w-full h-36 object-cover rounded-xl" />
                  <h3 className="font-bold text-base text-white">{course.titleUz}</h3>
                  <p className="text-xs text-slate-400 line-clamp-2">{course.subtitleUz}</p>
                  {course.targetAudienceUz && (
                    <p className="text-[11px] text-sky-400">👤 {course.targetAudienceUz}</p>
                  )}
                  <div className="flex justify-between items-center text-xs text-[#C6F432] font-bold pt-2 border-t border-[#1E3A5F]">
                    <span>
                      {course.discountPrice ? (
                        <>
                          <span className="line-through text-slate-500 mr-1">{money(course.price)}</span>
                          {money(course.discountPrice)}
                        </>
                      ) : money(course.price)}
                    </span>
                    <span>{course.studentCount} ta talaba</span>
                  </div>

                  <div className="flex items-center space-x-2 pt-2">
                    <button
                      onClick={() => handleEditCourse(course)}
                      className="flex-1 bg-[#1E3A5F] hover:bg-[#2A4D7B] text-white py-1.5 rounded-lg text-xs font-semibold transition text-center"
                    >
                      ✏️ Tahrirlash
                    </button>
                    <button
                      onClick={() => handleDeleteCourse(course.id)}
                      className="bg-red-500/20 hover:bg-red-500/40 text-red-400 px-3 py-1.5 rounded-lg text-xs font-semibold transition"
                    >
                      🗑️
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Tab 3: News */}
        {activeTab === 'news' && (
          <div className="space-y-4">
            <div className="flex justify-between items-center">
              <h2 className="text-lg font-bold">📰 Yangiliklar va E'lonlar</h2>
              <button
                onClick={handleOpenAddNews}
                className="bg-[#C6F432] text-[#041426] font-bold px-4 py-2 rounded-xl text-sm hover:bg-[#b0de28] transition"
              >
                + Yangi E'lon Yaratish
              </button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {news.map(item => (
                <div key={item.id} className="bg-[#0A1D33] border border-[#1E3A5F] rounded-2xl p-4 flex space-x-4 relative">
                  <img src={item.coverImage} alt={item.titleUz} className="w-28 h-28 object-cover rounded-xl" />
                  <div className="flex-1 space-y-1 flex flex-col justify-between">
                    <div>
                      <span className="text-[10px] text-[#C6F432] font-bold">{new Date(item.createdAt).toLocaleDateString('uz-UZ')}</span>
                      <h3 className="font-bold text-sm leading-snug text-white">{item.titleUz}</h3>
                      <p className="text-xs text-slate-400 line-clamp-2 mt-1">{item.contentUz}</p>
                    </div>

                    <div className="flex items-center space-x-3 pt-2">
                      <button onClick={() => { setNewsForm(item); setIsNewsModalOpen(true); }} className="text-xs text-[#C6F432] hover:text-[#b0de28] font-semibold">✏️ Tahrirlash</button>
                      <button
                        onClick={() => handleDeleteNews(item.id)}
                        className="text-xs text-red-400 hover:text-red-300 font-semibold"
                      >
                        🗑️ O'chirish
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Tab 4: Students */}
        {activeTab === 'students' && (
          <div className="space-y-4">
            <h2 className="text-lg font-bold">👥 Ro'yxatdan O'tgan Talabalar</h2>
            <div className="bg-[#0A1D33] border border-[#1E3A5F] rounded-2xl overflow-hidden shadow-xl">
              <div className="overflow-x-auto">
              <table className="w-full min-w-[680px] text-left text-xs">
                <thead className="bg-[#041426] text-slate-300 uppercase tracking-wider font-semibold">
                  <tr>
                    <th className="p-4">Talaba</th>
                    <th className="p-4">Telefon</th>
                    <th className="p-4">Shahar</th>
                    <th className="p-4">Kurslar</th>
                    <th className="p-4">Sana</th>
                    <th className="p-4 text-right">Rol</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#1E3A5F]">
                  {students.map(std => (
                    <tr key={std.id} className="hover:bg-[#132A45] transition">
                      <td className="p-4 font-bold flex items-center space-x-3">
                        {std.avatarUrl ? (
                          <img src={std.avatarUrl} alt="" className="w-8 h-8 rounded-full border border-[#C6F432] object-cover" />
                        ) : (
                          <div className="w-8 h-8 rounded-full bg-[#1E3A5F] flex items-center justify-center text-[#C6F432] text-[10px] font-bold">
                            {std.firstName?.[0]}{std.lastName?.[0]}
                          </div>
                        )}
                        <span>{std.firstName} {std.lastName}</span>
                      </td>
                      <td className="p-4 font-mono text-[#C6F432]">{std.phoneNumber}</td>
                      <td className="p-4 text-slate-300">{std.city || '—'}</td>
                      <td className="p-4">{std._count?.enrollments ?? 0} ta kurs</td>
                      <td className="p-4 text-slate-400">{new Date(std.createdAt).toLocaleDateString('uz-UZ')}</td>
                      <td className="p-4 text-right">
                        <span className="bg-emerald-500/20 text-emerald-400 px-2.5 py-1 rounded-lg text-[10px] font-bold">
                          {std.role}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
              </div>
            </div>
          </div>
        )}

        {/* Tab 5: Enrollments Queue */}
        {activeTab === 'enrollments' && (
          <div className="space-y-4">
            <h2 className="text-lg font-bold">📋 Arizalar Navbati</h2>
            <div className="bg-[#0A1D33] border border-[#1E3A5F] rounded-2xl overflow-hidden shadow-xl">
              <div className="overflow-x-auto">
              <table className="w-full min-w-[720px] text-left text-xs">
                <thead className="bg-[#041426] text-slate-300 uppercase tracking-wider font-semibold">
                  <tr>
                    <th className="p-4">Talaba</th>
                    <th className="p-4">Telefon</th>
                    <th className="p-4">Yoshi</th>
                    <th className="p-4">Manzil</th>
                    <th className="p-4">Tanlangan Kurs</th>
                    <th className="p-4">Holat</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#1E3A5F]">
                  {enrollments.map(enr => (
                    <tr key={enr.id} className="hover:bg-[#132A45] transition">
                      <td className="p-4 font-bold">{enr.user?.firstName} {enr.user?.lastName}</td>
                      <td className="p-4 font-mono text-[#C6F432]">
                        <a href={`tel:${enr.user?.phoneNumber}`} className="hover:underline">{enr.user?.phoneNumber}</a>
                      </td>
                      <td className="p-4">{enr.applicantAge ?? '—'}</td>
                      <td className="p-4 text-slate-400">{enr.address || '—'}</td>
                      <td className="p-4">{enr.course?.titleUz}</td>
                      <td className="p-4">
                        <select
                          value={enr.status}
                          onChange={(e) => handleEnrollmentStatusChange(enr.id, e.target.value)}
                          className={`px-2 py-1 rounded-lg font-bold text-[10px] border-0 ${statusBadge(enr.status)}`}
                        >
                          {ENROLLMENT_STATUSES.map(s => <option key={s} value={s} className="bg-[#0A1D33] text-white">{s}</option>)}
                        </select>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
              </div>
            </div>
          </div>
        )}

        {/* Tab: Payments */}
        {activeTab === 'payments' && (
          <div className="space-y-4">
            <h2 className="text-lg font-bold">💳 To'lovlar</h2>
            <div className="bg-[#0A1D33] border border-[#1E3A5F] rounded-2xl overflow-hidden shadow-xl">
              <div className="overflow-x-auto">
              <table className="w-full min-w-[760px] text-left text-xs">
                <thead className="bg-[#041426] text-slate-300 uppercase tracking-wider font-semibold">
                  <tr>
                    <th className="p-4">Talaba</th>
                    <th className="p-4">Kurs</th>
                    <th className="p-4">Summasi</th>
                    <th className="p-4">Usuli</th>
                    <th className="p-4">Chek</th>
                    <th className="p-4">Holat</th>
                    <th className="p-4 text-right">Amallar</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#1E3A5F]">
                  {payments.map(p => (
                    <tr key={p.id} className="hover:bg-[#132A45] transition">
                      <td className="p-4 font-bold">{p.user?.firstName} {p.user?.lastName}<br /><span className="font-mono text-[#C6F432] font-normal">{p.user?.phoneNumber}</span></td>
                      <td className="p-4">{p.enrollment?.course?.titleUz}</td>
                      <td className="p-4 text-[#C6F432] font-bold">{money(p.amount)}</td>
                      <td className="p-4">{p.method}</td>
                      <td className="p-4">
                        {p.receiptUrl ? (
                          <a href={p.receiptUrl} target="_blank" rel="noreferrer">
                            <img src={p.receiptUrl} alt="chek" className="w-12 h-12 object-cover rounded-lg border border-[#1E3A5F]" />
                          </a>
                        ) : '—'}
                      </td>
                      <td className="p-4">
                        <span className={`px-2.5 py-1 rounded-lg font-bold text-[10px] ${statusBadge(p.status)}`}>{p.status}</span>
                      </td>
                      <td className="p-4 text-right space-x-2">
                        {p.status === 'PENDING' && (
                          <>
                            <button onClick={() => handlePaymentStatus(p.id, 'APPROVED')} className="bg-emerald-500/20 hover:bg-emerald-500/40 text-emerald-300 px-2.5 py-1 rounded-lg text-xs font-semibold">✓ Tasdiqlash</button>
                            <button onClick={() => handlePaymentStatus(p.id, 'REJECTED')} className="bg-red-500/20 hover:bg-red-500/40 text-red-400 px-2.5 py-1 rounded-lg text-xs font-semibold">✕ Rad etish</button>
                          </>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
              </div>
              {payments.length === 0 && <p className="text-center text-slate-500 text-xs py-8">Hozircha to'lovlar yo'q</p>}
            </div>
          </div>
        )}

        {/* Tab: Notifications */}
        {activeTab === 'notifications' && (
          <div className="space-y-4 max-w-xl">
            <h2 className="text-lg font-bold">🔔 Barchaga Bildirishnoma Yuborish</h2>
            <div className="bg-[#0A1D33] border border-[#1E3A5F] rounded-2xl p-6 space-y-4">
              <div>
                <label className="block text-xs font-semibold text-slate-300 mb-1">Sarlavha</label>
                <input
                  type="text"
                  value={notifTitle}
                  onChange={e => setNotifTitle(e.target.value)}
                  placeholder="Masalan: Yangi guruhlarga qabul boshlandi!"
                  className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#C6F432]"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-300 mb-1">Xabar matni</label>
                <textarea
                  rows={4}
                  value={notifBody}
                  onChange={e => setNotifBody(e.target.value)}
                  placeholder="Xabar matnini kiriting..."
                  className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#C6F432]"
                />
              </div>
              {notifResult && <p className="text-xs text-slate-300">{notifResult}</p>}
              <button
                onClick={handleSendBroadcast}
                disabled={notifSending}
                className="bg-[#C6F432] hover:bg-[#b0de28] text-[#041426] font-bold px-5 py-2.5 rounded-xl transition shadow-lg text-sm disabled:opacity-60"
              >
                {notifSending ? 'Yuborilmoqda...' : '📢 Barchaga yuborish'}
              </button>
            </div>
          </div>
        )}
      </main>

      {/* Category Modal */}
      {isCategoryModalOpen && (
        <div className="fixed inset-0 bg-black/80 backdrop-blur-md flex items-center justify-center p-4 z-50">
          <div className="bg-[#0A1D33] border border-[#1E3A5F] rounded-3xl p-6 w-full max-w-md space-y-4 shadow-2xl max-h-[90vh] overflow-y-auto">
            <div className="flex justify-between items-center border-b border-[#1E3A5F] pb-3">
              <h3 className="text-lg font-bold text-[#C6F432]">{categoryForm.id ? '✏️ Kategoriyani Tahrirlash' : '➕ Yangi Kategoriya'}</h3>
              <button onClick={() => setIsCategoryModalOpen(false)} className="text-slate-400 hover:text-white text-xl font-bold">&times;</button>
            </div>
            <div className="space-y-3 text-xs">
              <div>
                <label className="block font-semibold text-slate-300 mb-1">Nomi *</label>
                <input type="text" value={categoryForm.nameUz || ''} onChange={e => setCategoryForm({ ...categoryForm, nameUz: e.target.value })} className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-white focus:outline-none focus:border-[#C6F432]" />
              </div>
              <div>
                <label className="block font-semibold text-slate-300 mb-1">Slug (masalan: kompyuter-it) *</label>
                <input type="text" value={categoryForm.slug || ''} onChange={e => setCategoryForm({ ...categoryForm, slug: e.target.value })} className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-white focus:outline-none focus:border-[#C6F432]" />
              </div>
              <div>
                <label className="block font-semibold text-slate-300 mb-1">Tartib raqami</label>
                <input type="number" value={categoryForm.sortOrder ?? 0} onChange={e => setCategoryForm({ ...categoryForm, sortOrder: parseInt(e.target.value) || 0 })} className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-white focus:outline-none focus:border-[#C6F432]" />
              </div>
            </div>
            <div className="flex justify-end space-x-3 pt-3 border-t border-[#1E3A5F]">
              <button onClick={() => setIsCategoryModalOpen(false)} className="px-4 py-2 rounded-xl text-xs font-semibold text-slate-400 hover:text-white">Bekor qilish</button>
              <button onClick={handleSaveCategory} className="bg-[#C6F432] hover:bg-[#b0de28] text-[#041426] font-bold px-5 py-2 rounded-xl text-xs shadow-lg">💾 Saqlash</button>
            </div>
          </div>
        </div>
      )}

      {/* Content Block (Site Section) Modal */}
      {isBlockModalOpen && (
        <div className="fixed inset-0 bg-black/80 backdrop-blur-md flex items-center justify-center p-4 z-50">
          <div className="bg-[#0A1D33] border border-[#1E3A5F] rounded-3xl p-6 w-full max-w-md space-y-4 shadow-2xl max-h-[90vh] overflow-y-auto">
            <div className="flex justify-between items-center border-b border-[#1E3A5F] pb-3">
              <h3 className="text-lg font-bold text-[#C6F432]">
                {blockForm.id ? '✏️ Elementni Tahrirlash' : '➕ Yangi Element'} — {CONTENT_SECTIONS.find(s => s.key === blockForm.section)?.label}
              </h3>
              <button onClick={() => setIsBlockModalOpen(false)} className="text-slate-400 hover:text-white text-xl font-bold">&times;</button>
            </div>
            <div className="space-y-3 text-xs">
              {blockForm.section === 'TESTIMONIAL' ? (
                <>
                  <div>
                    <label className="block font-semibold text-slate-300 mb-1">Video URL (istalgan YouTube havolasi) *</label>
                    <input type="text" value={blockForm.mediaUrl || ''} onChange={e => setBlockForm({ ...blockForm, mediaUrl: e.target.value })} placeholder="https://www.youtube.com/watch?v=... yoki youtu.be/..." className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-white focus:outline-none focus:border-[#C6F432]" />
                    <p className="text-[10px] text-slate-500 mt-1">Har qanday YouTube havolasini joylashtirsangiz bo'ladi (watch, youtu.be, shorts) — saqlashda avtomatik to'g'ri formatga o'giriladi.</p>
                  </div>
                  <div>
                    <label className="block font-semibold text-slate-300 mb-1">Sarlavha</label>
                    <input type="text" value={blockForm.titleUz || ''} onChange={e => setBlockForm({ ...blockForm, titleUz: e.target.value })} className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-white focus:outline-none focus:border-[#C6F432]" />
                  </div>
                </>
              ) : blockForm.section === 'STAT' ? (
                <>
                  <div>
                    <label className="block font-semibold text-slate-300 mb-1">Raqam (masalan: 500+) *</label>
                    <input type="text" value={blockForm.titleUz || ''} onChange={e => setBlockForm({ ...blockForm, titleUz: e.target.value })} className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-white focus:outline-none focus:border-[#C6F432]" />
                  </div>
                  <div>
                    <label className="block font-semibold text-slate-300 mb-1">Yorliq matni</label>
                    <input type="text" value={blockForm.bodyUz || ''} onChange={e => setBlockForm({ ...blockForm, bodyUz: e.target.value })} className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-white focus:outline-none focus:border-[#C6F432]" />
                  </div>
                </>
              ) : (
                <>
                  <div>
                    <label className="block font-semibold text-slate-300 mb-1">Ikonka (FontAwesome klass, masalan: fa-solid fa-user-graduate)</label>
                    <input type="text" value={blockForm.iconName || ''} onChange={e => setBlockForm({ ...blockForm, iconName: e.target.value })} className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-white focus:outline-none focus:border-[#C6F432]" />
                  </div>
                  <div>
                    <label className="block font-semibold text-slate-300 mb-1">Sarlavha *</label>
                    <input type="text" value={blockForm.titleUz || ''} onChange={e => setBlockForm({ ...blockForm, titleUz: e.target.value })} className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-white focus:outline-none focus:border-[#C6F432]" />
                  </div>
                  {blockForm.section !== 'TRUST_BULLET' && (
                    <div>
                      <label className="block font-semibold text-slate-300 mb-1">Matn</label>
                      <textarea rows={2} value={blockForm.bodyUz || ''} onChange={e => setBlockForm({ ...blockForm, bodyUz: e.target.value })} className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-white focus:outline-none focus:border-[#C6F432]" />
                    </div>
                  )}
                </>
              )}
              <div>
                <label className="block font-semibold text-slate-300 mb-1">Tartib raqami</label>
                <input type="number" value={blockForm.sortOrder ?? 0} onChange={e => setBlockForm({ ...blockForm, sortOrder: parseInt(e.target.value) || 0 })} className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-white focus:outline-none focus:border-[#C6F432]" />
              </div>
              <div className="flex items-center space-x-3 pt-1">
                <input type="checkbox" checked={blockForm.isActive ?? true} onChange={e => setBlockForm({ ...blockForm, isActive: e.target.checked })} className="w-4 h-4" />
                <label className="font-semibold text-slate-300">Saytda ko'rinsin (faol)</label>
              </div>
            </div>
            <div className="flex justify-end space-x-3 pt-3 border-t border-[#1E3A5F]">
              <button onClick={() => setIsBlockModalOpen(false)} className="px-4 py-2 rounded-xl text-xs font-semibold text-slate-400 hover:text-white">Bekor qilish</button>
              <button onClick={handleSaveBlock} className="bg-[#C6F432] hover:bg-[#b0de28] text-[#041426] font-bold px-5 py-2 rounded-xl text-xs shadow-lg">💾 Saqlash</button>
            </div>
          </div>
        </div>
      )}

      {/* Course Edit/Create Modal */}
      {isCourseModalOpen && (
        <div className="fixed inset-0 bg-black/80 backdrop-blur-md flex items-center justify-center p-4 z-50">
          <div className="bg-[#0A1D33] border border-[#1E3A5F] rounded-3xl p-6 w-full max-w-lg space-y-4 shadow-2xl max-h-[90vh] overflow-y-auto">
            <div className="flex justify-between items-center border-b border-[#1E3A5F] pb-3">
              <h3 className="text-lg font-bold text-[#C6F432]">
                {courseForm.id ? '✏️ Kursni Tahrirlash' : '➕ Yangi Kurs Qo\'shish'}
              </h3>
              <button onClick={() => setIsCourseModalOpen(false)} className="text-slate-400 hover:text-white text-xl font-bold">&times;</button>
            </div>

            <div className="space-y-3 text-xs">
              <div>
                <label className="block font-semibold text-slate-300 mb-1">Kategoriya *</label>
                <select
                  value={courseForm.categoryId || ''}
                  onChange={e => setCourseForm({ ...courseForm, categoryId: e.target.value })}
                  className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-white focus:outline-none focus:border-[#C6F432]"
                >
                  <option value="">Tanlang...</option>
                  {categories.map(c => <option key={c.id} value={c.id}>{c.nameUz}</option>)}
                </select>
              </div>

              <div>
                <label className="block font-semibold text-slate-300 mb-1">Kurs Nomi *</label>
                <input
                  type="text"
                  value={courseForm.titleUz || ''}
                  onChange={e => setCourseForm({ ...courseForm, titleUz: e.target.value })}
                  placeholder="Masalan: Web Dasturlash (Full-stack)"
                  className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-white focus:outline-none focus:border-[#C6F432]"
                />
              </div>

              <div>
                <label className="block font-semibold text-slate-300 mb-1">Kichik Tavsif / Subtitle</label>
                <input
                  type="text"
                  value={courseForm.subtitleUz || ''}
                  onChange={e => setCourseForm({ ...courseForm, subtitleUz: e.target.value })}
                  placeholder="Masalan: HTML, CSS, JavaScript va React noldan"
                  className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-white focus:outline-none focus:border-[#C6F432]"
                />
              </div>

              <div>
                <label className="block font-semibold text-slate-300 mb-1">Kimlar uchun (maqsadli auditoriya)</label>
                <input
                  type="text"
                  value={courseForm.targetAudienceUz || ''}
                  onChange={e => setCourseForm({ ...courseForm, targetAudienceUz: e.target.value })}
                  placeholder="Masalan: 14-25 yosh o'smir va yoshlar uchun"
                  className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-white focus:outline-none focus:border-[#C6F432]"
                />
              </div>

              <div>
                <label className="block font-semibold text-slate-300 mb-1">To'liq tavsif *</label>
                <textarea
                  rows={3}
                  value={courseForm.descriptionUz || ''}
                  onChange={e => setCourseForm({ ...courseForm, descriptionUz: e.target.value })}
                  className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-white focus:outline-none focus:border-[#C6F432]"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-semibold text-slate-300 mb-1">Narxi (so'm) *</label>
                  <input
                    type="number"
                    value={courseForm.price ?? 0}
                    onChange={e => setCourseForm({ ...courseForm, price: parseInt(e.target.value) || 0 })}
                    className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-white focus:outline-none focus:border-[#C6F432]"
                  />
                </div>

                <div>
                  <label className="block font-semibold text-slate-300 mb-1">Chegirmali narx (ixtiyoriy)</label>
                  <input
                    type="number"
                    value={courseForm.discountPrice ?? ''}
                    onChange={e => setCourseForm({ ...courseForm, discountPrice: e.target.value === '' ? undefined : parseInt(e.target.value) })}
                    className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-white focus:outline-none focus:border-[#C6F432]"
                  />
                </div>
              </div>

              <div>
                <label className="block font-semibold text-slate-300 mb-1">Muqova Rasmi</label>
                <div className="flex items-center space-x-3">
                  <img src={courseForm.coverImage} alt="preview" className="w-16 h-16 object-cover rounded-xl border border-[#1E3A5F]" />
                  <FileUploadButton id="upload-course-image" onChange={handleCourseImageUpload} hint="Tavsiya: 1200×800 px (gorizontal, 3:2), JPG yoki PNG format, hajmi 2 MB dan oshmasin — kurs kartochkasida shu nisbatda ko'rinadi." />
                </div>
              </div>

              <div className="flex items-center space-x-2 pt-1">
                <input type="checkbox" checked={!!courseForm.isPopular} onChange={e => setCourseForm({ ...courseForm, isPopular: e.target.checked })} className="w-4 h-4" />
                <label className="font-semibold text-slate-300">Mashhur kurs sifatida belgilash (mobil ilova bosh sahifasida alohida banner bilan chiqadi)</label>
              </div>
            </div>

            <div className="flex justify-end space-x-3 pt-3 border-t border-[#1E3A5F]">
              <button
                onClick={() => setIsCourseModalOpen(false)}
                className="px-4 py-2 rounded-xl text-xs font-semibold text-slate-400 hover:text-white"
              >
                Bekor qilish
              </button>
              <button
                onClick={handleSaveCourse}
                className="bg-[#C6F432] hover:bg-[#b0de28] text-[#041426] font-bold px-5 py-2 rounded-xl text-xs shadow-lg"
              >
                💾 Saqlash
              </button>
            </div>
          </div>
        </div>
      )}

      {/* News Modal */}
      {isNewsModalOpen && (
        <div className="fixed inset-0 bg-black/80 backdrop-blur-md flex items-center justify-center p-4 z-50">
          <div className="bg-[#0A1D33] border border-[#1E3A5F] rounded-3xl p-6 w-full max-w-lg space-y-4 shadow-2xl max-h-[90vh] overflow-y-auto">
            <div className="flex justify-between items-center border-b border-[#1E3A5F] pb-3">
              <h3 className="text-lg font-bold text-[#C6F432]">{newsForm.id ? '✏️ E\'lonni Tahrirlash' : '📰 Yangi E\'lon Yaratish'}</h3>
              <button onClick={() => setIsNewsModalOpen(false)} className="text-slate-400 hover:text-white text-xl font-bold">&times;</button>
            </div>

            <div className="space-y-3 text-xs">
              <div>
                <label className="block font-semibold text-slate-300 mb-1">E'lon Sarlavhasi *</label>
                <input
                  type="text"
                  value={newsForm.titleUz || ''}
                  onChange={e => setNewsForm({ ...newsForm, titleUz: e.target.value })}
                  placeholder="Yangilik sarlavhasini kiriting..."
                  className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-white focus:outline-none focus:border-[#C6F432]"
                />
              </div>

              <div>
                <label className="block font-semibold text-slate-300 mb-1">Batafsil Matni</label>
                <textarea
                  rows={4}
                  value={newsForm.contentUz || ''}
                  onChange={e => setNewsForm({ ...newsForm, contentUz: e.target.value })}
                  placeholder="Yangilik matni..."
                  className="w-full bg-[#041426] border border-[#1E3A5F] rounded-xl px-4 py-2.5 text-white focus:outline-none focus:border-[#C6F432]"
                />
              </div>

              <div>
                <label className="block font-semibold text-slate-300 mb-1">Rasm</label>
                <div className="flex items-center space-x-3">
                  <img src={newsForm.coverImage} alt="preview" className="w-16 h-16 object-cover rounded-xl border border-[#1E3A5F]" />
                  <FileUploadButton id="upload-news-image" onChange={handleNewsImageUpload} hint="Tavsiya: 1200×800 px (gorizontal, 3:2), JPG yoki PNG format, hajmi 2 MB dan oshmasin." />
                </div>
              </div>

              <div className="flex items-center space-x-2 pt-1">
                <input type="checkbox" checked={!!newsForm.isFeatured} onChange={e => setNewsForm({ ...newsForm, isFeatured: e.target.checked })} className="w-4 h-4" />
                <label className="font-semibold text-slate-300">Bosh sahifada ko'rsatish (Featured)</label>
              </div>
            </div>

            <div className="flex justify-end space-x-3 pt-3 border-t border-[#1E3A5F]">
              <button
                onClick={() => setIsNewsModalOpen(false)}
                className="px-4 py-2 rounded-xl text-xs font-semibold text-slate-400 hover:text-white"
              >
                Bekor qilish
              </button>
              <button
                onClick={handleSaveNews}
                className="bg-[#C6F432] hover:bg-[#b0de28] text-[#041426] font-bold px-5 py-2 rounded-xl text-xs shadow-lg"
              >
                🚀 Saqlash
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
