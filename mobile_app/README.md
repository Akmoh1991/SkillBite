This is the Flutter client scaffold for the new Django mobile API under `/api/mobile/v1/`.

Current scope:
- Token login against the Django mobile API
- Role-aware home flow for `employee` and `business_owner`
- Basic dashboards and lists wired to live API endpoints

To continue locally:
1. Install Flutter.
2. From this folder run `flutter create .` if you want generated platform folders.
3. Run `flutter pub get`.
4. Update `baseUrl` in `lib/main.dart` for your local or production Django server.
5. Start the app with `flutter run`.
