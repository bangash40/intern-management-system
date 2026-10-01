# Intern Management System

A Flutter mobile app for managing intern profiles, assigned tasks and progress tracking in one place, backed by Firebase Authentication and Cloud Firestore. Data syncs in real time: a task an admin assigns appears on the intern's phone right away, and a status change shows up on the admin dashboard right away.

Built as an internship task for [Internee.pk](https://internee.pk).

> **Status:** ✅ v1.0.0 complete.

## Features

**For interns**
- Secure email and password login with a persistent session
- Dashboard with task counts, completion percentage, overdue tasks and the next deadlines
- Task list filtered by status and sorted by due date, with overdue tasks flagged
- Task detail: start a task, submit it with a note or link, and see admin remarks when it is sent back
- Profile screen

**For admins**
- Dashboard with total and active interns, total tasks, completion rate, overdue count, a status pie chart, top interns and the interns with the most overdue tasks
- Add interns from inside the app (creates their login and profile), search, filter active or inactive, edit, and deactivate or reactivate them without losing history
- Intern detail with profile, progress and task list
- Create, assign, edit and delete tasks
- Review submitted tasks: approve them, or send them back with remarks

**For everyone**
- Role-based routing: admins and interns each see only their own screens
- Material 3 design
- Loading, empty and error states on every list
- Readable error messages (wrong password, no internet, email already in use)

Not included in v1: forgot-password email, push notifications and file uploads.

## Tech Stack

Flutter · Dart · Firebase Authentication · Cloud Firestore · Riverpod · go_router

| Package | Purpose |
|---|---|
| `firebase_core`, `firebase_auth`, `cloud_firestore` | Firebase setup, login and database |
| `flutter_riverpod` | State management |
| `go_router` | Navigation and role-based redirects |
| `intl` | Date formatting |
| `fl_chart` | Dashboard charts |
| `fake_cloud_firestore`, `firebase_auth_mocks`, `mock_exceptions` (dev) | Testing without a real backend |
| `flutter_launcher_icons` (dev) | App icon generation |

## Firebase Setup

The Firebase config files are not committed, so after cloning you need to add them yourself:

1. Create a Firebase project with **Email/Password** sign-in and **Cloud Firestore** enabled.
2. Register the Android app (`com.example.intern_management_system`) and place the downloaded `google-services.json` in `android/app/`.
3. Generate `lib/firebase_options.dart` with `flutterfire configure` (this also sets up iOS).
4. Deploy the security rules and indexes (see below).

## Creating the First Admin

Interns cannot sign themselves up, so the first admin is created by hand, once:

1. In the Firebase console, go to **Authentication > Users > Add user** and create the account (email and password).
2. Copy the new user's **UID**.
3. In **Firestore Database**, create a document `users/{UID}` with these fields:

| Field | Type | Value |
|---|---|---|
| `uid` | string | the UID |
| `name` | string | the admin's name |
| `email` | string | the admin's email, lowercase |
| `role` | string | `admin` |
| `isActive` | boolean | `true` |

Everything after that is done inside the app: sign in as the admin, open **Interns > Add intern** to create intern accounts, and **All Tasks > Add task** to assign work. Share the intern's email and temporary password with them so they can sign in.

## Security Rules and Indexes

Access control is enforced by Firestore security rules, not by hiding screens:

- Interns can read only their own profile and their own tasks, and can change only a task's status and submission note. They cannot mark a task completed.
- Admins can read and manage everything. Deactivated users lose access to tasks.

The rules are in [firestore.rules](firestore.rules) and the composite indexes the task queries need are in [firestore.indexes.json](firestore.indexes.json).

To deploy them, either:

- paste `firestore.rules` into **Firestore Database > Rules** in the Firebase console and click **Publish**, and create the three indexes from `firestore.indexes.json` under **Indexes**; or
- use the Firebase CLI (`firebase deploy --only firestore`) after running `firebase init firestore` in the project folder and pointing it at these two files.

If a query needs an index that is missing, the Firestore log prints a link that creates it with one click.

## Running, Testing and Building

```
flutter pub get
flutter run            # run on a connected device
flutter analyze        # static analysis
flutter test           # unit and widget tests
flutter build apk --release
```

## Folder Structure

```
lib/
├── main.dart
├── app/                 # app widget, router, theme
├── core/                # constants, utils (validators, progress stats), shared widgets
└── features/
    ├── auth/            # data, providers, presentation (login)
    ├── interns/         # data, models, providers, presentation
    ├── tasks/           # data, models, providers, presentation
    └── dashboard/       # presentation (admin and intern dashboards, charts)
test/
firestore.rules
firestore.indexes.json
```

Screens never call Firebase directly. They go through repositories (`AuthRepository`, `InternRepository`, `TaskRepository`), and Firestore streams feed Riverpod providers, so every screen updates in real time.

## Roadmap

- [x] Requirements and technical design
- [x] Flutter project and folder structure
- [x] Firebase connection
- [x] Authentication and role-based routing
- [x] Intern features
- [x] Admin features
- [x] Dashboards and charts
- [x] Security rules and tests
- [x] v1.0.0 release
- [ ] Forgot-password flow (planned)

## Author

**Farhan Ali Haider** · [@bangash40](https://github.com/bangash40)
