# Project Overview (TL;DR)
FarmDashr is a Flutter-based marketplace application designed to connect local farmers directly with customers. It facilitates product browsing, inventory management, and order processing, leveraging Firebase for real-time data persistence and authentication.

---

# Repository Structure
The repository is organized into a clean, layered structure within the `lib/` directory:
- `lib/blocs/`: Feature-specific BLoCs (`auth`, `cart`, `order`, `product`, `vendor`) managing business logic and state.
- `lib/core/`:
  - `constants/`: Application-wide constants (`app_colors.dart`, `app_text_styles.dart`, `app_dimensions.dart`).
  - `services/`: Specialized infrastructure services (`AuthService`, `GoogleAuthService`, `CloudinaryService`).
- `lib/data/`:
  - `models/`: Serializable data classes (e.g., `Product`, `Order`) using `equatable`.
  - `repositories/`: Firestore interaction logic (e.g., `ProductRepository`, `VendorRepository`, `OrderRepository`).
- `lib/pages/`: UI screens categorized by user role (`customer/`, `farmer/`) and shared screens (`login_screen.dart`, `onboarding.dart`).
- `lib/presentation/`: Reusable UI widgets (e.g., `widgets/` directory).
- `lib/router.dart`: Centralized navigation configuration using `go_router`.

---

# Architecture
FarmDashr follows a layered architecture with a clear separation of concerns:
- **Presentation Layer**: Flutter widgets and pages that react to states emitted by BLoCs.
  - **Strict Styling**: All UI components MUST use `AppColors`, `AppTextStyles`, and `AppDimensions`. Hardcoded values are strictly forbidden.
- **Business Logic Layer**: BLoC pattern (`flutter_bloc`) is used to manage application state.
  - **Multi-Tenancy**: The app distinguishes between `Customer` and `Farmer` roles. Data is filtered by `farmerId` to ensure farmers only see their own inventory and orders.
  - **Authentication**: `AuthBloc` orchestrates complex flows including "Account Linking" (merging Google Sign-In with existing Email/Password accounts).
- **Data Layer**: Repositories abstract the data source (Firebase) and return domain models.
- **Service Layer**: Handles specialized external interactions (e.g., Firebase Authentication, Cloudinary Image Hosting).

---

# Data Flow
1. **Firebase -> Repository**: Firebase Firestore provides raw data via `get()` or `snapshots()`.
2. **Repository -> Model**: Repositories map raw JSON data into strongly-typed models.
   - **Provider Sync**: `UserRepository` actively syncs Firebase Auth providers (e.g., `google.com`) to Firestore to prevent login conflicts.
3. **Model -> BLoC**: BLoCs call repository methods and emit states (Loading, Loaded, Error).
4. **BLoC -> UI**: The UI uses `BlocBuilder` to update the view.
5. **Order Lifecycle**:
   - **Cart**: `CartBloc` manages local cart state.
   - **Checkout**: Splits the cart by `farmerId` and creates separate `Order` documents in Firestore with 'pending' status.
   - **Real-time**: `OrderBloc` streams updates to both Farmer (incoming orders) and Customer (order status).

---

# Firebase Usage
- **Firebase Auth**: 
  - Supports Email/Password and Google Sign-In.
  - **Account Linking**: Critical flow to merge credentials for the same email address.
- **Cloud Firestore**:
  - `products`: Publicly readable, writable by owners (`farmerId`).
  - `users`: Stores profiles. `providers` array tracks linked login methods.
  - `orders`: Immutable transaction records.
- **Real-time Synchronization**: Firestore `snapshots()` drive the Farmer Dashboard and Customer Order History.

---

# Coding Conventions & Patterns
- **State Management**: Strict adherence to BLoC.
- **Models**: Must extend `Equatable` and support `copyWith`.
- **UI Styling (CRITICAL)**: verify `AppColors` and `AppTextStyles` usage in PR reviews.
- **Navigation**: `go_router` manages all stacks. Profile switching (Customer <-> Farmer) is a navigation event, NOT a data mutation.
- **Asynchronous Code**: Use `context.mounted` checks before using Context across async gaps.

---

# Build & CI/CD
- **Development**: Managed via standard Flutter tooling.
- **CI/CD**: GitHub Actions workflows (`.github/workflows/main.yml`) automate:
  - Testing and linting.
  - Android APK/AAB building and signing.
  - iOS build preparation.

---

# Safe Extension Guidelines (CRITICAL)
- **Adding Features**: 
  1. Define the data model in `lib/data/models/`.
  2. Create a repository in `lib/data/repositories/` to handle data fetching.
  3. Implement a BLoC in `lib/blocs/` to manage the feature's state.
  4. Create UI pages in `lib/pages/` and register them in `lib/router.dart`.
- **Styling**: Do NOT use ad-hoc colors/styles. Add new constants to helpers if needed.
- **Integrity**: Ensure new features support the Multi-Tenant model (always handle `farmerId`).

---

# Known Pain Points & Warnings
- **Provider Synchronization**: Firebase Auth and Firestore can get out of sync. `UserRepository.syncProviders()` is the fix.
- **Platform Specifics**: Google Sign-In behaves differently on Web vs Mobile.
- **Data Completeness**: `Order` objects must containing snapshot data (Product Name, Price) at time of purchase to handle future price changes.

---

# Glossary
- **BLoC**: Business Logic Component.
- **Equatable**: A Flutter package used to simplify comparison between objects.
- **ShellRoute**: A route that displays a UI "shell" (like a navbar) around a sub-route.
- **SKU**: Stock Keeping Unit, used for inventory tracking.
- **Cloudinary**: External service used for hosting and transforming product/profile images.
