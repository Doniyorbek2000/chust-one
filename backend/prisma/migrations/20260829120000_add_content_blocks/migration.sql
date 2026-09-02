-- AlterTable
ALTER TABLE "AppSetting" ADD COLUMN     "aboutIntroUz" TEXT NOT NULL DEFAULT 'Biz Chust shahridagi zamonaviy IT va media ta''lim markazlaridan biri sifatida, nazariyadan ko''ra amaliyotga ko''proq vaqt ajratamiz. Har bir talaba individual e''tibor va real loyihalar ustida ishlash imkoniyatiga ega bo''ladi.',
ADD COLUMN     "aboutImageUrl" TEXT NOT NULL DEFAULT 'https://images.unsplash.com/photo-1571260899304-425eee4c7efc?auto=format&fit=crop&w=700&q=80',
ADD COLUMN     "aboutBadgeNumberUz" TEXT NOT NULL DEFAULT '500+',
ADD COLUMN     "aboutBadgeLabelUz" TEXT NOT NULL DEFAULT 'Muvaffaqiyatli bitiruvchilar';

-- CreateTable
CREATE TABLE "ContentBlock" (
    "id" TEXT NOT NULL,
    "section" TEXT NOT NULL,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "iconName" TEXT,
    "titleUz" TEXT,
    "bodyUz" TEXT,
    "mediaUrl" TEXT,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ContentBlock_pkey" PRIMARY KEY ("id")
);
