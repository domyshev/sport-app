import Foundation
import Testing
@testable import SportApp

struct TodayEffortCalculatorTests {
    @Test func summarizesTrainingActivitiesForSelectedDay() {
        let activities = [
            activity(id: 1, date: "2026-07-11", calories: 100, durationMinutes: 10),
            activity(id: 2, date: "2026-07-11", calories: 60, durationMinutes: 20),
            activity(id: 3, date: "2026-07-10", calories: 500, durationMinutes: 50),
            activity(id: 4, date: "2026-07-11", name: "Rest", activityType: "other", sportType: "INVALID", calories: 50, durationMinutes: 10)
        ]

        let summary = TodayEffortCalculator().calculate(
            from: activities,
            on: Self.isoDateFormatter.date(from: "2026-07-11")!
        )

        #expect(summary.trainingCount == 2)
        #expect(summary.calories == 160)
        #expect(summary.durationMinutes == 30)
        #expect(abs(summary.effort - 6.5) < 0.0001)
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
        let start = Self.isoDateFormatter.date(from: date)!
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

    private static let isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
