# Connected Services Documentation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an in-app documentation section that opens from the dashboard and explains the fields SportApp can receive from Apple Health and Garmin Connect.

**Architecture:** Add a static read-only documentation catalog in app code, backed by tests that lock the Apple Health integration fields and Garmin export field inventory. Render the catalog in a SwiftUI sheet with a `NavigationStack`, accessible from a new icon beside the settings button.

**Tech Stack:** Swift, SwiftUI, HealthKit field names, SF Symbols, Swift Testing, XCTest UI tests, Xcode file-system synchronized groups.

## Global Constraints

- Do not modify `from_garmin_official_export`.
- Do not commit raw training history, Garmin ZIP files, FIT/TCX/GPX files, local app store JSON, provisioning profiles, or other sensitive data files.
- The Garmin documentation catalog must contain field names, Russian labels, descriptions, and supported activity types only. It must not contain concrete workout values, dates, activity IDs, coordinates, email addresses, or user-specific records.
- Apple Health documentation must describe only fields currently used by `SportApp/HealthKitTrainingActivitySource.swift`, not the whole HealthKit API.
- Keep user-facing documentation text in Russian.
- Keep the existing dashboard tabs, period/type filters, settings sheet, and import flows unchanged.
- No runtime reading from `from_garmin_official_export` for the documentation screen.

---

### Task 1: Add Catalog Tests First

**Files:**
- Create: `SportAppTests/ConnectedServiceDocumentationCatalogTests.swift`

**Interfaces under test:**
- `ConnectedServiceDocumentationCatalog.services`
- `ConnectedServiceDocumentationCatalog.appleHealth`
- `ConnectedServiceDocumentationCatalog.garminConnect`
- `ConnectedServiceDocumentation.allFields`
- `ServiceDocumentationField.systemName`
- `ServiceDocumentationField.supportedTypes`

- [ ] Add `ConnectedServiceDocumentationCatalogTests` with `import Testing` and `@testable import SportApp`.
- [ ] Add `catalogContainsAppleHealthAndGarminConnect()`:
  - `ConnectedServiceDocumentationCatalog.services.map(\.id)` equals `["appleHealth", "garminConnect"]`.
  - `ConnectedServiceDocumentationCatalog.services.map(\.title)` equals `["Apple Health", "Garmin Connect"]`.
- [ ] Add `appleHealthCatalogContainsCurrentIntegrationFieldsOnly()` with exact expected field names:

```swift
[
    "HKWorkout.uuid",
    "HKWorkout.workoutActivityType",
    "HKWorkout.startDate",
    "HKWorkout.duration",
    "HKQuantityTypeIdentifier.activeEnergyBurned",
    "HKWorkout.totalDistance / distanceWalkingRunning",
    "HKWorkout.totalDistance / distanceCycling",
    "HKWorkout.totalDistance / distanceSwimming",
    "HKMetadataKeySwimmingLocationType",
    "HKMetadataKeyLapLength"
]
```

- [ ] Add `garminCatalogContainsOneHundredThirtyTwoFields()`:
  - `ConnectedServiceDocumentationCatalog.garminConnect.allFields.count == 132`.
- [ ] Add `garminCatalogContainsAllObservedActivityTypes()` with exact expected type ids:

```swift
[
    "cycling",
    "elliptical",
    "indoor_cardio",
    "indoor_cycling",
    "lap_swimming",
    "meditation",
    "open_water_swimming",
    "other",
    "running",
    "stand_up_paddleboarding_v2",
    "strength_training",
    "walking"
]
```

- [ ] Add `poolLengthSupportsLapSwimming()`:
  - Find Garmin field `poolLength`.
  - Assert `supportedTypes.map(\.id)` contains `lap_swimming`.
- [ ] Add `appleHealthLapLengthSupportsPoolSwimming()`:
  - Find Apple Health field `HKMetadataKeyLapLength`.
  - Assert `supportedTypes.map(\.id)` contains `lap_swimming`.
- [ ] Add `garminCatalogContainsExactObservedFieldNames()` using this exact expected set:

