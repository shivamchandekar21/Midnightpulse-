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
exports.generateQrData = void 0;
const admin = __importStar(require("firebase-admin"));
const functions = __importStar(require("firebase-functions/v1"));
// -------------------------------------------------------------------
// generateQrData — Cloud Function (HTTPS Callable)
//
// Generates a signed QR payload for a given booking. This can be
// called when the user needs a fresh QR code (e.g., if the original
// was lost or for re-verification at the venue).
// -------------------------------------------------------------------
exports.generateQrData = functions.https.onCall(async (request) => {
    var _a, _b, _c, _d;
    if (!request.auth) {
        throw new functions.https.HttpsError("unauthenticated", "You must be signed in.");
    }
    const data = request.data;
    const bookingId = String((_a = data === null || data === void 0 ? void 0 : data.bookingId) !== null && _a !== void 0 ? _a : "");
    if (!bookingId) {
        throw new functions.https.HttpsError("invalid-argument", "bookingId is required");
    }
    // Ensure the caller owns this booking
    const db = admin.firestore();
    const bookingSnap = await db.collection("bookings").doc(bookingId).get();
    if (!bookingSnap.exists) {
        throw new functions.https.HttpsError("not-found", "Booking not found.");
    }
    const bookingData = bookingSnap.data();
    if (bookingData.userId !== request.auth.uid) {
        throw new functions.https.HttpsError("permission-denied", "You can only generate QR for your own bookings.");
    }
    const signedPayload = Buffer.from(JSON.stringify({
        bookingId,
        eventId: (_b = bookingData.eventId) !== null && _b !== void 0 ? _b : "",
        ticketCount: (_c = bookingData.ticketCount) !== null && _c !== void 0 ? _c : 1,
        status: (_d = bookingData.status) !== null && _d !== void 0 ? _d : "confirmed",
        issuedAt: Date.now(),
    })).toString("base64");
    const qrData = `MP-${signedPayload}`;
    // Persist the latest QR data on the booking
    await db.collection("bookings").doc(bookingId).update({ qrData });
    return { qrData };
});
//# sourceMappingURL=generateQrData.js.map