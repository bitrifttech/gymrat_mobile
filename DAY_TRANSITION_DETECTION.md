# Day Transition Detection Implementation

## Overview
This document describes the implementation of automatic day transition detection in the GymRat app, which ensures that the app automatically refreshes to show the current day's data when the system date changes while the app is running.

## Problem Statement
Previously, when the GymRat app was left running overnight (or across any day boundary), it would continue displaying the previous day's data. Users had to close and restart the app to see data for the new day.

## Solution Architecture

### Core Component: DayChangeNotifier
**Location:** `app/lib/core/day_change_notifier.dart`

A custom ChangeNotifier that:
1. Monitors the current date at regular intervals (every minute)
2. Detects when the system date changes
3. Notifies listeners when a day transition occurs
4. Responds to app lifecycle events (pause/resume)

**Key Features:**
- Timer-based polling (every 60 seconds) to check for day changes
- Implements `WidgetsBindingObserver` to detect when the app resumes from background
- Automatically checks for day change when app comes to foreground
- Minimal performance impact (single timer, lightweight date comparison)

### Provider Integration
**Provider:** `currentDateProvider`

A Riverpod Provider that exposes the current date from DayChangeNotifier. Other providers can watch this to automatically rebuild when the day changes.

## Updated Components

### 1. Food Tracking Providers
**File:** `app/lib/features/food/data/food_repository.dart`

Updated providers:
- `todayTotalsProvider` - Watches currentDateProvider to refresh macro totals
- `todayPerMealTotalsProvider` - Watches currentDateProvider to refresh per-meal totals
- `todaysMealsProvider` - Uses currentDate for meal queries

These providers now automatically refresh when the day changes, ensuring meal history, macro rings, and food logs always show current day data.

### 2. Workout Providers
**File:** `app/lib/features/workout/data/workout_repository.dart`

Updated providers:
- `scheduledTemplateTodayProvider` - Shows today's scheduled workout template
- `todaysScheduledWorkoutCompletedProvider` - Tracks completion status for today
- `todaysWorkoutAnyProvider` - Shows any workout logged today
- `todaysScheduledWorkoutAnyProvider` - Shows today's scheduled workout instance

These providers now respond to day changes, ensuring the home screen correctly shows:
- Today's scheduled workout
- Workout completion status
- Active/completed workout indicators

### 3. Tasks/Habits Providers
**File:** `app/lib/features/tasks/data/tasks_repository.dart`

Updated providers:
- `tasksForTodayProvider` - Shows tasks scheduled for today's day of week
- `completedTodayProvider` - Shows which tasks are completed today

These providers ensure the daily habit checklist automatically updates when the day changes.

### 4. Home Screen
**File:** `app/lib/features/home/ui/home_screen.dart`

The home screen now:
- Watches `currentDateProvider` to detect day changes
- Automatically resets the selected date to "today" when a day transition occurs (if user was viewing a past date)
- Uses `currentDate` instead of `DateTime.now()` throughout the UI logic
- Ensures all date comparisons use the centralized current date

**Day Change Behavior:**
- If user is viewing today's data → automatically shows new day's data
- If user is viewing a past date → the selection is preserved (user explicitly navigated there)
- Navigation buttons update correctly based on the new current date

## Implementation Details

### Timer Frequency
The day change check runs every minute. This provides:
- Near-immediate detection of day changes (max 60s delay)
- Minimal battery/performance impact
- Adequate responsiveness for a day-level feature

### App Lifecycle Handling
When the app is resumed from background:
- `didChangeAppLifecycleState(AppLifecycleState.resumed)` triggers
- Immediate check for day change (doesn't wait for timer)
- Ensures data is current even if app was suspended overnight

### Memory Management
- Timer is properly canceled in `dispose()`
- WidgetsBindingObserver is unregistered on disposal
- No memory leaks or orphaned timers

## Testing

### Unit Tests
**File:** `app/test/day_change_notifier_test.dart`

Tests verify:
- Correct initialization with current date
- Listener notification on date changes
- Proper handling of app lifecycle events

### Manual Testing Scenarios
1. **Basic day transition:** Leave app running, wait for midnight → data refreshes
2. **App suspend/resume:** Background app before midnight, resume after → data updates
3. **Date navigation:** Navigate to past date, wait for day change → selection preserved
4. **Timezone changes:** Change device timezone → app adapts correctly

## Performance Considerations

### Minimal Overhead
- Single timer shared across entire app
- Only one date comparison per minute
- Providers only rebuild when day actually changes
- No impact on scrolling, animations, or other UI operations

### Battery Impact
Timer running every 60 seconds is negligible for battery usage, especially compared to:
- Network requests
- Database queries
- UI rendering
- Location services

## Edge Cases Handled

1. **Timezone Changes:** App uses system DateTime.now(), so timezone changes are automatically reflected
2. **Clock Adjustments:** If user manually adjusts device clock, next timer tick detects the change
3. **App Restart:** Fresh providers created with correct current date
4. **Multiple Day Changes:** If app runs for multiple days, each transition is detected
5. **Date Navigation:** User can still manually navigate dates; only auto-resets when viewing "today"

## Future Enhancements (Optional)

Possible improvements if needed:
1. Add configuration for timer interval
2. Emit events with old/new dates for analytics
3. Add visual notification when day changes (snackbar, animation)
4. Optimize timer to fire at exactly midnight (more complex but more efficient)

## Acceptance Criteria Status

✅ App automatically detects day transitions while running  
✅ Dashboard and data views refresh to show the new day without user restart  
✅ No performance impact from the day-change monitoring  
✅ Works across app suspend/resume cycles  
✅ Handles edge cases (timezone changes, manual clock adjustments)

## Related Files

- `app/lib/core/day_change_notifier.dart` - Core detection logic
- `app/lib/features/food/data/food_repository.dart` - Food tracking providers
- `app/lib/features/workout/data/workout_repository.dart` - Workout providers
- `app/lib/features/tasks/data/tasks_repository.dart` - Tasks/habits providers
- `app/lib/features/home/ui/home_screen.dart` - Home dashboard UI
- `app/test/day_change_notifier_test.dart` - Unit tests
