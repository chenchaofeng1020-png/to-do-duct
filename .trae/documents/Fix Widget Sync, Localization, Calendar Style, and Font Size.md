I have identified the root causes for the reported issues and have a clear plan to fix them.

### 1. Widget Sync Issue
**Root Cause**: There is a **Schema Mismatch** between the main app and the widget.
- `To_Do_DuckApp.swift` initializes SwiftData with `[DailyCardV3, TodoItemV3, MemoCardV3]`.
- `Provider.swift` (Widget) initializes SwiftData with `[DailyCardV3, TodoItemV3, MemoCardV3, RepeatRule]`.
- This mismatch can prevent the Widget from correctly opening or reading the shared database store.

**Fix**:
- Add `RepeatRule.self` to the Schema in `To_Do_DuckApp.swift` to ensure both targets use the exact same data model definition.

### 2. Localization Missing
**Root Cause**: The keys `next_monday` and `confirm_continuation` are used in the code but missing from the translation file.

**Fix**:
- Add the following entries to `Localizable.xcstrings`:
    - `next_monday`: "下周一" (zh-Hans), "Next Monday" (en)
    - `confirm_continuation`: "确认延后" (zh-Hans), "Confirm" (en)

### 3. "Add One Day" Calendar Style
**Root Cause**: The calendar cells are too small (`28x28`) and tightly packed (`spacing: 4`), causing the calendar to look "flattened" or squashed in the new sheet layout.

**Fix**:
- In `CustomCalendarView.swift`:
    - Increase `DayCell` size from `28` to `32`.
    - Increase grid spacing from `4` to `8` to give it more breathing room.

### 4. Font Size Adjustment
**Root Cause**: The body text font size is currently hardcoded to `14` in both iOS and Mac views.

**Fix**:
- **iOS (`MainView.swift`)**: Update `TodoItemRowNew` font size from `14` to `15`.
- **Mac (`MacTodoHomeView.swift`)**: Update `MacTodoItemView` font size from `14` to `15`.
