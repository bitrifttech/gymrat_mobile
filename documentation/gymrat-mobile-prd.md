# Product Requirements Document: GymRat

## Executive Summary
GymRat is a mobile-first fitness tracking application focused on simplicity and effectiveness. It combines diet tracking with workout logging to help users meet their protein targets, manage calories, and progressively improve their strength training performance.
Implemented as a Flutter (Dart) mobile application for iOS and Android.

## Product Vision
Create the simplest, most efficient fitness tracking app that helps users:
- Track macronutrients (protein, carbs, fats) and calories
- Log and progress in their workouts
- Build consistent healthy habits
- View straightforward analytics on their progress

## Core Principles
- **Mobile-first**: Optimized for quick entry during workouts and meals
- **Minimal clicks**: Every core action should be achievable with minimal taps
- **Progressive tracking**: Always show users what they need to beat
- **Simple analytics**: Clear, actionable insights without overwhelming data

## User Personas

### Primary User
- **Age**: 18-45
- **Tech comfort**: Moderate to high
- **Goals**: Build muscle, lose fat, or maintain weight while tracking protein intake
- **Pain points**: Complex fitness apps, too many features, difficult food entry
- **Needs**: Quick workout logging, easy food tracking, clear progress visibility

## Feature Requirements

### 1. User Management

#### 1.1 Account System
- Email/password authentication
- Basic profile setup:
  - Height
  - Current weight
  - Age
  - Gender
  - Activity level
  - Goal (bulk/cut/maintain)

#### 1.2 Goal Setting
- Manual target setting for:
  - Daily calories (min/max based on goal)
  - Protein (grams)
  - Carbohydrates (grams)
  - Fats (grams)
- "Suggest targets" feature that calculates recommendations based on:
  - User stats (height, weight, age, gender)
  - Selected goal (bulk/cut/maintain)
  - Activity level

### 2. Home Dashboard

#### 2.1 Daily Overview
Display upon app open:
- Macronutrient progress rings/bars:
  - Calories consumed vs target
  - Protein consumed vs minimum
  - Carbs and fats vs targets
- Today's tasks checklist:
  - Scheduled workout (if any)
  - Custom daily tasks (meditation, bible study, etc.)
  - Completion checkmarks

#### 2.2 Quick Actions
- "Log Food" button
- "Start Workout" (if scheduled)
- "Complete Task" buttons for each daily task

### 3. Diet Tracking

#### 3.1 Food Entry Methods
- **Recent foods**: Quick-select from previously logged items
- **Barcode scanner**: Scan packaged foods
- **Search**: Query external food database API
- **Custom entry**: Manual macro input

#### 3.2 Meal Logging Flow
1. Select meal type (breakfast/lunch/dinner/snack)
2. Add foods via any entry method
3. Specify quantity:
   - Servings
   - Grams/ounces
   - Milliliters
   - Cups/tablespoons
4. Multi-select capability for adding multiple foods at once
5. Save meal as template option

#### 3.3 Meal Templates
- Save frequently eaten meals
- Quick-add entire meal with one tap
- Edit quantities when adding template

#### 3.4 Food Database
- Integrate with existing API (USDA, Nutritionix, or similar)
- Cache frequently used foods locally
- Allow custom food creation

### 4. Workout Tracking

#### 4.1 Workout Creation (Mobile-first)
- Add exercises with:
  - Exercise name
  - Target sets
  - Target reps
  - Rest time between sets
- Save as workout template
- Assign to specific days of the week

#### 4.2 Active Workout Flow
1. Tap workout task from home screen
2. Workout timer starts automatically
3. For each exercise, display:
   - Exercise name
   - Last week's performance (weight × reps for each set)
   - Input fields for current set:
     - Weight
     - Reps
   - "Start Rest" button after set completion
4. Rest timer:
   - Countdown based on pre-set rest time
   - Audio/haptic alert when complete
   - "Skip" option to end early
5. "Finish Workout" saves all data with timestamp

#### 4.3 Workout History
- View completed workouts by date
- See all sets/reps/weight for each session
- Track total workout duration

#### 4.4 Exercise Management
- User-created exercise library
- No pre-populated exercises initially
- Simple add/edit/delete functionality

### 5. Daily Tasks & Habits

#### 5.1 Task Creation
- Custom task name (yoga, meditation, bible study, etc.)
- Recurring schedule by day of week
- One-time/ad-hoc tasks

