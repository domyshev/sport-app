import Foundation

struct TodayEffortSummary: Equatable {
    let trainingCount: Int
    let calories: Double
    let durationMinutes: Double
    let effort: Double

    static let empty = TodayEffortSummary(
        trainingCount: 0,
        calories: 0,
        durationMinutes: 0,
        effort: 0
    )
}

struct TodayEffortCalculator {
    let filter: TrainingActivityFilter
    let calendar: Calendar

    init(
        filter: TrainingActivityFilter = .default,
        calendar: Calendar = WeeklyEffortCalculator.makeMondayFirstCalendar()
    ) {
        self.filter = filter
        self.calendar = calendar
    }

    func calculate(from activities: [GarminActivity], on date: Date = Date()) -> TodayEffortSummary {
        let targetDay = calendar.startOfDay(for: date)
        let todayActivities = activities.filter { activity in
            filter.includes(activity)
                && calendar.startOfDay(for: Self.date(fromMilliseconds: activity.startTimeLocal)) == targetDay
        }

        let calories = todayActivities.compactMap(\.calories).reduce(0, +)
        let durationMinutes = todayActivities.compactMap { activity -> Double? in
            guard let duration = activity.duration, duration > 0 else {
                return nil
            }
            return duration / 60_000
        }.reduce(0, +)

        let effortValues = todayActivities.compactMap(effortValue)
        let effort = effortValues.isEmpty ? 0 : effortValues.reduce(0, +) / Double(effortValues.count)

        return TodayEffortSummary(
            trainingCount: todayActivities.count,
            calories: calories,
            durationMinutes: durationMinutes,
            effort: effort
        )
    }

    private func effortValue(for activity: GarminActivity) -> Double? {
        guard let calories = activity.calories,
              let duration = activity.duration,
              duration > 0
        else {
            return nil
        }

        let durationMinutes = duration / 60_000
        guard durationMinutes > 0 else {
            return nil
        }

        return calories / durationMinutes
    }

    private static func date(fromMilliseconds milliseconds: Double) -> Date {
        Date(timeIntervalSince1970: milliseconds / 1000)
    }
}
