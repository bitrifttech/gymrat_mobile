# Progress Log

## Documentation
- Updated `documentation/gymrat-mobile-prd.md` to Flutter (Dart) mobile-only; removed desktop scope.
- Updated `documentation/ux-description.md` to mobile-only; converted desktop flows to mobile equivalents.
- Added SQLite storage specification (Drift, schema, indices, migrations, encryption options) to PRD.
- Created `documentation/implementation-plan.md` with incremental milestones and testing strategy.

## Flutter App Setup
- Initialized Flutter app at `app/` for iOS and Android.
- Verified iOS build without codesigning; produced `app/build/ios/iphoneos/Runner.app`.
- Launched iOS Simulator and attempted run; initial run hit a transient Dart compiler disconnect, environment confirmed.

## Milestone 0 (Foundations)
- Added dependencies: `go_router`, `flutter_riverpod`, `drift`, `drift_sqflite`, `path_provider`, `flutter_secure_storage`, `dio`, `build_runner`, `drift_dev`, `path`.
- Scaffolded directories: `lib/core`, `lib/router`, `lib/data/db`, `lib/features/home/{ui,domain,data}`.
- Implemented router (`lib/router/app_router.dart`) and `HomeScreen`.
- Initialized Drift database with a minimal `settings` table (`lib/data/db/app_database.dart`) and a Riverpod DB provider (`lib/core/db_provider.dart`).
- Ran code generation (build_runner) and analyzer; project is clean.

## Next
- Milestone 2 completed: Home Dashboard (read-only).

## Milestone 1 (Onboarding + Profile/Goals)
- Drift schema: added `users` and `goals` tables; ACID transactions for saves.
- Onboarding flow (3 steps):
  - Profile: age, height, weight, Sex (Male/Female), activity level, units (Metric/Imperial) with live label changes.
  - Goal: bulk/cut/maintain.
  - Macros: user-editable fields; "Use Suggestions" fills from heuristic, never overwrites user edits unless pressed.
- Units preference: persisted in `settings` and respected across onboarding and edit screens; height/weight converted to metric for storage.
- Home: displays saved calorie range and macro targets from SQLite.
- Edit Profile & Goals screen:
  - Full form with validation, Sex (no "Other"), units toggle (persists immediately), and Save.
  - Reset button: clears users/goals/settings and routes back to onboarding.
- Analyzer: clean; build verified on iOS simulator.

## Milestone 2 (Home Dashboard - Read-only)
- Macro rings: circular progress for Calories/Protein/Carbs/Fats against targets.
- Responsive layout: Wrap used to avoid overflows on smaller widths.
- Quick Actions: stubs for Log Food, Start Workout, Add Task with routes.
- Today section: placeholders for tasks and workout.
- Visual tweaks: visible ring background track and primary color.
- Analyzer: clean; verified on iOS simulator.
