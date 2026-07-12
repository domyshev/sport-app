import Foundation
import CoreGraphics

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

    var axisLabel: String {
        Self.axisDateFormatter.string(from: weekStart)
    }

    static let axisDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = WeeklyEffortCalculator.makeMondayFirstCalendar()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()

    private static let tooltipFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = WeeklyEffortCalculator.makeMondayFirstCalendar()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter
    }()
}

struct WeeklyEffortXAxisLabel: Equatable {
    let index: Int
    let text: String
}

enum WeeklyEffortChartAxisValues {
    static func xAxisLabels(for points: [WeeklyEffortPoint]) -> [WeeklyEffortXAxisLabel] {
        xAxisLabels(for: points, visibleWidth: 408, pointSpacing: WeeklyEffortChartScale.standard.pointSpacing)
    }

    static func xAxisLabels(
        for points: [WeeklyEffortPoint],
        visibleWidth: CGFloat,
        pointSpacing: CGFloat
    ) -> [WeeklyEffortXAxisLabel] {
        guard !points.isEmpty else {
            return []
        }

        if points.count <= 4 {
            return points.enumerated().map { index, point in
                WeeklyEffortXAxisLabel(index: index, text: point.axisLabel)
            }
        }

        let safePointSpacing = max(pointSpacing, 1)
        let minimumIndexSpacing = max(Int(ceil(visibleWidth / (3 * safePointSpacing))), 1)
        let lastIndex = points.count - 1
        var indexes: [Int] = []
        var index = 0

        while index <= lastIndex {
            indexes.append(index)
            index += minimumIndexSpacing
        }

        if indexes.last != lastIndex {
            indexes.append(lastIndex)
            while indexes.count >= 2,
                  indexes[indexes.count - 1] - indexes[indexes.count - 2] < minimumIndexSpacing {
                indexes.remove(at: indexes.count - 2)
            }
        }

        return indexes.map { index in
            WeeklyEffortXAxisLabel(index: index, text: points[index].axisLabel)
        }
    }

    static func yAxisLabels(maxValue: Double) -> [Double] {
        let maximum = max(maxValue, 0)
        return (0..<4).map { index in
            maximum * Double(index) / 3
        }
    }
}

enum WeeklyEffortChartScale: Int, Codable, Equatable, CaseIterable {
    case compact
    case standard
    case wide

    var pointSpacing: CGFloat {
        switch self {
        case .compact:
            return 22
        case .standard:
            return 34
        case .wide:
            return 52
        }
    }

    var canZoomOut: Bool {
        self != .compact
    }

    var canZoomIn: Bool {
        self != .wide
    }

    func zoomedOut() -> Self {
        switch self {
        case .compact:
            return .compact
        case .standard:
            return .compact
        case .wide:
            return .standard
        }
    }

    func zoomedIn() -> Self {
        switch self {
        case .compact:
            return .standard
        case .standard:
            return .wide
        case .wide:
            return .wide
        }
    }

    func reset() -> Self {
        .standard
    }
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

    func calculate(from activities: [TrainingActivity]) -> [WeeklyEffortPoint] {
        let activityDays = activities.map { calendar.startOfDay(for: $0.startDate) }
        guard let firstActivityDay = activityDays.min(),
              let lastActivityDay = activityDays.max()
        else {
            return []
        }

        return calculate(from: activities, firstDay: firstActivityDay, lastDay: lastActivityDay)
    }

    func calculate(
        from activities: [TrainingActivity],
        period: TrainingPeriodSelection,
        typeSelection: TrainingActivityTypeSelection
    ) -> [WeeklyEffortPoint] {
        guard let latestActivity = activities.max(by: { $0.startDate < $1.startDate }) else {
            return []
        }

        let latestDate = latestActivity.startDate
        let range = period.dateRange(latestDate: latestDate, calendar: calendar)
        let filteredActivities = activities.filter { activity in
            let date = calendar.startOfDay(for: activity.startDate)
            return range.contains(date) && typeSelection.includes(activity) && filter.includes(activity)
        }

        guard !filteredActivities.isEmpty else {
            return []
        }

        return calculate(from: filteredActivities, firstDay: range.lowerBound, lastDay: range.upperBound)
    }

    private func calculate(from activities: [TrainingActivity], firstDay: Date, lastDay: Date) -> [WeeklyEffortPoint] {
        guard let firstWeekStart = firstCompleteWeekStart(from: firstDay),
              let lastWeekStart = lastCompleteWeekStart(from: lastDay),
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

    private func dailyAverages(from activities: [TrainingActivity]) -> [Date: Double] {
        let valuesByDay = activities.reduce(into: [Date: [Double]]()) { result, activity in
            guard filter.includes(activity),
                  let value = effortValue(for: activity)
            else {
                return
            }

            let day = calendar.startOfDay(for: activity.startDate)
            result[day, default: []].append(value)
        }

        return valuesByDay.mapValues { values in
            values.reduce(0, +) / Double(values.count)
        }
    }

    private func effortValue(for activity: TrainingActivity) -> Double? {
        guard let calories = activity.caloriesKilocalories,
              let durationSeconds = activity.durationSeconds,
              durationSeconds > 0
        else {
            return nil
        }

        let durationMinutes = durationSeconds / 60
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
}
