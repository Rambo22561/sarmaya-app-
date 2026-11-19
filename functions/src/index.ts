import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";

admin.initializeApp();
const db = admin.firestore();

async function assertAdmin(uid: string | undefined): Promise<string> {
  if (!uid) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }
  const adminDoc = await db.collection("admins").doc(uid).get();
  if (adminDoc.exists) return uid;
  const userDoc = await db.collection("users").doc(uid).get();
  if (userDoc.exists && userDoc.data()?.role === "admin") {
    return uid;
  }
  throw new HttpsError("permission-denied", "Admin privileges required.");
}

async function createNotification(
  userId: string,
  title: string,
  body: string,
  type: string
): Promise<void> {
  await db.collection("notifications").add({
    userId,
    title,
    body,
    type,
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

async function writeAuditLog(
  actorId: string,
  action: string,
  targetCollection: string,
  targetId: string,
  summary: string
): Promise<void> {
  await db.collection("audit_logs").add({
    actorId,
    action,
    targetCollection,
    targetId,
    summary,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

function writeLedgerPair(
  tx: FirebaseFirestore.Transaction,
  params: {
    groupId: string;
    userId: string;
    debitAccount: string;
    creditAccount: string;
    category: string;
    amount: number;
    userBalanceAfter: number;
    description: string;
  }
): void {
  const now = admin.firestore.FieldValue.serverTimestamp();
  const debitRef = db.collection("ledger_entries").doc();
  const creditRef = db.collection("ledger_entries").doc();

  tx.set(debitRef, {
    transactionGroupId: params.groupId,
    accountType: params.debitAccount,
    userId: params.userId,
    entryType: "debit",
    category: params.category,
    amount: params.amount,
    balanceAfter: params.userBalanceAfter,
    description: params.description,
    createdAt: now,
  });

  tx.set(creditRef, {
    transactionGroupId: params.groupId,
    accountType: params.creditAccount,
    userId: params.userId,
    entryType: "credit",
    category: params.category,
    amount: params.amount,
    balanceAfter: params.userBalanceAfter,
    description: params.description,
    createdAt: now,
  });
}

export const initializeNewUserAccount = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Login required.");

  const referralCodeInput = (request.data?.referralCodeInput as string | undefined)
    ?.trim()
    .toUpperCase();

  const walletRef = db.collection("wallets").doc(uid);
  const walletSnap = await walletRef.get();
  if (!walletSnap.exists) {
    await walletRef.set({
      userId: uid,
      availableBalance: 0,
      pendingBalance: 0,
      investedCapital: 0,
      realizedProfit: 0,
      buybackProceeds: 0,
      totalWithdrawn: 0,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  if (referralCodeInput) {
    const userDoc = await db.collection("users").doc(uid).get();
    const userData = userDoc.data();
    if (!userData) return { ok: true };

    if (userData.referralCode === referralCodeInput) {
      throw new HttpsError("invalid-argument", "Self-referrals are not allowed.");
    }

    const existingRel = await db
      .collection("referral_relationships")
      .where("referredUserId", "==", uid)
      .limit(1)
      .get();

    if (existingRel.empty) {
      const referrerSnap = await db
        .collection("users")
        .where("referralCode", "==", referralCodeInput)
        .limit(1)
        .get();

      if (!referrerSnap.empty) {
        const referrerDoc = referrerSnap.docs[0];
        if (referrerDoc.id !== uid) {
          await db.collection("users").doc(uid).update({
            referredByUserId: referrerDoc.id,
          });
          await db.collection("referral_relationships").add({
            referrerId: referrerDoc.id,
            referrerName: referrerDoc.data().fullName || "Member",
            referredUserId: uid,
            referredUserName: userData.fullName || "New Member",
            referredUserEmail: userData.email || "",
            isEligibleActive: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      }
    }
  }

  return { ok: true };
});

export const approvePaymentRequest = onCall(async (request) => {
  const adminUid = await assertAdmin(request.auth?.uid);
  const paymentRequestId = request.data?.paymentRequestId as string;
  const adminNote = (request.data?.adminNote as string | undefined) || "";
  if (!paymentRequestId) {
    throw new HttpsError("invalid-argument", "paymentRequestId is required.");
  }

  await db.runTransaction(async (tx) => {
    const payRef = db.collection("payment_requests").doc(paymentRequestId);
    const paySnap = await tx.get(payRef);
    if (!paySnap.exists) {
      throw new HttpsError("not-found", "Payment request not found.");
    }
    const pay = paySnap.data()!;
    if (pay.status !== "pending") {
      throw new HttpsError("failed-precondition", "Payment already processed.");
    }

    const packRef = db.collection("packs").doc(pay.packId);
    const projectRef = db.collection("projects").doc(pay.projectId);
    const walletRef = db.collection("wallets").doc(pay.userId);

    const [packSnap, projectSnap, walletSnap] = await Promise.all([
      tx.get(packRef),
      tx.get(projectRef),
      tx.get(walletRef),
    ]);

    if (!packSnap.exists || !projectSnap.exists) {
      throw new HttpsError("not-found", "Pack or project not found.");
    }

    const pack = packSnap.data()!;
    const project = projectSnap.data()!;
    const qty = Number(pay.quantity);
    const unitsRequested = qty * Number(pack.unitsPerPack || 1);

    if (Number(pack.stockQuantity) < qty) {
      throw new HttpsError("failed-precondition", "Insufficient pack stock.");
    }
    if (Number(project.availableStockUnits) < unitsRequested) {
      throw new HttpsError("failed-precondition", "Insufficient project units.");
    }

    const totalProjectValue =
      Number(project.totalStockUnits) * Number(project.productCost || 1);
    const ownershipPercentage =
      totalProjectValue > 0
        ? (Number(pay.totalAmount) / totalProjectValue) * 100
        : 0;

    const currentWallet = walletSnap.exists ? walletSnap.data()! : {};
    const newInvestedCapital =
      Number(currentWallet.investedCapital || 0) + Number(pay.totalAmount);

    tx.update(packRef, {
      stockQuantity: Number(pack.stockQuantity) - qty,
    });
    tx.update(projectRef, {
      availableStockUnits: Number(project.availableStockUnits) - unitsRequested,
    });
    tx.update(payRef, {
      status: "approved",
      adminNote,
      reviewedBy: adminUid,
      reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const ownershipRef = db.collection("ownership_records").doc();
    tx.set(ownershipRef, {
      userId: pay.userId,
      projectId: pay.projectId,
      projectTitle: pay.projectTitle,
      productId: pay.productId,
      packId: pay.packId,
      packName: pay.packName,
      paymentRequestId,
      quantity: qty,
      remainingQuantity: qty,
      purchaseAmount: Number(pay.totalAmount),
      remainingCapital: Number(pay.totalAmount),
      realizedProfit: 0,
      ownershipPercentage,
      purchaseDate: admin.firestore.FieldValue.serverTimestamp(),
      currentStatus: "active",
    });

    tx.set(
      walletRef,
      {
        userId: pay.userId,
        investedCapital: newInvestedCapital,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    writeLedgerPair(tx, {
      groupId: `PAY_${paymentRequestId}`,
      userId: pay.userId,
      debitAccount: "platform_cash",
      creditAccount: "user_capital",
      category: "pack_purchase",
      amount: Number(pay.totalAmount),
      userBalanceAfter: Number(currentWallet.availableBalance || 0),
      description: `Approved pack purchase: ${pay.projectTitle} (${pay.packName} x${qty})`,
    });
  });

  const payDoc = await db.collection("payment_requests").doc(paymentRequestId).get();
  const userId = payDoc.data()?.userId as string | undefined;
  if (userId) {
    await createNotification(
      userId,
      "Payment Approved & Ownership Issued",
      `Your purchase of ${payDoc.data()?.packName} has been verified and recorded.`,
      "payment"
    );
  }
  await writeAuditLog(
    adminUid,
    "APPROVE_PAYMENT",
    "payment_requests",
    paymentRequestId,
    "Approved manual payment and created ownership record."
  );

  return { ok: true };
});

export const rejectPaymentRequest = onCall(async (request) => {
  const adminUid = await assertAdmin(request.auth?.uid);
  const paymentRequestId = request.data?.paymentRequestId as string;
  const reason = (request.data?.reason as string | undefined) || "Rejected by admin.";

  const ref = db.collection("payment_requests").doc(paymentRequestId);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError("not-found", "Payment not found.");
  if (snap.data()?.status !== "pending") {
    throw new HttpsError("failed-precondition", "Already processed.");
  }

  await ref.update({
    status: "rejected",
    adminNote: reason,
    reviewedBy: adminUid,
    reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await createNotification(
    snap.data()!.userId,
    "Payment Request Rejected",
    reason,
    "payment"
  );
  await writeAuditLog(
    adminUid,
    "REJECT_PAYMENT",
    "payment_requests",
    paymentRequestId,
    reason
  );
  return { ok: true };
});

export const recordProductSale = onCall(async (request) => {
  const adminUid = await assertAdmin(request.auth?.uid);
  const projectId = request.data?.projectId as string;
  const unitsSold = Number(request.data?.unitsSold || 0);
  const grossRevenue = Number(request.data?.grossRevenue || 0);
  const allocatedProductCost = Number(request.data?.allocatedProductCost || 0);
  const eligibleExpenses = Number(request.data?.eligibleExpenses || 0);
  const notes = (request.data?.notes as string | undefined) || "";

  if (!projectId || unitsSold <= 0 || grossRevenue < 0) {
    throw new HttpsError("invalid-argument", "Valid sale values required.");
  }

  const distributableProfit =
    grossRevenue - allocatedProductCost - eligibleExpenses;
  const platformCommission =
    distributableProfit > 0 ? distributableProfit * 0.1 : 0;
  const investorProfitPool = distributableProfit - platformCommission;

  const ownershipSnap = await db
    .collection("ownership_records")
    .where("projectId", "==", projectId)
    .where("currentStatus", "in", ["active", "partially_sold"])
    .get();

  const totalRemainingCapital = ownershipSnap.docs.reduce(
    (sum, d) => sum + Number(d.data().remainingCapital || 0),
    0
  );

  const saleRef = db.collection("sales").doc();

  await db.runTransaction(async (tx) => {
    const projectRef = db.collection("projects").doc(projectId);
    const projectSnap = await tx.get(projectRef);
    if (!projectSnap.exists) {
      throw new HttpsError("not-found", "Project not found.");
    }
    const project = projectSnap.data()!;

    // Read all affected wallets before writes
    const walletSnaps = new Map<string, FirebaseFirestore.DocumentSnapshot>();
    for (const oDoc of ownershipSnap.docs) {
      const uid = oDoc.data().userId as string;
      if (!walletSnaps.has(uid)) {
        walletSnaps.set(uid, await tx.get(db.collection("wallets").doc(uid)));
      }
    }

    let totalCapitalReturned = 0;

    if (totalRemainingCapital > 0) {
      const capitalReturnRatio = Math.min(
        1,
        allocatedProductCost / totalRemainingCapital
      );

      for (const oDoc of ownershipSnap.docs) {
        const o = oDoc.data();
        const oCap = Number(o.remainingCapital || 0);
        if (oCap <= 0) continue;

        const shareRatio = oCap / totalRemainingCapital;
        const capReturn = Number((oCap * capitalReturnRatio).toFixed(2));
        const profitShare = Number((investorProfitPool * shareRatio).toFixed(2));
        totalCapitalReturned += capReturn;

        const newCap = Math.max(0, Number((oCap - capReturn).toFixed(2)));
        const newStatus = newCap <= 0.01 ? "sold" : "partially_sold";

        tx.update(oDoc.ref, {
          remainingCapital: newCap,
          realizedProfit: Number(o.realizedProfit || 0) + profitShare,
          currentStatus: newStatus,
        });

        const wSnap = walletSnaps.get(o.userId);
        const w = wSnap?.exists ? wSnap.data()! : {};
        const nextAvail =
          Number(w.availableBalance || 0) + capReturn + profitShare;
        const nextInvested = Math.max(
          0,
          Number(w.investedCapital || 0) - capReturn
        );
        const nextProfit = Number(w.realizedProfit || 0) + profitShare;

        tx.set(
          db.collection("wallets").doc(o.userId),
          {
            availableBalance: nextAvail,
            investedCapital: nextInvested,
            realizedProfit: nextProfit,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );

        if (capReturn > 0) {
          writeLedgerPair(tx, {
            groupId: `SALE_CAP_${saleRef.id}_${oDoc.id}`,
            userId: o.userId,
            debitAccount: "user_capital",
            creditAccount: "user_available",
            category: "capital_return",
            amount: capReturn,
            userBalanceAfter: nextAvail,
            description: `Original capital returned from ${project.title} sale`,
          });
        }
        if (profitShare !== 0) {
          writeLedgerPair(tx, {
            groupId: `SALE_PROFIT_${saleRef.id}_${oDoc.id}`,
            userId: o.userId,
            debitAccount: "platform_sales_pool",
            creditAccount: "user_available",
            category: "profit_distribution",
            amount: profitShare,
            userBalanceAfter: nextAvail,
            description: `Realized profit share (after 10% platform fee) from ${project.title}`,
          });
        }
      }
    }

    tx.set(saleRef, {
      projectId,
      projectTitle: project.title,
      unitsSold,
      grossRevenue,
      allocatedProductCost,
      eligibleExpenses,
      distributableProfit,
      platformCommission,
      investorProfitPool,
      capitalReturned: totalCapitalReturned,
      notes,
      recordedBy: adminUid,
      saleDate: admin.firestore.FieldValue.serverTimestamp(),
    });

    tx.update(projectRef, {
      soldUnits: Number(project.soldUnits || 0) + unitsSold,
    });
  });

  await writeAuditLog(
    adminUid,
    "RECORD_SALE",
    "sales",
    saleRef.id,
    `Recorded sale of ${unitsSold} units; commission: ${platformCommission}`
  );

  return { ok: true, saleId: saleRef.id };
});

export const requestBuyback = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Login required.");
  const ownershipId = request.data?.ownershipId as string;

  const oSnap = await db.collection("ownership_records").doc(ownershipId).get();
  if (!oSnap.exists) throw new HttpsError("not-found", "Ownership not found.");
  const o = oSnap.data()!;
  if (o.userId !== uid) throw new HttpsError("permission-denied", "Not owner.");
  if (o.currentStatus !== "active" || Number(o.remainingCapital) <= 0) {
    throw new HttpsError("failed-precondition", "Not eligible for buyback.");
  }

  const userSnap = await db.collection("users").doc(uid).get();
  const basePrice = Number(o.remainingCapital);
  const deduction = Number((basePrice * 0.1).toFixed(2));
  const netPayout = Number((basePrice - deduction).toFixed(2));

  await db.runTransaction(async (tx) => {
    tx.update(oSnap.ref, { currentStatus: "buyback_requested" });
    tx.set(db.collection("buyback_requests").doc(), {
      userId: uid,
      userName: userSnap.data()?.fullName || "Member",
      ownershipId,
      projectId: o.projectId,
      projectTitle: o.projectTitle,
      packName: o.packName,
      originalAmount: basePrice,
      proposedBuybackPrice: basePrice,
      deductionAmount: deduction,
      netPayoutAmount: netPayout,
      status: "pending_admin",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  return { ok: true };
});

export const adminReviewBuyback = onCall(async (request) => {
  const adminUid = await assertAdmin(request.auth?.uid);
  const buybackId = request.data?.buybackId as string;
  const approveOffer = Boolean(request.data?.approveOffer);
  const confirmedPrice = Number(request.data?.confirmedBuybackPrice || 0);
  const adminNote = (request.data?.adminNote as string | undefined) || "";

  const bRef = db.collection("buyback_requests").doc(buybackId);
  const bSnap = await bRef.get();
  if (!bSnap.exists) throw new HttpsError("not-found", "Buyback not found.");
  const b = bSnap.data()!;

  if (!approveOffer) {
    await db.runTransaction(async (tx) => {
      tx.update(bRef, { status: "rejected", adminNote });
      tx.update(db.collection("ownership_records").doc(b.ownershipId), {
        currentStatus: "active",
      });
    });
    await createNotification(
      b.userId,
      "Buyback Request Declined",
      adminNote || "Buyback unavailable at this time.",
      "buyback"
    );
    return { ok: true };
  }

  const deduction = Number((confirmedPrice * 0.1).toFixed(2));
  const netPayout = Number((confirmedPrice - deduction).toFixed(2));

  await bRef.update({
    proposedBuybackPrice: confirmedPrice,
    deductionAmount: deduction,
    netPayoutAmount: netPayout,
    status: "awaiting_user_acceptance",
    adminNote,
  });

  await createNotification(
    b.userId,
    "Buyback Offer Ready",
    `Admin confirmed buyback payout of Rs. ${netPayout} (after 10% deduction). Accept or reject in My Ownership.`,
    "buyback"
  );
  await writeAuditLog(
    adminUid,
    "REVIEW_BUYBACK",
    "buyback_requests",
    buybackId,
    `Offered net payout Rs. ${netPayout}`
  );
  return { ok: true };
});

export const userRespondBuyback = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Login required.");
  const buybackId = request.data?.buybackId as string;
  const accept = Boolean(request.data?.accept);

  await db.runTransaction(async (tx) => {
    const bRef = db.collection("buyback_requests").doc(buybackId);
    const bSnap = await tx.get(bRef);
    if (!bSnap.exists) throw new HttpsError("not-found", "Buyback not found.");
    const b = bSnap.data()!;
    if (b.userId !== uid) throw new HttpsError("permission-denied", "Not owner.");
    if (b.status !== "awaiting_user_acceptance") {
      throw new HttpsError("failed-precondition", "Offer not awaiting acceptance.");
    }

    const oRef = db.collection("ownership_records").doc(b.ownershipId);
    if (!accept) {
      tx.update(bRef, { status: "cancelled_by_user" });
      tx.update(oRef, { currentStatus: "active" });
      return;
    }

    const walletRef = db.collection("wallets").doc(uid);
    const wSnap = await tx.get(walletRef);
    const w = wSnap.exists ? wSnap.data()! : {};
    const netPayout = Number(b.netPayoutAmount);
    const origCap = Number(b.originalAmount);
    const nextAvail = Number(w.availableBalance || 0) + netPayout;

    tx.update(bRef, { status: "completed" });
    tx.update(oRef, {
      currentStatus: "bought_back",
      remainingCapital: 0,
      remainingQuantity: 0,
    });
    tx.set(
      walletRef,
      {
        availableBalance: nextAvail,
        investedCapital: Math.max(0, Number(w.investedCapital || 0) - origCap),
        buybackProceeds: Number(w.buybackProceeds || 0) + netPayout,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    writeLedgerPair(tx, {
      groupId: `BUYBACK_${buybackId}`,
      userId: uid,
      debitAccount: "platform_buyback_reserve",
      creditAccount: "user_available",
      category: "buyback",
      amount: netPayout,
      userBalanceAfter: nextAvail,
      description: `Buyback completed for ${b.projectTitle} (${b.packName})`,
    });
  });

  return { ok: true };
});

export const requestWithdrawal = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Login required.");

  const amount = Number(request.data?.amount || 0);
  const method = request.data?.method as string;
  const accountTitle = request.data?.accountTitle as string;
  const accountNumber = request.data?.accountNumber as string;
  const bankName = (request.data?.bankName as string | undefined) || "";

  if (amount <= 0) throw new HttpsError("invalid-argument", "Invalid amount.");

  const userSnap = await db.collection("users").doc(uid).get();

  await db.runTransaction(async (tx) => {
    const walletRef = db.collection("wallets").doc(uid);
    const wSnap = await tx.get(walletRef);
    const w = wSnap.exists ? wSnap.data()! : {};
    const avail = Number(w.availableBalance || 0);
    if (avail < amount) {
      throw new HttpsError("failed-precondition", "Insufficient available balance.");
    }

    const nextAvail = avail - amount;
    const nextPending = Number(w.pendingBalance || 0) + amount;

    tx.update(walletRef, {
      availableBalance: nextAvail,
      pendingBalance: nextPending,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const wReqRef = db.collection("withdrawal_requests").doc();
    tx.set(wReqRef, {
      userId: uid,
      userName: userSnap.data()?.fullName || "Member",
      amount,
      method,
      accountTitle,
      accountNumber,
      bankName,
      status: "pending",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    writeLedgerPair(tx, {
      groupId: `WDR_HOLD_${wReqRef.id}`,
      userId: uid,
      debitAccount: "user_available",
      creditAccount: "user_pending",
      category: "withdrawal",
      amount,
      userBalanceAfter: nextAvail,
      description: `Withdrawal requested via ${method}`,
    });
  });

  return { ok: true };
});

export const processWithdrawal = onCall(async (request) => {
  const adminUid = await assertAdmin(request.auth?.uid);
  const withdrawalId = request.data?.withdrawalId as string;
  const approve = Boolean(request.data?.approve);
  const adminNote = (request.data?.adminNote as string | undefined) || "";

  let targetUserId = "";
  let amount = 0;

  await db.runTransaction(async (tx) => {
    const wReqRef = db.collection("withdrawal_requests").doc(withdrawalId);
    const wReqSnap = await tx.get(wReqRef);
    if (!wReqSnap.exists) throw new HttpsError("not-found", "Request not found.");
    const wReq = wReqSnap.data()!;
    if (wReq.status !== "pending") {
      throw new HttpsError("failed-precondition", "Already processed.");
    }
    targetUserId = wReq.userId;
    amount = Number(wReq.amount);

    const walletRef = db.collection("wallets").doc(targetUserId);
    const wSnap = await tx.get(walletRef);
    const w = wSnap.exists ? wSnap.data()! : {};
    const nextPending = Math.max(0, Number(w.pendingBalance || 0) - amount);

    if (approve) {
      tx.update(walletRef, {
        pendingBalance: nextPending,
        totalWithdrawn: Number(w.totalWithdrawn || 0) + amount,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      tx.update(wReqRef, {
        status: "approved",
        adminNote,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      writeLedgerPair(tx, {
        groupId: `WDR_SETTLE_${withdrawalId}`,
        userId: targetUserId,
        debitAccount: "user_pending",
        creditAccount: "platform_cash",
        category: "withdrawal",
        amount,
        userBalanceAfter: Number(w.availableBalance || 0),
        description: `Withdrawal approved & paid via ${wReq.method}`,
      });
    } else {
      const nextAvail = Number(w.availableBalance || 0) + amount;
      tx.update(walletRef, {
        pendingBalance: nextPending,
        availableBalance: nextAvail,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      tx.update(wReqRef, {
        status: "rejected",
        adminNote,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      writeLedgerPair(tx, {
        groupId: `WDR_REFUND_${withdrawalId}`,
        userId: targetUserId,
        debitAccount: "user_pending",
        creditAccount: "user_available",
        category: "withdrawal",
        amount,
        userBalanceAfter: nextAvail,
        description: `Withdrawal rejected & refunded: ${adminNote}`,
      });
    }
  });

  if (targetUserId) {
    await createNotification(
      targetUserId,
      approve ? "Withdrawal Paid" : "Withdrawal Rejected",
      approve
        ? `Your withdrawal of Rs. ${amount} has been approved.`
        : `Your withdrawal of Rs. ${amount} was rejected and refunded.`,
      "withdrawal"
    );
  }
  await writeAuditLog(
    adminUid,
    approve ? "APPROVE_WITHDRAWAL" : "REJECT_WITHDRAWAL",
    "withdrawal_requests",
    withdrawalId,
    `Amount Rs. ${amount}`
  );
  return { ok: true };
});

export const recalculateMonthlySubscription = onCall(async (request) => {
  const adminUid = await assertAdmin(request.auth?.uid);
  const monthKey = request.data?.monthKey as string;
  const breakdown = (request.data?.expenseBreakdown || {}) as Record<string, number>;
  const promoEnabled = Boolean(request.data?.promoEnabled);
  const promoAmount = Number(request.data?.promoAmount || 1);
  const promoStartIso = request.data?.promoStartIso as string | undefined;
  const promoEndIso = request.data?.promoEndIso as string | undefined;

  const totalMonthlyExpenses = Object.values(breakdown).reduce(
    (s, v) => s + Number(v || 0),
    0
  );

  const eligibleUsersSnap = await db
    .collection("users")
    .where("isEligibleMember", "==", true)
    .get();
  const eligibleCount = Math.max(1, eligibleUsersSnap.size);
  const sharePerMember = Number((totalMonthlyExpenses / eligibleCount).toFixed(2));

  const now = new Date();
  const promoStart = promoStartIso ? new Date(promoStartIso) : null;
  const promoEnd = promoEndIso ? new Date(promoEndIso) : null;
  const isPromoActive =
    promoEnabled &&
    promoStart !== null &&
    promoEnd !== null &&
    now >= promoStart &&
    now <= promoEnd;
  const effectiveDue = isPromoActive ? promoAmount : sharePerMember;

  await db.collection("subscriptions").doc(monthKey).set(
    {
      monthLabel: monthKey,
      totalMonthlyExpenses,
      expenseBreakdown: breakdown,
      eligibleActiveMembers: eligibleCount,
      calculatedSharePerMember: sharePerMember,
      promoEnabled,
      promoAmount,
      promoStartDate: promoStart
        ? admin.firestore.Timestamp.fromDate(promoStart)
        : null,
      promoEndDate: promoEnd
        ? admin.firestore.Timestamp.fromDate(promoEnd)
        : null,
      collectedTotal: 0,
      surplusOrShortfall: -totalMonthlyExpenses,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  const batch = db.batch();
  for (const userDoc of eligibleUsersSnap.docs) {
    const invRef = db
      .collection("subscription_invoices")
      .doc(`${monthKey}_${userDoc.id}`);
    batch.set(
      invRef,
      {
        userId: userDoc.id,
        monthKey,
        amountDue: effectiveDue,
        isPromoApplied: isPromoActive,
        status: "due",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  }
  await batch.commit();

  await writeAuditLog(
    adminUid,
    "RECALCULATE_SUBSCRIPTION",
    "subscriptions",
    monthKey,
    `Expenses: ${totalMonthlyExpenses}, Eligible: ${eligibleCount}, Share: ${sharePerMember}`
  );
  return { ok: true, sharePerMember, eligibleCount };
});

export const paySubscriptionInvoice = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Login required.");
  const invoiceId = request.data?.invoiceId as string;

  await db.runTransaction(async (tx) => {
    const invRef = db.collection("subscription_invoices").doc(invoiceId);
    const invSnap = await tx.get(invRef);
    if (!invSnap.exists) throw new HttpsError("not-found", "Invoice not found.");
    const inv = invSnap.data()!;
    if (inv.userId !== uid) throw new HttpsError("permission-denied", "Not owner.");
    if (inv.status !== "due") {
      throw new HttpsError("failed-precondition", "Invoice already settled.");
    }

    const amountDue = Number(inv.amountDue || 0);
    const walletRef = db.collection("wallets").doc(uid);
    const wSnap = await tx.get(walletRef);
    const w = wSnap.exists ? wSnap.data()! : {};
    const avail = Number(w.availableBalance || 0);
    if (avail < amountDue) {
      throw new HttpsError("failed-precondition", "Insufficient wallet balance.");
    }

    const nextAvail = Number((avail - amountDue).toFixed(2));
    const subRef = db.collection("subscriptions").doc(inv.monthKey);
    const subSnap = await tx.get(subRef);
    const sub = subSnap.exists ? subSnap.data()! : {};
    const nextCollected = Number(sub.collectedTotal || 0) + amountDue;
    const totalExp = Number(sub.totalMonthlyExpenses || 0);

    tx.update(walletRef, {
      availableBalance: nextAvail,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.update(invRef, {
      status: "paid",
      paidAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.update(db.collection("users").doc(uid), {
      subscriptionStatus: inv.isPromoApplied ? "promo_active" : "active",
    });
    tx.set(
      subRef,
      {
        collectedTotal: nextCollected,
        surplusOrShortfall: Number((nextCollected - totalExp).toFixed(2)),
      },
      { merge: true }
    );

    writeLedgerPair(tx, {
      groupId: `SUB_${invoiceId}`,
      userId: uid,
      debitAccount: "user_available",
      creditAccount: "platform_expense_pool",
      category: "subscription",
      amount: amountDue,
      userBalanceAfter: nextAvail,
      description: `Monthly shared operating expense payment (${inv.monthKey})`,
    });
  });

  return { ok: true };
});

export const updateMemberEligibility = onCall(async (request) => {
  const adminUid = await assertAdmin(request.auth?.uid);
  const targetUserId = request.data?.targetUserId as string;
  const isEligibleMember = Boolean(request.data?.isEligibleMember);

  await db.collection("users").doc(targetUserId).update({
    isEligibleMember,
  });

  const relSnap = await db
    .collection("referral_relationships")
    .where("referredUserId", "==", targetUserId)
    .get();
  for (const doc of relSnap.docs) {
    await doc.ref.update({ isEligibleActive: isEligibleMember });
  }

  await writeAuditLog(
    adminUid,
    "UPDATE_ELIGIBILITY",
    "users",
    targetUserId,
    `isEligibleMember=${isEligibleMember}`
  );
  return { ok: true };
});
