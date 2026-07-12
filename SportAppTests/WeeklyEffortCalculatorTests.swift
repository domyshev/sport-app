import Foundation
import Testing
@testable import SportApp

struct WeeklyEffortCalculatorTests {
    @Test func dropsPartialWeeksAndUsesMondayToSunday() {
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

    @Test func averagesMultipleTrainingValuesInsideDayThenSumsDaysInsideWeek() {
        let activities = [
            activity(id: 1, date: "2025-06-16", calories: 100, durationMinutes: 10),
            activity(id: 2, date: "2025-06-16", calories: 60, durationMinutes: 20),
            activity(id: 3, date: "2025-06-17", calories: 90, durationMinutes: 30),
            activity(id: 4, date: "2025-06-22", calories: 40, durationMinutes: 20)
        ]

        let points = WeeklyEffortCalculator(filter: .default).calculate(from: activities)

        #expect(points.count == 1)
        #expect(abs(points[0].value - 11.5) < 0.0001)
    }

    @Test func skipsInvalidActivitiesMissingCaloriesOrDuration() {
        let activities = [
            activity(id: 1, date: "2025-06-16", calories: nil, durationMinutes: 10),
            activity(id: 2, date: "2025-06-17", calories: 100, durationMinutes: 0),
            activity(id: 3, date: "2025-06-18", calories: 80, durationMinutes: 20),
            activity(id: 4, date: "2025-06-19", name: "Rest", activityType: "other", sportType: "INVALID", calories: 300, durationMinutes: 30),
            activity(id: 5, date: "2025-06-22", calories: 0, durationMinutes: 10)
        ]

        let points = WeeklyEffortCalculator(filter: .default).calculate(from: activities)

        #expect(points.count == 1)
        #expect(points[0].value == 4)
    }

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

    private func activity(
        id: Int64,
        date: String,
        name: String = "Training",
        activityType: String = "cycling",
        sportType: String? = "CYCLING",
        calories: Double?,
        durationMinutes: Double
    ) -> TrainingActivity {
        let start = Self.isoDateFormatter.date(from: date)!
        return TrainingActivity(
            id: uuid(id),
            name: name,
            activityType: activityType,
            sportType: sportType,
            startDate: start,
            durationSeconds: durationMinutes * 60,
            caloriesKilocalories: calories,
            distanceMeters: nil,
            primarySource: .garminOfficialExport,
            sourceReferences: [.init(source: .garminOfficialExport, id: "\(id)")]
        )
    }

    private func uuid(_ value: Int64) -> UUID {
        UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012lld", value))")!
    }

    private static let isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private func date(_ value: String) -> Date {
        Self.isoDateFormatter.date(from: value)!
    }
}
