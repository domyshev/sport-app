# Weekly Effort UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first iPhone SwiftUI analytics screen that renders a horizontally scrollable weekly Garmin effort curve.

**Architecture:** Keep parsing, filtering, weekly aggregation, and SwiftUI rendering in focused files. Unit tests cover the calculation rules before UI integration. The Garmin export source folder remains untouched; the app reads a copied bundled JSON resource.

**Tech Stack:** Swift, SwiftUI, Swift Testing, Foundation JSON decoding, Xcode iOS app target.

## Execution Notes

- Xcode in this workspace exposes `iPhone Air` as the available simulator target. `iPhone 15 Pro Max` and `iPhone 14 Pro Max` are target devices for the design, but they are not available in the current local simulator list, so verification commands are run on `iPhone Air`.
- The finalized weekly effort formula is: for every training calculate `calories / durationInMinutes`; if a day has multiple trainings, calculate the arithmetic mean for that day; weekly value is the sum of day values from Monday through Sunday.
- The Xcode project uses file-system-synchronized groups, so new Swift files and `SportApp/garmin_summarized_activities.json` are picked up by the app target without manually editing `project.pbxproj`.
- Implemented tests: `TrainingActivityFilterTests`, `WeeklyEffortCalculatorTests`, `GarminActivitiesLoaderTests`.

---

## File Structure

- `SportApp/GarminActivity.swift` - Decodable models for the summarized Garmin activities JSON.
- `SportApp/TrainingActivityFilter.swift` - Default rule for excluding non-training activities.
- `SportApp/WeeklyEffortCalculator.swift` - Calendar/date math and weekly value calculation.
- `SportApp/GarminActivitiesLoader.swift` - Bundle JSON loading.
- `SportApp/WeeklyEffortView.swift` - Main screen with name, week count, and chart.
- `SportApp/WeeklyEffortChartView.swift` - Scrollable line chart, points, and tooltip.
- `SportApp/ContentView.swift` - Entry point that hosts `WeeklyEffortView`.
- `SportApp/garmin_summarized_activities.json` - Copied resource from the Garmin export.
- `SportAppTests/WeeklyEffortCalculatorTests.swift` - Swift Testing coverage for date and formula rules.
- `SportAppTests/TrainingActivityFilterTests.swift` - Swift Testing coverage for default filter.
- `SportAppTests/GarminActivitiesLoaderTests.swift` - Swift Testing coverage for JSON decoding and bundled resource loading.

## Task 1: Data Models and Filter

**Files:**
- Create: `SportApp/GarminActivity.swift`
- Create: `SportApp/TrainingActivityFilter.swift`
- Test: `SportAppTests/TrainingActivityFilterTests.swift`

- [ ] **Step 1: Add tests for the training filter**

Create `SportAppTests/TrainingActivityFilterTests.swift`:

```swift
import Testing
@testable import SportApp

struct TrainingActivityFilterTests {
    @Test func defaultFilterAllowsRealTrainingActivities() {
        let activity = GarminActivity(
            activityId: 1,
            name: "Pool Swim",
            activityType: "lap_swimming",
            sportType: "SWIMMING",
            startTimeLocal: 1_750_000_000_000,
            startTimeGmt: 1_750_000_000_000,
            duration: 600_000,
            calories: 120
        )

        #expect(TrainingActivityFilter.default.includes(activity))
    }

    @Test func defaultFilterRejectsInvalidRestTrackMeAndMeditation() {
        let blocked = [
            GarminActivity(activityId: 1, name: "Rest", activityType: "other", sportType: "INVALID", startTimeLocal: 0, startTimeGmt: 0, duration: 600_000, calories: 10),
            GarminActivity(activityId: 2, name: "Track Me", activityType: "other", sportType: "GENERIC", startTimeLocal: 0, startTimeGmt: 0, duration: 600_000, calories: 10),
            GarminActivity(activityId: 3, name: "Meditating 5min", activityType: "meditation", sportType: "MEDITATION", startTimeLocal: 0, startTimeGmt: 0, duration: 300_000, calories: nil),
            GarminActivity(activityId: 4, name: "Valencia Meditation", activityType: "other", sportType: "INVALID", startTimeLocal: 0, startTimeGmt: 0, duration: 300_000, calories: nil)
        ]

        for activity in blocked {
            #expect(!TrainingActivityFilter.default.includes(activity))
        }
    }
}
```

