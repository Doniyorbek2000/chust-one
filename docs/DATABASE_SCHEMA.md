# DATABASE SCHEMA — CHUST ONE ACADEMY (Prisma ORM)

```prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

generator client {
  provider = "prisma-client-js"
}

enum Role {
  SUPER_ADMIN
  ADMIN
  CONTENT_MANAGER
  OPERATOR
  TEACHER
  STUDENT
}

enum EnrollmentStatus {
  NEW
  CONTACTED
  APPROVED
  PAYMENT_PENDING
  ENROLLED
  REJECTED
  COMPLETED
}

enum PaymentStatus {
  PENDING
  PROCESSING
  PAID
  FAILED
  CANCELED
  REFUNDED
}

enum PaymentMethod {
  CLICK
  PAYME
  UZUM
  BANK_TRANSFER
  CASH
}

model User {
  id            String         @id @default(uuid())
  firstName     String
  lastName      String
  phoneNumber   String         @unique
  email         String?        @unique
  passwordHash  String
  role          Role           @default(STUDENT)
  avatarUrl     String?
  city          String?
  isVerified    Boolean        @default(false)
  createdAt     DateTime       @default(now())
  updatedAt     DateTime       @updatedAt
  enrollments   Enrollment[]
  payments      Payment[]
  favorites     Favorite[]
  notifications Notification[]
  refreshTokens RefreshToken[]
}

model RefreshToken {
  id        String   @id @default(uuid())
  userId    String
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  token     String   @unique
  expiresAt DateTime
  createdAt DateTime @default(now())
}

model CourseCategory {
  id          String   @id @default(uuid())
  nameUz      String
  nameRu      String
  nameEn      String
  slug        String   @unique
  iconName    String
  sortOrder   Int      @default(0)
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
  courses     Course[]
}

model Course {
  id              String          @id @default(uuid())
  categoryId      String
  category        CourseCategory  @relation(fields: [categoryId], references: [id])
  titleUz         String
  titleRu         String
  titleEn         String
  subtitleUz      String?
  subtitleRu      String?
  subtitleEn      String?
  descriptionUz   String
  descriptionRu   String
  descriptionEn   String
  coverImage      String
  price           Float
  discountPrice   Float?
  durationMonths  Int
  lessonCount     Int
  lessonsPerWeek  Int
  level           String          @default("Zero dan Pro gacha")
  format          String          @default("Oflayn / Amaliy")
  isPopular       Boolean         @default(false)
  isKompyuterKids Boolean         @default(false)
  kidsTargetGrades String?        // e.g. "1-5 sinflar"
  kidsDuration    String?         // e.g. "2 oylik"
  rating          Float           @default(5.0)
  studentCount    Int             @default(0)
  createdAt       DateTime        @default(now())
  updatedAt       DateTime        @updatedAt
  modules         CourseModule[]
  enrollments     Enrollment[]
  favorites       Favorite[]
  teachers        TeacherCourse[]
}

model CourseModule {
  id          String   @id @default(uuid())
  courseId    String
  course      Course   @relation(fields: [courseId], references: [id], onDelete: Cascade)
  titleUz     String
  titleRu     String
  titleEn     String
  sortOrder   Int      @default(0)
  topics      CourseTopic[]
}

model CourseTopic {
  id          String       @id @default(uuid())
  moduleId    String
  module      CourseModule @relation(fields: [moduleId], references: [id], onDelete: Cascade)
  titleUz     String
  titleRu     String
  titleEn     String
  icon        String?
  sortOrder   Int          @default(0)
}

model Teacher {
  id            String          @id @default(uuid())
  fullName      String
  specialization String
  experienceYears Int
  bio           String
  avatarUrl     String
  rating        Float           @default(5.0)
  createdAt     DateTime        @default(now())
  courses       TeacherCourse[]
}

model TeacherCourse {
  teacherId String
  courseId  String
  teacher   Teacher @relation(fields: [teacherId], references: [id], onDelete: Cascade)
  course    Course  @relation(fields: [courseId], references: [id], onDelete: Cascade)

  @@id([teacherId, courseId])
}

model Branch {
  id           String       @id @default(uuid())
  nameUz       String
  nameRu       String
  nameEn       String
  addressLandmark String    // "Book Kafee yonida, Ilhom Travel binosida"
  city         String       // "Chust shahri"
  latitude     Float
  longitude    Float
  phonePrimary String       // "+998 (99) 972 52 22"
  telegramUser String?      // "@Kompyuter_Kursi15"
  telegramContact String?   // "@Kayumkhadjayev"
  instagramUser String?     // "@Chust_One_Academy"
  workingHours String
  createdAt    DateTime     @default(now())
  enrollments  Enrollment[]
}

model Enrollment {
  id             String           @id @default(uuid())
  userId         String
  user           User             @relation(fields: [userId], references: [id])
  courseId       String
  course         Course           @relation(fields: [courseId], references: [id])
  branchId       String?
  branch         Branch?          @relation(fields: [branchId], references: [id])
  preferredTime  String           // "Ertalabki (09:00 - 11:00)"
  applicantAge   Int?
  parentPhone    String?
  comment        String?
  referralSource String?
  promoCode      String?
  status         EnrollmentStatus @default(NEW)
  createdAt      DateTime         @default(now())
  updatedAt      DateTime         @updatedAt
  payments       Payment[]
}

model Payment {
  id            String        @id @default(uuid())
  enrollmentId  String
  enrollment    Enrollment    @relation(fields: [enrollmentId], references: [id])
  userId        String
  user          User          @relation(fields: [userId], references: [id])
  amount        Float
  method        PaymentMethod
  status        PaymentStatus @default(PENDING)
  receiptUrl    String?
  notes         String?
  createdAt     DateTime      @default(now())
  updatedAt     DateTime      @updatedAt
}

model News {
  id          String   @id @default(uuid())
  titleUz     String
  titleRu     String
  titleEn     String
  contentUz   String
  contentRu   String
  contentEn   String
  coverImage  String
  viewCount   Int      @default(0)
  isFeatured  Boolean  @default(false)
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
}

model Favorite {
  userId    String
  courseId  String
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  course    Course   @relation(fields: [courseId], references: [id], onDelete: Cascade)
  createdAt DateTime @default(now())

  @@id([userId, courseId])
}

model Notification {
  id        String   @id @default(uuid())
  userId    String
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  title     String
  body      String
  type      String   @default("SYSTEM")
  isRead    Boolean  @default(false)
  createdAt DateTime @default(now())
}

model AppSetting {
  id               String   @id @default("1")
  heroTitleUz      String   @default("Kelajagingizni biz bilan yarating!")
  heroSubtitleUz   String   @default("Zamonaviy kasblar va kompyuter savodxonligini o'rganing.")
  mainPhone        String   @default("+998 (99) 972 52 22")
  isMaintenance    Boolean  @default(false)
  minAppVersion    String   @default("1.0.0")
  updatedAt        DateTime @updatedAt
}
```
