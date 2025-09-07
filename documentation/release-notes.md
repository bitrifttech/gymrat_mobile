## GymRat Mobile — Internal/TestFlight Release Notes

### Highlights
- **Redesigned Log Food**: Quick meal buttons (Breakfast/Lunch/Dinner/Snack) with clear selection highlight. See foods for the selected meal, add/remove instantly, and edit quantity/unit via a simple dialog.
- **Smarter Serving Units**: Default quantity/unit to the food’s base serving, remember the last-used unit per food, and added "slice" for items like bread or deli meat.
- **Search & Scan**: Add foods via search or barcode scanning from the Log Food screen.
- **Configure Cleanup**: Removed meal templates; kept workout templates. Tabs renamed and reordered to: Workouts, Foods, Tasks, Schedule, Profile. Foods tab now uses an Add Food popup instead of inline fields.
- **Backup & Restore**: Export a zipped database to Files and restore from a zip. Uses native file dialogs; iOS share sheet issues resolved.

### Improvements
- **Data Reactivity**: Meals update immediately on add/edit/delete; dashboard reacts to goal changes in real-time.
- **Profile & Goals**: Values persist reliably; macro reconciliation honors calories and protein while calculating carbs/fats.
- **Metrics**: Cleaner x-axis labels and lines clipped at zero to avoid negative dips before first data point.
- **Reset Onboarding**: Fully clears meals, foods, tasks, workouts, and related tables; removed demo data seeding on startup.

### Fixes
- Eliminated dropdown assertion errors by normalizing unit and activity values.
- Fixed adding food to meals that already contain items (e.g., Breakfast).
- Removed unused meal-template providers and related dead code.

### How to Use Backup/Restore
- **Backup**: Settings → Backup & Restore → Back up to file → Choose a location in Files/iCloud Drive.
- **Restore**: Settings → Backup & Restore → Restore from file → Select a previously exported zip.

### Notes
- This build focuses on food logging UX, persistence correctness, and a reliable backup path for testing across installs.

