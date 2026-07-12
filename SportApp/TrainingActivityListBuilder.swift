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

    func dateRange(latestDate: Date, calendar: Calendar) -> ClosedRange<Date> {
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

    func title(calendar: Calendar) -> String {
        switch value {
        case .preset(let preset):
            return preset.title
        case .custom(let start, let end):
            return "\(Self.customDateFormatter(calendar: calendar).string(from: min(start, end))) - \(Self.customDateFormatter(calendar: calendar).string(from: max(start, end)))"
        }
    }

    var customPeriod: TrainingRecentCustomPeriod? {
        switch value {
        case .preset:
            return nil
        case .custom(let start, let end):
            return TrainingRecentCustomPeriod(start: min(start, end), end: max(start, end))
        }
    }

    private static func customDateFormatter(calendar: Calendar) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }
}

extension TrainingPeriodSelection.Preset {
    var title: String {
        switch self {
        case .oneWeek: return "1 неделя"
        case .twoWeeks: return "2 недели"
        case .oneMonth: return "1 месяц"
        case .threeMonths: return "3 месяца"
        case .sixMonths: return "6 месяцев"
        case .oneYear: return "1 год"
        }
    }
}

struct TrainingActivityTypeCategory: Hashable, Codable, Identifiable, Comparable {
    let id: String
    let title: String

    nonisolated init(id: String, title: String) {
        self.id = id
        self.title = title
    }

    nonisolated init(activity: GarminActivity) {
        self.init(activityType: activity.activityType, name: activity.name)
    }

    nonisolated init(activity: TrainingActivity) {
        self.init(activityType: activity.activityType, name: activity.name)
    }

    private nonisolated init(activityType rawActivityType: String, name: String) {
        let activityType = rawActivityType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercasedName = normalizedName.lowercased()

        if lowercasedName.contains("rest") || activityType.contains("rest") {
            self.init(id: "rest", title: "Отдых")
            return
        }

        switch activityType {
        case "open_water_swimming":
            self.init(id: "open_water_swimming", title: "Плавание Море")
        case "lap_swimming":
            self.init(id: "lap_swimming", title: "Бассейн")
        case "cycling", "indoor_cycling":
            self.init(id: "cycling", title: "Велик")
        case "running":
            self.init(id: "running", title: "Бег")
        case "walking":
            self.init(id: "walking", title: "Ходьба")
        case "strength_training":
            self.init(id: "strength_training", title: "Силовая")
        case "elliptical":
            self.init(id: "elliptical", title: "Эллипс")
        case "stand_up_paddleboarding_v2":
            self.init(id: "stand_up_paddleboarding_v2", title: "SUP")
        default:
            self.init(id: activityType.isEmpty ? lowercasedName : activityType, title: normalizedName.isEmpty ? rawActivityType : normalizedName)
        }
    }

    static func availableCategories(from activities: [TrainingActivity]) -> [Self] {
        let categoriesByID = activities.reduce(into: [String: Self]()) { result, activity in
            let category = Self(activity: activity)
            result[category.id] = category
        }

        return categoriesByID.values.sorted { lhs, rhs in
            lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
        }
    }

