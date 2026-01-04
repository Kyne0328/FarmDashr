# PROJECT UPDATES

## 2026-01-02

### Enhanced Search and Filtering UI
- **Change**: Completely redesigned the browse page search and filtering experience with modern, beautiful UI.
- **Details**:
    - Added horizontal scrollable category filter chips with emoji icons (All, Fruits, Vegetables, Bakery, Dairy, Meat, Other).
    - Enhanced search bar with focus glow animation and rounded icon transitions.
    - Added active filters indicator bar showing current category and search terms with dismiss buttons.
    - Added "Clear" button in header when filters are active.
    - Improved empty state with circular icon container and contextual messages for different filter combinations.
    - Removed legacy duplicate code, centralized filter state in parent component.
- **Why**: Previous search was basic; category filtering from home page was disconnected from browse page UI.
- **Impact**: Premium, polished filtering experience matching modern app design standards.

### Category Filtering for Customer Browse
- **Change**: Customers can now filter products by category when tapping category buttons on the home page.
- **Details**:
    - Updated `customer_home_page.dart` to pass category as query parameter when navigating.
    - Modified `router.dart` to parse `?category=` query parameter and pass to `CustomerBrowsePage`.
    - Updated `_ProductsList` in `customer_browse_page.dart` to filter products by selected category.
    - Added dismissible category filter chip for visual feedback and easy filter removal.
- **Why**: Category buttons previously navigated to browse without applying any filter.
- **Impact**: Customers can quickly find products in specific categories (Fruits, Vegetables, Bakery, Dairy).

### Cart Persistence to Firestore
- **Change**: Implemented cart persistence using Firestore. Cart data now survives app restarts.
- **Details**:
    - Created `CartRepository` with `getCart()`, `saveCart()`, `clearCart()`, and `watchCart()` methods.
    - Added `toJson()` and `fromJson()` serialization to `CartItem` model.
    - Refactored `CartBloc` to persist all cart mutations (add, remove, update, clear) to Firestore.
    - Modified `main.dart` to listen for authentication changes and load user-specific cart on login.
    - Cart stored at `carts/{userId}` with product snapshots for offline/deleted product handling.
- **Why**: Previously, cart was stored only in-memory and lost on app restart.
- **Impact**: Customers retain their cart items across sessions, improving user experience and reducing abandoned carts.

### Consistency Audit: UI Styling & Model Fixes
- **Change**: Conducted a comprehensive audit of the codebase for convention violations. Fixed 10+ inline `TextStyle` declarations and corrected `UserStats.formattedRevenue` to use `₱` instead of `$`.
- **Details**:
    - Replaced inline `TextStyle` in: `customer_browse_page.dart`, `edit_profile_dialog.dart`, `signup_screen.dart`, `login_screen.dart`, `customer_home_page.dart`, `inventory_page.dart`.
    - Fixed `UserStats.formattedRevenue` in `user_profile.dart` to use Philippine Peso symbol.
- **Why**: Project conventions require all UI styling to use centralized tokens (`AppTextStyles`, `AppColors`, `AppDimensions`). Currency formatting must be consistent across the app.
- **Impact**: Improved code maintainability and consistency. All styling now flows from centralized constants.

### Search Functionality - Live Interaction
- **Change**: Connected the cosmetic search bar in `CustomerBrowsePage` to `ProductBloc` and `VendorBloc`. 
- **Details**:
    - Implemented debounced search (500ms) in `_SearchBar` widget.
    - Updated `ProductBloc` and `VendorBloc` to preserve `searchQuery` and re-apply filters when real-time data updates from Firestore.
    - Updated UI to display "No results" messages helpful for users search queries.
- **Why**: The search bar was purely cosmetic and didn't allow users to find specific items or producers.
- **Impact**: Customers can now search for products and vendors efficiently across both tabs with state preservation when switching.

