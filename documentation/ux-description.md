# UX Documentation: GymRat

## Screen Architecture Overview

### Mobile Screens (iOS Priority)
1. **Authentication Screens**
   - Login Screen
   - Sign Up Screen
   - Forgot Password Screen

2. **Onboarding Screens**
   - Profile Setup Screen
   - Goal Setting Screen
   - Macro Targets Screen

3. **Core App Screens**
   - Home Dashboard
   - Food Logging Screen
   - Food Search Screen
   - Barcode Scanner Screen
   - Active Workout Screen
   - Rest Timer Screen
   - Task Management Screen
   - Analytics Dashboard
   - Profile/Settings Screen

### Desktop Web Screens
1. **Routine Setup Wizard**
   - Diet Configuration Screen
   - Meal Templates Screen
   - Workout Templates Screen
   - Daily Tasks Screen
   - Weekly Schedule Screen
   - Review & Activate Screen

---

## Mobile Screen Specifications

### 1. Login Screen
**Purpose**: Authenticate existing users

**Layout**: Vertical stack, centered

**Widgets**:
- Logo/App Name (top)
- Email TextField
  - Placeholder: "Email"
  - Keyboard: Email
- Password SecureField
  - Placeholder: "Password"
  - Show/Hide toggle button
- "Login" Button (primary, full width)
- "Forgot Password?" Link
- Divider with "OR"
- "Sign Up" Button (secondary, full width)

**Navigation**:
- Login → Home Dashboard
- Forgot Password → Forgot Password Screen
- Sign Up → Sign Up Screen

---

### 2. Sign Up Screen
**Purpose**: Create new user account

**Layout**: Vertical stack, scrollable

**Widgets**:
- Back Button (top left)
- "Create Account" Title
- Email TextField
- Password SecureField
  - Password strength indicator below
- Confirm Password SecureField
- "Create Account" Button (primary)
- "Already have an account? Login" Link

**Navigation**:
- Back → Login Screen
- Create Account → Profile Setup Screen
- Login Link → Login Screen

---

### 3. Profile Setup Screen
**Purpose**: Collect user stats for calculations

**Layout**: Form with sections

**Widgets**:
- Progress Indicator (Step 1 of 3)
- "Your Profile" Title
- Age NumberField (years)
- Height Fields:
  - Feet NumberField + Inches NumberField (US)
  - Toggle for cm (metric)
- Weight NumberField (lbs/kg toggle)
- Gender SegmentedControl (Male/Female/Other)
- Activity Level Picker:
  - Sedentary
  - Lightly Active
  - Active
  - Very Active
- "Continue" Button (primary)

**Navigation**:
- Continue → Goal Setting Screen

---

### 4. Goal Setting Screen
**Purpose**: Define fitness goals

**Layout**: Vertical options with descriptions

**Widgets**:
- Progress Indicator (Step 2 of 3)
- "Your Goal" Title
- Goal RadioButtons with descriptions:
  - **Bulk** (+500 calories)
    - "Build muscle and gain weight"
  - **Cut** (-500 calories)
    - "Lose fat while preserving muscle"
  - **Maintain** (±0 calories)
    - "Maintain current weight"
- Body Fat % NumberField (optional)
- "Continue" Button

**Navigation**:
- Continue → Macro Targets Screen
- Back → Profile Setup Screen

---

### 5. Macro Targets Screen
**Purpose**: Set daily macro goals

**Layout**: Vertical form with suggestions

**Widgets**:
- Progress Indicator (Step 3 of 3)
- "Daily Targets" Title
- "Use Suggestions" Button (calculates based on profile)
- Calories Section:
  - Min NumberField
  - Max NumberField
- Protein NumberField (grams)
  - Helper text: "0.8-1g per lb suggested"
- Carbs NumberField (grams)
- Fats NumberField (grams)
- Macro Split Preview (pie chart)
- "Start Using GymRat" Button

**Navigation**:
- Start → Home Dashboard
- Back → Goal Setting Screen

---

### 6. Home Dashboard
**Purpose**: Daily overview and quick actions