#### 5.2 Task Completion
- Single tap to mark complete from home screen
- Visual feedback (checkmark, color change)
- Completion timestamp

#### 5.3 Streak Tracking
- Display current streak for each recurring task
- Streak recovery (miss one day without breaking)
- Visual indicators for milestones

### 6. Analytics & Progress

#### 6.1 Metrics Dashboard
Time periods: Daily, Weekly, Monthly, All-time

**Workout Metrics:**
- Weight progression per exercise (line graphs)
- Total volume per exercise
- Personal records (PRs) for each exercise
- Workout frequency/consistency

**Diet Metrics:**
- Macronutrient intake over time
- Calorie trends
- Protein consistency percentage
- Average daily macros

**Body Metrics:**
- Weight trend
- Body fat percentage trend
- Progress indicators (gaining/losing/maintaining)

**Habit Metrics:**
- Task completion rates
- Streak calendars
- Consistency scores

#### 6.2 Data Export
- CSV export for all data
- PDF reports for specific date ranges
- Include all workouts, meals, and measurements

### 7. Platform-Specific Features

#### 7.1 Mobile (Flutter: iOS and Android)
- Optimized for one-handed use
- Large tap targets for gym use
- Swipe gestures for quick navigation
- Number pad for weight/rep entry
- Barcode scanner using camera
- Bulk exercise/workout creation (mobile-friendly editors)
- Meal template management
- Custom food database management
- Analytics deep-dive views
- Data export functions

## User Journeys

### Journey 1: Daily App Opening
**Goal**: Check daily progress and see what needs to be done
**Target**: 0 clicks to view, 1 click to act

1. **Open app** → Immediately see home dashboard
2. **View at a glance**:
   - Macro progress bars (calories: 1,200/2,000, protein: 80/150g)
   - Today's incomplete tasks with clear buttons:
     - "Start Push Day Workout" (if not done)
     - "✓ Bible Study" (if completed, grayed out)
     - "Complete Meditation"
3. **Single tap** any button to begin that activity

### Journey 2: Logging Food (Quick Add)
**Goal**: Add food with minimal friction
**Target**: 3-4 taps for recent foods, 5-6 for new foods

#### Path A: Recent Food (3 taps)
1. **Tap** "Log Food" from home screen
2. **Tap** meal type (Breakfast/Lunch/Dinner/Snack) 
3. **Tap** recent food item (shows last 20 foods with serving size)
4. **Tap** "Add" (uses same serving as last time)
   - Optional: Adjust quantity before adding

#### Path B: Barcode Scan (4 taps)
1. **Tap** "Log Food" from home screen
2. **Tap** "Scan Barcode" icon
3. **Point** camera at barcode (auto-captures)
4. **Enter** serving amount
5. **Tap** "Add to [current meal]"

#### Path C: Search Food (5 taps)
1. **Tap** "Log Food" from home screen
2. **Type** food name in search bar
3. **Tap** correct food from results
4. **Enter** serving amount
5. **Tap** meal type
6. **Tap** "Add"

### Journey 3: Working Out
**Goal**: Complete workout with progressive overload tracking
**Target**: 2 taps per set + rest timer

1. **From home**: Tap "Start Push Day Workout"
2. **Workout begins** (timer starts automatically)
3. **First exercise appears**: "Bench Press"
   - Shows last week: Set 1: 135×8, Set 2: 135×7, Set 3: 135×6