### Vendor Storefront & Interaction
- **Change**: Made the vendor list in `CustomerBrowsePage` interactive. Implemented `VendorDetailsBottomSheet` (displaying vendor info, ratings, and stats) and `VendorProductsBottomSheet` (displaying vendor-specific product inventory).
- **Why**: To bridge the gap where customers could see vendors but couldn't interact with them or browse their specific storefronts.
- **Impact**: Customers can now explore individual farmer profiles and view their full product range in a streamlined, bottom-sheet driven experience.

### Technical Debt: Mock Data Removal
- **Change**: Removed hardcoded vendor ratings (`4.8`), review counts, distances (`2.5 mi`), and "Local" status badges from `CustomerBrowsePage`, `CustomerHomePage`, `ProductDetailPage`, and detailed bottom sheets.
- **Why**: To eliminate misleading mock information and prepare the UI for real reputation and location data from the `VendorBloc` and Firestore.
- **Impact**: UI now correctly reflects current data capabilities, avoiding user confusion from static "baked-in" scores.

## 2025-12-30

### Multi-Vendor Checkout Support
- **Change**: Refactored `CartBloc` to group cart items by `farmerId` during checkout and create separate `Order` documents for each vendor. Removed single-farmer assumption from `CheckoutCart` event.
- **Why**: Previous implementation incorrectly assigned mixed-vendor orders to a single farmer, causing data and payment attribution errors.
- **Impact**: Each farmer receives a discrete order containing only their products.

### Removal of All Service Fees & Tax
- **Change**: Removed the 8% Sales Tax and the ₱2.99 Service Fee from both `CartBloc` calculation logic and the UI (`CustomerCartPage`, `PreOrderCheckoutPage`).
- **Why**: Simplified business logic to provide a more transparent and attractive price to customers.
- **Impact**: Checkout total now exactly matches product subtotal.

### Checkout Optimization & Consistency
- **Change**: Refined `PreOrderCheckoutPage` to use `context.read<AuthBloc>().state` for checkout data. Restored the `AuthBloc` dependency.
- **Why**: To restore architectural consistency with the rest of the app's BLoC pattern while still solving the reactive UI sync bug.
- **Impact**: Maintainable, pattern-compliant code with a stable checkout flow.

### AppColors Expansion: Centralized Color Constants
- **Change**: Added 18 new color constants to `app_colors.dart`: gradient colors, farmer/customer theme colors, gray variants, status border colors, and container colors.
- **Why**: Inconsistency audit found 40+ hardcoded `Color(0x...)` values across pages violating the "always use AppColors" convention.
- **Impact**: Enables refactoring pages to use centralized constants instead of hardcoded colors.

### AppTextStyles Expansion: Centralized Text Styles
- **Change**: Added 25+ new text style constants to `app_text_styles.dart`: label styles (large/medium/small), tab labels, card styles (title/subtitle/caption), section headers, status text (error/success/warning), action text, price text, hint text, emoji text, and dialog title.
- **Why**: Inconsistency audit found 40+ inline `TextStyle()` declarations across pages violating the "always use AppTextStyles" convention.
- **Impact**: Enables refactoring pages to use centralized text styles instead of inline declarations.

### UI Styling Compliance: Page Refactoring
- **Change**: Refactored 8 pages to use `AppColors` and `AppTextStyles` instead of hardcoded values:
  - `customer_profile_page.dart` (13+ violations)
  - `farmer/profile_page.dart` (12+ violations)
  - `onboarding.dart` (5 violations)
  - `customer_orders_page.dart` (5 violations)
  - `customer_cart_page.dart` (5 violations)
  - `farmer/orders_page.dart` (6 violations)
  - `farmer_home_page.dart` (1 violation)
  - `pre_order_checkout_page.dart` (4 violations)
- **Reviewed as compliant**: `login_screen.dart`, `signup_screen.dart`, `customer_home_page.dart`, `customer_browse_page.dart`, `inventory_page.dart`
- **Why**: Inconsistency audit identified 80+ styling violations across the codebase.
- **Impact**: All pages now fully comply with the UI styling convention. 50+ violations fixed.

