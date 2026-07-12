# HealthKit Local Store Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. User explicitly requested implementation without subagents.

**Goal:** Make the iPhone app read workouts from one local phone store that can be populated by Apple Health, Garmin official export ZIP, or Garmin official export folder imports.

**Architecture:** Introduce a normalized `TrainingActivity` domain model with seconds/meters/kcal units, then migrate current UI/calculators from `GarminActivity` to `TrainingActivity`. Add a JSON-backed local store with mandatory deduplication before writes. Add HealthKit and Garmin import services that merge into the store and refresh the dashboard.

**Tech Stack:** SwiftUI, Foundation, HealthKit, UniformTypeIdentifiers, zlib, Swift Testing, Xcode file-system synchronized groups.

## Global Constraints

- Do not modify `from_garmin_official_export`.
- Do not commit raw training history files or newly generated sensitive data files.
- Keep Garmin official export raw ZIP/folder contents temporary on device; persist only normalized activities in app sandbox.
- Apple Health is the primary source. Garmin ZIP/folder imports only add new activities and fill missing fields for duplicates.
- UI must continue to support the existing tabs, shared period/type filters, chart scale controls, and training cards.
- No subagents for this implementation.

---

### Task 1: Normalized Activity Model And Deduplication

**Files:**
- Create: `SportApp/TrainingActivity.swift`
- Create: `SportApp/TrainingActivityDeduplicator.swift`
- Test: `SportAppTests/TrainingActivityStoreTests.swift`

**Interfaces:**
- Produces `TrainingActivity`, `TrainingActivitySource`, `TrainingActivitySourceReference`, `TrainingImportSummary`.
- Produces `TrainingActivityDeduplicator.merge(existing:incoming:) -> TrainingImportResult`.

- [x] Add failing tests proving exact source-id duplicates are skipped, HealthKit beats Garmin on conflict, Garmin fills empty fields, and near-match duplicate detection works.
- [x] Implement the normalized model with seconds, meters, kcal, `Date`, `UUID`, and source references.
- [x] Implement the deduplicator and import summary.
- [x] Run `xcodebuild test`.

### Task 2: Local JSON Store And Garmin Mapping

**Files:**
- Create: `SportApp/LocalTrainingActivityStore.swift`
- Create: `SportApp/GarminTrainingActivityImporter.swift`
- Modify: `SportApp/GarminActivity.swift`
- Test: `SportAppTests/TrainingActivityStoreTests.swift`
- Test: `SportAppTests/GarminActivitiesLoaderTests.swift`

**Interfaces:**
- Produces `LocalTrainingActivityStore.loadActivities()`, `saveActivities(_:)`, `merge(_:)`.
- Produces `GarminOfficialExportImporter.importFolder(at:)`, `importZip(at:)`, and `importBundledActivities()`.

- [x] Add failing tests for JSON store persistence and Garmin unit conversion from milliseconds/centimeters to seconds/meters.
- [x] Implement local JSON persistence in Application Support by default, with injectable file URL for tests.
- [x] Implement Garmin mapping from existing export JSON into `TrainingActivity`.
- [x] Implement folder import by recursively scanning `.json` files and decoding Garmin summarized activity exports.
- [x] Implement ZIP import by reading JSON entries from stored or deflated ZIP files.
- [x] Run targeted tests, then full tests.

### Task 3: Migrate Calculators And Cards To TrainingActivity

**Files:**
- Modify: `SportApp/TrainingActivityFilter.swift`
- Modify: `SportApp/TrainingActivityListBuilder.swift`
- Modify: `SportApp/TrainingActivityPresentation.swift`
- Modify: `SportApp/WeeklyEffortCalculator.swift`
- Modify: `SportApp/TodayEffortCalculator.swift`
- Modify: tests using `GarminActivity` fixtures.

**Interfaces:**
- Existing UI-facing APIs keep the same names where possible, but consume `[TrainingActivity]`.

- [x] Update tests to build `TrainingActivity` fixtures and verify existing chart/list behavior still passes.
- [x] Migrate filters, categories, list builder, presentation, and weekly effort math to normalized units.
- [x] Keep Garmin decoding tests for the raw export model.
- [x] Run full tests.

### Task 4: HealthKit Source

**Files:**
- Create: `SportApp/HealthKitTrainingActivitySource.swift`
- Modify: `Config/SportApp-Info.plist`
- Create: `SportApp/SportApp.entitlements`
- Modify: `SportApp.xcodeproj/project.pbxproj`

**Interfaces:**
- Produces `HealthKitTrainingActivitySource.requestAuthorizationAndFetch() async throws -> [TrainingActivity]`.

- [x] Add HealthKit privacy strings and entitlement.
- [x] Implement authorization and workout fetch.
- [x] Map HKWorkout to `TrainingActivity` using duration seconds, total distance meters, active/total energy kcal, and HealthKit UUID.
- [x] Build for simulator and generic iOS.

### Task 5: Dashboard Store, Settings, Imports

**Files:**
- Modify: `SportApp/SportDashboardView.swift`
- Modify: `SportApp/TrainingListView.swift`
- Modify: `SportApp/WeeklyEffortView.swift`

**Interfaces:**
- Dashboard owns store-backed `[TrainingActivity]`.
- Settings sheet exposes Health sync, Garmin ZIP import, Garmin folder import, and import status.

- [x] Load local store on launch.
- [x] If store is empty, seed from bundled Garmin JSON so existing history still appears.
- [x] Add settings button and sheet.
- [x] Add Health sync action that merges HealthKit workouts into local store.
- [x] Add file importer for `.zip` and `.folder`, merge imported activities, and show added/skipped/updated/errors status.
- [x] Run tests and build.

### Task 6: Documentation And Verification

**Files:**
- Modify: `docs/steps_human.md`

- [x] Record final answer for step 46.
- [x] Run `git diff --check`.
- [x] Check changed files do not include raw Garmin export or new training-history data files.
- [x] Report build/test results and any limitation.
