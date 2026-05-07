# midnight_pulse

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


# 🎵 Midnight Pulse — Production-Ready Launch Plan
**Target: 4-Week Sprint → Google Play Store**  
**Stack: Flutter + Firebase (Firestore, Auth, Cloud Functions, FCM, Analytics, Crashlytics)**  
**Payment: Razorpay (India-focused: UPI, Card, NetBanking)**

---

## Current State Assessment

| Layer | Status | Gap |
|---|---|---|
| Auth (Firebase) | ✅ Working | No auth-gate on app start |
| Events (Firestore) | ✅ Working | Pagination, filters done |
| Booking model | ⚠️ Mock data only | No Firestore persistence |
| Payment screen | ⚠️ UI only | No Razorpay SDK integration |
| User profile | ⚠️ Hardcoded "John Doe" | No real Firestore reads |
| Booking confirmation | ⚠️ No booking saved | Ticket ID is fake |
| Notifications | ⚠️ Empty screen | No FCM setup |
| Saved events | ⚠️ Stub screen | No user-specific saves |
| Reviews & ratings | ❌ Missing | Not implemented |
| QR ticket | ❌ Missing | Not implemented |
| Admin panel | ❌ Missing | Not implemented |
| Security rules | ❌ Missing | Open Firestore |
| Analytics | ❌ Missing | No event tracking |
| Crashlytics | ❌ Missing | No crash reporting |

---

## Week 1 — Backend Foundation + Core Data Models
**Goal:** Real data flowing end-to-end. Profile reads live user. Bookings written to Firestore.

### Day 1 — Dependencies + Models
- [ ] Add to `pubspec.yaml`:
  - `razorpay_flutter: ^1.3.5`
  - `firebase_messaging: ^15.x`
  - `firebase_analytics: ^11.x`
  - `firebase_crashlytics: ^4.x`
  - `qr_flutter: ^4.x`
  - `uuid: ^4.x`
  - `intl: ^0.19.x`
  - `cached_network_image: ^3.x`
- [ ] Create `lib/data/models/app_user.dart` (name, email, phone, photoUrl, savedEventIds, fcmToken, createdAt, membershipTier)
- [ ] Create `lib/data/models/booking.dart` (proper model: id, userId, eventId, eventTitle, eventDate, eventLocation, imageUrl, ticketCount, subtotal, serviceFee, processingFee, totalAmount, status, paymentMethod, razorpayOrderId, razorpayPaymentId, qrData, bookingDate, cancelledAt)
- [ ] Create `lib/data/models/payment.dart` (id, bookingId, userId, amount, currency, status, razorpayOrderId, razorpayPaymentId, razorpaySignature, method, createdAt)
- [ ] Create `lib/data/models/review.dart` (id, userId, userName, eventId, rating, comment, createdAt)
- [ ] Update `lib/data/models/event.dart` — add `totalSeats`, `bookedSeats`, `averageRating`, `reviewCount`

### Day 2-3 — Services
- [ ] Create `lib/data/services/user_firestore_service.dart`
  - `getUser(uid)`, `createUser(user)`, `updateUser(uid, fields)`, `watchUser(uid)` stream
  - `saveEvent(uid, eventId)`, `unsaveEvent(uid, eventId)`, `getSavedEvents(uid)`
  - `updateFcmToken(uid, token)`
- [ ] Create `lib/data/services/booking_firestore_service.dart`
  - `createBooking(booking)` — Firestore transaction (lock seats → write booking)
  - `getUserBookings(uid)` stream
  - `getBookingById(id)`
  - `updateBookingStatus(id, status)`
  - `cancelBooking(id)` — restore seat count
- [ ] Create `lib/data/services/review_firestore_service.dart`
  - `addReview(review)`, `getEventReviews(eventId)`, `getUserReview(userId, eventId)`
- [ ] Update `lib/auth/auth_service.dart` — create AppUser doc on signup with full fields

### Day 4 — Providers + State
- [ ] Create `lib/providers/auth_providers.dart`
  - `authStateProvider` (StreamProvider of `User?`)
  - `currentUserIdProvider`