### Auth Screens: BLoC Pattern Compliance
- **Change**: Refactored `LoginScreen` and `SignUpScreen` to use `AuthBloc` events instead of direct service calls. Added `AuthLinkGoogleRequested` event and `AuthGoogleLinkRequired` state. Injected `UserRepository` into `AuthBloc`. Enhanced Google sign-in handler to check for existing accounts and emit link-required state.
- **Why**: Auth screens were bypassing the BLoC pattern by instantiating their own `AuthService`, `GoogleAuthService`, and `UserRepository`. This violated the project's architecture conventions.
- **Impact**: Auth flow is now consistent with the rest of the app. All authentication actions go through `AuthBloc`, improving testability and maintainability.

### Pickup Date/Time: Native Pickers
- **Change**: Updated `PreOrderCheckoutPage` to use `showDatePicker` and `showTimePicker` instead of plain text fields for pickup date/time selection. Added state tracking for selected values and created a reusable `_buildDatePickerField` widget.
- **Why**: Plain text fields for date/time are error-prone and don't provide  constraints. Native pickers enforce valid input and provide a better UX.
- **Impact**: Pickup dates now enforce a minimum 24-hour lead time and a 30-day maximum. Time selection uses the system's native time picker.

### Farmer Homepage: Live Data Integration
- **Change**: Updated `FarmerHomePage` to fetch and display live data from `OrderBloc` and `ProductBloc`. Added farmer-specific loading via `LoadFarmerOrders` event. Added loading/error state handling.
- **Why**: To replace mock data with real Firestore content.
- **Impact**: Farmer dashboard now shows real-time sales, order counts, unique customers, and revenue based on actual orders.

### OrderRepository: Farmer-Specific Queries
- **Change**: Added `getByFarmerId` and `watchByFarmerId` methods with client-side sorting to avoid composite index requirements.
- **Why**: To support farmer-specific order fetching without Firestore index configuration.
- **Impact**: Farmers can now view only orders related to their products.

### Google Account Linking: Provider Sync Fix
- **Change**: Updated `UserRepository` to record auth providers during profile creation and added `syncProviders()` method. Called `syncProviders()` after Google sign-in in `LoginScreen`.
- **Why**: Firestore's `providers` list was out of sync with Firebase Auth, causing repeated link prompts.
- **Impact**: Users with already-linked Google accounts are no longer prompted to link again.

---

## 2025-12-28
### Customer Home Page: Real Data Integration
- **Change**: 
  - Integrated `AuthBloc`, `ProductBloc`, and `VendorBloc` into `CustomerHomePage`.
  - Replaced hardcoded "Hello, Sarah!" with the current user's display name from `AuthBloc`.
  - Replaced mock vendor and product lists with real-time data from `VendorBloc` and `ProductBloc`.
  - Applied `AppColors`, `AppDimensions`, and `AppTextStyles` throughout the page.
  - Implemented dynamic image loading for products and vendors from Cloudinary URLs.
- **Why**: To bring the home page to life with real content and ensure design consistency across the application.
- **Impact**: Customers now see their actual name, real local producers, and available products upon landing on the app.

### Profile Switching: No-Toggle Refactor
- **Change**: 
  - Refactored profile switching between Customer and Farmer views in `CustomerProfilePage` and `Farmer/ProfilePage`.
  - Replaced Firestore-based `userType` toggling with client-side navigation (`context.go`).
  - Updated `UserRepository` to ensure `userType` remains `farmer` permanently once a farmer profile is created.
- **Why**: To prevent farmers from "disappearing" from the vendor list and marketplace when they browse as customers.
- **Impact**: Improved data consistency and reliable vendor discovery across the platform.

### Account Linking v2: Firestore-Based Provider Tracking
- **Change**: 
  - Added `checkEmailAndProviders(email)` to `UserRepository` - returns `{userId, hasGoogleProvider}` to check if email exists and if Google is already linked.
  - Added `addGoogleProvider(userId)` to `UserRepository` - stores `"google.com"` in a `providers` array field after linking.
  - Added `getGoogleCredential()` to `GoogleAuthService` - returns Google credential + email without signing in (mobile only).
  - Added `signInWithCredential(credential)` to `GoogleAuthService` - completes sign-in with an existing credential.
  - Added `linkProviderToAccount(credential)` to `AuthService` - links credential to current user using `user.linkWithCredential()`.
  - Updated `LoginScreen` and `SignUpScreen` with new flow: get credential → check Firestore → show link dialog only if email exists AND Google not yet linked.
