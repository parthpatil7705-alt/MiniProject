# RoomBuddy 🏠🤝

RoomBuddy is a comprehensive Flutter application designed to simplify the process of finding off-campus housing and compatible roommates for college students. It bridges the gap between students looking for accommodation, landlords offering properties, and administrators managing the platform.

## Features ✨

### For Students 🎓
*   **Property Browsing:** Search, filter, and view detailed listings of available rooms and apartments near the campus.
*   **Roommate Discovery:** Find compatible roommates based on lifestyle preferences (sleep schedule, cleanliness, budget, etc.) using a built-in matching algorithm.
*   **Enquiries:** Directly message landlords to inquire about properties.
*   **Reviews & Ratings:** Read and leave reviews for properties to help fellow students.
*   **Map View:** Visualize properties on a map to assess their proximity to the campus and other amenities.

### For Landlords 🏡
*   **Property Management:** Easily add, edit, and manage property listings, including uploading photos and specifying amenities.
*   **Enquiry Management:** Receive and respond to inquiries from interested students directly within the app.
*   **Dashboard:** Track the status of properties and manage communications efficiently.

### For Administrators 🛡️
*   **Verification:** Review and verify landlords and property listings to ensure a safe and trustworthy platform.
*   **User Management:** Manage student and landlord accounts.
*   **Content Moderation:** Oversee reviews and platform activity.

## Tech Stack 🛠️
*   **Frontend:** Flutter (Dart) - *Version 3.47+ recommended*
*   **State Management:** Riverpod (`flutter_riverpod`)
*   **Backend & Database:** Firebase (Firebase Auth, Cloud Firestore, Firebase Storage)
*   **Local Storage:** Hive (`hive_flutter`)
*   **Maps Integration:** Google Maps SDK

## Prerequisites 📋
Before you begin, ensure you have the following:
*   Flutter SDK (3.47+)
*   Dart SDK
*   A Firebase Project
*   A Google Maps API Key

## Setup Instructions 🚀

### 1. Clone the Repository
```bash
git clone https://github.com/your-username/room_buddy.git
cd room_buddy
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Firebase Setup 🔥
1.  Go to the [Firebase Console](https://console.firebase.google.com/).
2.  Create a new project.
3.  **Enable Authentication:** Set up Email/Password authentication.
4.  **Create Cloud Firestore Database:** Start in production mode.
5.  **Enable Firebase Storage:** Set up a default storage bucket.
6.  **Install FlutterFire CLI:**
    ```bash
    dart pub global activate flutterfire_cli
    ```
7.  **Configure Firebase:**
    ```bash
    flutterfire configure
    ```
    *(This will automatically generate the `firebase_options.dart` file in your `lib` directory.)*

### 4. Deploy Firestore Rules 🔒
Deploy the provided security rules to your Firestore database to ensure data privacy and access control.
```bash
firebase deploy --only firestore:rules
```

### 5. Google Maps Setup 🗺️
1.  Go to the [Google Cloud Console](https://console.cloud.google.com/).
2.  Create a project and enable the **Maps SDK for Android** and **Maps SDK for iOS**.
3.  Generate an API Key.
4.  **Android:** Add the API key to `android/app/src/main/AndroidManifest.xml`:
    ```xml
    <meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_API_KEY_HERE"/>
    ```
5.  **iOS:** Add the API key to `ios/Runner/AppDelegate.swift` (follow official Flutter Google Maps documentation).

### 6. Run the App 📱
```bash
flutter run
```

## Project Structure 📁
```
lib/
├── core/             # Core utilities, constants, theme, and API helpers
├── models/           # Data models (User, Property, Review, etc.)
├── providers/        # Riverpod providers for state management
├── screens/          # UI Screens grouped by user role
│   ├── admin/
│   ├── auth/
│   ├── landlord/
│   └── student/
├── services/         # Firebase and external API services
├── widgets/          # Shared, reusable UI components
└── main.dart         # App entry point and routing setup
```

## Data Model (Firestore) 🗄️
The application uses the following main collections in Cloud Firestore:
*   `users`: Stores user profiles (id, name, email, role, etc.).
*   `properties`: Stores property listings (id, landlordId, title, rent, location, amenities, images, etc.).
*   `reviews`: Stores property reviews (id, propertyId, studentId, rating, comment, etc.).
*   `enquiries`: Stores messages between students and landlords (id, propertyId, studentId, landlordId, message, status, etc.).
*   `roommate_preferences`: Stores student preferences for matchmaking.

## User Roles 👥
1.  **student**: Can browse properties, find roommates, and make inquiries.
2.  **landlord**: Can list properties and manage inquiries.
3.  **admin**: Manages users, verifies properties, and oversees platform operations.

### Creating an Admin User
To test admin features, you must manually assign the 'admin' role:
1.  Sign up a new user through the app (they will be a 'student' or 'landlord' by default).
2.  Go to the Firestore Database in your Firebase Console.
3.  Find the document for that user in the `users` collection.
4.  Change the `role` field from 'student'/'landlord' to `admin`.

## Testing 🧪
Run the widget and unit tests using:
```bash
flutter test
```

## Future Enhancements 🔮
*   In-app chat functionality (Realtime Database).
*   Payment gateway integration for rent or booking deposits.
*   Advanced filtering algorithms for roommate matching.
*   Push notifications for new inquiries and roommate matches.
*   Virtual tours for property listings.

## License 📄
This project is licensed under the MIT License.
