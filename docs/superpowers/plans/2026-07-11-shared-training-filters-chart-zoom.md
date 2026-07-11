# Shared Training Filters And Chart Zoom Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `Тренировки` and `График` use the same selected period and activity-type filters, add recent custom periods, and add `-` / reset / `+` chart X zoom controls.

**Architecture:** Keep filter and axis behavior in pure Swift helpers that can be tested with Swift Testing. Keep shared state in `SportDashboardView`, then pass selected filters into `TrainingListView` and `WeeklyEffortView`. Keep Garmin data read-only and continue loading the existing bundled JSON.

**Tech Stack:** Swift, SwiftUI, Swift Testing, Xcode iOS app target.

## Global Constraints

- Work only inside `/Volumes/code/domyshev/sport-app`.
- Do not modify `from_garmin_official_export`.
- Do not create commit-tracked Garmin history data files.
- `from_garmin_official_export/`, `garmin_summarized_activities.json`, and `.temp/` must remain ignored.
- User-facing copy is Russian.
- Default period is `1 неделя` ending at the latest available activity date in bundled data.
- X-axis date format is `dd/MM/yyyy`, for example `07/06/2026`.
- At most four X-axis labels should fit into one iPhone screen width.
- Chart X zoom controls are `-`, reset, `+`.

---

### Task 1: Shared Filter Domain

**Files:**
- Modify: `SportApp/TrainingActivityListBuilder.swift`
- Modify: `SportApp/TrainingActivityPresentation.swift`
- Modify: `SportAppTests/TrainingActivityListBuilderTests.swift`

**Interfaces:**
- Produces: `TrainingActivityTypeCategory: Hashable, Codable, Identifiable, Comparable`
- Produces: `TrainingActivityTypeSelection: Equatable`
- Produces: `TrainingRecentCustomPeriod: Codable, Equatable, Identifiable`
- Produces: `TrainingRecentCustomPeriods: Codable, Equatable`
- Produces: public `TrainingPeriodSelection.dateRange(latestDate:calendar:)`
- Produces: `TrainingPeriodSelection.title(calendar:) -> String`

- [ ] **Step 1: Write failing tests**

Add tests to `SportAppTests/TrainingActivityListBuilderTests.swift`:

```swift
@Test func typeCategoriesCombineCyclingVariantsAndUseRussianTitles() {
    let categories = TrainingActivityTypeCategory.availableCategories(from: [
        activity(id: 1, type: "cycling", name: "Outdoor"),
        activity(id: 2, type: "indoor_cycling", name: "Indoor"),
        activity(id: 3, type: "lap_swimming", name: "Pool")
    ])

    #expect(categories.map(\.title) == ["Бассейн", "Велик"])
}

@Test func activityTypeSelectionSupportsMultipleCategories() {
    let cycling = activity(id: 1, type: "cycling", name: "Ride")
    let pool = activity(id: 2, type: "lap_swimming", name: "Pool")
    let selection = TrainingActivityTypeSelection(selected: [
        TrainingActivityTypeCategory(activity: cycling)
    ])

    #expect(selection.includes(cycling))
    #expect(!selection.includes(pool))
}

@Test func listBuilderFiltersByPeriodAndActivityTypes() {
    let activities = [
        activity(id: 1, type: "running", name: "Run", date: "2026-06-14"),
        activity(id: 2, type: "cycling", name: "Ride", date: "2026-06-13"),
        activity(id: 3, type: "cycling", name: "Old Ride", date: "2026-06-01")
    ]
    let selection = TrainingActivityTypeSelection(selected: [
        TrainingActivityTypeCategory(activity: activities[1])
    ])

    let cards = TrainingActivityListBuilder(calendar: calendar).buildCards(
        from: activities,
        period: .preset(.oneWeek),
        typeSelection: selection
    )

    #expect(cards.map(\.id) == [2])
}

@Test func recentCustomPeriodsKeepFiveAndMoveDuplicateToTop() {
    let periods = (1...6).reduce(into: TrainingRecentCustomPeriods()) { result, day in
        result.remember(
            TrainingRecentCustomPeriod(start: date("2026-06-\(String(format: "%02d", day))"), end: date("2026-06-\(String(format: "%02d", day + 1))")),
            calendar: calendar
        )
    }
    var updated = periods
    let duplicate = TrainingRecentCustomPeriod(start: date("2026-06-03"), end: date("2026-06-04"))

    updated.remember(duplicate, calendar: calendar)

    #expect(updated.items.count == 5)
    #expect(updated.items.first == duplicate)
}
```

- [ ] **Step 2: Run RED**

Run:

```bash
xcodebuild test -scheme SportApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .temp/TDDSharedFilters -only-testing:SportAppTests/TrainingActivityListBuilderTests
```

Expected: FAIL because the new filter and recent-period types do not exist and `buildCards` does not accept `typeSelection`.

- [ ] **Step 3: Implement minimal domain code**

In `TrainingActivityListBuilder.swift`:

