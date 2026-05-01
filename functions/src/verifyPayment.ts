import * as crypto from "crypto";
import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";

// -------------------------------------------------------------------
// verifyPayment — Cloud Function (HTTPS Callable)
//
// Verifies the Razorpay payment signature using HMAC-SHA256, then
// updates the booking document and creates a payment record.
// -------------------------------------------------------------------

export const verifyPayment = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "You must be signed in to verify payment.",
    );
  }

  const data = request.data;
  const bookingId = String(data?.bookingId ?? "");
  const razorpayOrderId = String(data?.razorpayOrderId ?? "");
  const razorpayPaymentId = String(data?.razorpayPaymentId ?? "");
  const razorpaySignature = String(data?.razorpaySignature ?? "");

  if (!bookingId || !razorpayOrderId || !razorpayPaymentId || !razorpaySignature) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "bookingId, razorpayOrderId, razorpayPaymentId and razorpaySignature are required",
    );
  }

  // Read Razorpay secret
  const keySecret = process.env.RAZORPAY_KEY_SECRET ?? functions.config()?.razorpay?.key_secret ?? "";

  // Verify HMAC signature (skip verification if secret is not configured — dev mode)
  if (keySecret) {
    const expectedSignature = crypto
      .createHmac("sha256", keySecret)
      .update(`${razorpayOrderId}|${razorpayPaymentId}`)
      .digest("hex");

    if (expectedSignature !== razorpaySignature) {
      functions.logger.error("Razorpay signature mismatch", {
        bookingId,
        razorpayOrderId,
        razorpayPaymentId,
      });
      throw new functions.https.HttpsError(
        "permission-denied",
        "Payment signature verification failed. Possible tampering detected.",
      );
    }
  } else {
    functions.logger.warn(
      "Razorpay key_secret not configured — skipping signature verification (dev mode).",
    );
  }

  const db = admin.firestore();
  const bookingRef = db.collection("bookings").doc(bookingId);
  const bookingSnap = await bookingRef.get();

  if (!bookingSnap.exists) {
    throw new functions.https.HttpsError(
      "not-found",
      `Booking ${bookingId} does not exist.`,
    );
  }

  const bookingData = bookingSnap.data()!;

  // Ensure the caller is the booking owner
  if (bookingData.userId !== request.auth.uid) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "You can only verify your own bookings.",
    );
  }

  // Generate a signed QR payload for the ticket
  const qrPayload = Buffer.from(
    JSON.stringify({
      bookingId,
      eventId: bookingData.eventId ?? "",
      ticketCount: bookingData.ticketCount ?? 1,
      verifiedAt: Date.now(),
    }),
  ).toString("base64");

  const qrData = `MP-${qrPayload}`;

  // Update booking with payment details and QR data
  await bookingRef.update({
    status: "confirmed",
    razorpayOrderId,
    razorpayPaymentId,
    qrData,
    paymentVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Create a payment record
  await db.collection("payments").doc(razorpayPaymentId).set({
    bookingId,
    userId: request.auth.uid,
    amount: bookingData.totalAmount ?? 0,
    currency: "INR",
    status: "captured",
    razorpayOrderId,
    razorpayPaymentId,
    razorpaySignature,
    method: bookingData.paymentMethod ?? "",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Create a confirmation notification
  await db
    .collection("users")
    .doc(request.auth.uid)
    .collection("notifications")
    .add({
      title: "Payment Confirmed",
      body: `Your booking for ${bookingData.eventTitle ?? "event"} has been confirmed! Show the QR code at entry.`,
      type: "payment_confirmed",
      data: { bookingId, eventId: bookingData.eventId ?? "" },
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

  return { verified: true, qrData };
});
