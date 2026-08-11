# CHUST ONE ACADEMY — PRODUCTION MOBILE APP, BACKEND & ADMIN PANEL

This repository contains the complete production-ready ecosystem for **Chust One Academy** in Chust, Uzbekistan.

---

## 📱 Ecosystem Components

1. **`mobile/`**: Cross-platform Flutter Mobile Application (Android & iOS)
   - Built with Flutter 3.44+ & Dart 3.12+
   - Riverpod State Management & GoRouter Navigation
   - Pixel-perfect synthesis of Chust One Academy visual reference designs:
     - Dark Navy (`#041426`) & Vibrant Lime Accent (`#D7FF00`)
     - Complete "Kompyuter savodxonligi" course syllabus (Word, Excel, PowerPoint, Internet searching, Printer usage, Document printing, Security)
     - Specialized "Kompyuter Kids" 2-month program highlight for grades 1–5
     - Branch location card: *"Book Kafee yonida, Ilhom Travel binosida. Chust shahri."*
     - Direct contacts: `+998 (99) 972 52 22`, Telegram `@Kompyuter_Kursi15`, `@Kayumkhadjayev`, Instagram `@Chust_One_Academy`
   - Uzbek (Latin) only — no other languages
   - Dark mode only — no theme toggle

2. **`backend/`**: Node.js / Express REST API Backend with Prisma ORM & PostgreSQL
   - JWT Authentication with password hashing
   - Full seed script with real Chust One Academy course catalog, branch location, teachers, and news

3. **`admin/`**: Next.js 14 Web Admin Panel
   - Real-time KPI statistics dashboard
   - Candidate application pipeline (Status: `NEW` -> `CONTACTED` -> `APPROVED` -> `PAID` -> `ENROLLED`)
   - Course CMS & Location manager

---

## 🚀 Quick Start Guide

### 1. Run Backend REST API Server
Requires a PostgreSQL database. Copy `.env.example` to `.env` and fill in `DATABASE_URL`, `JWT_SECRET`, and (optionally) `ADMIN_PHONE`/`ADMIN_EMAIL`/`ADMIN_PASSWORD` before seeding.
```bash
cd backend
npm install
cp .env.example .env   # then edit .env with real values
npx prisma migrate deploy
npm run db:seed
npm run dev
```
Backend API will be live on `http://localhost:5000`.

### 2. Run Flutter Mobile App
```bash
cd mobile
flutter pub get
flutter run
```

### 3. Run Web Admin Panel
```bash
cd admin
npm install
npm run dev
```
Admin Dashboard will be live on `http://localhost:3000`.

---

## 🔑 Admin Credentials

The seed script creates the initial superadmin account from `ADMIN_PHONE` / `ADMIN_EMAIL` / `ADMIN_PASSWORD` in `backend/.env`. Set real values there before seeding a production database — do not deploy with the `.env.example` placeholders.