- **Why**: Firebase with "Link accounts that use the same email" enabled was replacing the password provider instead of preserving both. The proactive Firestore check prevents this by: (1) not completing Google Sign-In until user authenticates with password, (2) properly linking providers, (3) tracking linked providers in Firestore.
- **Impact**: Users who sign up with email/password can now link their Google account without losing password access. After linking, subsequent Google sign-ins work seamlessly without prompting.

### Checkout & Order Creation Implementation
- **Change**: 
  - Updated `Order` model to include `customerId` for proper user-order linking.
  - Enhanced `CheckoutCart` event in `CartBloc` to accept `customerId` and `customerName`.
  - Injected `OrderRepository` into `CartBloc` via `main.dart`.
  - Implemented real checkout logic in `CartBloc._onCheckout` to calculate totals, create a Firestore-backed `Order` document, and clear the cart upon success.
  - Exposed `repository` getter in `OrderBloc` to allow access from dependency injection in `main.dart`.
- **Why**: To transition from mock checkout placeholders to a functional order processing system that persists transactions in Firestore.
- **Impact**: Customers can now place real orders that are stored in the database, linked to their profiles, and visible to farmers.

### Customer "Add to Cart" & Checkout Flow
- **Change**:
  - Connected `ProductDetailPage` to `CartBloc` to allow adding items to the cart.
  - Linked `CustomerCartPage` to `CartBloc` and `AuthBloc` to show real cart items and handle user-specific checkout.
  - Implemented cart management (increment, decrement, remove, clear) in the UI.
  - Updated `CartState` to use PHP (`₱`) currency formatting.
  - Added visual feedback (snackbars) for successful cart operations and checkout.
  - **Fix**: Corrected snackbar "View Cart" action to use `context.go` for reliable navigation into the shell route.
- **Why**: To provide a complete, functional shopping experience for customers.
- **Impact**: The app now supports the full lifecycle from product discovery to purchase, replacing all previous mock data/logic.

### Pre-Order Checkout Flow
- **Change**:
  - Implemented `PreOrderCheckoutPage` to collect pickup location, date, time, and instructions.
  - Updated `Order` model and Firestore schema to persist pre-order pickup details.
  - Refactored `CustomerOrdersPage` to use `OrderBloc` and show live user-specific orders.
  - Updated `FarmerOrdersPage` and `CustomerOrdersPage` cards to display pickup information.
- **Why**: To accommodate the business requirement of scheduled pickups (24h lead time).
- **Impact**: Customers can now provide specific delivery/pickup context, and farmers can see exactly when and where an order is expected.

### Vendor Layer & Multi-Tenancy Implementation
- **Change**:
  - Created `VendorRepository` and `VendorBloc` for real-time farmer profile management.
  - Updated `Order` model to include `farmerId` and `farmerName` for multi-tenancy support.
  - Updated `Product` model to include `farmerName` for easier UI display.
  - Replaced placeholders in `CustomerBrowsePage` Vendors tab with live data from `VendorBloc`.
  - Updated `CartBloc` checkout logic to capture vendor information from the items in the cart.
  - Registered `VendorBloc` in `main.dart`.
- **Why**: To replace hardcoded vendor mockups with real data and ensure orders are correctly attributed to specific farmers, enabling future vendor-specific order filtering.
- **Impact**: All core data loops (Users, Products, Orders, and now Vendors) are fully functional and connected to Firestore. Customers see real producers, and orders are correctly linked to vendors.

---

## 2025-12-27