```swift
[
    "activeLengths",
    "activeSets",
    "activityId",
    "activityTrainingLoad",
    "activityType",
    "aerobicTrainingEffect",
    "aerobicTrainingEffectMessage",
    "anaerobicTrainingEffect",
    "anaerobicTrainingEffectMessage",
    "atpActivity",
    "autoCalcCalories",
    "avgBikeCadence",
    "avgDoubleCadence",
    "avgFractionalCadence",
    "avgGradeAdjustedSpeed",
    "avgGroundContactTime",
    "avgHr",
    "avgPower",
    "avgRespirationRate",
    "avgRunCadence",
    "avgSpeed",
    "avgStress",
    "avgStrideLength",
    "avgStrokeCadence",
    "avgStrokeDistance",
    "avgStrokes",
    "avgSwimCadence",
    "avgSwolf",
    "avgVerticalOscillation",
    "avgVerticalRatio",
    "beginTimestamp",
    "bmrCalories",
    "calories",
    "decoDive",
    "description",
    "deviceId",
    "differenceBodyBattery",
    "differenceStress",
    "distance",
    "duration",
    "elapsedDuration",
    "elevationCorrected",
    "elevationGain",
    "elevationLoss",
    "endLatitude",
    "endLongitude",
    "endStress",
    "eventTypeId",
    "favorite",
    "floorsClimbed",
    "floorsDescended",
    "hrTimeInZone_0",
    "hrTimeInZone_1",
    "hrTimeInZone_2",
    "hrTimeInZone_3",
    "hrTimeInZone_4",
    "hrTimeInZone_5",
    "hrTimeInZone_6",
    "intensityFactor",
    "isRunPowerWindDataEnabled",
    "jumpCount",
    "lapCount",
    "locationName",
    "manufacturer",
    "max20MinPower",
    "maxBikeCadence",
    "maxDoubleCadence",
    "maxElevation",
    "maxFractionalCadence",
    "maxHr",
    "maxLatitude",
    "maxLongitude",
    "maxPower",
    "maxRespirationRate",
    "maxRunCadence",
    "maxSpeed",
    "maxStress",
    "maxStrokeCadence",
    "maxSwimCadence",
    "maxTemperature",
    "maxVerticalSpeed",
    "minElevation",
    "minHr",
    "minLatitude",
    "minLongitude",
    "minRespirationRate",
    "minTemperature",
    "moderateIntensityMinutes",
    "movingDuration",
    "name",
    "normPower",
    "parent",
    "poolLength",
    "powerTimeInZone_0",
    "powerTimeInZone_1",
    "powerTimeInZone_2",
    "powerTimeInZone_3",
    "powerTimeInZone_4",
    "powerTimeInZone_5",
    "powerTimeInZone_6",
    "powerTimeInZone_7",
    "pr",
    "purposeful",
    "rule",
    "runPowerWindDataEnabled",
    "splitSummaries",
    "splits",
    "sportType",
    "startLatitude",
    "startLongitude",
    "startStress",
    "startTimeGmt",
    "startTimeLocal",
    "steps",
    "strokes",
    "summarizedDiveInfo",
    "summarizedExerciseSets",
    "surfaceInterval",
    "timeZoneId",
    "totalReps",
    "totalSets",
    "trainingEffectLabel",
    "trainingStressScore",
    "userProfileId",
    "uuidLsb",
    "uuidMsb",
    "vO2MaxValue",
    "vigorousIntensityMinutes",
    "waterEstimated",
    "workoutFeel",
    "workoutId",
    "workoutRpe"
]
```

- [ ] Run the failing targeted test:

```bash
xcodebuild test -project SportApp.xcodeproj -scheme SportApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .temp/ConnectedServicesDocsDerivedData -only-testing:SportAppTests/ConnectedServiceDocumentationCatalogTests
```

**Expected result before implementation:** compile failure because `ConnectedServiceDocumentationCatalog` does not exist.

### Task 2: Implement The Static Documentation Catalog

**Files:**
- Create: `SportApp/ConnectedServiceDocumentationCatalog.swift`

**Interfaces:**

```swift
struct ConnectedServiceDocumentation: Identifiable, Equatable {
    let id: String
    let title: String
    let summary: String
    let sections: [ServiceDocumentationSection]

    var allFields: [ServiceDocumentationField] { get }
}

struct ServiceDocumentationSection: Identifiable, Equatable {
    let id: String
    let title: String
    let fields: [ServiceDocumentationField]
}

struct ServiceDocumentationField: Identifiable, Equatable {
    let systemName: String
    let humanName: String
    let description: String
    let supportedTypes: [SupportedTrainingType]

    var id: String { get }
}

struct SupportedTrainingType: Identifiable, Equatable, Hashable, Comparable {
    let id: String
    let title: String
}

enum ConnectedServiceDocumentationCatalog {
    static let services: [ConnectedServiceDocumentation]
    static let appleHealth: ConnectedServiceDocumentation
    static let garminConnect: ConnectedServiceDocumentation
}
```

- [ ] Add `SupportedTrainingType` canonical values with these Russian titles:
  - `cycling` -> `Велик`
  - `indoor_cycling` -> `Велик`
  - `running` -> `Бег`
  - `walking` -> `Ходьба`
  - `lap_swimming` -> `Бассейн`
  - `open_water_swimming` -> `Плавание Море`
  - `swimming` -> `Плавание`
  - `strength_training` -> `Силовая`
  - `elliptical` -> `Эллипс`
  - `stand_up_paddleboarding_v2` -> `SUP`
  - `indoor_cardio` -> `Кардио`
  - `meditation` -> `Медитация`
  - `other` -> `Другое`
