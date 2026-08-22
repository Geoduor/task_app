# Reflection

## What I built

A create-task / complete-task flow spanning a NestJS + MongoDB API and a
Flutter screen, structured as two independent projects in one repository.

## Challenges

- **Distinguishing "bad input" from "not found."** A task id that isn't a
  valid MongoDB ObjectId and a task id that's well-formed but doesn't exist
  are both "the task can't be completed," but they deserve different HTTP
  status codes (400 vs. 404). Mongoose throws the same kind of error for
  malformed ObjectIds as for other query failures, so this needed an
  explicit `isValidObjectId()` check ahead of the database call rather than
  relying on catching whatever Mongoose throws.
- **Emulator networking.** `localhost` inside an Android emulator refers to
  the emulator itself, not the host machine running the API — a classic trap
  for anyone testing a Flutter app against a local backend for the first
  time. Centralizing that logic in one `ApiConfig` class, with an escape
  hatch (`--dart-define`) for physical devices, was the cleanest way to
  avoid scattering platform checks through the codebase.
- **Deciding what *not* to build.** The brief asks for exactly two
  endpoints and one screen. It was tempting to add task deletion, editing,
  or persistence beyond MongoDB, but the more valuable signal for a timed
  assignment is a small surface area implemented correctly (validation,
  status codes, rollback on failure) rather than a larger, thinner one.

## Trade-offs

- Chose `provider` over Bloc/Riverpod for state management — appropriate for
  a single screen with one list, but I'd reconsider for a multi-screen app
  with more shared/derived state.
- Added `GET /tasks` beyond the two required endpoints so the app has
  something to show on load/restart, rather than only ever displaying
  tasks created in the current session. This felt necessary to make the
  two required endpoints demoable as a real, working screen rather than a
  strictly literal reading of the brief.
- Optimistic UI updates for "complete" trade a small amount of complexity
  (rollback-on-failure logic) for a screen that feels responsive even on a
  slow connection.

## What I'd do with more time

- Integration/e2e tests against a real (or in-memory) MongoDB instance for
  the backend, rather than only unit tests against a mocked model.
- Widget tests for `TaskScreen` itself (the current Flutter tests cover the
  provider/service layer, which holds the actual logic).
- A CI workflow (GitHub Actions) running `npm test` and `flutter test` on
  every push.