### Profile Enhancement & Cloudinary Integration
- **Change**: Added `profilePictureUrl` to `UserProfile` model. Integrated `CloudinaryService` into `EditProfileDialog`. Enabled edit profile functionality in both Customer and Farmer profile pages. Updated `UserRepository` to sync Firestore profile data with Firebase Auth profile (displayName and photoURL). Fixed profile picture preview by using `MemoryImage` and `Uint8List` for cross-platform compatibility.
- **Why**: To allow users to personalize their accounts with photos and ensure a consistent administrative experience for farmers.
- **Impact**: Users can now upload profile pictures to Cloudinary; these pictures are persisted in Firestore and synced with Firebase Auth.

### Authentication UI Cleanup: Removed Facebook Placeholder
- **Change**: Removed the "Continue with Facebook" placeholder button from `LoginScreen` and `SignUpScreen`. Deleted the unused `assets/sign_up/assets/Facebook.svg` asset. Simplified the social login row to display only the functional Google login button.
- **Why**: The Facebook login was a non-functional placeholder. Removing it reduces UI clutter and avoids user confusion.
- **Impact**: Cleaner authentication screens with a focus on supported login methods (Email and Google). Improved repository hygiene by removing unused assets.

### Authentication UI Cleanup: Removed "Remember Me" Placeholder
- **Change**: Removed the "Remember me" checkbox and associated logic from `LoginScreen`. Repositioned the "Forgot password?" link to be right-aligned below the password field.
- **Why**: The "Remember me" feature was a non-functional UI placeholder. Removing it prevents user expectation of a feature that isn't implemented.
- **Impact**: More honest and streamlined login experience.

### Authentication Phase: Forgot Password Implementation
- **Change**: Added `resetPassword(String email)` to `AuthService`. Created `ForgotPasswordScreen` and registered it in `router.dart`. Updated `LoginScreen` to navigate to the new screen.
- **Why**: To provide users with a way to recover their accounts if they forget their passwords, completing the core authentication flow.
- **Impact**: Users can now request password reset emails directly from the app.

### Bug Fix: Authentication Overlap & Name Persistence
- **Change**: 
  - Updated `AuthService.updateDisplayName` to explicitly sync the user's name to the Firestore `users` collection.
  - Modified `SignUpScreen` and `LoginScreen` to trigger `UserRepository.getCurrentUserProfile()` immediately after successful authentication, ensuring Firestore profile initialization for new users.
  - Documented the requirement to enable "Allow creation of multiple accounts with the same email address" in Firebase Console to prevent Google Sign-In from overwriting Password accounts.
- **Why**: Users were losing password login access when using Google with the same email, and their full names weren't being persisted to Firestore during signup.
- **Impact**: Improved account reliability and consistent user profile data across the application.

### Authentication Phase: Account Linking (Option B)
- **Change**: 
  - Implemented `linkWithEmailPassword` in `GoogleAuthService` to merge Google credentials with existing Email/Password accounts.
  - Added `_showLinkAccountDialog` to both `LoginScreen` and `SignUpScreen` to handle `account-exists-with-different-credential` errors.
  - Enabled a seamless "Link Account" flow where users provide their password to unify their login methods under a single profile UID.
- **Why**: To prevent duplicate accounts for the same email address and ensure user data (orders, profile) is shared across all login methods.
- **Impact**: More professional authentication flow that preserves user data across different login providers.

### Product Detail View & Navigation Integration
- **Change**: Implemented `ProductDetailPage` and integrated it into both `CustomerBrowsePage` and `InventoryPage`. Replaced mock product data in browsing and inventory with real `Product` model state. Added `/product-detail` route to `router.dart`.
- **Why**: To provide users with detailed information about products they are interested in and allow farmers to inspect their own inventory entries in detail.
- **Impact**: Customers can now view full product info and click "Add to Cart". Farmers can view detailed stats and click "Edit" directly from the product view.

### Production Readiness: Logging Cleanup
- **Change**: Replaced `print()` occurrences with `debugPrint()` in `UserRepository`.
- **Why**: To prevent sensitive or unnecessary logging in release builds as per best practices.
- **Impact**: Cleaner production logs and improved security/privacy.