- [ ] Create `lib/providers/user_providers.dart`
  - `appUserProvider` (StreamProvider of `AppUser?` from Firestore)
  - `savedEventsProvider`
- [ ] Create `lib/providers/booking_providers.dart`
  - `userBookingsProvider` (StreamProvider)
  - `upcomingBookingsProvider` (derived)
  - `pastBookingsProvider` (derived)
  - `createBookingProvider` (StateNotifier)
- [ ] Create `lib/providers/review_providers.dart`
  - `eventReviewsProvider(eventId)`
  - `submitReviewProvider`

### Day 5 — Auth Gate + Navigation
- [ ] Create `lib/screens/auth_gate.dart` — StreamBuilder on `authStateProvider`, redirect logic
- [ ] Update `lib/main.dart` — start with `AuthGate` instead of `SplashScreen`
- [ ] Fix `lib/screens/profile_screen.dart` — wire to `appUserProvider`
- [ ] Fix `lib/screens/bookings_screen.dart` — wire to `userBookingsProvider`
- [ ] Fix `lib/screens/saved_events_screen.dart` — wire to `savedEventsProvider`

---

## Week 2 — Razorpay Payment + Complete Booking Flow
**Goal:** End-to-end payment. Booking saved. QR ticket generated. Confirmation shows real data.

### Day 6-8 — Razorpay Integration
- [ ] Create `lib/services/razorpay_service.dart`
  - Initialize Razorpay with key
  - `createOrder(amount, currency, receipt)` → calls Cloud Function
  - Handlers: `_handlePaymentSuccess`, `_handlePaymentError`, `_handleExternalWallet`
  - Verify signature server-side via Cloud Function
- [ ] Update `lib/screens/payment_screen.dart`
  - Remove mock UI for Crypto (India-only: UPI, Card, NetBanking, Wallet)
  - Integrate `RazorpayService` — call `openCheckout()` on tap
  - Loading state while payment processes
  - Error state with retry button
- [ ] Update `lib/screens/checkout_screen.dart`
  - Show live seat availability (bookedSeats / totalSeats)
  - Disable "Proceed" if event is sold out
  - Coupon code field (optional, Week 3)

### Day 9-10 — Cloud Functions (TypeScript)
- [ ] Set up `functions/` folder: `firebase init functions`
- [ ] `functions/src/createRazorpayOrder.ts` — create Razorpay order, return orderId + amount
- [ ] `functions/src/verifyPayment.ts` — verify HMAC signature, update booking + payment docs
- [ ] `functions/src/onBookingCreated.ts` — Firestore trigger → send FCM confirmation notification
- [ ] `functions/src/generateQrData.ts` — generate signed QR payload for ticket
- [ ] Deploy functions to Firebase

### Day 11-12 — Confirmation + QR Ticket
- [ ] Update `lib/screens/booking_confirmation_screen.dart`
  - Receive full `Booking` object (not just event + count)
  - Show real booking ID, payment method, total paid
  - Display QR code widget (`qr_flutter`) with booking ID as data
  - "Download Ticket" button (share as image)
- [ ] Create `lib/screens/qr_ticket_screen.dart`
  - Full-screen QR ticket view
  - Event name, date, location, seat info, booking ID
  - Scannable QR code (large, high error correction)

---

## Week 3 — Notifications, Reviews, Analytics + Admin Panel
**Goal:** Push notifications live. Reviews visible on event page. Firebase Analytics tracking. Basic admin.

### Day 13-14 — FCM Notifications
- [ ] Create `lib/services/fcm_service.dart`
  - `initialize()` — request permissions, get token, save to Firestore
  - `setupForegroundHandler()` — in-app notification banner
  - `setupBackgroundHandler()` — handle tap → navigate to booking
- [ ] Update `lib/main.dart` — call `FcmService.initialize()` after Firebase.initializeApp
- [ ] Update `lib/screens/notifications_screen.dart` — fetch notifications from Firestore `users/{uid}/notifications` subcollection
- [ ] Cloud Function `sendEventReminder.ts` — 24h before event, send FCM to all booked users