- make `dateRange(latestDate:calendar:)` internal instead of fileprivate;
- add `title(calendar:)`;
- add `TrainingActivityTypeCategory`;
- add `TrainingActivityTypeSelection`;
- add recent custom period structs;
- change `buildCards` signature to:

```swift
func buildCards(
    from activities: [GarminActivity],
    period: TrainingPeriodSelection,
    typeSelection: TrainingActivityTypeSelection = .all
) -> [TrainingActivityCardModel]
```

Filter cards by both date range and `typeSelection.includes(activity)`.

- [ ] **Step 4: Run GREEN**

Run the RED command again.

Expected: PASS.

---

### Task 2: Weekly Graph Filtering, Axis Format, And Zoom Model

**Files:**
- Modify: `SportApp/WeeklyEffortCalculator.swift`
- Modify: `SportAppTests/WeeklyEffortCalculatorTests.swift`
- Modify: `SportAppTests/WeeklyEffortChartAxisTests.swift`

**Interfaces:**
- Produces: `WeeklyEffortCalculator.calculate(from:period:typeSelection:)`
- Produces: `WeeklyEffortChartScale`
- Produces: `WeeklyEffortChartAxisValues.xAxisLabels(for:visibleWidth:pointSpacing:)`

- [ ] **Step 1: Write failing graph tests**

Update `SportAppTests/WeeklyEffortChartAxisTests.swift`:

```swift
@Test func formatsXAxisDatesAsDayMonthYearWithSlashes() {
    #expect(WeeklyEffortPoint.axisDateFormatter.string(from: date("2026-06-07")) == "07/06/2026")
    #expect(WeeklyEffortPoint.axisDateFormatter.string(from: date("2024-04-12")) == "12/04/2024")
}

@Test func spacesXAxisLabelsForFourLabelsPerVisibleWidth() {
    let points = (0..<20).map { index in
        WeeklyEffortPoint(
            weekStart: date("2026-01-\(String(format: "%02d", index + 1))"),
            weekEnd: date("2026-01-\(String(format: "%02d", index + 1))"),
            value: Double(index)
        )
    }

    let values = WeeklyEffortChartAxisValues.xAxisLabels(
        for: points,
        visibleWidth: 408,
        pointSpacing: 34
    )

    #expect(zip(values.map(\.index), values.dropFirst().map(\.index)).allSatisfy { lhs, rhs in rhs - lhs >= 4 })
}

@Test func chartScaleCanZoomOutResetAndZoomIn() {
    #expect(WeeklyEffortChartScale.standard.zoomedOut().pointSpacing < WeeklyEffortChartScale.standard.pointSpacing)
    #expect(WeeklyEffortChartScale.standard.zoomedIn().pointSpacing > WeeklyEffortChartScale.standard.pointSpacing)
    #expect(WeeklyEffortChartScale.standard.zoomedIn().reset() == .standard)
}
```

Add a filtering test to `SportAppTests/WeeklyEffortCalculatorTests.swift`:

```swift
@Test func calculatesWeeklyEffortForSelectedPeriodAndTypes() {
    let activities = [
        activity(id: 1, date: "2025-06-16", activityType: "running", calories: 120, durationMinutes: 20),
        activity(id: 2, date: "2025-06-17", activityType: "cycling", calories: 300, durationMinutes: 30),
        activity(id: 3, date: "2025-06-23", activityType: "cycling", calories: 900, durationMinutes: 30)
    ]
    let selection = TrainingActivityTypeSelection(selected: [
        TrainingActivityTypeCategory(activity: activities[1])
    ])

    let points = WeeklyEffortCalculator(filter: .default).calculate(
        from: activities,
        period: .custom(start: date("2025-06-16"), end: date("2025-06-22")),
        typeSelection: selection
    )

    #expect(points.count == 1)
    #expect(points[0].value == 10)
}
```

- [ ] **Step 2: Run RED**

Run:

```bash
xcodebuild test -scheme SportApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .temp/TDDChartFilters -only-testing:SportAppTests/WeeklyEffortChartAxisTests -only-testing:SportAppTests/WeeklyEffortCalculatorTests
```

Expected: FAIL because axis format, scale, dynamic labels, and filtered calculation are missing.

- [ ] **Step 3: Implement graph helpers**

In `WeeklyEffortCalculator.swift`:

- change axis formatter to `dd/MM/yyyy`;
- add overload `calculate(from:period:typeSelection:)` that filters activities to the selected date range and type selection, then reuses existing weekly calculation;
- add `WeeklyEffortChartScale` with levels `.compact`, `.standard`, `.wide`.

In `WeeklyEffortChartAxisValues`:

- keep the old simple API only as a wrapper if needed;
- implement visible-width API with minimum index spacing `ceil(visibleWidth / (3 * pointSpacing))`;
- include first and last labels while preserving minimum spacing by dropping the previous label near the end when needed.

- [ ] **Step 4: Run GREEN**

Run the RED command again.

Expected: PASS.