### Convention Compliance: Equatable for Data Models
- **Change**: Added `Equatable` extension to all data models: `Product`, `UserProfile`, `BusinessInfo`, `Certification`, `UserStats`, `Order`, `OrderItem`, and `CartItem`. Refactored `CartItem` to be fully immutable with `copyWith` pattern (removed mutable `quantity` field and void `increment()`/`decrement()` methods). Updated `CartBloc` to use immutable list replacement pattern.
- **Why**: To comply with PROJECT_CONTEXT.md convention requiring all models to extend `Equatable` for efficient BLoC rebuilding and testing. Immutable models also prevent accidental state mutations.
- **Impact**: All models now support value-based equality comparison. `CartBloc` uses proper immutable state management. This enables more predictable state handling and efficient widget rebuilds.

### Convention Compliance: UI Styling Constants
- **Change**: Refactored `login_screen.dart` and `customer_browse_page.dart` to use `AppColors`, `AppDimensions`, and `AppTextStyles` constants instead of hardcoded values. Added missing constants: `radiusXXL` (16), `buttonHeightLarge` (50), `spacingXXL` (32). Replaced all inline `TextStyle()` declarations with predefined `AppTextStyles` variants. Replaced hardcoded `Color(0xFF...)` values with `AppColors` constants.
- **Why**: To comply with PROJECT_CONTEXT.md convention: "Always use `AppColors`, `AppTextStyles`, and `AppDimensions` instead of hardcoded values."
- **Impact**: Improved consistency and maintainability. UI styling is now centralized in constants files, making theme changes easier and reducing potential for inconsistent styling.

### BLoC Integration: Customer Browse Products
- **Change**: Replaced `Product.sampleProducts` mock data in `customer_browse_page.dart` with real-time data from `ProductBloc` using `BlocBuilder<ProductBloc, ProductState>`. Added loading spinner, error state with message display, and empty state with friendly "No products available" message.
- **Why**: As noted in PROJECT_CONTEXT.md: "Mock Data: Some pages currently use `sampleProducts` or hardcoded lists; these should gradually be replaced with BLoC-driven data."
- **Impact**: Customer browse page now displays real products from Firestore. Vendor data remains as placeholder (TODO added) pending future `VendorBloc` implementation.

---

This file tracks meaningful changes to the FarmDashr repository, including new features, refactors, and architectural shifts.

## 2025-12-26
### Project Context Initialization
- **Change**: Created `/.ai/PROJECT_CONTEXT.md` and `/.ai/PROJECT_UPDATES.md`.
- **Why**: To provide a persistent, AI-oriented single source of truth for the codebase, architecture, and coding standards.
- **Impact**: Enables safer feature additions and better preservation of existing patterns by future AI interactions.

---

## 2025-12-26
### Farmer-Specific Product Association
- **Change**: Added `farmerId` to `Product` model and updated `ProductRepository`, `ProductBloc`, and UI components (`AddProductPage`, `InventoryPage`) to support association and filtering by farmer.
- **Why**: To ensure that products added by a farmer are private to their profile/inventory and not visible to other farmers.
- **Impact**: Multi-tenancy support for farmers; products are now correctly isolated and associated with their respective owners in Firestore.

---

## 2025-12-26
### Cloudinary Multiple Image Upload Integration
- **Change**: Integrated Cloudinary for product image hosting. Updated `Product` model to support `List<String> imageUrls`, created `CloudinaryService`, and added multi-image selection/preview to `AddProductPage`.
- **Why**: To allow farmers to upload and showcase multiple real-world photos of their products, enhancing the customer browsing experience.
- **Impact**: Products now support multiple high-quality images. The implementation is platform-agnostic (supporting both Web and Mobile) and includes backward compatibility for the legacy single `imageUrl` field.
---

## 2025-12-26
### Service Layer Unification
- **Change**: Unified `lib/services/` and `lib/core/services/` into a single `lib/core/services/` directory. Moved `AuthService` and `GoogleAuthService` and updated all relevant imports.
- **Why**: To improve project organization and consistency by housing all infrastructure-level services in a centralized location under `core`.
- **Impact**: Cleaner repository structure and improved maintainability. No functional changes to authentication or external integrations.

---