### Day 15-17 — Reviews + Ratings
- [ ] Update `lib/data/models/event.dart` — `averageRating`, `reviewCount` fields
- [ ] Update home_screen.dart event card — show star rating badge
- [ ] Add `ReviewsSection` widget to event detail view
  - Stream of reviews from Firestore
  - Rating breakdown (5★ to 1★ bars)
- [ ] Create `lib/widgets/review_form_dialog.dart`
  - Star rating selector + comment field
  - Only shown for completed bookings
- [ ] Update `lib/screens/bookings_screen.dart` (Past Events tab)
  - "Rate & Review" button for completed events
  - Show review if already submitted
- [ ] Cloud Function `onReviewCreated.ts` — update event's `averageRating` + `reviewCount`

### Day 18 — Analytics + Crashlytics
- [ ] Update `lib/main.dart` — initialize Crashlytics (`FlutterError.onError`)
- [ ] Create `lib/services/analytics_service.dart`
  - `logEventViewed(eventId, title)`
  - `logBookingStarted(eventId)`
  - `logPaymentSuccess(amount, method)`
  - `logPaymentFailed(reason)`
  - `logReviewSubmitted(eventId, rating)`
  - `logSearchQuery(query)`
- [ ] Wire analytics calls in: `home_screen.dart`, `checkout_screen.dart`, `payment_screen.dart`

### Day 19-21 — Admin Panel (Flutter Web or Simple Firebase Hosting)
- [ ] Create `lib/screens/admin/` directory (accessed only by admin users)
- [ ] Admin role: Add `isAdmin: true` field to user doc + Firestore security rule
- [ ] `lib/screens/admin/admin_dashboard.dart` — stats: total bookings, revenue, upcoming events
- [ ] `lib/screens/admin/manage_events_screen.dart` — CRUD events (uses existing `eventsControllerProvider`)
- [ ] `lib/screens/admin/manage_bookings_screen.dart` — view/cancel bookings
- [ ] `lib/screens/admin/send_notification_screen.dart` — send push to all users or per-event attendees
- [ ] Add admin navigation in `AppDrawer` (only if `isAdmin == true`)

---

## Week 4 — Security, Polish + Play Store Submission
**Goal:** Secure, tested, beautiful app ready for production.

### Day 22 — Firestore Security Rules
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own doc
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    // Bookings: user can read their own, create new, no update/delete
    match /bookings/{bookingId} {
      allow read: if request.auth != null && request.auth.uid == resource.data.userId;
      allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
      allow update: if false; // Only Cloud Functions update bookings
    }
    // Events: public read, only admins write
    match /events/{eventId} {
      allow read: if true;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
    // Reviews: public read, auth users create once per event
    match /reviews/{reviewId} {
      allow read: if true;
      allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
      allow update, delete: if false;
    }
    // Payments: user can read their own, Cloud Functions write
    match /payments/{paymentId} {
      allow read: if request.auth != null && request.auth.uid == resource.data.userId;
      allow write: if false;
    }
  }
}
```

### Day 23-24 — UI Polish + Animations
- [ ] Add `shimmer` package for loading skeletons on bookings/events list
- [ ] Add `lottie` package for:
  - Payment success animation (confetti/checkmark)
  - Empty state animations (bookings, saved events)
  - Loading animation on splash screen
- [ ] Smooth page transitions (custom `PageRouteBuilder` with fade+slide)
- [ ] Hero animation on event card → event detail
- [ ] Animate ticket count changes in checkout
- [ ] Animated tab indicator in bookings screen

### Day 25-26 — Testing
- [ ] Unit tests: `AuthService`, `BookingFirestoreService`, `RazorpayService`
- [ ] Widget tests: `CheckoutScreen`, `PaymentScreen`, `BookingConfirmationScreen`
- [ ] Integration test: full booking flow (event → checkout → mock payment → confirmation)
- [ ] Test on physical device (Android): payment, QR display, notifications

### Day 27 — App Signing + Release Config
- [ ] Generate Android keystore:
  ```
  keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
  ```
- [ ] Configure `android/key.properties` + `android/app/build.gradle` for release signing
- [ ] Update `android/app/src/main/AndroidManifest.xml`:
  - App name, permissions (INTERNET, VIBRATE, RECEIVE_BOOT_COMPLETED)
  - Deep link scheme for Razorpay callback
- [ ] Update `pubspec.yaml`: version to `1.0.0+1`, app description
- [ ] Build release APK: `flutter build apk --release`
- [ ] Build App Bundle: `flutter build appbundle --release`

### Day 28 — Play Store Submission
- [ ] Create Play Store listing:
  - App name: "Midnight Pulse - Concert Tickets"
  - Short description (80 chars), full description
  - Screenshots (phone + 7-inch tablet)
  - Feature graphic (1024×500)
  - Content rating questionnaire
  - Privacy Policy URL (required for Firebase Auth apps)
- [ ] Submit for review (usually 1-3 days)

---

## Firestore Collections Schema

```
users/
  {uid}/
    name, email, phone, photoUrl
    savedEventIds: string[]
    fcmToken: string
    isAdmin: bool
    membershipTier: 'free' | 'midnight_pass'
    createdAt: timestamp
    notifications/  (subcollection)
      {notifId}/ title, body, type, data, isRead, createdAt

