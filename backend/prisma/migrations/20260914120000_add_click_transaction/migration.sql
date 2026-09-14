-- CreateTable
CREATE TABLE "ClickTransaction" (
    "id" TEXT NOT NULL,
    "clickTransId" TEXT NOT NULL,
    "merchantPrepareId" SERIAL NOT NULL,
    "enrollmentId" TEXT NOT NULL,
    "paymentId" TEXT,
    "amount" DOUBLE PRECISION NOT NULL,
    "state" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "preparedAt" TIMESTAMP(3),
    "performedAt" TIMESTAMP(3),
    "cancelledAt" TIMESTAMP(3),

    CONSTRAINT "ClickTransaction_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "ClickTransaction_clickTransId_key" ON "ClickTransaction"("clickTransId");

-- CreateIndex
CREATE UNIQUE INDEX "ClickTransaction_merchantPrepareId_key" ON "ClickTransaction"("merchantPrepareId");

-- CreateIndex
CREATE UNIQUE INDEX "ClickTransaction_paymentId_key" ON "ClickTransaction"("paymentId");

-- AddForeignKey
ALTER TABLE "ClickTransaction" ADD CONSTRAINT "ClickTransaction_enrollmentId_fkey" FOREIGN KEY ("enrollmentId") REFERENCES "Enrollment"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
