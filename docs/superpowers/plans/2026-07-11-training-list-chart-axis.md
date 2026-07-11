# Training List And Chart Axis Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the `Тренировки` tab as a period-filtered activity card list and improve the `График` tab axes.

**Architecture:** Keep Garmin parsing and presentation logic outside SwiftUI. `TrainingActivityListBuilder` produces stable card models from `[GarminActivity]`; SwiftUI views render those models and manage period/settings state. Chart axis values are computed by small pure helpers and rendered by `WeeklyEffortChartView`.

**Tech Stack:** Swift, SwiftUI, Swift Testing, Xcode iOS app target.

## Global Constraints

- Do not read or modify `from_garmin_official_export`.
- Do not commit Garmin training data files; `SportApp/garmin_summarized_activities.json` must remain ignored.
- Keep project documentation and user-facing copy in Russian.
- Target the existing iPhone-focused app layout.
- Default training-list period is `1 неделя` ending at the latest available activity date in bundled data.
- X-axis date format is `dMMyy`: `70626` for 7 June 2026 and `120424` for 12 April 2024.
- `Rest` is displayed in the training list as `Отдых`, but remains excluded from weekly effort calculation.

---

### Task 1: Training Activity Domain Models

**Files:**
- Modify: `SportApp/GarminActivity.swift`
- Create: `SportApp/TrainingActivityPresentation.swift`
- Create: `SportApp/TrainingActivityListBuilder.swift`
- Test: `SportAppTests/TrainingActivityListBuilderTests.swift`

**Interfaces:**
- Consumes: `[GarminActivity]`
- Produces:
  - `enum TrainingActivityDisplayField: String, CaseIterable, Codable, Identifiable`
  - `struct TrainingPeriodSelection: Equatable`
  - `struct TrainingActivityCardModel: Identifiable, Equatable`
  - `struct TrainingActivityListBuilder`
  - `struct TrainingActivityPresentation`

- [ ] **Step 1: Write failing tests for decoding, names, sorting, and periods**

Create `SportAppTests/TrainingActivityListBuilderTests.swift`:

```swift
import Foundation
import Testing
@testable import SportApp

struct TrainingActivityListBuilderTests {
    private let calendar = WeeklyEffortCalculator.makeMondayFirstCalendar()

    @Test func decodesOptionalDistanceFromGarminSummary() throws {
        let json = """
        [
          {
            "summarizedActivitiesExport": [
              {
                "activityId": 1,
                "name": "Sea swim",
                "activityType": "open_water_swimming",
                "sportType": "SWIMMING",
                "startTimeLocal": 1780704000000,
                "startTimeGmt": 1780704000000,
                "duration": 1800000,
                "calories": 200,
                "distance": 1500
              }
            ]
          }
        ]
        """

        let activities = try GarminActivitiesLoader.decodeActivities(from: Data(json.utf8))

        #expect(activities.first?.distance == 1500)
    }

    @Test func mapsGarminActivityTypesToRussianTitles() {
        #expect(TrainingActivityPresentation.title(for: activity(id: 1, type: "open_water_swimming", name: "Sea")) == "Плавание Море")
        #expect(TrainingActivityPresentation.title(for: activity(id: 2, type: "lap_swimming", name: "Pool")) == "Бассейн")
        #expect(TrainingActivityPresentation.title(for: activity(id: 3, type: "cycling", name: "Ride")) == "Велик")
        #expect(TrainingActivityPresentation.title(for: activity(id: 4, type: "other", name: "Rest")) == "Отдых")
    }

    @Test func buildsNewestFirstCardsForDefaultWeekEndingAtLatestActivity() {
        let activities = [
            activity(id: 1, type: "running", name: "Old", date: "2026-06-01", distance: 1000),
            activity(id: 2, type: "cycling", name: "Latest", date: "2026-06-14", distance: 12000),
            activity(id: 3, type: "lap_swimming", name: "Pool", date: "2026-06-08", distance: 800),
            activity(id: 4, type: "walking", name: "Too old", date: "2026-06-07", distance: 500)
        ]

        let cards = TrainingActivityListBuilder(calendar: calendar).buildCards(
            from: activities,
            period: .preset(.oneWeek)
        )

        #expect(cards.map(\.id) == [2, 3])
        #expect(cards[0].title == "Велик")
        #expect(cards[0].distanceText == "12 км")
        #expect(cards[1].title == "Бассейн")
        #expect(cards[1].distanceText == "800 м")
    }

    @Test func buildsCardsForCustomDateRangeInclusive() {
        let activities = [
            activity(id: 1, type: "running", name: "Before", date: "2026-06-01", distance: 1000),
            activity(id: 2, type: "running", name: "Inside", date: "2026-06-10", distance: 2000),
            activity(id: 3, type: "running", name: "After", date: "2026-06-20", distance: 3000)
        ]
        let start = date("2026-06-09")
        let end = date("2026-06-10")

        let cards = TrainingActivityListBuilder(calendar: calendar).buildCards(
            from: activities,
            period: .custom(start: start, end: end)
        )

        #expect(cards.map(\.id) == [2])
    }

    private func activity(
        id: Int64,
        type: String,
        name: String,
        date: String = "2026-06-14",
        distance: Double? = nil,
        durationMinutes: Double = 45
    ) -> GarminActivity {
        let timestamp = self.date(date).timeIntervalSince1970 * 1000
        return GarminActivity(
            activityId: id,
            name: name,
            activityType: type,
            sportType: nil,
            startTimeLocal: timestamp,
            startTimeGmt: timestamp,
            duration: durationMinutes * 60_000,
            calories: 300,
            distance: distance
        )
    }

    private func date(_ value: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)!
    }
}
```

