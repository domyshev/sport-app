import Foundation

enum TrainingActivityDisplayField: String, CaseIterable, Codable, Identifiable {
    case distance
    case duration
    case startTime
    case calories

    var id: String { rawValue }

    static let defaultFields: [Self] = [.distance, .duration, .startTime]
}

struct TrainingActivityCardModel: Identifiable, Equatable {
    let id: UUID
    let activityType: String
    let title: String
    let distanceText: String
    let durationText: String
    let startTimeText: String
    let caloriesText: String
}

enum TrainingActivityPresentation {
    private static let distanceKilometersFormatStyle = FloatingPointFormatStyle<Double>
        .number
        .precision(.fractionLength(1))
        .locale(Locale(identifier: "ru_RU"))

    static func title(for activity: TrainingActivity) -> String {
        let activityType = activity.activityType.lowercased()
        let normalizedName = activity.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if normalizedName.contains("rest") || activityType.contains("rest") {
            return "Отдых"
        }

        switch activityType {
        case "open_water_swimming":
            return "Плавание Море"
        case "lap_swimming":
            return "Бассейн"
        case "cycling", "indoor_cycling":
            return "Велик"
        case "running":
            return "Бег"
        case "walking":
            return "Ходьба"
        case "strength_training":
            return "Силовая"
        case "elliptical":
            return "Эллипс"
        case "stand_up_paddleboarding_v2":
            return "SUP"
        default:
            return activity.name
        }
    }

    static func durationText(forSeconds seconds: Double?) -> String {
        guard let seconds, seconds > 0 else { return "—" }
        let totalMinutes = Int((seconds / 60).rounded())
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 && minutes > 0 { return "\(hours) ч \(minutes) мин" }
        if hours > 0 { return "\(hours) ч" }
        return "\(minutes) мин"
    }

    static func distanceText(forMeters meters: Double?) -> String {
        guard let meters, meters >= 0 else { return "—" }
        if meters >= 1_000 {
            let kilometers = meters / 1_000
            return kilometers.rounded() == kilometers ? "\(Int(kilometers)) км" : "\(kilometers.formatted(distanceKilometersFormatStyle)) км"
        }
        return "\(Int(meters.rounded())) м"
    }

    static func startTimeText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "d MMM, HH:mm"
        return formatter.string(from: date)
    }

    static func caloriesText(for calories: Double?) -> String {
        guard let calories else { return "—" }
        return "\(Int(calories.rounded())) ккал"
    }
}
