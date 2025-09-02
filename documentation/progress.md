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

## Milestone 3 (Food Logging: Manual + Recent)
- Schema & Migration: Added `foods`, `meals`, `meal_items` (schema v2), with FKs and cascade deletes.
- Repository: `FoodRepository` for creating foods, adding to meals, listing recent foods, streaming today's totals and per-meal subtotals.
- UI: `FoodLogScreen` with meal selector, manual entry form (name/brand/serving/calories/protein/carbs/fats + quantity/unit), recent foods list (shows kcal + P/C/F) with quantity/unit prompt, and per-meal subtotals.
- Home integration: rings now reflect live totals from today's logged meals.
- Analyzer: clean; verified on iOS simulator.

## Milestone 4 (Barcode Scanner + Food Search)
- Schema: Extended `foods` with `barcode`, `source`, `remoteId`, `isCustom`, `servingQty`, `servingUnit` (schema v3).
- Repository: Integrated Open Food Facts (search + barcode); cached results locally; helpers for fetch by barcode and listing cached results.
- UI: Added `ScanFoodScreen` (camera via `mobile_scanner`) and `FoodSearchScreen` with add-to-meal prompts (meal selection + qty/unit).
- Food Log: Added Scan and Search actions in the app bar.
- iOS: Set `NSCameraUsageDescription` for barcode scanning.
- Analyzer: clean; verified in iOS simulator; scan and search add items and update Home rings immediately.

## Milestone 5 (Workout Templates, Schedule, Active + History)
- Schema & Migration: Added `exercises`, `workouts`, `workout_exercises`, `workout_sets` (v4); added `workout_templates`, `template_exercises` with `setsCount`, `repsMin`, `repsMax`, `restSeconds`, and `workout_schedule` (v5-v7). `workouts.sourceTemplateId` supports template lineage.
- Repository: Template CRUD, schedule, start/resume from schedule, read template targets, upsert sets by index, reopen and restart/reset finished workouts, delete workout (cascade sets/exercises), delete today's scheduled workout instances.
- UI:
  - Templates: create/delete templates, add exercises, targets (sets + rep range) and rest seconds per exercise.
  - Schedule: assign templates to days; dropdowns bound to live schedule stream.
  - Active Workout: inline set rows (reps/weight) with immediate persistence, Save & End, focus auto-advance, per-exercise rest timer with haptic + audible alert, integer-only weights, visible elapsed workout timer in AppBar.
  - Home: "Today's Workout" reflects scheduled/active/completed; completed shows green with Edit; Delete action removes today's scheduled instance(s).
  - History: list completed workouts linking to detail.
  - Detail: inline edit of sets; Save; shows total workout time; single Restart button prompts to keep values (restart) or clear (reset).
- Settings: "Reset and Restart Onboarding" clears all data across tables and resets sequences.
- Analyzer: clean; smoke tested flows — schedule → start → fill sets → save/end → edit from task → restart/reset via prompt → delete from task.

-- Milestone 5 closed. --
