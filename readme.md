# Task App — NestJS + Flutter Monorepo

A minimal end-to-end task feature: create a task, mark it complete. Built with
NestJS + MongoDB on the backend and Flutter on the frontend.

```
task-app/
├── backend/     # NestJS API
├── mobile/      # Flutter app
├── readme.md
├── documentation.md
└── reflection.md
```

## Prerequisites

| Tool | Version tested | Notes |
|---|---|---|
| Node.js | 20.x LTS | for the NestJS API |
| npm | 10.x | ships with Node |
| MongoDB | 7.x | local install, Docker, or a free MongoDB Atlas cluster |
| Flutter SDK | 3.22+ (Dart 3.3+) | `flutter doctor` should show no blocking issues |
| A device/emulator | Android emulator, iOS simulator, or Chrome | for running the app |

## 1. Backend (NestJS)

```bash
cd backend
npm install
cp .env.example .env
# Edit .env if your MongoDB URI differs from the default
npm run start:dev
```

The API starts on **http://localhost:3000** by default.

### Running MongoDB locally

Pick one:

```bash
# Option A: Docker (fastest)
docker run -d -p 27017:27017 --name task-mongo mongo:7

# Option B: local install (macOS example)
brew tap mongodb/brew && brew install mongodb-community@7.0
brew services start mongodb-community@7.0
```

Or point `MONGODB_URI` in `.env` at a MongoDB Atlas connection string —
no local install needed.

### Endpoints

| Method | Path | Body | Success | Notes |
|---|---|---|---|---|
| POST | `/tasks` | `{ "title": string }` | 201 | Rejects empty/missing title with 400 |
| GET | `/tasks` | — | 200 | Lists all tasks, newest first (used by the app on load) |
| PATCH | `/tasks/:id/complete` | — | 200 | 400 for a malformed id, 404 for an unknown id |

### Running tests

```bash
cd backend
npm test
```

## 2. Mobile (Flutter)

```bash
cd mobile
flutter pub get
flutter run
```

### Pointing the app at the API

The app auto-selects a sensible base URL per platform (see
`lib/services/api_config.dart`):

- **Android emulator** → `http://10.0.2.2:3000` (emulator's alias for the host machine)
- **iOS simulator / Chrome / desktop** → `http://localhost:3000`
- **Physical device** → override with your machine's LAN IP:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.42:3000
```

Make sure the backend is running before launching the app.

### Running tests

```bash
cd mobile
flutter test
```

## Quick smoke test (curl)

```bash
curl -X POST http://localhost:3000/tasks -H "Content-Type: application/json" -d '{"title":"Buy milk"}'
curl http://localhost:3000/tasks
curl -X PATCH http://localhost:3000/tasks/<id-from-above>/complete
```
