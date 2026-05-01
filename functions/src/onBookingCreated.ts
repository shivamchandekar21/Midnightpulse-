import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";

// -------------------------------------------------------------------
// onBookingCreated — Firestore Trigger
//
// Fires when a new booking document is written to /bookings/{bookingId}.
// Creates a notification in the user's subcollection and attempts to
// send an FCM push if the user has a stored fcmToken.
// -------------------------------------------------------------------

export const onBookingCreated = functions.firestore
  .document("bookings/{bookingId}")
  .onCreate(async (snapshot, context) => {
    const booking = snapshot.data();
    const bookingId = context.params.bookingId as string;
    const userId = booking.userId as string | undefined;

    if (!userId) {
      functions.logger.warn(`Booking ${bookingId} has no userId — skipping notification.`);
      return;
    }

    const db = admin.firestore();
    const eventTitle = booking.eventTitle ?? "event";
    const ticketCount = booking.ticketCount ?? 1;

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
          eventId: booking.eventId ?? "",
        },
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    // Send FCM push notification if user has a token
    try {
      const userDoc = await db.collection("users").doc(userId).get();
      const fcmToken = userDoc.data()?.fcmToken as string | undefined;

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
            eventId: booking.eventId ?? "",
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
    } catch (err) {
      // FCM send is best-effort — don't fail the trigger
      functions.logger.error("FCM send failed for booking creation", err);
    }
  });
