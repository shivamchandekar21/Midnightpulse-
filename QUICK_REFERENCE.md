# 🚀 Quick Reference: Midnight Pulse Screen Navigation

## All Screens at a Glance

### Main App Screens (Bottom Nav)
| Icon | Screen | File | Purpose |
|------|--------|------|---------|
| 🏠 | Home (Discover) | `home_screen.dart` | Browse & discover events |
| 🎫 | Bookings | `bookings_screen.dart` | View booked tickets |
| 👤 | Profile | `profile_screen.dart` | User settings & info |

---

### Drawer Navigation

#### **Navigate Section** (Main)
```
HomeScreen/BookingsScreen/ProfileScreen
```

#### **More Section** (New Additions)

```
SAVED LINEUP
├─ File: saved_events_screen.dart
├─ Navigation: Tap "Saved Lineup" in drawer
├─ Purpose: Manage events saved via double-click
├─ Features:
│  ├─ Display all saved events
│  ├─ Show event details (date, location, price)
│  ├─ Remove events from lineup
│  └─ Empty state handling
└─ Data Source: savedEventsProvider

PAYMENT METHODS ⭐ NEW
├─ File: payment_methods_screen.dart
├─ Navigation: Tap "Payment Methods" in drawer
├─ Purpose: Manage all payment operations
├─ 3 Tabs:
│  ├─ Saved Cards
│  │  ├─ View, edit, delete cards
│  │  ├─ Set default payment method
│  │  └─ Card type badges
│  ├─ Add New
│  │  ├─ Card form (number, expiry, CVV)
│  │  ├─ UPI form (UPI ID)
│  │  └─ Real-time validation
│  └─ History
│     ├─ Transaction list
│     ├─ Status indicators
│     └─ Filter by date/amount
└─ Data Source: Mock (Ready for Firestore)

MIDNIGHT PASS ⭐ NEW
├─ File: midnight_pass_screen.dart
├─ Navigation: Tap "Midnight Pass" in drawer
├─ Purpose: Premium membership management
├─ 4 Tabs:
│  ├─ Details
│  │  ├─ Premium benefits overview
│  │  └─ 5 benefit cards with icons
│  ├─ Subscribe
│  │  ├─ 3 pricing tiers
│  │  ├─ Feature lists per tier
│  │  └─ Subscribe CTAs
│  ├─ Status
│  │  ├─ Current membership status
│  │  ├─ Renewal info
│  │  └─ Upgrade CTA if inactive
│  └─ Perks
│     ├─ Active offers
│     ├─ Member-only events
│     └─ Limited time drops
└─ Pricing:
   ├─ Monthly: ₹499
   ├─ Quarterly: ₹1,299 (12% off)
   └─ Yearly: ₹4,799 (20% off)

HELP & SUPPORT
├─ File: help_support_screen.dart
├─ Navigation: Tap "Help & Support" in drawer
├─ Purpose: Customer support & FAQs
├─ Features:
│  ├─ FAQ section
│  ├─ Chat interface
│  └─ Ticket tracking
└─ Status: Already implemented
```

#### **Premium Access Section** (Updated)
```
PREMIUM ACCESS ⭐ UPDATED
├─ Location: Drawer bottom "Learn More" button
├─ File: premium_access_screen.dart
├─ Navigation: Tap "Learn More" button
├─ Purpose: Showcase premium value & convert
├─ 2 Tabs:
│  ├─ Features
│  │  ├─ Free vs Premium comparison table
│  │  ├─ 4 highlight cards
│  │  └─ Value proposition
│  └─ Pricing
│     ├─ 3 detailed plan cards
│     ├─ Billing information
│     └─ Legal disclaimers
└─ Target: Premium signup conversion
```

---

## 🔄 Screen-by-Screen Details

### **SavedEventsScreen**
**Path:** `lib/screens/saved_events_screen.dart` (already existed)
```dart
// How to navigate
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const SavedEventsScreen()),
);

// Watch saved events
final savedEventsAsync = ref.watch(savedEventsProvider);

// Data flow: Home → double-click → save → view in SavedEventsScreen
```

### **PaymentMethodsScreen** ⭐ NEW
**Path:** `lib/screens/payment_methods_screen.dart`
```dart
// Navigation
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()),
);

// Initial tab (optional)
const PaymentMethodsScreen(initialTab: 0) // 0=Cards, 1=Add, 2=History

// Features:
// - Add/Edit/Delete payment methods
// - View transaction history
// - Form validation
// - Empty states
```

### **MidnightPassScreen** ⭐ NEW
**Path:** `lib/screens/midnight_pass_screen.dart`
```dart
// Navigation
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const MidnightPassScreen()),
);

// Start at specific tab (optional)
const MidnightPassScreen(initialTab: 0) // 0=Details, 1=Subscribe, 2=Status, 3=Perks

// Features:
// - View membership benefits
// - Choose and subscribe to plans
// - Check membership status
// - View active perks & offers
// - Pricing: Monthly/Quarterly/Yearly
```