- [ ] **Step 2: Run filter tests to verify they fail**

Run:

```bash
xcodebuild test -scheme SportApp -destination 'platform=iOS Simulator,name=iPhone 15 Pro Max' -only-testing:SportAppTests/TrainingActivityFilterTests
```

Expected: fails because `GarminActivity` and `TrainingActivityFilter` do not exist.

- [ ] **Step 3: Add Garmin activity model**

Create `SportApp/GarminActivity.swift`:

```swift
import Foundation

struct GarminActivitiesExport: Decodable {
    let summarizedActivitiesExport: [GarminActivity]
}

struct GarminActivity: Decodable, Equatable, Identifiable {
    let activityId: Int64
    let name: String
    let activityType: String
    let sportType: String?
    let startTimeLocal: Double
    let startTimeGmt: Double?
    let duration: Double?
    let calories: Double?

    var id: Int64 { activityId }
}
```

- [ ] **Step 4: Add default training filter**

Create `SportApp/TrainingActivityFilter.swift`:

```swift
import Foundation

struct TrainingActivityFilter {
    var includes: (GarminActivity) -> Bool

    static let `default` = TrainingActivityFilter { activity in
        let blockedSportTypes = Set(["INVALID", "MEDITATION"])
        if let sportType = activity.sportType?.uppercased(), blockedSportTypes.contains(sportType) {
            return false
        }

        let normalizedName = activity.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalizedName.contains("rest") || normalizedName.contains("track me") || normalizedName.contains("meditation") || normalizedName.contains("meditating") {
            return false
        }

        return true
    }
}
```

- [ ] **Step 5: Run filter tests**

Run:

```bash
xcodebuild test -scheme SportApp -destination 'platform=iOS Simulator,name=iPhone 15 Pro Max' -only-testing:SportAppTests/TrainingActivityFilterTests
```

Expected: PASS.

## Task 2: Weekly Effort Calculator

**Files:**
- Create: `SportApp/WeeklyEffortCalculator.swift`
- Test: `SportAppTests/WeeklyEffortCalculatorTests.swift`

- [ ] **Step 1: Add calculator tests**

Create `SportAppTests/WeeklyEffortCalculatorTests.swift`:

```swift
import Foundation
import Testing
@testable import SportApp

struct WeeklyEffortCalculatorTests {
    private let calendar = WeeklyEffortCalculator.makeMondayFirstCalendar()

    @Test func dropsPartialWeeksAndUsesMondayToSunday() throws {
        let activities = [
            activity(id: 1, date: "2025-06-14", calories: 100, durationMinutes: 10),
            activity(id: 2, date: "2025-06-16", calories: 120, durationMinutes: 20),
            activity(id: 3, date: "2025-06-22", calories: 60, durationMinutes: 10),
            activity(id: 4, date: "2025-06-23", calories: 500, durationMinutes: 10)
        ]

        let points = WeeklyEffortCalculator(filter: .default).calculate(from: activities)

        #expect(points.count == 1)
        #expect(points[0].tooltipStart == "06/16/2025")
        #expect(points[0].tooltipEnd == "06/22/2025")
        #expect(points[0].value == 12)
    }

    @Test func averagesMultipleTrainingValuesInsideDayThenSumsDaysInsideWeek() throws {
        let activities = [
            activity(id: 1, date: "2025-06-16", calories: 100, durationMinutes: 10),
            activity(id: 2, date: "2025-06-16", calories: 60, durationMinutes: 20),
            activity(id: 3, date: "2025-06-17", calories: 90, durationMinutes: 30)
        ]

        let points = WeeklyEffortCalculator(filter: .default).calculate(from: activities)

        #expect(points.count == 1)
        #expect(abs(points[0].value - 9.5) < 0.0001)
    }

    @Test func skipsInvalidActivitiesMissingCaloriesOrDuration() throws {
        let activities = [
            activity(id: 1, date: "2025-06-16", calories: nil, durationMinutes: 10),
            activity(id: 2, date: "2025-06-17", calories: 100, durationMinutes: 0),
            activity(id: 3, date: "2025-06-18", calories: 80, durationMinutes: 20),
            activity(id: 4, date: "2025-06-19", name: "Rest", activityType: "other", sportType: "INVALID", calories: 300, durationMinutes: 30)
        ]

        let points = WeeklyEffortCalculator(filter: .default).calculate(from: activities)

        #expect(points.count == 1)
        #expect(points[0].value == 4)
    }

    private func activity(
        id: Int64,
        date: String,
        name: String = "Training",
        activityType: String = "cycling",
        sportType: String? = "CYCLING",
        calories: Double?,
        durationMinutes: Double
    ) -> GarminActivity {
        let start = try! Date(date, strategy: .iso8601.year().month().day())
        return GarminActivity(
            activityId: id,
            name: name,
            activityType: activityType,
            sportType: sportType,
            startTimeLocal: start.timeIntervalSince1970 * 1000,
            startTimeGmt: start.timeIntervalSince1970 * 1000,
            duration: durationMinutes * 60 * 1000,
            calories: calories
        )
    }
}
```

