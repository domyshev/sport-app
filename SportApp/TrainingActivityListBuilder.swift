import Foundation

struct TrainingPeriodSelection: Equatable {
    enum Preset: CaseIterable {
        case oneWeek
        case twoWeeks
        case oneMonth
        case threeMonths
        case sixMonths
        case oneYear
    }

    private enum Value: Equatable {
        case preset(Preset)
        case custom(start: Date, end: Date)
    }

    private let value: Value

    private init(value: Value) { self.value = value }

    static func preset(_ preset: Preset) -> Self { Self(value: .preset(preset)) }

    static func custom(start: Date, end: Date) -> Self { Self(value: .custom(start: start, end: end)) }

    fileprivate func dateRange(latestDate: Date, calendar: Calendar) -> ClosedRange<Date> {
        let latestDay = calendar.startOfDay(for: latestDate)
        switch value {
        case .preset(let preset):
            let start: Date
            switch preset {
            case .oneWeek:
                start = calendar.date(byAdding: .day, value: -6, to: latestDay) ?? latestDay
            case .twoWeeks:
                start = calendar.date(byAdding: .day, value: -13, to: latestDay) ?? latestDay
            case .oneMonth:
                start = calendar.date(byAdding: .month, value: -1, to: latestDay) ?? latestDay
            case .threeMonths:
                start = calendar.date(byAdding: .month, value: -3, to: latestDay) ?? latestDay
            case .sixMonths:
                start = calendar.date(byAdding: .month, value: -6, to: latestDay) ?? latestDay
            case .oneYear:
                start = calendar.date(byAdding: .year, value: -1, to: latestDay) ?? latestDay
            }
            return start...latestDay
        case .custom(let start, let end):
            let normalizedStart = calendar.startOfDay(for: min(start, end))
            let normalizedEnd = calendar.startOfDay(for: max(start, end))
            return normalizedStart...normalizedEnd
        }
    }
}

struct TrainingActivityListBuilder {
    let calendar: Calendar

    init(calendar: Calendar = WeeklyEffortCalculator.makeMondayFirstCalendar()) {
        self.calendar = calendar
    }

    func buildCards(from activities: [GarminActivity], period: TrainingPeriodSelection) -> [TrainingActivityCardModel] {
        guard let latestActivity = activities.max(by: { $0.startTimeLocal < $1.startTimeLocal }) else { return [] }
        let latestDate = Date(timeIntervalSince1970: latestActivity.startTimeLocal / 1_000)
        let range = period.dateRange(latestDate: latestDate, calendar: calendar)

        return activities
            .filter { activity in
                let date = calendar.startOfDay(for: Date(timeIntervalSince1970: activity.startTimeLocal / 1_000))
                return range.contains(date)
            }
            .sorted { lhs, rhs in
                if lhs.startTimeLocal != rhs.startTimeLocal { return lhs.startTimeLocal > rhs.startTimeLocal }
                return lhs.activityId > rhs.activityId
            }
            .map(makeCard)
    }

    private func makeCard(from activity: GarminActivity) -> TrainingActivityCardModel {
        TrainingActivityCardModel(
            id: activity.activityId,
            activityType: activity.activityType,
            title: TrainingActivityPresentation.title(for: activity),
            distanceText: TrainingActivityPresentation.distanceText(forGarminCentimeters: activity.distance),
            durationText: TrainingActivityPresentation.durationText(for: activity.duration),
            startTimeText: TrainingActivityPresentation.startTimeText(for: activity.startTimeLocal),
            caloriesText: TrainingActivityPresentation.caloriesText(for: activity.calories)
        )
    }
}