- [ ] Implement `Comparable` by `title.localizedStandardCompare(_:)`, then `id.localizedStandardCompare(_:)` when titles match.
- [ ] Implement `ConnectedServiceDocumentation.allFields` as `sections.flatMap(\.fields)`.
- [ ] Add `appleHealth` with sections:
  - `Идентификация и время`: `HKWorkout.uuid`, `HKWorkout.workoutActivityType`, `HKWorkout.startDate`, `HKWorkout.duration`.
  - `Метрики`: `HKQuantityTypeIdentifier.activeEnergyBurned`, the three distance rows.
  - `Плавание`: `HKMetadataKeySwimmingLocationType`, `HKMetadataKeyLapLength`.
- [ ] Use the exact Apple Health descriptions from `docs/superpowers/specs/2026-07-12-connected-services-documentation-design.md`.
- [ ] Add `garminConnect` with semantic sections matching the spec:
  - `Идентификаторы и время`
  - `Длительность, дистанция и энергия`
  - `Пульс, зоны и нагрузка`
  - `Скорость, темп, каденс и движение`
  - `Высота, координаты и место`
  - `Плавание`
  - `SUP и гребковые активности`
  - `Силовые тренировки`
  - `Мощность`
  - `Температура, вода, самочувствие и стресс`
  - `Шаги, этажи, VO2 Max и интенсивность`
  - `Флаги и служебные признаки`
  - `Разбиения и дополнительные структуры`
- [ ] For Garmin field support, run this read-only command and copy only generated field/type ids into source code:

```bash
jq -r '.[0].summarizedActivitiesExport[] as $activity | ($activity.activityType | if type == "object" then .typeKey else . end) as $activityType | $activity | keys[] | "\(.)|\($activityType)"' from_garmin_official_export/DI_CONNECT/DI-Connect-Fitness/*_summarizedActivities.json | sort -u
```

- [ ] Do not copy any values other than field names and activity type ids from the command output.
- [ ] Add a small private constructor such as `garminField(_ systemName: String, _ humanName: String, _ description: String, supportedTypeIDs: [String]) -> ServiceDocumentationField`.
- [ ] For Garmin descriptions, keep them concise and field-specific:
  - IDs: stable identifiers and references used by Garmin.
  - Time fields: start time, local time, GMT time, or timezone.
  - Duration fields: total, elapsed, moving duration.
  - Distance/energy fields: distance, calories, basal calories.
  - Heart-rate fields: average, minimum, maximum, and time in zones.
  - Training effect/load fields: Garmin load and aerobic/anaerobic effect.
  - Movement fields: speed, cadence, stride length, vertical metrics, ground contact.
  - Location/elevation fields: coordinates, place, elevation gain/loss/min/max.
  - Swimming fields: lengths, strokes, stroke distance, swim cadence, swolf, pool length.
  - Strength fields: sets, reps, exercise sets, workout id.
  - Power fields: average/max/normalized power, zones, TSS, IF, 20-minute max.
  - Wellness fields: temperature, water estimate, feel, RPE, body battery, stress, respiration.
  - Step/intensity fields: steps, floors, jump count, VO2 Max, intensity minutes.
  - Flags/service fields: Garmin boolean flags, device/manufacturer, parent/favorite/PR flags.
  - Splits/structures: split summaries, splits, description, dive info.
- [ ] Run the targeted catalog tests again.

**Expected result after Task 2:** `ConnectedServiceDocumentationCatalogTests` pass.

### Task 3: Add Documentation SwiftUI Screens

**Files:**
- Create: `SportApp/ConnectedServicesDocumentationView.swift`

**Interfaces:**
- `ConnectedServicesDocumentationView(catalog: [ConnectedServiceDocumentation] = ConnectedServiceDocumentationCatalog.services)`
- `ConnectedServiceDetailView(service: ConnectedServiceDocumentation)`
- `DocumentationFieldDisclosureView(field: ServiceDocumentationField)`
- `SupportedTrainingTypeChips(types: [SupportedTrainingType])`

- [ ] Build `ConnectedServicesDocumentationView` as a `NavigationStack`.
- [ ] Add a root `List` with `Section("Связанные сервисы")`.
- [ ] Add one `NavigationLink` row per service.
- [ ] Root title: `Документация`.
- [ ] Service detail title: service title.
- [ ] Service detail content:
  - short summary text from catalog;
  - one section per `ServiceDocumentationSection`;
  - one `DocumentationFieldDisclosureView` per field.
