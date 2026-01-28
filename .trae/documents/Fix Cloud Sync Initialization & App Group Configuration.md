I will fix the Cloud Sync initialization error (SwiftDataError 1) and ensure reliable syncing between macOS and iOS by refactoring the `ModelContainer` configuration to use the standard `groupContainer` API. This will resolve the configuration mismatch causing the error.

### Plan

1.  **Refactor `To_Do_DuckApp.swift`**:
    *   Replace the manual file URL construction with the modern `ModelConfiguration(..., groupContainer: .identifier("group.sdy.tododuck"), ...)` initializer.
    *   This ensures SwiftData automatically handles the correct paths and CloudKit metadata for the App Group.
    *   Preserve the fallback logic for local-only mode if CloudKit fails.
    *   Update the debug info logging to reflect the new managed path.

2.  **Update `TodoWidget/Provider.swift`**:
    *   Apply the same `groupContainer` configuration change to the Widget's `ModelContainer` setup.
    *   This ensures the Widget and Main App continue to share the same database file.

3.  **Update Debug & Reset Logic (`MacProfileView.swift`)**:
    *   Update the "Reset Local Data" logic to target the new file path managed by SwiftData (usually in `Library/Application Support/Shared.store` inside the group container) to ensure the reset function works correctly with the new configuration.

### Technical Details
*   **Why this fixes Error 1**: The error typically occurs when SwiftData attempts to treat a manually managed SQLite file (created without CloudKit) as a CloudKit-mirroring store without proper migration. By switching to the `groupContainer` API, we let SwiftData manage the store location and creation, ensuring a fresh, compatible database structure is created for CloudKit sync.
*   **Note**: This change will effectively start with a **fresh database** on the device. Old local data in the manually managed file will be ignored (but not deleted unless the user resets). This is necessary to clear the "corrupted" state and enable sync. Sync will then pull data from the Cloud if available.
