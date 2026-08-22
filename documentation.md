# Architecture & Design Decisions

## 1. Monorepo layout

`backend/` and `mobile/` are kept as two independent, self-contained
projects (own `package.json` / `pubspec.yaml`, own dependency trees) inside
one repository. This was chosen over a shared root config because the two
stacks (Node vs. Dart) have no shared tooling to gain from unification, and
keeping them independent means each can be opened directly in its native
IDE/tooling without special workspace configuration.

## 2. Backend (NestJS)

### Module structure

```
src/
├── app.module.ts        # wires ConfigModule + MongooseModule + TasksModule
├── main.ts               # bootstrap, global ValidationPipe, CORS
└── tasks/
    ├── tasks.controller.ts   # HTTP layer only — no business logic
    ├── tasks.service.ts      # business logic, talks to Mongoose model
    ├── tasks.module.ts
    ├── tasks.service.spec.ts # unit tests (mocked model)
    ├── dto/
    │   ├── create-task.dto.ts    # input validation (class-validator)
    │   └── task-response.dto.ts  # explicit output shape
    └── schemas/
        └── task.schema.ts    # Mongoose schema (title, completed, timestamps)
```

This follows Nest's standard layering: **Controller → Service → Model**.
The controller never touches Mongoose directly, so the persistence layer
could be swapped (e.g. to PostgreSQL/Prisma) without touching HTTP concerns.

### API design

| Decision | Rationale |
|---|---|
| `POST /tasks` returns `201` with the created task | Standard REST semantics; lets the client immediately render the task with its server-assigned `id` and `createdAt`, instead of re-fetching. |
| `PATCH /tasks/:id/complete` rather than a generic `PUT /tasks/:id` | The brief specifies exactly one state transition ("mark as complete"). A narrow, intention-revealing endpoint avoids exposing a general-purpose update that isn't required and could let a client accidentally overwrite fields. |
| `GET /tasks` (added beyond the two required endpoints) | The mobile screen needs *some* way to display existing tasks after an app restart — otherwise the UI could only ever show tasks created in the current session. This was the smallest addition that makes the two required endpoints demoable as a real screen. |
| Response DTO separate from the Mongoose document | Decouples the wire format (`id` as string) from Mongo's internal `_id`/`ObjectId` representation, and avoids leaking Mongoose internals (e.g. `__v`) to clients. |
| Global `ValidationPipe` with `whitelist: true` | Centralizes input validation instead of manual `if` checks in every controller method; unknown/extra body fields are stripped rather than silently accepted. |

### Validation & error handling

- **Missing/empty title** → `class-validator`'s `@IsNotEmpty` on `CreateTaskDto`
  triggers Nest's built-in `400 Bad Request` via the global `ValidationPipe`,
  with a clear message array.
- **Malformed task id** (not a valid Mongo ObjectId, e.g. `/tasks/abc/complete`)
  → checked explicitly with `isValidObjectId()` in the service *before*
  hitting the database, returning `400 Bad Request` with a descriptive
  message. Without this guard, Mongoose would throw a `CastError` that Nest's
  default filter turns into an unhelpful `500`.
- **Unknown but well-formed id** (valid ObjectId, no matching document) →
  `404 Not Found`.
- **Success** → `200 OK` for the completion PATCH, `201 Created` for creation.

This gives three distinct, correctly-coded outcomes for the "unknown ID"
class of bugs that's easy to get wrong (400 for garbage input vs. 404 for a
legitimate-but-absent id), which the brief calls out explicitly.

### Data model

```ts
{
  title: string;       // required, trimmed
  completed: boolean;  // defaults to false
  createdAt: Date;      // via { timestamps: true }
  updatedAt: Date;
}
```

Kept intentionally minimal to match the brief's scope (no due dates,
priorities, or user ownership) — extra fields would be speculative.

## 3. Mobile (Flutter)

### Structure

```
lib/
├── main.dart                  # app entrypoint, theme, Provider wiring
├── models/task.dart           # immutable Task model, JSON (de)serialization
├── services/
│   ├── api_config.dart        # resolves base URL per platform
│   └── task_service.dart      # thin HTTP client (create/list/complete)
├── providers/task_provider.dart  # ChangeNotifier — app state & error handling
└── screens/task_screen.dart   # UI: input field, list, checkboxes
```

### State management: `provider` (ChangeNotifier)

For a single screen with one list of tasks and two operations (add,
complete), `provider` gives the same testable, unidirectional-data-flow
benefits as Bloc/Riverpod with meaningfully less boilerplate. `TaskProvider`
exposes:

- `tasks` — the current list (unmodifiable view)
- `status` — `initial | loading | loaded | error`, driving what the screen renders
- `addTask()` / `toggleComplete()` — return an error message string (or
  `null` on success) instead of throwing, so the widget layer can show a
  `SnackBar` without try/catch in the UI

### Frontend/backend integration

1. On screen load, `TaskProvider.loadTasks()` calls `GET /tasks` and
   populates the list.
2. Submitting the text field calls `TaskProvider.addTask()`, which:
   - Validates non-empty title client-side (fast feedback, avoids a round
     trip for the obvious case)
   - Calls `POST /tasks`
   - Prepends the server's response (with its real `id`) to the list
3. Tapping a checkbox calls `toggleComplete()`, which:
   - **Optimistically** flips the task to completed in local state so the UI
     feels instant
   - Calls `PATCH /tasks/:id/complete`
   - On failure, rolls back the optimistic change and surfaces the server's
     error message via `SnackBar`
   - Because the API has no "un-complete" action, a completed checkbox is
     rendered as disabled (`onChanged: null`) rather than allowing a toggle
     that the backend cannot honor
4. `ApiConfig` resolves `10.0.2.2` vs `localhost` automatically so the same
   code runs unmodified on the Android emulator, iOS simulator, and web/desktop.

### Error surfacing

`TaskService` inspects the HTTP status code and, where possible, the
NestJS error body (`{ statusCode, message }`) to produce a human-readable
string. Network failures (server not running, DNS issues) are caught
separately and shown as "Could not reach the server" rather than a raw
exception trace.

## 4. Trade-offs & things intentionally left out

- **No authentication/user scoping** — out of scope per the brief; all tasks
  are global.
- **No task deletion or un-completing** — the brief specifies exactly create
  + complete; adding more endpoints than asked risks over-engineering a
  timed assignment.
- **No offline cache/local DB on the Flutter side** — the app is a thin
  client over the API; adding e.g. `sqflite` for offline support would be
  disproportionate to a two-endpoint feature.
- **`GET /tasks` was added** beyond the two required endpoints — see the
  API design table above for the reasoning; flagged here for visibility
  since it's the one deviation from the literal brief.
