import Foundation

struct TrainingActivityFilter {
    var includes: (TrainingActivity) -> Bool

    static let `default` = TrainingActivityFilter { activity in
        let blockedSportTypes = Set(["INVALID", "MEDITATION"])
        if let sportType = activity.sportType?.uppercased(), blockedSportTypes.contains(sportType) {
            return false
        }

        let normalizedName = activity.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalizedName.contains("rest") ||
            normalizedName.contains("track me") ||
            normalizedName.contains("meditation") ||
            normalizedName.contains("meditating") {
            return false
        }

        return true
    }
}