**Layout**: Vertical scroll with fixed header

**Widgets**:

**Header Section**:
- Date Display (Today, Monday Oct 23)
- Settings Icon (top right)
- Profile Icon (top left)

**Macro Progress Section** (non-scrolling):
- Circular Progress Rings:
  - Calories: 1,250/2,000 (center number)
  - Protein: 80/150g
  - Carbs: 150/250g
  - Fats: 40/70g
- "Log Food" Button (prominent, full width)

**Today's Tasks Section**:
- Section Title: "Today"
- Task Cards (vertical list):
  - Workout Card (if scheduled):
    - "Push Day" Title
    - "5 exercises" Subtitle
    - "Start Workout" Button or "✓ Completed"
  - Task Cards:
    - Task Name
    - Streak indicator (🔥 5 days)
    - Checkbox or "✓ Completed"

**Quick Add FAB** (floating action button):
- "+" Button (bottom right)
- Expands to:
  - "Log Food"
  - "Start Workout"
  - "Add Task"

**Bottom Tab Bar**:
- Home (selected)
- Analytics
- Profile

**Navigation**:
- Log Food → Food Logging Screen
- Start Workout → Active Workout Screen
- Task Checkbox → Updates state (no navigation)
- Settings → Profile/Settings Screen
- Analytics Tab → Analytics Dashboard
- Profile Tab → Profile/Settings Screen

---

### 7. Food Logging Screen
**Purpose**: Add food to daily log

**Layout**: Tab view with search

**Top Section**:
- Back Button
- "Add Food" Title
- Meal Selector (SegmentedControl):
  - Breakfast | Lunch | Dinner | Snack

**Search Bar**:
- Search TextField
- Barcode Scanner Icon

**Content Tabs**:
- **Recent** (default):
  - List of recent foods with:
    - Food name
    - Brand (if applicable)
    - Last used serving
    - Macros (P/C/F/Cal)
    - "+" Quick add button
- **Search Results**:
  - Similar list format
- **My Foods**:
  - Custom created foods
- **Templates**:
  - Saved meal templates
  - "Add All" button per template

**Selected Foods Section** (bottom sheet):
- Selected items with quantity fields
- Total macros preview
- "Add to Diary" Button

**Navigation**:
- Back → Home Dashboard
- Barcode → Barcode Scanner Screen
- Search → Updates results in same screen
- Add to Diary → Home Dashboard

---

### 8. Food Search Screen
**Purpose**: Search food database

**Layout**: Search with filtered results

**Widgets**:
- Search Bar (auto-focused)
- Cancel Button
- Filter Chips:
  - All | Branded | Generic | My Foods
- Results List:
  - Food name
  - Brand
  - Serving size
  - Macros per serving
- "Create Custom Food" Button (if no results)

**Navigation**:
- Select Food → Food Detail/Quantity Screen
- Cancel → Food Logging Screen
- Create Custom → Custom Food Creation Screen

---

### 9. Barcode Scanner Screen
**Purpose**: Scan product barcodes

**Layout**: Full screen camera

**Widgets**:
- Camera View (full screen)
- Close Button (X, top left)
- Scan Frame Overlay
- Flash Toggle Button
- Manual Entry Button (bottom)
- Status Text ("Point at barcode")

**Auto-behavior**:
- Auto-captures when barcode detected
- Shows loading spinner
- Transitions to Food Detail on success

**Navigation**:
- Close → Food Logging Screen
- Successful Scan → Food Detail Screen
- Manual Entry → Food Search Screen

---

### 10. Active Workout Screen
**Purpose**: Log workout in real-time

**Layout**: Vertical pager for exercises

**Header** (fixed):
- Workout Name
- Timer Display (00:15:23)
- "Finish Workout" Button (top right)

**Exercise Card** (swipeable):
- Exercise Name (large)
- Set Progress (Set 2 of 3)
- Previous Performance Box:
  - "Last Week:"
  - Set 1: 135 × 8
  - Set 2: 135 × 7
  - Set 3: 135 × 6

