# Smart Campus Health and Safety Notification Application

A Flutter mobile application for reporting and managing health, safety, environmental, lost-and-found, and technical incidents on campus.

## Features

### User Features
- Create incident notifications
- List, filter, and search notifications
- View notifications on map
- View notification details
- Follow/unfollow notifications
- Receive notifications on status changes
- Manage profile and settings

### Admin Features
- View all user notifications
- Update notification statuses (Open → Under Review → Resolved)
- Edit notification descriptions
- Delete incorrect/inappropriate notifications
- Send emergency alerts to all users

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user_model.dart
│   └── notification_model.dart
├── providers/                # State management (Provider)
│   ├── auth_provider.dart
│   └── notification_provider.dart
├── services/                 # Business logic
│   ├── auth_service.dart
│   ├── notification_service.dart
│   └── router_service.dart
└── screens/                  # UI screens
    ├── splash_screen.dart
    ├── auth/
    │   ├── login_screen.dart
    │   ├── register_screen.dart
    │   └── forgot_password_screen.dart
    ├── home/
    │   └── home_screen.dart
    ├── notification/
    │   ├── notification_list_screen.dart
    │   ├── notification_detail_screen.dart
    │   └── create_notification_screen.dart
    ├── map/
    │   └── map_screen.dart
    └── profile/
        └── profile_screen.dart
```

## Setup

1. Make sure Flutter is installed on your system
2. Clone the repository
3. Run `flutter pub get` to install dependencies
4. Configure Firebase:
   - Add `google-services.json` (Android) to `android/app/`
   - Add `GoogleService-Info.plist` (iOS) to `ios/Runner/`
5. Run the app: `flutter run`

## Dependencies

- `firebase_core` - Firebase initialization
- `firebase_auth` - Authentication
- `cloud_firestore` - Database
- `firebase_storage` - File storage
- `firebase_messaging` - Push notifications
- `google_maps_flutter` - Maps
- `geolocator` - Location services
- `image_picker` - Image selection
- `provider` - State management

## Notes

- Firebase configuration is required for the app to work
- Google Maps API key needs to be configured
- Location permissions are required for map features


