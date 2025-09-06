# GymRat Implementation Plan (Flutter/Dart, Mobile-Only)

This plan is incremental, dependency-aware, and structured so each step ships a testable feature. We will build locally first (SQLite via Drift), validate flows, then add sync/auth. Each milestone lists scope, dependencies, deliverables, and acceptance criteria (AC).

## Tech Baseline
- Flutter (Dart), iOS and Android
- State management: Provider or Riverpod (to be chosen at Milestone 0)
- Navigation: go_router
- Local storage: SQLite via Drift ORM (+ flutter_secure_storage for secrets)
- HTTP: http or dio
- DI: riverpod providers or get_it (decide in Milestone 0)

## Milestone 0: Project Foundations
- Scope:
  - Set up app package structure: `core/`, `features/`, `data/`, `domain/`, `ui/`
  - Add dependencies (drift, drift_sqflite, path_provider, flutter_secure_storage, go_router, state mgmt)
  - Initialize Drift database and migration scaffolding
  - Define base theme, typography, colors
  - Add CI lint/format checks (flutter analyze, format)
- Dependencies: None
- Deliverables:
  - Running app skeleton with navigation shell
  - Drift database file created at startup
- AC:
  - App launches to a placeholder Home screen
  - `flutter analyze` reports 0 issues

## Milestone 1: User Profile + Goals (Onboarding)
- Scope:
  - Data model: `users`, `goals`
  - Onboarding flow: Profile Setup → Goal Setting → Macro Targets (per PRD/UX)
  - Persist profile and targets in SQLite
- Dependencies: Milestone 0
- Deliverables:
  - Onboarding screens implemented with validation
  - Repository + use-cases for profile/goals
- AC:
  - New install shows onboarding; completing it persists data
  - Relaunch shows Home (no onboarding)

## Milestone 2: Home Dashboard (Read-Only)
- Scope:
  - Home dashboard UI with macro rings, Today tasks area (placeholder states), Quick actions
  - Compute daily macro totals from DB (will be 0 until logging added)
- Dependencies: Milestone 1
- Deliverables:
  - Macro rings reflect targets from goals
- AC:
  - Home shows correct target values and 0/target progress

## Milestone 3: Food Logging (Manual Entry + Recent)
- Scope:
  - Data model: `foods` (custom), `meals`, `meal_items`
  - Food Logging screens: Add Food (Manual + Recent)
  - Update Home rings from logged meals
- Dependencies: Milestone 2
- Deliverables:
  - Create custom food, add to meal (breakfast/lunch/dinner/snack)
  - Recent foods list (last N items)
- AC:
  - Adding a food updates Home macro progress immediately
  - Recent correctly lists last used items

## Milestone 4: Barcode Scanner + Food Search (External API)
- Scope:
  - Integrate camera barcode scanning
  - Food database search via external API; cache results
  - Extend `foods` table for branded items
- Dependencies: Milestone 3
- Deliverables:
  - Search tab with results; scan-to-lookup flow
- AC:
  - Scanning or searching returns items and allows adding to meals
  - Offline shows cached items, search gracefully degrades

## Milestone 5: Active Workout (Minimal)
- Scope:
  - Data model: `exercises`, `workouts`, `workout_exercises`, `workout_sets`
  - Active Workout screen: start custom workout, log sets (weight, reps), timer start (no rest yet)
  - Workout history list (read-only)
- Dependencies: Milestone 2
- Deliverables:
  - Start/finish workout, per-exercise set logging, auto timestamp
- AC:
  - Completing a workout persists sets; history shows session with totals

## Milestone 6: Rest Timer + Last Week Context
- Scope:
  - Rest Timer screen with haptics
  - Show last session performance per exercise
- Dependencies: Milestone 5
- Deliverables:
  - Per-set flow: Complete → Rest Timer → Next set
- AC:
  - Rest timer counts down; alert triggers; last-week box shows correct data

