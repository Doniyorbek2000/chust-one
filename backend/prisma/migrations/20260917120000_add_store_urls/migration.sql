-- AlterTable
ALTER TABLE "AppSetting" ADD COLUMN     "androidStoreUrl" TEXT NOT NULL DEFAULT 'https://play.google.com/store/apps/details?id=uz.chustone.academy',
ADD COLUMN     "iosStoreUrl" TEXT NOT NULL DEFAULT '';