**Current Set Input**:
- Weight NumberField (pre-filled from last)
  - Large touch targets for +5/-5 buttons
- "×" symbol
- Reps NumberField
  - Large touch targets for +1/-1 buttons
- "Complete Set" Button (primary, large)

**Completed Sets Display**:
- Set 1: 135 × 9 ✓

**Exercise Navigation**:
- Dots indicator (bottom)
- Swipe left/right between exercises
- "Next Exercise" appears after last set

**Navigation**:
- Complete Set → Rest Timer Screen (if rest configured)
- Finish Workout → Workout Summary → Home Dashboard
- Back (with confirmation) → Home Dashboard

---

### 11. Rest Timer Screen
**Purpose**: Time rest between sets

**Layout**: Full screen timer

**Widgets**:
- Large Countdown Display (01:27)
- Circular Progress Ring
- Exercise Name (next set preview)
- "Skip Rest" Button
- "Add 30s" Button
- Sound Toggle

**Auto-behavior**:
- Vibration + sound at 0:00
- Auto-dismisses after alert

**Navigation**:
- Timer Complete → Active Workout Screen
- Skip → Active Workout Screen

---

### 12. Task Management Screen
**Purpose**: View and manage daily tasks

**Layout**: Grouped list by day

**Widgets**:
- "This Week" Title
- Day Sections (collapsible):
  - Monday (Today)
  - Tuesday
  - etc.
- Task Items per day:
  - Checkbox
  - Task name
  - Streak badge
  - Time (if scheduled)
- "Add Task" FAB

**Navigation**:
- Back → Home Dashboard
- Add Task → Task Creation Modal

---

### 13. Analytics Dashboard
**Purpose**: View progress metrics

**Layout**: Scrollable with tabs

**Time Period Selector**:
- SegmentedControl: Day | Week | Month | All

**Tabs**:
- **Diet**:
  - Macro trends graph
  - Average daily intake
  - Protein consistency %
  - Calorie adherence %
  
- **Workouts**:
  - Exercise selector dropdown
  - Weight progression graph
  - Volume chart
  - PR indicators
  - Workout frequency heatmap
  
- **Body**:
  - Weight trend graph
  - Body fat % graph
  - Current vs Starting stats
  
- **Habits**:
  - Task completion calendar
  - Streak overview
  - Consistency scores

**Export Button** (top right)

**Navigation**:
- Back/Tab → Home Dashboard
- Export → Export Options Modal

---

### 14. Profile/Settings Screen
**Purpose**: Manage account and app settings

**Layout**: Grouped list

**Sections**:

**Profile**:
- Edit Profile
- Update Goals
- Adjust Macros

**Data**:
- Export Data
- Import Data

**Preferences**:
- Units (Imperial/Metric)
- First Day of Week
- Default Rest Timer

**Account**:
- Change Password
- Email Preferences
- Sign Out

**About**:
- Version
- Terms
- Privacy Policy
- Support

**Navigation**:
- Each item → Respective detail screen
- Sign Out → Login Screen

---

## Desktop Web Screen Specifications

### 1. Diet Configuration Screen
**Purpose**: Set up nutrition goals

**Layout**: Two-column form

**Left Column - Profile**:
- Height Input (ft/in or cm)
- Weight Input (lbs or kg)
- Age Input
- Gender Select
- Activity Level Select
- Goal Radio Buttons

**Right Column - Targets**:
- Suggested Values Display
- "Apply Suggestions" Button
- Calories Min/Max Inputs
- Protein Input (g)
- Carbs Input (g)
- Fats Input (g)
- Macro Split Visualization

**Actions**:
- "Save & Continue" Button
- "Skip" Link

**Navigation**:
- Continue → Meal Templates Screen
- Skip → Workout Templates Screen

---

### 2. Meal Templates Screen
**Purpose**: Create reusable meal templates

**Layout**: Table with inline editing

**Template Table**:
- Columns: Name | Foods | P | C | F | Cal | Actions
- Add Template Row
- Inline food search
- Quantity inputs
- Delete button per row

**Quick Actions Bar**:
- "Import Common Templates" Button
- "Add Template" Button
- Search existing templates