## Milestone 7: Daily Tasks & Habits
- Scope:
  - Data model: `tasks`, `task_occurrences`
  - Today list with toggle complete and streaks
- Dependencies: Milestone 2
- Deliverables:
  - Create recurring tasks; auto-generate occurrences per day
- AC:
  - Toggling a task updates streak; Today reflects completion state

## Milestone 8: Analytics (Basic Weekly)
- Scope:
  - Weekly graphs: Diet (macros), Workouts (volume), Habits (completion)
  - SQLite views/queries and simple charting
- Dependencies: 3, 5, 7
- Deliverables:
  - Analytics tab with three basic charts
- AC:
  - Weekly data matches underlying entries (spot-checked)

## Milestone 9: Templates (Meals + Workouts)
- Scope:
  - Meal templates and quick add
  - Workout templates creation and use in Active Workout
- Dependencies: 3, 5
- Deliverables:
  - Template CRUD and apply flows
- AC:
  - Applying template pre-fills items/sets correctly

## Milestone 10: Data Export (CSV/PDF)
- Scope:
  - CSV export for meals, workouts, tasks, body metrics
  - Optional PDF summaries
- Dependencies: 3, 5, 7, 8
- Deliverables:
  - Export options from Analytics or Settings
- AC:
  - Files generated to Documents; share sheet works

## Milestone 11: Backup/Restore + Authentication (Phase 1)
- Scope:
  - Local backup/export/import to file (zip of SQLite DB) via share sheet (iOS iCloud Drive/Files, Android Drive, etc.)
  - Restore from selected backup file (validates and replaces DB), app reloads providers
  - Prep for auth/sync (defer full backend): retain SQLite as cache
- Dependencies: 0–10
- Deliverables:
  - Settings screen buttons: “Back up to file” and “Restore from file”
  - Zip includes DB and WAL/SHM if present; restore replaces safely
- AC:
  - User can export backup to Files and restore it later, surviving uninstall/reinstall scenario when the file is kept externally

## Milestone 12: Polishing + Accessibility + Perf
- Scope:
  - Accessibility pass (contrast, labels, haptics)
  - Performance: indices, query optimization, pagination
  - Error handling/empty states, UX polish
- Dependencies: 0–11
- Deliverables:
  - Smooth, accessible flows; documented known issues resolved
- AC:
  - Meets design and performance targets from PRD

---

## Data Model (Initial Drift Schema)
- users(id, name, email, age, height, weight, gender, activity_level)
- goals(id, user_id, calories_min, calories_max, protein_g, carbs_g, fats_g, created_at)
- foods(id, user_id, name, brand, serving_desc, macros_p, macros_c, macros_f, calories)
- meals(id, user_id, date, meal_type)
- meal_items(id, meal_id, food_id, quantity, unit, macros_p, macros_c, macros_f, calories)
- exercises(id, user_id, name)
- workouts(id, user_id, started_at, finished_at, name)
- workout_exercises(id, workout_id, exercise_id, order_index)
- workout_sets(id, workout_exercise_id, set_index, weight, reps)
- tasks(id, user_id, name, days_mask, order_index)
- task_occurrences(id, task_id, date, completed_at)
- body_metrics(id, user_id, date, weight, body_fat_pct)
- sync_queue(id, entity_type, entity_id, op, payload_json, created_at)

Note: Add FKs, cascades, and indices per PRD storage section.

## Testing Strategy
- Unit tests: repositories, use-cases, Drift DAOs
- Widget tests: onboarding flow, food logging, active workout, tasks
- Golden tests: key screens
- Integration tests: happy-path flows (new user → onboard → log food → see rings)

## Release Cadence
- Ship a build at the end of each milestone (TestFlight/internal testing)
- Maintain a migration log per milestone when schema changes

## Risks & Mitigations
- External API limits: cache results; exponential backoff; offline graceful UX
- Complexity creep: keep PRD scope; milestone-based approvals
- Data loss: local backups; tested migrations; sync status indicators
