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
   - Multi-language support: Uzbek (Latin), Russian, English
   - Dark Mode & Light Mode support

2. **`backend/`**: Node.js / Express REST API Backend with Prisma ORM & SQLite/PostgreSQL
   - JWT Authentication with password hashing
   - Full seed script with real Chust One Academy course catalog, branch location, teachers, news, and admin user (`admin@chustone.uz` / `admin123`)

3. **`admin/`**: Next.js 14 Web Admin Panel
   - Real-time KPI statistics dashboard
   - Candidate application pipeline (Status: `NEW` -> `CONTACTED` -> `APPROVED` -> `PAID` -> `ENROLLED`)
   - Course CMS & Location manager

---

## 🚀 Quick Start Guide

### 1. Run Backend REST API Server
```bash
cd backend
npm install
npx prisma db push
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

## 🔑 Default Credentials
- **Superadmin Email**: `admin@chustone.uz`
- **Superadmin Password**: `admin123`
- **Student Phone**: `+998991234567`
- **Student Password**: `student123`
