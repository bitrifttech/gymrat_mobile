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

## Milestone 6 (Metrics & Insights)
- Demo data seeding: Ensured meals (last 14 days) and multiple completed workouts exist on first run so metrics have data. Reset + restart onboarding reseeds.
- Nutrition metrics:
  - Single interactive LineChart (fl_chart) with macro selector (Kcal, Protein, Carbs, Fats, All) and time range (Week, Month, All time).
  - Data sourcing aligned with Meal History using per-day totals (same WHERE m.date = ? logic). Added robust date casting for SQLite (int/string/DateTime) and guarded all macro columns.
  - Added an optional debug panel under the chart listing raw daily rows to verify graph inputs.
  - Chart polish: compact Y-axis labels (K format), tooltips with full values, disabled top/right titles, and computed “nice” axis bounds to prevent an extra overlapping top label.
- Workout metrics:
  - Weekly volume (last 6 weeks) and Top exercises by volume charts with tooltips and compact axes.
  - Recent PRs detection and display (Epley est. 1RM per set), with robust startedAt date parsing (int/string/DateTime) to prevent type errors.
  - Post-workout summary screen exists with sets, tonnage, per-exercise breakdown, and recent PRs.
- Navigation: Added Metrics entry on Home and route wiring.
- App polish: Set app display name to “GymRat” on Android/iOS and configured GymRat_red launcher icon via flutter_launcher_icons.

-- Milestone 6 closed. --

## Housekeeping & Polish
- UX:
  - Added concise descriptions for activity levels (Onboarding + Edit Settings).
  - Home: clarified in-progress workout label and removed the unused Workout section.
- Workouts:
  - Rest timers now toggle Start/Stop (Stop cancels the timer).
  - After restart/reset, workout detail renders placeholder set rows from template targets so you can enter new data immediately.
  - Added Save & End button to Workout Detail for in-progress sessions.
  - Removed the Active Workout screen and routes; flows now use Workout Detail directly. Summary page includes a prominent Close back to Home.
- Metrics:
  - Removed the temporary Nutrition debug panel.
  - Chart axis label polish retained (no overlapping top label), PR date parsing fix retained from prior work.
- Performance & Build:
  - Added DB indexes and bumped schema to v8 (meals.date, meal_items.meal_id, workouts.started_at, workouts.source_template_id, workout_exercises.workout_id, workout_sets.workout_exercise_id).
  - Configured adaptive Android launcher icon and regenerated icons; kept GymRat_red branding across platforms.
  - Removed unused daily macro providers after metrics revamp.

-- Housekeeping & Polish closed. --

## UI ReOrg and Tweaks
- Navigation:
  - Added bottom navigation (Home, Meals, Workouts, Metrics, Configure).
  - Configure screen converted to tabs (Templates, Schedule, Profile, Tasks) with inline editors.
- Templates:
  - Full-screen template editor (no side list): inline template rename, per-exercise rename, delete with confirm.
  - Drag-reorder exercises with persisted order (updates `orderIndex`).
- Schedule:
  - Day-first editor with mobile-friendly day chips, per-day workout template picker, Clear and Copy-to-days actions.
  - Tasks are stubbed locally in UI; persistence deferred to next milestone.
- Profile:
  - Embedded editor in Configure tab; save shows snackbar when embedded (no pop crash).
- Home:
  - Quick Actions trimmed to Log Food, Today’s Meals, Add Task.
- Fixes/Polish:
  - Prevent duplicate route names and add Close button on workout summary.

-- UI ReOrg and Tweaks closed. --