# Immunova

Offline-first immunization records app designed for clinics and caregivers. Works fully offline with IndexedDB (via idb_shim) and can be connected to an online backend later (e.g., Supabase/Postgres).

- Offline-first by default
- Local accounts (no network required)
- Patients scoped to the signed-in user
- IndexedDB storage with idb_shim
- Clean UI with modern onboarding/sign-in flow

## Features

- Onboarding with a friendly introduction
- Sign in using a local account (employee ID + password)
- Account mode: online registration (placeholder) or local signup
- Home dashboard with quick actions (grid)
- Patient records list, filtering, searching
- Add patient flow with guarded date inputs (native date picker)
- Immunization logging per patient
- Settings and profile, both bound to the current local user

## Tech stack

- Flutter 3.x / Dart 3.x
- IndexedDB (idb_shim)
- Provider (state management)
- Shared Preferences (persistence for user session)
- Google Fonts

Key dependencies:
- idb_shim
- provider
- shared_preferences
- google_fonts

## Project structure (high-level)

```
lib/
  Screens/
    onboarding_screen.dart
    signin_screen.dart
    account_mode_screen.dart
    local_signup_screen.dart
    home_page.dart
    patient_records.dart
    add_patient_page.dart
    setting_page.dart
    profile.dart
    ...other screens...
  database/
    database_helper.dart
  models/
    patient.dart
    immunization.dart
  providers/
    user_session.dart
main.dart
```

## Data model (offline)

Object stores (keyPath: local_id, autoIncrement: true)
- users
  - indexes: remote_id (unique), employee_id (unique)
- user_settings
  - indexes: user_id (unique)
- patients
  - indexes: remote_id (unique), doc_id
- vaccines
  - indexes: name (unique)
- immunizations
  - indexes: patient_id, vaccine_id
- notifications
  - indexes: user_id, patient_id

Notes:
- Models use local_id as the key path for offline records.
- Patient.doc_id points to the signed-in user's local_id to scope access.
- Dose is stored as a string (e.g., “1st”, “Booster”).
- Dates are stored as ISO strings; UI uses native date pickers.

## Session management

- Global session: providers/user_session.dart (ChangeNotifier)
- Persists current user local_id via SharedPreferences
- Methods:
  - signInLocal(employeeId, password)
  - registerLocal(userMap)
  - signOut()
- Access in widgets:
  - context.watch<UserSession>().currentUser
  - context.watch<UserSession>().displayName
  - context.watch<UserSession>().localId

## Setup

Prerequisites:
- Flutter SDK 3.x
- Android Studio or Xcode (optional for mobile)
- Chrome (for web dev)

Install deps:
```
flutter pub get
```

Run (Web):
```
flutter run -d web-server --web-hostname=localhost --web-port=3000
```

Run (Android):
```
flutter run -d android
```

Run (iOS):
```
flutter run -d ios
```

Optional clean:
```
flutter clean
flutter pub get
```

## Offline database

- IndexedDB is initialized at first app start (database_helper.dart)
- If you change store/index definitions during development, reset the DB:

Browser console:
```
indexedDB.deleteDatabase('immunova_db')
```

Or programmatically (dev only):
- Call DatabaseHelper().resetDatabase() once before app start.

Common errors:
- NotFoundError: object store not found
  - Reset IndexedDB and reload the app so stores are recreated.
- idb_shim factory is null
  - Ensure running in a web/desktop/mobile environment that supports idb_shim usage.

## Flows

- Onboarding → Sign In (default)
- “New user? Sign up” → Account Mode
  - Online registration (placeholder screen)
  - Local signup (minimal form, creates ‘users’ record)
- After sign-in or signup → Home (grid dashboard)
- From Home: navigate to Patients, Add Patient, Settings, etc.

## UI

- Poppins as primary font (google_fonts)
- Accent color: #4ECDC4
- Modern cards, gradients, rounded shapes, elevated components

## Troubleshooting

- Date parsing errors:
  - DOB and Immunization dates use a native date picker and are stored as YYYY-MM-DD.
- Dose parsing errors:
  - Doses are strings (e.g., “1st”, “2nd”, “Booster”), not integers.
- Updating schema:
  - If stores/indices change, reset IndexedDB and reload.
- Users see each other’s data:
  - Ensure queries use doc_id index with the current user local_id (already done in patient_records/add_patient logic).

## Security notes

- Local password storage is plaintext for development convenience.
- For production, hash and salt passwords; consider platform-secure storage.
- Sync targets (Supabase/Postgres) can be added later; this codebase is offline-first.

## Roadmap

- Online signup and full sync pipeline
- Repository layer and unit tests
- Analytics and richer notifications
- Export/import of local data

## License

MIT (or your preferred license).