4. **Complete Set 1**:
   - Pre-filled with 135 lbs (last week's weight)
   - **Tap** reps field → enter "9" 
   - **Tap** "Complete Set & Rest"
5. **Rest timer starts** (90 seconds, pre-configured)
   - Shows countdown prominently
   - Alert when complete
6. **Complete remaining sets** (same flow)
7. **Swipe** to next exercise
8. **After last exercise**: Tap "Finish Workout"
   - Shows summary: Duration, total volume, PRs hit

### Journey 4: Completing a Daily Task
**Goal**: Mark daily habits as complete
**Target**: 1 tap

1. **From home screen**: See "Complete Meditation" button
2. **Tap** the button
3. **Button changes** to "✓ Meditation" (grayed out)
4. **Streak updates** if applicable (+1 day)

### Journey 5: Routine Setup (Mobile, Initial Configuration)
**Goal**: Set up entire weekly routine from mobile
**Target**: Streamlined wizard-style setup with tap-first interaction

#### Step 1: Login & Navigate
1. **Open app and log in**
2. **Tap** "Setup Routine" button (prominent on dashboard)
   - Alternative: Menu → "Routine Setup"

#### Step 2: Diet Configuration
1. **Profile & Goals Section**:
   - Enter/confirm stats: Height, weight, age, gender
   - Select activity level: Sedentary/Lightly Active/Active/Very Active
   - Choose goal: Bulk (+500 cal) / Cut (-500 cal) / Maintain
2. **Macro Targets Section**:
   - Auto-calculated suggestions appear based on stats
   - Each field is editable:
     - Calories: Min [2000] Max [2200] 
     - Protein: Min [150g] (0.8g per lb shown as hint)
     - Carbs: Target [250g]
     - Fats: Target [70g]
   - "Use Suggestions" button to reset to calculated values
3. **Tap** "Save & Continue"

#### Step 3: Meal Templates Setup
1. **Quick Add Common Meals**:
   - Table view with inline editing:
     ```
     Template Name    |  Foods                      | Macros (P/C/F/Cal)
     ----------------|-----------------------------|-------------------
     Morning Oats    | [+ Add Food]                | Auto-calculated
     Chicken & Rice  | [+ Add Food]                | Auto-calculated
     Protein Shake   | [+ Add Food]                | Auto-calculated
     ```
2. **Adding foods to template**:
   - Tap "Add Food" → Search modal appears
   - Type to search → Select food → Enter quantity
   - Tap "Add Another" to add another food
   - Tap "Done" to close and save
3. **Bulk actions**:
   - "Import Common Templates" button for preset meals
   - "Copy Template" to duplicate and modify
4. **Click** "Save & Continue" (templates are optional)

#### Step 4: Workout Templates Creation
1. **Create Multiple Workout Templates**:
   - Tabs for each workout: [Push] [Pull] [Legs] [+ Add Workout]
2. **For each workout tab**:
   ```
   Workout Name: [Push Day]
   
   Exercise         | Sets | Target Reps | Rest Time
   ----------------|------|-------------|----------
   Bench Press     |  3   |    8-10     |   90s
   Overhead Press  |  3   |    8-10     |   90s  
   Incline DB Press|  3   |    10-12    |   75s
   Lateral Raises  |  4   |    12-15    |   60s
   Tricep Dips     |  3   |    10-12    |   60s
   [+ Add Exercise]
   ```
3. **Quick entry mode**:
   - Type exercise name → Next → Enter sets → Next → Enter reps → Next → Enter rest → Add Row
   - Drag handles to reorder exercises
4. **Template options**:
   - "Duplicate Workout" to create variations
   - "Import from Library" (if we add community templates later)
5. **Click** "Save & Continue"

#### Step 5: Daily Tasks Configuration
1. **Add Recurring Tasks**:
   ```
   Task Name        | Mon | Tue | Wed | Thu | Fri | Sat | Sun |
   ----------------|-----|-----|-----|-----|-----|-----|-----|
   Bible Study     | ✓   | ✓   | ✓   | ✓   | ✓   | ✓   | ✓   |
   Meditation      | ✓   |     | ✓   |     | ✓   |     |     |
   Yoga            |     | ✓   |     | ✓   |     | ✓   |     |
   Walk 10k Steps  | ✓   | ✓   | ✓   | ✓   | ✓   | ✓   | ✓   |
   Stretching      | ✓   | ✓   | ✓   | ✓   | ✓   |     |     |
   [+ Add Task]
   ```
2. **Quick controls**:
   - Click task name to edit
   - Click checkboxes to toggle days
   - "Select All" / "Clear All" buttons per row
   - Drag to reorder tasks
3. **Click** "Save & Continue"

#### Step 6: Weekly Schedule Assignment
1. **Visual Calendar View**:
   ```
   Monday    | Tuesday   | Wednesday | Thursday  | Friday    | Saturday  | Sunday
   ----------|-----------|-----------|-----------|-----------|-----------|----------
   Push Day  | Pull Day  | Legs      | Push Day  | Pull Day  | Rest      | Rest
   ↓         | ↓         | ↓         | ↓         | ↓         |           |
   [Change]  | [Change]  | [Change]  | [Change]  | [Change]  | [+ Add]   | [+ Add]
   
   ✓ Bible Study     ✓ Bible Study    ✓ Bible Study    (auto-populated from Step 5)
   ✓ Walk 10k        ✓ Yoga           ✓ Meditation
   ✓ Stretching      ✓ Walk 10k       ✓ Walk 10k
                     ✓ Stretching     ✓ Stretching
   ```
2. **Workout Assignment**:
   - Tap "Change" dropdown → Select from workout templates
   - Or drag workout templates from a mobile drawer to days
   - "Copy Week" button to duplicate weekly schedule
3. **Tasks auto-populate** based on Step 5 selections
4. **Quick adjustments**:
   - Toggle individual tasks on/off for specific days
   - "Add One-time Task" for specific day
5. **Tap** "Save & Continue"

#### Step 7: Review & Activate
1. **Complete Routine Summary**:
   - Diet targets overview
   - Weekly workout schedule
   - Daily tasks summary
   - Estimated weekly time commitment
2. **Actions**:
   - "Edit" buttons for each section to go back
   - "Save as Draft" to finish later
   - "Activate Routine" to start using immediately
3. **Post-activation**:
   - "View Today's Plan" to see immediate tasks

#### Alternative: Quick Setup Mode
**For experienced users** - Single page view:
1. **All sections visible** in accordion layout
2. **Quick actions**:
   - Tap section headers to jump between sections
   - Swipe/scroll for navigation
   - Tap to save section
3. **Import/Export**:
   - "Import Routine" from JSON/CSV
   - "Export Routine" for backup or sharing
4. **Templates**:
   - "Start from Template": PPL, Upper/Lower, Full Body
   - Pre-fills everything, user just tweaks

### Journey 6: Quick Workout Addition (Ad-hoc)
**Goal**: Add an unscheduled workout
**Target**: 2 taps to start

1. **From home**: Tap "+" button
2. **Select** "Start Custom Workout"
3. **Choose** from templates or "Empty Workout"
4. **Proceed** with normal workout flow

## Technical Requirements

### Backend
- User authentication system
- RESTful API for data sync
- PostgreSQL or similar for data storage
- Integration with food database API
- Real-time sync between devices

### Mobile (Flutter)
- Flutter (Dart) cross-platform (iOS and Android)
- Local storage: SQLite (sqflite) or Hive
- Camera and barcode scanning via Flutter plugins
- Haptic feedback and vibration support
- Drag-and-drop style interactions for schedule building
- HealthKit/Google Fit integration (future)

## Success Metrics
- Daily active users
- Workout completion rate
- Food logging consistency (% of days logged)
- User retention (30-day, 90-day)
- Average time to log workout: <30 seconds per set
- Average time to log meal: <15 seconds for recent, <30 seconds for new
- Setup completion rate: >80% of users who start setup
- Time to complete setup: <10 minutes for full setup

## MVP Scope

### Phase 1 (Launch)
- User authentication
- Basic profile and goal setting
- Food logging (all methods)
- Workout creation and logging
- Home dashboard
- Basic analytics (weekly view)
- Mobile routine setup wizard

### Phase 2 (Post-launch)
- Meal templates
- Workout templates  
- Streak tracking
- Extended analytics
- Data export
- Body weight/fat percentage tracking

### Phase 3 (Future)
- Community workout templates
- Advanced analytics
- HealthKit/Google Fit integration
- Premium features

## Out of Scope (Current Version)
- Water tracking
- Progress photos
- Body measurements beyond weight/body fat
- Exercise instruction videos
- Automated progression suggestions
- Social features
- Push notifications
- Offline mode

## Design Principles
- **Clarity**: Every number and metric should be immediately understandable
- **Speed**: Optimize for quick entry during workouts and meals
- **Focus**: Show only essential information on each screen
- **Progress**: Always display what users need to beat or maintain
- **Consistency**: Uniform interaction patterns across all features
- **Accessibility**: Large touch targets, clear contrast, simple navigation

## Risk Mitigation
- **Food database API limits**: Cache frequently used foods locally
- **User drop-off during setup**: Provide templates and quick-start options
- **Complexity creep**: Regular user testing to ensure simplicity
- **Data loss**: Regular backups and sync status indicators

## Success Criteria
- Users can log a meal in under 15 seconds
- Users can complete a workout set in under 30 seconds
- 80% of users complete initial setup
- 60% daily active user rate after 30 days
- Average app rating of 4.5+ stars