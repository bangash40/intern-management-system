# Intern Management System

A Flutter mobile app for managing intern profiles, assigned tasks and progress tracking in one place, backed by Firebase Authentication and Cloud Firestore.

Built as an internship task for [Internee.pk](https://internee.pk).

> **Status:** 📝 In development. Project structure is set up; Firebase and features come next.

## Planned Features

**For interns**
- Secure login with Firebase Authentication
- View assigned tasks and update their status
- Personal dashboard with task counts and completion percentage
- Profile screen

**For admins**
- Add, update, review and deactivate intern profiles
- Create, assign, edit and review tasks
- Dashboard with overall progress, completion rate and overdue tasks

## Tech Stack

Flutter · Dart · Firebase Authentication · Cloud Firestore · Riverpod · go_router

## Dependencies

| Package | Purpose |
|---|---|
| `firebase_core`, `firebase_auth`, `cloud_firestore` | Firebase setup, login and database |
| `flutter_riverpod` | State management |
| `go_router` | Navigation and role-based redirects |
| `intl` | Date formatting |
| `fl_chart` | Dashboard charts |
| `fake_cloud_firestore`, `firebase_auth_mocks` (dev) | Testing without a real backend |

## Firebase Setup

The Firebase config files are not committed, so after cloning you need to add them yourself:

1. Create a Firebase project with **Email/Password** sign-in and **Cloud Firestore** enabled.
2. Register the Android app (`com.example.intern_management_system`) and place the downloaded `google-services.json` in `android/app/`.
3. Generate `lib/firebase_options.dart` with `flutterfire configure` (this also sets up iOS).

## Creating the First Admin

Interns cannot sign themselves up, so the first admin is created by hand:

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

After signing in, an admin lands on the admin dashboard and an intern on the intern dashboard. A user with a missing or deactivated profile is signed out.

## Folder Structure

```
lib/
├── main.dart
├── app/                 # app widget, router, theme
├── core/                # constants, utils, shared widgets
└── features/
    ├── auth/            # data, providers, presentation
    ├── interns/         # data, models, providers, presentation
    ├── tasks/           # data, models, providers, presentation
    └── dashboard/       # providers, presentation
test/
```

## Documentation

- [Product Requirements (PRD)](docs/PRD.md)
- [Technical Requirements (TRD)](docs/TRD.md)

## Roadmap

- [x] Requirements and technical design
- [x] Flutter project and folder structure
- [x] Firebase connection
- [x] Authentication and role-based routing
- [ ] Intern features
- [ ] Admin features
- [ ] Dashboards and charts
- [ ] Security rules and tests
- [ ] v1.0.0 release

## Author

**Farhan Ali Haider** · [@bangash40](https://github.com/bangash40)