- [ ] `DocumentationFieldDisclosureView` collapsed state must show:
  - `field.humanName` as the primary label;
  - `field.systemName` in `.font(.system(.caption, design: .monospaced))`;
  - a small count like `N типов`, where `N == field.supportedTypes.count`.
- [ ] Expanded state must show:
  - `field.description`;
  - supported type chips with Russian titles and system ids visible in compact text.
- [ ] Use existing visual language:
  - dark background with `SportAppVisualStyle.palette`;
  - panel/card backgrounds from the palette;
  - `SportAppVisualStyle.cardRadius`;
  - cyan/orange accents already used by the dashboard.
- [ ] Avoid nesting cards inside cards. Use `List`/sections and lightweight rows.
- [ ] Add accessibility labels:
  - root view: `Документация`;
  - service links: service titles;
  - field rows: human name plus system name.
- [ ] Build the app for simulator:

```bash
xcodebuild build -project SportApp.xcodeproj -scheme SportApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .temp/ConnectedServicesDocsDerivedData
```

**Expected result:** build succeeds and no raw Garmin data files are generated.

### Task 4: Add Dashboard Entry Point

**Files:**
- Modify: `SportApp/SportDashboardView.swift`

**Interfaces:**
- New state: `@State private var isShowingDocumentationSheet = false`

- [ ] Add `isShowingDocumentationSheet` beside the existing sheet state values.
- [ ] Add a `NeonIconButton` before the gear button:
  - `systemName: "book.closed"`
  - `accessibilityLabel: "Документация"`
  - action sets `isShowingDocumentationSheet = true`.
- [ ] Add a sheet:

```swift
.sheet(isPresented: $isShowingDocumentationSheet) {
    ConnectedServicesDocumentationView()
}
```

- [ ] Keep the settings sheet behavior unchanged.
- [ ] Keep the title `Илья`, tabs, filter bar, data status banner, and content group unchanged.
- [ ] Run a simulator build.

**Expected result:** the app builds, and the dashboard has two top-right icon buttons: documentation and settings.

### Task 5: Add UI Test For Documentation Access

**Files:**
- Modify: `SportAppUITests/SportAppUITests.swift`

- [ ] Add `testDocumentationOpensConnectedServices()`:
  - launch app;
  - wait for `app.buttons["Документация"]`;
  - tap it;
  - assert `app.navigationBars["Документация"]` exists;
  - assert `app.staticTexts["Связанные сервисы"]` exists;
  - assert `app.staticTexts["Apple Health"]` exists;
  - assert `app.staticTexts["Garmin Connect"]` exists.
- [ ] Run the targeted UI test:

```bash
xcodebuild test -project SportApp.xcodeproj -scheme SportApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .temp/ConnectedServicesDocsDerivedData -only-testing:SportAppUITests/SportAppUITests/testDocumentationOpensConnectedServices
```

**Expected result:** UI test passes.

### Task 6: Full Verification And Sensitive Data Check

**Files:**
- Modify: `docs/steps_human.md`

- [ ] Run catalog tests:

```bash
xcodebuild test -project SportApp.xcodeproj -scheme SportApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .temp/ConnectedServicesDocsDerivedData -only-testing:SportAppTests/ConnectedServiceDocumentationCatalogTests
```

- [ ] Run full unit tests:

```bash
xcodebuild test -project SportApp.xcodeproj -scheme SportApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .temp/ConnectedServicesDocsDerivedData -only-testing:SportAppTests
```

- [ ] Run targeted UI test:

```bash
xcodebuild test -project SportApp.xcodeproj -scheme SportApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .temp/ConnectedServicesDocsDerivedData -only-testing:SportAppUITests/SportAppUITests/testDocumentationOpensConnectedServices
```

- [ ] Run whitespace verification:

```bash
git diff --check
```

- [ ] Confirm Garmin export was not modified:

```bash
git status --short -- from_garmin_official_export
```

Expected output: empty.

- [ ] Confirm no new visible sensitive data files are staged or unstaged:

```bash
git status --short | rg 'garmin_summarized_activities|from_garmin_official_export|\\.zip|\\.fit|\\.tcx|\\.gpx|\\.json|\\.mobileprovision|\\.xcuserstate'
```

Expected output: empty, except unrelated already ignored files should not appear.

- [ ] Confirm `.temp/ConnectedServicesDocsDerivedData` is ignored or untracked outside git status. If it appears in `git status`, add `.temp/` to `.gitignore` before committing.
- [ ] Append the final user-facing answer for the related step in `docs/steps_human.md`.

**Expected final result:** documentation is reachable by icon, Apple Health and Garmin Connect services are browsable, the static catalog is covered by tests, and no raw training data or generated sensitive files are committed.