- [ ] **Step 2: Run calculator tests to verify they fail**

Run:

```bash
xcodebuild test -scheme SportApp -destination 'platform=iOS Simulator,name=iPhone 15 Pro Max' -only-testing:SportAppTests/WeeklyEffortCalculatorTests
```

Expected: fails because `WeeklyEffortCalculator` and `WeeklyEffortPoint` do not exist.

- [ ] **Step 3: Add calculator implementation**

Create `SportApp/WeeklyEffortCalculator.swift`:

```swift
import Foundation

struct WeeklyEffortPoint: Identifiable, Equatable {
    let weekStart: Date
    let weekEnd: Date
    let value: Double

    var id: Date { weekStart }

    var tooltipStart: String {
        Self.tooltipFormatter.string(from: weekStart)
    }

    var tooltipEnd: String {
        Self.tooltipFormatter.string(from: weekEnd)
    }

    private static let tooltipFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = WeeklyEffortCalculator.makeMondayFirstCalendar()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter
    }()
}

struct WeeklyEffortCalculator {
    let filter: TrainingActivityFilter

    static func makeMondayFirstCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 2
        return calendar
    }

    func calculate(from activities: [GarminActivity]) -> [WeeklyEffortPoint] {
        let calendar = Self.makeMondayFirstCalendar()
        let datedActivities = activities.compactMap { activity -> (GarminActivity, Date)? in
            guard filter.includes(activity) else { return nil }
            return (activity, Date(timeIntervalSince1970: activity.startTimeLocal / 1000))
        }

        guard
            let minDate = datedActivities.map(\.1).min(),
            let maxDate = datedActivities.map(\.1).max(),
            let firstWeekStart = firstCompleteWeekStart(onOrAfter: minDate, calendar: calendar),
            let lastWeekStart = lastCompleteWeekStart(onOrBefore: maxDate, calendar: calendar),
            firstWeekStart <= lastWeekStart
        else {
            return []
        }

        var valuesByDay: [Date: [Double]] = [:]

        for (activity, date) in datedActivities {
            guard
                date >= firstWeekStart,
                date < calendar.date(byAdding: .day, value: 7, to: lastWeekStart)!,
                let calories = activity.calories,
                let duration = activity.duration,
                duration > 0
            else {
                continue
            }

            let durationMinutes = duration / 1000 / 60
            guard durationMinutes > 0 else { continue }

            let dayStart = calendar.startOfDay(for: date)
            valuesByDay[dayStart, default: []].append(calories / durationMinutes)
        }

        var points: [WeeklyEffortPoint] = []
        var weekStart = firstWeekStart

        while weekStart <= lastWeekStart {
            var weeklyValue = 0.0

            for offset in 0..<7 {
                let day = calendar.date(byAdding: .day, value: offset, to: weekStart)!
                let dayValues = valuesByDay[day, default: []]
                if !dayValues.isEmpty {
                    weeklyValue += dayValues.reduce(0, +) / Double(dayValues.count)
                }
            }

            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
            points.append(WeeklyEffortPoint(weekStart: weekStart, weekEnd: weekEnd, value: weeklyValue))
            weekStart = calendar.date(byAdding: .day, value: 7, to: weekStart)!
        }

        return points
    }

    private func firstCompleteWeekStart(onOrAfter date: Date, calendar: Calendar) -> Date? {
        let dayStart = calendar.startOfDay(for: date)
        if calendar.component(.weekday, from: dayStart) == 2 {
            return dayStart
        }
        return calendar.nextDate(after: dayStart, matching: DateComponents(weekday: 2), matchingPolicy: .nextTime)
    }

    private func lastCompleteWeekStart(onOrBefore date: Date, calendar: Calendar) -> Date? {
        let dayStart = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: dayStart)
        let daysFromMonday = (weekday + 5) % 7
        let currentWeekStart = calendar.date(byAdding: .day, value: -daysFromMonday, to: dayStart)!
        let currentWeekEnd = calendar.date(byAdding: .day, value: 6, to: currentWeekStart)!

        if dayStart >= currentWeekEnd {
            return currentWeekStart
        }

        return calendar.date(byAdding: .day, value: -7, to: currentWeekStart)
    }
}
```

