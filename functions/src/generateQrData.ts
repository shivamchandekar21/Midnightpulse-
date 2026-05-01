import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";

// -------------------------------------------------------------------
// generateQrData — Cloud Function (HTTPS Callable)
//
// Generates a signed QR payload for a given booking. This can be
// called when the user needs a fresh QR code (e.g., if the original
// was lost or for re-verification at the venue).
// -------------------------------------------------------------------

export const generateQrData = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "You must be signed in.",
    );
  }

  const data = request.data;
  const bookingId = String(data?.bookingId ?? "");

  if (!bookingId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "bookingId is required",
    );
  }

  // Ensure the caller owns this booking
  const db = admin.firestore();
  const bookingSnap = await db.collection("bookings").doc(bookingId).get();

  if (!bookingSnap.exists) {
    throw new functions.https.HttpsError("not-found", "Booking not found.");
  }

  const bookingData = bookingSnap.data()!;

  if (bookingData.userId !== request.auth.uid) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "You can only generate QR for your own bookings.",
    );
  }

  const signedPayload = Buffer.from(
    JSON.stringify({
      bookingId,
      eventId: bookingData.eventId ?? "",
      ticketCount: bookingData.ticketCount ?? 1,
      status: bookingData.status ?? "confirmed",
      issuedAt: Date.now(),
    }),
  ).toString("base64");

  const qrData = `MP-${signedPayload}`;

  // Persist the latest QR data on the booking
  await db.collection("bookings").doc(bookingId).update({ qrData });

  return { qrData };
});
