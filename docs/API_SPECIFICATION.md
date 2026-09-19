# API SPECIFICATION — CHUST ONE ACADEMY REST API

Base URL: `/api/v1`

## 1. Auth Module (`/auth`)
Mobile app uses phone + SMS-code only (no password):
- `POST /auth/otp/request` — Send a 4-digit code (via Eskiz.uz) to a phone number. Uzbek numbers only; limited to 1 per 60s and 5 per hour per phone (plus a global hourly cap).
- `POST /auth/otp/verify` — Verify the code. Returns `{status: 'logged_in', token, user}` for an existing account, or `{status: 'registration_required', registrationToken}` for a new phone.
- `POST /auth/otp/complete-registration` — Finish signup for a new phone using the `registrationToken` plus `firstName`, `lastName`, `birthDate` (YYYY-MM-DD), `address`. Returns `{token, user}`.

Admin panel still uses password login:
- `POST /auth/register` — Register with name, phone (+998), password, city.
- `POST /auth/login` — Login with phone and password.
- `GET /auth/me` — Retrieve current authenticated user profile.
- `PATCH /auth/profile` — Update profile fields (name, city, age, address, birthDate, avatarUrl).
- `DELETE /auth/account` — Self-service account deletion; confirm with `password` or a fresh `otpCode`.

A user's birthday automatically triggers an in-app notification (see Notifications) — no client call needed.

## 2. Courses & Categories (`/courses`, `/categories`)
- `GET /categories` — List active course categories.
- `GET /courses` — List courses with search query, category filter, price range, and level filter.
- `GET /courses/:id` — Detailed course info including syllabus modules, topics, teacher info, and Kompyuter Kids flag.
- `GET /courses/:id/related` — Suggested related courses.

## 3. Enrollments & Applications (`/enrollments`)
- `POST /enrollments` — Submit application for a course (Student name, phone, age, preferred schedule, group, branch, referral).
- `GET /enrollments/my` — Get candidate's submitted applications & status updates.
- `GET /enrollments/:id` — Application details and status timeline.

## 4. Payments (`/payments`)
- `POST /payments/upload-receipt` — Submit payment check/receipt screenshot with payment provider selection (Click, Payme, Uzum, Cash, Bank Transfer).
- `GET /payments/my` — User payment history and verification status.

## 5. Branches & Contacts (`/branches`, `/contact`)
- `GET /branches` — Get academy branches with geo coordinates, location landmark ("Book Kafee yonida, Ilhom Travel binosida"), address, contacts, and working hours.
- `POST /contact/callback` — Request callback from academy operators.

## 6. News & Announcements (`/news`)
- `GET /news` — Paginated list of academy news and announcements.
- `GET /news/:id` — Detail article view.

## 7. Teachers (`/teachers`)
- `GET /teachers` — Directory of academy instructors.
- `GET /teachers/:id` — Detailed instructor bio and taught courses.

## 8. Admin Controls (`/admin/...`)
- `GET /admin/dashboard/stats` — High-level KPI metrics for admin panel.
- `GET /admin/enrollments` — Review applicant queue with status transitions (NEW -> CONTACTED -> APPROVED -> PAID -> ENROLLED -> REJECTED).
- `PATCH /admin/enrollments/:id/status` — Change applicant status.
- `POST /admin/courses` — Create/Update courses and syllabus modules.
- `PATCH /admin/settings` — Update dynamic app settings (Hero text, maintenance toggle, branch address).