- [ ] **Step 2: Run the test and verify it fails**

Run:

```bash
xcodebuild test -scheme SportApp -destination 'platform=iOS Simulator,name=iPhone Air' -only-testing:SportAppTests/TrainingActivityListBuilderTests -derivedDataPath .temp/TDDDerivedData
```

Expected: FAIL because `distance`, `TrainingActivityPresentation`, `TrainingActivityListBuilder`, and related types do not exist.

- [ ] **Step 3: Implement the domain code**

Modify `GarminActivity` to include:

```swift
let distance: Double?
```

Create `TrainingActivityPresentation.swift` with Russian title mapping, duration formatting, distance formatting, and start time formatting.

Create `TrainingActivityListBuilder.swift` with period presets, inclusive custom date filtering, newest-first sorting, and card model creation.

- [ ] **Step 4: Run the task test until green**

Run the same command from Step 2.

Expected: PASS for `TrainingActivityListBuilderTests`.

---

### Task 2: Training List UI And Field Settings

**Files:**
- Modify: `SportApp/SportDashboardView.swift`
- Create: `SportApp/TrainingListView.swift`
- Create: `SportApp/TrainingActivityCardView.swift`
- Create: `SportApp/TrainingActivityFieldPreferences.swift`
- Test: `SportAppTests/TrainingActivityFieldPreferencesTests.swift`

**Interfaces:**
- Consumes: `TrainingActivityCardModel`, `TrainingActivityDisplayField`, `TrainingActivityListBuilder`
- Produces:
  - `TrainingListView`
  - `TrainingActivityCardView`
  - `TrainingActivityFieldPreferences`

- [ ] **Step 1: Write failing tests for field preferences**

Create `SportAppTests/TrainingActivityFieldPreferencesTests.swift`:

```swift
import Testing
@testable import SportApp

struct TrainingActivityFieldPreferencesTests {
    @Test func storesCustomFieldsForOneActivityTypeWithoutChangingOthers() throws {
        var preferences = TrainingActivityFieldPreferences()

        preferences.setFields([.duration, .startTime], for: "cycling")

        #expect(preferences.fields(for: "cycling") == [.duration, .startTime])
        #expect(preferences.fields(for: "running") == TrainingActivityDisplayField.defaultFields)
    }

    @Test func roundTripsThroughJSON() throws {
        var preferences = TrainingActivityFieldPreferences()
        preferences.setFields([.distance, .calories], for: "lap_swimming")

        let data = try preferences.encode()
        let decoded = try TrainingActivityFieldPreferences.decode(from: data)

        #expect(decoded.fields(for: "lap_swimming") == [.distance, .calories])
    }
}
```

- [ ] **Step 2: Run preference tests and verify they fail**

Run:

```bash
xcodebuild test -scheme SportApp -destination 'platform=iOS Simulator,name=iPhone Air' -only-testing:SportAppTests/TrainingActivityFieldPreferencesTests -derivedDataPath .temp/TDDDerivedData
```

Expected: FAIL because `TrainingActivityFieldPreferences` is missing.

- [ ] **Step 3: Implement preferences and SwiftUI views**

Implement `TrainingActivityFieldPreferences` as a Codable dictionary keyed by `activityType`.

Implement `TrainingListView`:

- loads bundled activities through `GarminActivitiesLoader`;
- default selected period is `.preset(.oneWeek)`;
- renders a top row with selected period text and an icon button;
- opens a sheet for period selection;
- renders `ScrollView` + `LazyVStack` of cards newest first.

Implement `TrainingActivityCardView`:

- card radius 8;
- title top-left;
- small `gearshape` button top-right;
- visible fields controlled by preferences for the card's `activityType`.

Update `SportDashboardView`:

- `.today` becomes `.trainings = "Тренировки"`;
- `.history` becomes `.chart = "График"`;
- `.trainings` renders `TrainingListView()`;
- `.chart` renders `WeeklyEffortView()`.

- [ ] **Step 4: Run task tests**

Run:

```bash
xcodebuild test -scheme SportApp -destination 'platform=iOS Simulator,name=iPhone Air' -only-testing:SportAppTests/TrainingActivityFieldPreferencesTests -derivedDataPath .temp/TDDDerivedData
```

Expected: PASS.

