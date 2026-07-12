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

    func calculate(from activities: [TrainingActivity], on date: Date = Date()) -> TodayEffortSummary {
        let targetDay = calendar.startOfDay(for: date)
        let todayActivities = activities.filter { activity in
            filter.includes(activity)
                && calendar.startOfDay(for: activity.startDate) == targetDay
        }

        let calories = todayActivities.compactMap(\.caloriesKilocalories).reduce(0, +)
        let durationMinutes = todayActivities.compactMap { activity -> Double? in
            guard let duration = activity.durationSeconds, duration > 0 else {
                return nil
            }
            return duration / 60
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

    private func effortValue(for activity: TrainingActivity) -> Double? {
        guard let calories = activity.caloriesKilocalories,
              let duration = activity.durationSeconds,
              duration > 0
        else {
            return nil
        }

        let durationMinutes = duration / 60
        guard durationMinutes > 0 else {
            return nil
        }

        return calories / durationMinutes
    }
}
