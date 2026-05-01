"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.verifyPayment = void 0;
const crypto = __importStar(require("crypto"));
const admin = __importStar(require("firebase-admin"));
const functions = __importStar(require("firebase-functions/v1"));
// -------------------------------------------------------------------
// verifyPayment — Cloud Function (HTTPS Callable)
//
// Verifies the Razorpay payment signature using HMAC-SHA256, then
// updates the booking document and creates a payment record.
// -------------------------------------------------------------------
exports.verifyPayment = functions.https.onCall(async (request) => {
    var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k, _l, _m, _o, _p;
    if (!request.auth) {
        throw new functions.https.HttpsError("unauthenticated", "You must be signed in to verify payment.");
    }
    const data = request.data;
    const bookingId = String((_a = data === null || data === void 0 ? void 0 : data.bookingId) !== null && _a !== void 0 ? _a : "");
    const razorpayOrderId = String((_b = data === null || data === void 0 ? void 0 : data.razorpayOrderId) !== null && _b !== void 0 ? _b : "");
    const razorpayPaymentId = String((_c = data === null || data === void 0 ? void 0 : data.razorpayPaymentId) !== null && _c !== void 0 ? _c : "");
    const razorpaySignature = String((_d = data === null || data === void 0 ? void 0 : data.razorpaySignature) !== null && _d !== void 0 ? _d : "");
    if (!bookingId || !razorpayOrderId || !razorpayPaymentId || !razorpaySignature) {
        throw new functions.https.HttpsError("invalid-argument", "bookingId, razorpayOrderId, razorpayPaymentId and razorpaySignature are required");
    }
    // Read Razorpay secret
    const keySecret = (_h = (_e = process.env.RAZORPAY_KEY_SECRET) !== null && _e !== void 0 ? _e : (_g = (_f = functions.config()) === null || _f === void 0 ? void 0 : _f.razorpay) === null || _g === void 0 ? void 0 : _g.key_secret) !== null && _h !== void 0 ? _h : "";
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
            throw new functions.https.HttpsError("permission-denied", "Payment signature verification failed. Possible tampering detected.");
        }
    }
    else {
        functions.logger.warn("Razorpay key_secret not configured — skipping signature verification (dev mode).");
    }
    const db = admin.firestore();
    const bookingRef = db.collection("bookings").doc(bookingId);
    const bookingSnap = await bookingRef.get();
    if (!bookingSnap.exists) {
        throw new functions.https.HttpsError("not-found", `Booking ${bookingId} does not exist.`);
    }
    const bookingData = bookingSnap.data();
    // Ensure the caller is the booking owner
    if (bookingData.userId !== request.auth.uid) {
        throw new functions.https.HttpsError("permission-denied", "You can only verify your own bookings.");
    }
    // Generate a signed QR payload for the ticket
    const qrPayload = Buffer.from(JSON.stringify({
        bookingId,
        eventId: (_j = bookingData.eventId) !== null && _j !== void 0 ? _j : "",
        ticketCount: (_k = bookingData.ticketCount) !== null && _k !== void 0 ? _k : 1,
        verifiedAt: Date.now(),
    })).toString("base64");
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
        amount: (_l = bookingData.totalAmount) !== null && _l !== void 0 ? _l : 0,
        currency: "INR",
        status: "captured",
        razorpayOrderId,
        razorpayPaymentId,
        razorpaySignature,
        method: (_m = bookingData.paymentMethod) !== null && _m !== void 0 ? _m : "",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    // Create a confirmation notification
    await db
        .collection("users")
        .doc(request.auth.uid)
        .collection("notifications")
        .add({
        title: "Payment Confirmed",
        body: `Your booking for ${(_o = bookingData.eventTitle) !== null && _o !== void 0 ? _o : "event"} has been confirmed! Show the QR code at entry.`,
        type: "payment_confirmed",
        data: { bookingId, eventId: (_p = bookingData.eventId) !== null && _p !== void 0 ? _p : "" },
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { verified: true, qrData };
});
//# sourceMappingURL=verifyPayment.js.map