### **PremiumAccessScreen** ⭐ NEW
**Path:** `lib/screens/premium_access_screen.dart`
```dart
// Navigation
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const PremiumAccessScreen()),
);

// Start at specific tab (optional)
const PremiumAccessScreen(initialTab: 0) // 0=Features, 1=Pricing

// Features:
// - Compare Free vs Premium
// - View detailed pricing plans
// - Call-to-action for signup
// - Highlight premium benefits
```

---

## 🎫 Event to Lineup Flow

```dart
// In HomeScreen._addEventToLineup(Event event)
Future<void> _addEventToLineup(Event event) async {
  try {
    final userId = ref.read(currentUserIdProvider).value;
    
    if (userId == null) {
      _showSnackBar('Please log in to save events.');
      return;
    }

    final userService = UserFirestoreService();
    await userService.saveEvent(userId, event.id);
    
    // Refresh the saved events list
    ref.invalidate(savedEventsProvider);
    
    _showSnackBar('✅ Added to your lineup');
  } catch (error) {
    _showSnackBar('Failed to save event: ${_resolveError(error)}');
  }
}

// Result: Event appears in SavedEventsScreen
```

---

## 📁 Files Modified

### **Updated Files:**
1. `lib/widgets/app_drawer.dart`
   - Added imports for new screens
   - Updated navigation logic
   - Removed `_showPlaceholder` method
   - Added "Learn More" button navigation

### **Created Files:**
1. `lib/screens/midnight_pass_screen.dart` (900+ lines)
2. `lib/screens/premium_access_screen.dart` (700+ lines)
3. `lib/screens/payment_methods_screen.dart` (850+ lines)

### **Documentation Files:**
1. `IMPLEMENTATION_GUIDE.md` - Complete implementation details
2. `APP_ARCHITECTURE.md` - System architecture & data flows
3. `QUICK_REFERENCE.md` - This file

---

## 🎨 Color & Theme Constants Used

```dart
// Primary Colors
AppColors.accent        // ⭐ Primary action
AppColors.violet        // 💜 Premium/special
AppColors.surface       // Card backgrounds
AppColors.surfaceStrong // Darker surface
AppColors.surfaceAlt    // Alternative surface

// Text Colors
AppColors.textPrimary     // Main text
AppColors.textSecondary   // Subtitle/meta
AppColors.textMuted       // Disabled/hint
AppColors.textSecondary   // Secondary info

// Borders & Dividers
AppColors.border          // Divider lines
AppColors.background      // Page background

// Gradients
AppGradients.primary      // Hero sections
AppGradients.background   // Page bg
AppGradients.panel        // Card bg
```

---

## ✅ Checklist for Using These Screens

- [x] All screens created and properly imported
- [x] Drawer navigation updated with actual screen routes
- [x] Event saving from HomeScreen integrated
- [x] Empty states implemented for all screens
- [x] Form validation on payment methods
- [x] Responsive layouts
- [x] Consistent theme usage
- [x] Navigation without placeholders
- [x] Ready for backend integration

---

## 🔌 Integration Points (Ready for Implementation)

### **Payment Methods Screen**
- [ ] Connect to Firestore `payment_methods` collection
- [ ] Real card validation with payment gateway
- [ ] Transaction history from Firestore
- [ ] Update default payment method logic
- [ ] Delete card confirmation

### **Midnight Pass Screen**
- [ ] Fetch real membership status from user profile
- [ ] Connect to subscription service APIs
- [ ] Real pricing from Firestore config
- [ ] Handle subscription state management
- [ ] Integrate with payment processing

### **Premium Access Screen**
- [ ] Dynamic pricing from remote config
- [ ] A/B testing variants
- [ ] Analytics event tracking
- [ ] Redirect to payment gateway

---

## 🚀 Next Steps (Awaiting Payment Method Checkout)

**Current Status:** All screens implemented and navigation complete
**Next Phase:** Payment method checkout & subscription processing

The screens are fully functional and can be enhanced with:
1. Real Firestore data
2. Razorpay payment gateway
3. Subscription management
4. Analytics tracking
5. Error handling refinements

---

## 📞 Support

For questions about:
- **Navigation Flow** → See `APP_ARCHITECTURE.md`
- **Implementation Details** → See `IMPLEMENTATION_GUIDE.md`
- **Code Structure** → Check individual screen files
- **Theme/Colors** → Reference `lib/theme/app_theme.dart`

---

**Last Updated:** 2026-05-06
**Status:** ✅ Ready for Payment Processing Integration
