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
- [ ] Firebase connection
- [ ] Authentication and role-based routing
- [ ] Intern features
- [ ] Admin features
- [ ] Dashboards and charts
- [ ] Security rules and tests
- [ ] v1.0.0 release

## Author

**Farhan Ali Haider** · [@bangash40](https://github.com/bangash40)
