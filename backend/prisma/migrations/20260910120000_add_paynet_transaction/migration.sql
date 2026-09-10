-- CreateTable
CREATE TABLE "PaynetTransaction" (
    "id" TEXT NOT NULL,
    "paynetTrnId" TEXT NOT NULL,
    "providerTrnId" SERIAL NOT NULL,
    "enrollmentId" TEXT NOT NULL,
    "paymentId" TEXT,
    "amount" DOUBLE PRECISION NOT NULL,
    "state" INTEGER NOT NULL DEFAULT 1,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "performedAt" TIMESTAMP(3),
    "cancelledAt" TIMESTAMP(3),

    CONSTRAINT "PaynetTransaction_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "PaynetTransaction_paynetTrnId_key" ON "PaynetTransaction"("paynetTrnId");

-- CreateIndex
CREATE UNIQUE INDEX "PaynetTransaction_providerTrnId_key" ON "PaynetTransaction"("providerTrnId");

-- CreateIndex
CREATE UNIQUE INDEX "PaynetTransaction_paymentId_key" ON "PaynetTransaction"("paymentId");

-- AddForeignKey
ALTER TABLE "PaynetTransaction" ADD CONSTRAINT "PaynetTransaction_enrollmentId_fkey" FOREIGN KEY ("enrollmentId") REFERENCES "Enrollment"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