---

### Task 3: Shared SwiftUI State And Sheets

**Files:**
- Modify: `SportApp/SportDashboardView.swift`
- Modify: `SportApp/TrainingListView.swift`
- Modify: `SportApp/WeeklyEffortView.swift`
- Modify: `SportApp/WeeklyEffortChartView.swift`
- Modify: `docs/steps_human.md`

**Interfaces:**
- Consumes: domain helpers from Tasks 1 and 2.
- Produces: visible shared filters, type multi-select, recent custom periods, and chart zoom controls.

- [ ] **Step 1: Move shared state to dashboard**

In `SportDashboardView`, add state:

```swift
@State private var activities: [GarminActivity] = []
@State private var selectedPeriod: TrainingPeriodSelection = .preset(.oneWeek)
@State private var selectedPreset: TrainingPeriodSelection.Preset = .oneWeek
@State private var isCustomPeriod = false
@State private var selectedTypes = TrainingActivityTypeSelection.all
@State private var chartScale = WeeklyEffortChartScale.standard
@State private var recentCustomPeriods = TrainingRecentCustomPeriods()
```

Load activities once with `GarminActivitiesLoader`.

- [ ] **Step 2: Render common filter row**

Add a compact row under the tab bar:

- period title on the left;
- calendar icon button opens period sheet;
- filter icon button opens type sheet;
- type summary text: `Все типы`, one selected title, or `N типов`.

- [ ] **Step 3: Update period sheet**

Move `TrainingPeriodSelectionView` so it can edit dashboard bindings and receive recent custom periods. Add section `Последние` above the custom date pickers when recent periods exist.

On `Готово`, if custom period is selected, call `recentCustomPeriods.remember(...)` and persist it with `@AppStorage`.

- [ ] **Step 4: Add type sheet**

Create a SwiftUI sheet in `TrainingListView.swift` or `SportDashboardView.swift`:

```swift
private struct TrainingTypeSelectionView: View
```

It shows available categories from `TrainingActivityTypeCategory.availableCategories(from: activities)`, supports multi-select checkmarks, and has `Все` action.

- [ ] **Step 5: Pass filters into tabs**

`TrainingListView` receives:

```swift
let activities: [GarminActivity]
let selectedPeriod: TrainingPeriodSelection
let selectedTypes: TrainingActivityTypeSelection
```

`WeeklyEffortView` receives:

```swift
let activities: [GarminActivity]
let selectedPeriod: TrainingPeriodSelection
let selectedPeriodTitle: String
let selectedTypes: TrainingActivityTypeSelection
@Binding var chartScale: WeeklyEffortChartScale
```

- [ ] **Step 6: Add chart zoom controls**

In `WeeklyEffortView`, add the `-`, reset, `+` buttons above `WeeklyEffortChartView`. Pass `chartScale` into `WeeklyEffortChartView` and use `chartScale.pointSpacing` instead of the current fixed `34`.

- [ ] **Step 7: Build**

Run:

```bash
xcodebuild build -scheme SportApp -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .temp/RunDerivedData
```

Expected: BUILD SUCCEEDED.

---

### Task 4: Full Verification And Relaunch

**Files:**
- No production code changes unless verification finds a bug.

- [ ] **Step 1: Run full tests**

Run:

```bash
xcodebuild test -scheme SportApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .temp/FinalDerivedData
```

Expected: TEST SUCCEEDED.

- [ ] **Step 2: Check git-sensitive files**

Run:

```bash
git status --short
git check-ignore -v from_garmin_official_export garmin_summarized_activities.json SportApp/garmin_summarized_activities.json .temp
git ls-files | rg '(^|/)(from_garmin_official_export|garmin_summarized_activities\.json)$|garmin|activities|\.fit$|\.tcx$|\.json$'
```

Expected: no Garmin history data is tracked. Only asset catalog JSON and docs JSON-like text may appear.

- [ ] **Step 3: Install and launch simulator build**

Use the working iPhone 17 Pro simulator because the iPhone Air simulator previously failed CoreSimulator migration.

Run:

```bash
xcrun simctl boot 5FB6B7A4-A4E9-4C6D-A388-0273F3FABC22 || true
xcrun simctl install 5FB6B7A4-A4E9-4C6D-A388-0273F3FABC22 .temp/RunDerivedData/Build/Products/Debug-iphonesimulator/SportApp.app
xcrun simctl launch 5FB6B7A4-A4E9-4C6D-A388-0273F3FABC22 com.domyshev.sportapp
open -a Simulator
```

Expected: updated app launches and visible UI includes common period/type filters plus graph zoom controls.

## Self-Review

- Spec coverage: every requested feature maps to Tasks 1-4.
- Placeholder scan: no TBD/TODO/fill-later language.
- Type consistency: `TrainingActivityTypeSelection`, `TrainingRecentCustomPeriods`, and `WeeklyEffortChartScale` names match across tasks.
- Sensitive data: no task creates a commit-tracked Garmin data file.