**Navigation**:
- Save & Continue → Workout Templates Screen
- Back → Diet Configuration Screen

---

### 3. Workout Templates Screen
**Purpose**: Create workout routines

**Layout**: Tab interface with exercise tables

**Workout Tabs**:
- Tab per workout (Push, Pull, Legs, +)
- Rename on double-click

**Exercise Table per Tab**:
- Columns: Exercise | Sets | Reps | Rest | Actions
- Drag handle for reordering
- Inline editing
- Delete button per row
- "Add Exercise" row

**Template Actions**:
- "Duplicate Workout" Button
- "Delete Workout" Button
- "Import Template" Button

**Navigation**:
- Save & Continue → Daily Tasks Screen
- Back → Meal Templates Screen

---

### 4. Daily Tasks Screen
**Purpose**: Set up recurring tasks

**Layout**: Task grid with day checkboxes

**Task Grid**:
- Columns: Task Name | Mon | Tue | Wed | Thu | Fri | Sat | Sun | Actions
- Checkbox per day
- Inline task name editing
- Delete button per row
- "Add Task" row

**Bulk Actions**:
- "Select All Days" per task
- "Clear All" per task

**Navigation**:
- Save & Continue → Weekly Schedule Screen
- Back → Workout Templates Screen

---

### 5. Weekly Schedule Screen
**Purpose**: Assign workouts and tasks to days

**Layout**: Calendar week view

**Week Calendar**:
- Column per day
- Workout dropdown per day
- Task list (from Daily Tasks)
- Add/remove tasks per day
- "Copy Week" Button

**Preview Section**:
- Shows selected day details
- Estimated time commitment

**Navigation**:
- Save & Continue → Review Screen
- Back → Daily Tasks Screen

---

### 6. Review & Activate Screen
**Purpose**: Confirm and activate routine

**Layout**: Summary cards

**Summary Sections**:
- Diet Overview Card
- Weekly Workout Schedule Card
- Daily Tasks Summary Card
- Total Time Commitment

**Actions**:
- "Edit" button per section
- "Save as Draft" Button
- "Activate Routine" Button (primary)

**Post-Activation**:
- QR code for app download
- "Open Dashboard" Button

**Navigation**:
- Edit → Respective screen
- Activate → Dashboard or App Download

---

## Screen Flow Diagrams

### New User Flow
```
Login → Sign Up → Profile Setup → Goal Setting → Macro Targets → Home Dashboard
```

### Daily Food Logging Flow
```
Home Dashboard → Food Logging → [Search/Scan/Recent] → Add Quantity → Home Dashboard
```

### Workout Flow
```
Home Dashboard → Active Workout → [Set Input → Rest Timer] × N → Workout Summary → Home Dashboard
```

### Desktop Setup Flow
```
Login → Setup Routine → Diet Config → Meal Templates → Workout Templates → Daily Tasks → Weekly Schedule → Review → Activate
```

---

## Widget Design Patterns

### Input Fields
- **Number Fields**: Large +/- buttons for touch
- **Text Fields**: Clear button when filled
- **All Inputs**: Minimum 44pt touch targets

### Buttons
- **Primary**: Full width, colored, large text
- **Secondary**: Outlined or text only
- **FAB**: 56pt minimum, bottom right

### Progress Indicators
- **Rings**: For macro tracking
- **Bars**: For linear progress
- **Dots**: For pagination

### Lists
- **Swipe Actions**: Delete, edit
- **Pull to Refresh**: Where applicable
- **Infinite Scroll**: For large datasets

### Feedback
- **Loading**: Spinner or skeleton screens
- **Success**: Green checkmark animation
- **Error**: Red text below inputs
- **Empty States**: Illustration + message + action

---

## Accessibility Considerations

- **Touch Targets**: Minimum 44×44 pt
- **Contrast**: WCAG AA compliant
- **Text Size**: Adjustable, minimum 14pt
- **VoiceOver**: Full support with labels
- **Haptics**: For timers and completions
- **Color Blind**: Not solely color-dependent