- [ ] **Step 4: Run calculator tests**

Run:

```bash
xcodebuild test -scheme SportApp -destination 'platform=iOS Simulator,name=iPhone 15 Pro Max' -only-testing:SportAppTests/WeeklyEffortCalculatorTests
```

Expected: PASS.

## Task 3: Bundle Resource and Loader

**Files:**
- Create: `SportApp/GarminActivitiesLoader.swift`
- Create: `SportApp/garmin_summarized_activities.json`
- Modify: `SportApp.xcodeproj/project.pbxproj`
- Test: `SportAppTests/GarminActivitiesLoaderTests.swift`

- [ ] **Step 1: Copy summarized activities into the app target**

Copy:

```text
from_garmin_official_export/DI_CONNECT/DI-Connect-Fitness/iadomyshev@gmail.com_0_summarizedActivities.json
```

to:

```text
SportApp/garmin_summarized_activities.json
```

Then add `SportApp/garmin_summarized_activities.json` to the Xcode app target resources.

- [ ] **Step 2: Add loader implementation**

Create `SportApp/GarminActivitiesLoader.swift`:

```swift
import Foundation

struct GarminActivitiesLoader {
    enum LoaderError: Error {
        case resourceNotFound
    }

    var bundle: Bundle = .main
    var resourceName: String = "garmin_summarized_activities"

    func load() throws -> [GarminActivity] {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw LoaderError.resourceNotFound
        }

        let data = try Data(contentsOf: url)
        let exports = try JSONDecoder().decode([GarminActivitiesExport].self, from: data)
        return exports.first?.summarizedActivitiesExport ?? []
    }
}
```

- [ ] **Step 3: Add loader test**

Create `SportAppTests/GarminActivitiesLoaderTests.swift`:

```swift
import Testing
@testable import SportApp

struct GarminActivitiesLoaderTests {
    @Test func loadsBundledActivities() throws {
        let activities = try GarminActivitiesLoader().load()

        #expect(!activities.isEmpty)
        #expect(activities.contains { $0.activityType == "cycling" || $0.activityType == "lap_swimming" })
    }
}
```

- [ ] **Step 4: Run loader test**

Run:

```bash
xcodebuild test -scheme SportApp -destination 'platform=iOS Simulator,name=iPhone 15 Pro Max' -only-testing:SportAppTests/GarminActivitiesLoaderTests
```

Expected: PASS.

## Task 4: SwiftUI Screen and Chart

**Files:**
- Create: `SportApp/WeeklyEffortView.swift`
- Create: `SportApp/WeeklyEffortChartView.swift`
- Modify: `SportApp/ContentView.swift`

- [ ] **Step 1: Add weekly effort screen**

Create `SportApp/WeeklyEffortView.swift`:

```swift
import SwiftUI

struct WeeklyEffortView: View {
    @State private var points: [WeeklyEffortPoint] = []
    @State private var selectedPoint: WeeklyEffortPoint?

    private let loader = GarminActivitiesLoader()
    private let calculator = WeeklyEffortCalculator(filter: .default)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Илья")
                .font(.system(size: 34, weight: .bold, design: .default))
                .foregroundStyle(.primary)

            Text("ты тренируешься уже \(points.count) недель")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.secondary)
                .padding(.top, 10)

            WeeklyEffortChartView(points: points, selectedPoint: $selectedPoint)
                .padding(.top, 24)
        }
        .padding(.horizontal, 18)
        .padding(.top, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.systemBackground))
        .task {
            loadPoints()
        }
    }

    private func loadPoints() {
        do {
            let activities = try loader.load()
            points = calculator.calculate(from: activities)
            selectedPoint = points.first
        } catch {
            points = []
            selectedPoint = nil
        }
    }
}

#Preview {
    WeeklyEffortView()
}
```

- [ ] **Step 2: Add chart view**

Create `SportApp/WeeklyEffortChartView.swift`:

```swift
import SwiftUI

struct WeeklyEffortChartView: View {
    let points: [WeeklyEffortPoint]
    @Binding var selectedPoint: WeeklyEffortPoint?

    private let chartHeight: CGFloat = 168
    private let pointSpacing: CGFloat = 36
    private let horizontalInset: CGFloat = 18

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()

            if points.isEmpty {
                emptyChart
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    chartCanvas
                        .frame(width: chartWidth, height: chartHeight)
                        .contentShape(Rectangle())
                }
            }

            if let first = points.first, let last = points.last {
                HStack {
                    Text(first.tooltipStart)
                    Spacer()
                    Text(last.tooltipEnd)
                }
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
            }
        }
    }

    private var emptyChart: some View {
        Rectangle()
            .fill(Color(.secondarySystemBackground))
            .frame(height: chartHeight)
            .overlay {
                Text("Нет данных")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
    }

    private var chartCanvas: some View {
        GeometryReader { proxy in
            let positions = pointPositions(in: proxy.size)

            ZStack(alignment: .topLeading) {
                gridLines(size: proxy.size)
                linePath(positions: positions)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                    let position = positions[index]
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 5, height: 5)
                        .position(position)
                        .onTapGesture {
                            selectedPoint = point
                        }
                }

                if let selectedPoint, let index = points.firstIndex(of: selectedPoint) {
                    tooltip(for: selectedPoint)
                        .position(x: positions[index].x, y: max(28, positions[index].y - 38))
                }
            }
        }
    }

    private var chartWidth: CGFloat {
        max(CGFloat(points.count - 1) * pointSpacing + horizontalInset * 2, 360)
    }

    private func pointPositions(in size: CGSize) -> [CGPoint] {
        let maxValue = max(points.map(\.value).max() ?? 1, 1)
        let topPadding: CGFloat = 18
        let bottomPadding: CGFloat = 30
        let drawableHeight = size.height - topPadding - bottomPadding

        return points.enumerated().map { index, point in
            let x = horizontalInset + CGFloat(index) * pointSpacing
            let normalized = point.value / maxValue
            let y = topPadding + drawableHeight * (1 - normalized)
            return CGPoint(x: x, y: y)
        }
    }

    private func linePath(positions: [CGPoint]) -> Path {
        Path { path in
            guard let first = positions.first else { return }
            path.move(to: first)
            for position in positions.dropFirst() {
                path.addLine(to: position)
            }
        }
    }

    private func gridLines(size: CGSize) -> some View {
        Path { path in
            for fraction in [0.25, 0.5, 0.75] {
                let y = size.height * fraction
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
        }
        .stroke(Color(.systemGray5), lineWidth: 1)
    }

    private func tooltip(for point: WeeklyEffortPoint) -> some View {
        VStack(spacing: 2) {
            Text("Неделя")
                .font(.system(size: 12, weight: .bold))
            Text(point.tooltipStart)
                .font(.system(size: 12))
            Text(point.tooltipEnd)
                .font(.system(size: 12))
        }
        .multilineTextAlignment(.center)
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color(.darkGray), in: RoundedRectangle(cornerRadius: 8))
    }
}
```

- [ ] **Step 3: Replace ContentView body**

Modify `SportApp/ContentView.swift`:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        WeeklyEffortView()
    }
}

#Preview {
    ContentView()
}
```

- [ ] **Step 4: Build app**

Run:

```bash
xcodebuild build -scheme SportApp -destination 'platform=iOS Simulator,name=iPhone 15 Pro Max'
```

Expected: BUILD SUCCEEDED.

## Task 5: Full Verification

**Files:**
- No new files.

- [ ] **Step 1: Run all tests**

Run:

```bash
xcodebuild test -scheme SportApp -destination 'platform=iOS Simulator,name=iPhone 15 Pro Max'
```

Expected: all Swift Testing tests pass.

- [ ] **Step 2: Run builds for target devices**

Run:

```bash
xcodebuild build -scheme SportApp -destination 'platform=iOS Simulator,name=iPhone 15 Pro Max'
xcodebuild build -scheme SportApp -destination 'platform=iOS Simulator,name=iPhone 14 Pro Max'
```

Expected: both builds succeed. If iPhone Air simulator is unavailable locally, record that it could not be verified.

- [ ] **Step 3: Inspect git status**

Run:

```bash
git status --short
```

Expected: only intended files changed. Do not commit unless the user explicitly asks.
