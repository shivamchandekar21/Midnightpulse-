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
exports.onBookingCreated = void 0;
const admin = __importStar(require("firebase-admin"));
const functions = __importStar(require("firebase-functions/v1"));
// -------------------------------------------------------------------
// onBookingCreated — Firestore Trigger
//
// Fires when a new booking document is written to /bookings/{bookingId}.
// Creates a notification in the user's subcollection and attempts to
// send an FCM push if the user has a stored fcmToken.
// -------------------------------------------------------------------
exports.onBookingCreated = functions.firestore
    .document("bookings/{bookingId}")
    .onCreate(async (snapshot, context) => {
    var _a, _b, _c, _d, _e;
    const booking = snapshot.data();
    const bookingId = context.params.bookingId;
    const userId = booking.userId;
    if (!userId) {
        functions.logger.warn(`Booking ${bookingId} has no userId — skipping notification.`);
        return;
    }
    const db = admin.firestore();
    const eventTitle = (_a = booking.eventTitle) !== null && _a !== void 0 ? _a : "event";
    const ticketCount = (_b = booking.ticketCount) !== null && _b !== void 0 ? _b : 1;
    // Write in-app notification
    await db
        .collection("users")
        .doc(userId)
        .collection("notifications")
        .add({
        title: "Booking Created",
        body: `Your booking for ${eventTitle} (${ticketCount} ticket${ticketCount > 1 ? "s" : ""}) is being processed.`,
        type: "booking_created",
        data: {
            bookingId,
            eventId: (_c = booking.eventId) !== null && _c !== void 0 ? _c : "",
        },
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    // Send FCM push notification if user has a token
    try {
        const userDoc = await db.collection("users").doc(userId).get();
        const fcmToken = (_d = userDoc.data()) === null || _d === void 0 ? void 0 : _d.fcmToken;
        if (fcmToken) {
            await admin.messaging().send({
                token: fcmToken,
                notification: {
                    title: "Booking in Progress 🎫",
                    body: `Your ${ticketCount} ticket${ticketCount > 1 ? "s" : ""} for ${eventTitle} — payment pending.`,
                },
                data: {
                    type: "booking_created",
                    bookingId,
                    eventId: (_e = booking.eventId) !== null && _e !== void 0 ? _e : "",
                },
                android: {
                    priority: "high",
                    notification: {
                        channelId: "bookings",
                        icon: "ic_notification",
                    },
                },
            });
        }
    }
    catch (err) {
        // FCM send is best-effort — don't fail the trigger
        functions.logger.error("FCM send failed for booking creation", err);
    }
});
//# sourceMappingURL=onBookingCreated.js.map