---

### Task 3: Weekly Chart Axis Labels

**Files:**
- Modify: `SportApp/WeeklyEffortCalculator.swift`
- Modify: `SportApp/WeeklyEffortChartView.swift`
- Test: `SportAppTests/WeeklyEffortChartAxisTests.swift`

**Interfaces:**
- Consumes: `[WeeklyEffortPoint]`
- Produces:
  - `WeeklyEffortPoint.axisLabel`
  - `WeeklyEffortChartAxisValues`

- [ ] **Step 1: Write failing chart axis tests**

Create `SportAppTests/WeeklyEffortChartAxisTests.swift`:

```swift
import Foundation
import Testing
@testable import SportApp

struct WeeklyEffortChartAxisTests {
    @Test func formatsXAxisDatesAsDayMonthYearWithoutLeadingDayZero() {
        #expect(WeeklyEffortPoint.axisDateFormatter.string(from: date("2026-06-07")) == "70626")
        #expect(WeeklyEffortPoint.axisDateFormatter.string(from: date("2024-04-12")) == "120424")
    }

    @Test func producesFourXAxisValuesFromFirstTwoIntermediateAndLastPoints() {
        let points = (0..<10).map { index in
            WeeklyEffortPoint(
                weekStart: date("2026-01-\(String(format: "%02d", index + 1))"),
                weekEnd: date("2026-01-\(String(format: "%02d", index + 7))"),
                value: Double(index)
            )
        }

        let values = WeeklyEffortChartAxisValues.xAxisLabels(for: points)

        #expect(values.count == 4)
        #expect(values.map(\.index) == [0, 3, 6, 9])
    }

    @Test func producesFourYAxisValuesFromZeroToMax() {
        let values = WeeklyEffortChartAxisValues.yAxisLabels(maxValue: 90)

        #expect(values == [0, 30, 60, 90])
    }

    private func date(_ value: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = WeeklyEffortCalculator.makeMondayFirstCalendar()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)!
    }
}
```

- [ ] **Step 2: Run chart axis tests and verify they fail**

Run:

```bash
xcodebuild test -scheme SportApp -destination 'platform=iOS Simulator,name=iPhone Air' -only-testing:SportAppTests/WeeklyEffortChartAxisTests -derivedDataPath .temp/TDDDerivedData
```

Expected: FAIL because axis helpers do not exist.

- [ ] **Step 3: Implement axis helpers and chart rendering**

Add `axisDateFormatter` and `axisLabel` to `WeeklyEffortPoint`.

Add `WeeklyEffortChartAxisValues` with:

- `xAxisLabels(for:)` returning four labels when possible;
- `yAxisLabels(maxValue:)` returning four values from 0 to max.

Update `WeeklyEffortChartView`:

- reserve leading space for Y labels;
- reserve bottom space for X labels;
- draw four horizontal grid positions;
- draw Y labels aligned to those grid positions;
- draw X labels at first, two intermediate, and last point positions;
- keep existing tooltip behavior and horizontal scroll.

- [ ] **Step 4: Run chart axis tests**

Run:

```bash
xcodebuild test -scheme SportApp -destination 'platform=iOS Simulator,name=iPhone Air' -only-testing:SportAppTests/WeeklyEffortChartAxisTests -derivedDataPath .temp/TDDDerivedData
```

Expected: PASS.

---

### Task 4: Integration Verification

**Files:**
- Modify only if tests or build reveal integration issues.

**Interfaces:**
- Consumes: Tasks 1-3.
- Produces: verified app.

- [ ] **Step 1: Run full test suite**

Run:

```bash
xcodebuild test -scheme SportApp -destination 'platform=iOS Simulator,name=iPhone Air' -derivedDataPath .temp/TestDerivedData
```

Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 2: Build and launch simulator for visual verification**

Run:

```bash
xcodebuild build -scheme SportApp -configuration Debug -destination 'platform=iOS Simulator,name=iPhone Air' -derivedDataPath .temp/RunDerivedData
xcrun simctl boot BF54D63E-47EC-49E7-816B-B5C44B41CF1D || true
xcrun simctl install BF54D63E-47EC-49E7-816B-B5C44B41CF1D .temp/RunDerivedData/Build/Products/Debug-iphonesimulator/SportApp.app
xcrun simctl launch BF54D63E-47EC-49E7-816B-B5C44B41CF1D com.domyshev.sportapp
xcrun simctl io BF54D63E-47EC-49E7-816B-B5C44B41CF1D screenshot .temp/sportapp-training-list.png
```

Expected: app launches and screenshot shows `Тренировки` and `График` tabs.

- [ ] **Step 3: Confirm ignored sensitive files**

Run:

```bash
git check-ignore -v SportApp/garmin_summarized_activities.json from_garmin_official_export .temp SportApp.xcodeproj/project.xcworkspace/xcuserdata/user.xcuserdatad/UserInterfaceState.xcuserstate
```

Expected: all paths are ignored by `.gitignore`.

