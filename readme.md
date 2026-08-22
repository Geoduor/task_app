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
| MongoDB | Atlas (cloud, free tier) | see setup below — no local install required |
| Flutter SDK | 3.24+ (Dart 3.3+) | installed manually, see setup below |
| Git | any recent version | required by the Flutter SDK tooling |
| A browser (Chrome/Edge) | — | used to run the app; no Android emulator required |

## 1. Backend (NestJS)

```bash
cd backend
npm install
cp .env.example .env
# Edit .env — see "Database setup" below for what to put here
npm run start:dev
```

The API starts on **http://localhost:3000** by default. On success you'll see:
```
Task API listening on http://localhost:3000
```

### Database setup — MongoDB Atlas (recommended)

This project was built and tested against **MongoDB Atlas** (a free cloud
cluster), not a local MongoDB install. This avoids requiring Docker or a
local MongoDB service, which is convenient for a quick clone-and-run setup.

1. Create a free cluster at https://www.mongodb.com/cloud/atlas/register
2. Under **Network Access**, allow your IP (or `0.0.0.0/0` for convenience —
   fine for a demo project, not for production)
3. Under **Database Access**, create a database user with a username/password
4. Click **Connect → Drivers**, copy the connection string, and add a
   database name to it, e.g.:
   ```
   mongodb+srv://<user>:<password>@cluster0.xxxxx.mongodb.net/task_app?retryWrites=true&w=majority&appName=Cluster0
   ```
5. Paste that into `backend/.env` as `MONGODB_URI`

**Alternative — local MongoDB:** if you'd rather not use Atlas, any local
MongoDB instance works too:
```bash
docker run -d -p 27017:27017 --name task-mongo mongo:7
```
and set `MONGODB_URI=mongodb://localhost:27017/task_app` in `.env` instead.

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

### Installing Flutter

If Flutter isn't installed yet, install it manually rather than through an
IDE's auto-installer (more reliable on Windows in our experience):

1. Download the SDK zip from https://docs.flutter.dev/get-started/install/windows
   (use the **"Install manually"** path, not the VS Code quick-start, if the
   quick-start's Git-based download fails)
2. Extract it to `C:\src\flutter` — **avoid paths with spaces**, such as
   `C:\Program Files\flutter`, which can cause permission and build errors
3. Add `C:\src\flutter\bin` to your user `Path` environment variable
4. Fully restart VS Code (not just the terminal) so it picks up the new PATH
5. Verify: `flutter --version`, then `flutter doctor`

```bash
cd mobile
flutter pub get
flutter run -d chrome
```

### Running without an Android emulator

This project doesn't require Android Studio or an emulator to demo. Running
with `-d chrome` launches the exact same Flutter/Dart code in a browser tab,
which is sufficient to demonstrate the full functional integration (state
management, API calls, validation, error handling) without the overhead of
setting up an Android SDK and AVD.

Check available devices any time with:
```bash
flutter devices
```

If you do have an Android emulator running, `flutter run` (no `-d` flag)
will let you pick it interactively.

### Pointing the app at the API

The app auto-selects a sensible base URL per platform (see
`lib/services/api_config.dart`):

- **Chrome / web / desktop** → `http://localhost:3000`
- **Android emulator** → `http://10.0.2.2:3000` (emulator's alias for the host machine)
- **Physical device** → override with your machine's LAN IP:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://192.168.1.42:3000
```

Make sure the backend is running **before** launching the app.

### Running tests

```bash
cd mobile
flutter test
```

## Quick smoke test

**macOS/Linux (curl):**
```bash
curl -X POST http://localhost:3000/tasks -H "Content-Type: application/json" -d '{"title":"Buy milk"}'
curl http://localhost:3000/tasks
curl -X PATCH http://localhost:3000/tasks/<id-from-above>/complete
```

**Windows PowerShell** (native `curl` is aliased to `Invoke-WebRequest`,
which uses different syntax — use `curl.exe` or `Invoke-RestMethod` instead):
```powershell
Invoke-RestMethod -Uri http://localhost:3000/tasks -Method Post -ContentType "application/json" -Body '{"title":"Buy milk"}'
Invoke-RestMethod -Uri http://localhost:3000/tasks -Method Get
Invoke-RestMethod -Uri "http://localhost:3000/tasks/<id-from-above>/complete" -Method Patch
```

## Troubleshooting notes

- **`nest : command not found` / `'nest' is not recognized`** — run
  `npm install` in `backend/` first; the CLI comes from `node_modules`.
- **`flutter : command not found`** — the SDK isn't on PATH yet, or VS Code
  hasn't been restarted since it was added. Close VS Code fully and reopen.
- **Flutter app can't reach the API** — confirm the backend terminal is
  still running and listening on port 3000; on an Android emulator
  specifically, remember `localhost` refers to the emulator itself, not
  your machine (see `api_config.dart`).
- **`docker: command not found`** — Docker Desktop isn't installed; use the
  MongoDB Atlas setup above instead, which requires no local install.
