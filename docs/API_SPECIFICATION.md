# API SPECIFICATION — CHUST ONE ACADEMY REST API

Base URL: `/api/v1`

## 1. Auth Module (`/auth`)
- `POST /auth/register` — Register student with name, phone (+998), password, city, interested courses.
- `POST /auth/login` — Login with phone/email and password.
- `POST /auth/verify-otp` — Verify SMS OTP code.
- `POST /auth/refresh` — Refresh access token using refresh token.
- `GET /auth/me` — Retrieve current authenticated user profile.
- `POST /auth/logout` — Invalidate user tokens.

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
