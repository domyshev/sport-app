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
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter
    }()
}

struct WeeklyEffortCalculator {
    let filter: TrainingActivityFilter
    let calendar: Calendar

    init(
        filter: TrainingActivityFilter = .default,
        calendar: Calendar = Self.makeMondayFirstCalendar()
    ) {
        self.filter = filter
        self.calendar = calendar
    }

    func calculate(from activities: [GarminActivity]) -> [WeeklyEffortPoint] {
        let activityDays = activities.map { calendar.startOfDay(for: Self.date(fromMilliseconds: $0.startTimeLocal)) }
        guard let firstActivityDay = activityDays.min(),
              let lastActivityDay = activityDays.max(),
              let firstWeekStart = firstCompleteWeekStart(from: firstActivityDay),
              let lastWeekStart = lastCompleteWeekStart(from: lastActivityDay),
              firstWeekStart <= lastWeekStart
        else {
            return []
        }

        let dailyAverages = dailyAverages(from: activities)
        var points: [WeeklyEffortPoint] = []
        var weekStart = firstWeekStart

        while weekStart <= lastWeekStart {
            let weekValue = (0..<7).reduce(0.0) { partial, dayOffset in
                guard let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else {
                    return partial
                }

                return partial + (dailyAverages[day] ?? 0)
            }

            guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
                break
            }

            points.append(WeeklyEffortPoint(weekStart: weekStart, weekEnd: weekEnd, value: weekValue))

            guard let nextWeekStart = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
                break
            }
            weekStart = nextWeekStart
        }

        return points
    }

    static func makeMondayFirstCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 1
        return calendar
    }

    private func dailyAverages(from activities: [GarminActivity]) -> [Date: Double] {
        let valuesByDay = activities.reduce(into: [Date: [Double]]()) { result, activity in
            guard filter.includes(activity),
                  let value = effortValue(for: activity)
            else {
                return
            }

            let day = calendar.startOfDay(for: Self.date(fromMilliseconds: activity.startTimeLocal))
            result[day, default: []].append(value)
        }

        return valuesByDay.mapValues { values in
            values.reduce(0, +) / Double(values.count)
        }
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

    private func firstCompleteWeekStart(from firstDay: Date) -> Date? {
        guard let containingWeekStart = calendar.dateInterval(of: .weekOfYear, for: firstDay)?.start else {
            return nil
        }

        if firstDay == containingWeekStart {
            return containingWeekStart
        }

        return calendar.date(byAdding: .day, value: 7, to: containingWeekStart)
    }

    private func lastCompleteWeekStart(from lastDay: Date) -> Date? {
        guard let containingWeekStart = calendar.dateInterval(of: .weekOfYear, for: lastDay)?.start,
              let containingWeekEnd = calendar.date(byAdding: .day, value: 6, to: containingWeekStart)
        else {
            return nil
        }

        if lastDay >= containingWeekEnd {
            return containingWeekStart
        }

        return calendar.date(byAdding: .day, value: -7, to: containingWeekStart)
    }

    private static func date(fromMilliseconds milliseconds: Double) -> Date {
        Date(timeIntervalSince1970: milliseconds / 1000)
    }
}
