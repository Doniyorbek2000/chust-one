# USER FLOWS & SCREEN MAP — CHUST ONE ACADEMY

## 1. Primary User Flows

### Flow A: Mobile App Discovery & Enrollment
1. **Launch**: Splash Screen -> Animated Logo & Branding -> Version/Token check.
2. **Onboarding**: 4 interactive intro slides -> Action "Boshlash".
3. **Authentication**: Enter Phone (+998 XX XXX XX XX) -> Input OTP -> Complete Profile.
4. **Home Navigation**: View Hero banner ("Kelajagingizni biz bilan yarating!") -> Explore Course Categories (e.g. "Kompyuter savodxonligi") or Branch Location ("Book Kafee yonida, Ilhom Travel binosida").
5. **Course Inspection**: Select "Kompyuter savodxonligi" -> Inspect topics (Word, Excel, PowerPoint, Internet searching, Printer usage, Security) & "Kompyuter Kids 1-5 grade" details.
6. **Enrollment**: Tap sticky CTA "Ro'yxatdan o'tish" -> Choose preferred time slot & branch -> Submit application.
7. **Payment Proof**: Select payment method (Click / Payme / Uzum / Cash) -> Upload payment screenshot -> Receive real-time application status tracker.

### Flow B: Admin Application Management
1. **Login**: Admin signs into Web Dashboard (`/admin/login`).
2. **KPI Overview**: Views recent candidates, total revenue, active course numbers.
3. **Application Review**: Selects incoming enrollment -> Updates status from `NEW` to `CONTACTED` or `APPROVED`.
4. **Payment Audit**: Inspects submitted user receipt screenshot -> Marks status as `PAID` / `ENROLLED`.
5. **Content Update**: Updates dynamic hero banner text or adds new course categories.

---

## 2. Screen Map

### Mobile Application Routes (`mobile/lib/app/router/`)
- `/splash` — Splash Screen
- `/onboarding` — Onboarding Carousel
- `/auth/login` — Phone/Email Login
- `/auth/register` — Student Registration
- `/auth/otp` — OTP Verification
- `/home` — Home Screen (Tab 0)
- `/courses` — Course Catalog (Tab 1)
- `/courses/:id` — Course Detail Screen
- `/enrollment` — Multi-step Enrollment Sheet
- `/payment/upload` — Payment Upload & Status Tracker
- `/news` — News Catalog (Tab 2)
- `/news/:id` — News Detail Screen
- `/teachers` — Teachers Directory
- `/branches` — Branch Location & Contact Info Map View
- `/profile` — Student Profile (Tab 3)
- `/profile/my-courses` — Active Enrolled Courses & Progress
- `/profile/applications` — My Applications History
- `/profile/settings` — Theme (Light/Dark), Language (Uz/Ru/En), Security

### Web Admin Panel Routes (`admin/app/`)
- `/login` — Admin Authentication
- `/dashboard` — Overview & Metrics
- `/courses` — Courses CMS
- `/enrollments` — Applicants Pipeline Table
- `/payments` — Audit Payment Receipts
- `/branches` — Branch Details & Address Manager
- `/teachers` — Teachers Management
- `/news` — News & Announcements Editor
- `/settings` — Mobile App Dynamic Configuration