events/
  {eventId}/
    title, description, location, tag
    startDate, endDate: timestamp
    price: number (in paise for Razorpay)
    imageUrl, isPremium, isActive
    totalSeats, bookedSeats
    averageRating, reviewCount
    createdAt, updatedAt

bookings/
  {bookingId}/
    userId, eventId, eventTitle, eventDate, eventLocation, imageUrl
    ticketCount, subtotal, serviceFee, processingFee, totalAmount
    status: 'pending' | 'confirmed' | 'completed' | 'cancelled'
    paymentMethod, razorpayOrderId, razorpayPaymentId
    qrData (signed string)
    bookingDate: timestamp

payments/
  {paymentId}/
    bookingId, userId
    amount (paise), currency: 'INR'
    status: 'created' | 'authorized' | 'captured' | 'failed' | 'refunded'
    razorpayOrderId, razorpayPaymentId, razorpaySignature
    method: 'upi' | 'card' | 'netbanking' | 'wallet'
    createdAt: timestamp

reviews/
  {reviewId}/
    userId, userName, eventId
    rating: 1-5
    comment: string
    createdAt: timestamp
```

---

## Key Dependencies to Add

```yaml
dependencies:
  # Payment
  razorpay_flutter: ^1.3.5
  
  # Firebase
  firebase_messaging: ^15.2.4
  firebase_analytics: ^11.4.0
  firebase_crashlytics: ^4.2.0
  
  # UI
  qr_flutter: ^4.1.0
  cached_network_image: ^3.4.1
  shimmer: ^3.0.0
  lottie: ^3.1.2
  
  # Utilities  
  uuid: ^4.5.1
  intl: ^0.19.0
  share_plus: ^10.1.4
  path_provider: ^2.1.5
```

---

## Implementation Order (Starting Now)

### ✅ PHASE 1 (Do Now — Week 1)
1. **Add all dependencies** to `pubspec.yaml`
2. **Create `AppUser` model** → replace hardcoded "John Doe"
3. **Create `Booking` model** → replace mock `Booking` class in `event.dart`
4. **Create `user_firestore_service.dart`**
5. **Create `booking_firestore_service.dart`**
6. **Update `auth_service.dart`** → create full user doc on signup
7. **Create auth providers** → `authStateProvider`, `appUserProvider`
8. **Create `auth_gate.dart`** → redirect based on auth state
9. **Wire `profile_screen.dart`** → real user data
10. **Wire `bookings_screen.dart`** → real Firestore bookings

### 🔜 PHASE 2 (Week 2)
11. Razorpay SDK integration
12. Cloud Functions setup
13. Real booking write on payment success
14. QR ticket screen

### 🔜 PHASE 3 (Week 3)
15. FCM push notifications
16. Reviews & ratings
17. Firebase Analytics + Crashlytics
18. Admin panel

### 🔜 PHASE 4 (Week 4)
19. Security rules
20. UI animations (Lottie)
21. Testing
22. Play Store submission

---

> [!IMPORTANT]
> **Starting implementation now with Phase 1** — all 10 items above will be implemented in this session.