    nonisolated static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
    }

    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct TrainingActivityTypeSelection: Equatable {
    private let selectedCategories: Set<TrainingActivityTypeCategory>?

    static let all = TrainingActivityTypeSelection()

    private init() {
        selectedCategories = nil
    }

    init(selected: some Sequence<TrainingActivityTypeCategory>) {
        selectedCategories = Set(selected)
    }

    var isAll: Bool {
        selectedCategories == nil
    }

    var selectedCount: Int {
        selectedCategories?.count ?? 0
    }

    var categories: Set<TrainingActivityTypeCategory>? {
        selectedCategories
    }

    func selectsAll(availableCategories: [TrainingActivityTypeCategory]) -> Bool {
        isAll || selectedCount == availableCategories.count
    }

    func includes(_ activity: TrainingActivity) -> Bool {
        guard let selectedCategories else { return true }
        return selectedCategories.contains(TrainingActivityTypeCategory(activity: activity))
    }

    func contains(_ category: TrainingActivityTypeCategory) -> Bool {
        guard let selectedCategories else { return true }
        return selectedCategories.contains(category)
    }

    func toggled(_ category: TrainingActivityTypeCategory, availableCategories: [TrainingActivityTypeCategory]) -> Self {
        var selected = selectedCategories ?? Set(availableCategories)
        if selected.contains(category) {
            selected.remove(category)
        } else {
            selected.insert(category)
        }

        if selected.count == availableCategories.count {
            return .all
        }

        return TrainingActivityTypeSelection(selected: selected)
    }

    func toggledAll(availableCategories: [TrainingActivityTypeCategory]) -> Self {
        guard !availableCategories.isEmpty else { return .all }
        if selectsAll(availableCategories: availableCategories) {
            return TrainingActivityTypeSelection(selected: [])
        }

        return .all
    }
}

struct TrainingRecentCustomPeriod: Codable, Equatable, Identifiable {
    let start: Date
    let end: Date

    var id: String {
        "\(start.timeIntervalSince1970)-\(end.timeIntervalSince1970)"
    }

    func selection() -> TrainingPeriodSelection {
        .custom(start: start, end: end)
    }

    func title(calendar: Calendar) -> String {
        selection().title(calendar: calendar)
    }
}

struct TrainingRecentCustomPeriods: Codable, Equatable {
    private(set) var items: [TrainingRecentCustomPeriod]

    init(items: [TrainingRecentCustomPeriod] = []) {
        self.items = Array(items.prefix(5))
    }

    mutating func remember(_ period: TrainingRecentCustomPeriod, calendar: Calendar) {
        let normalized = TrainingRecentCustomPeriod(
            start: calendar.startOfDay(for: min(period.start, period.end)),
            end: calendar.startOfDay(for: max(period.start, period.end))
        )
        items.removeAll { $0 == normalized }
        items.insert(normalized, at: 0)
        items = Array(items.prefix(5))
    }

    func encoded() -> Data {
        (try? JSONEncoder().encode(self)) ?? Data()
    }

    static func decoded(from data: Data) -> Self {
        guard !data.isEmpty,
              let decoded = try? JSONDecoder().decode(Self.self, from: data)
        else {
            return Self()
        }
        return decoded
    }
}

struct TrainingActivityListBuilder {
    let calendar: Calendar

    init(calendar: Calendar = WeeklyEffortCalculator.makeMondayFirstCalendar()) {
        self.calendar = calendar
    }

    func buildCards(
        from activities: [TrainingActivity],
        period: TrainingPeriodSelection,
        typeSelection: TrainingActivityTypeSelection = .all
    ) -> [TrainingActivityCardModel] {
        guard let latestActivity = activities.max(by: { $0.startDate < $1.startDate }) else { return [] }
        let latestDate = latestActivity.startDate
        let range = period.dateRange(latestDate: latestDate, calendar: calendar)

        return activities
            .filter { activity in
                let date = calendar.startOfDay(for: activity.startDate)
                return range.contains(date) && typeSelection.includes(activity)
            }
            .sorted { lhs, rhs in
                if lhs.startDate != rhs.startDate { return lhs.startDate > rhs.startDate }
                return lhs.id.uuidString > rhs.id.uuidString
            }
            .map(makeCard)
    }

    private func makeCard(from activity: TrainingActivity) -> TrainingActivityCardModel {
        TrainingActivityCardModel(
            id: activity.id,
            activityType: activity.activityType,
            title: TrainingActivityPresentation.title(for: activity),
            distanceText: TrainingActivityPresentation.distanceText(forMeters: activity.distanceMeters),
            durationText: TrainingActivityPresentation.durationText(forSeconds: activity.durationSeconds),
            startTimeText: TrainingActivityPresentation.startTimeText(for: activity.startDate),
            caloriesText: TrainingActivityPresentation.caloriesText(for: activity.caloriesKilocalories)
        )
    }
}
