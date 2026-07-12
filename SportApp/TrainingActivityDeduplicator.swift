import Foundation

struct TrainingActivityDeduplicator {
    private let startTolerance: TimeInterval
    private let durationTolerance: TimeInterval

    init(startTolerance: TimeInterval = 120, durationTolerance: TimeInterval = 180) {
        self.startTolerance = startTolerance
        self.durationTolerance = durationTolerance
    }

    func merge(existing: [TrainingActivity], incoming: [TrainingActivity]) -> TrainingImportResult {
        var activities = existing
        var summary = TrainingImportSummary.empty

        for activity in incoming {
            if let exactIndex = activities.firstIndex(where: { sharesSourceReference($0, activity) }) {
                activities[exactIndex].addSourceReferences(activity.sourceReferences)
                summary.skippedDuplicates += 1
                continue
            }

            if let duplicateIndex = activities.firstIndex(where: { isProbableDuplicate($0, activity) }) {
                activities[duplicateIndex] = merged(existing: activities[duplicateIndex], incoming: activity)
                summary.updated += 1
                continue
            }

            activities.append(activity)
            summary.added += 1
        }

        return TrainingImportResult(activities: activities, summary: summary)
    }

    private func sharesSourceReference(_ lhs: TrainingActivity, _ rhs: TrainingActivity) -> Bool {
        !Set(lhs.sourceReferences).isDisjoint(with: Set(rhs.sourceReferences))
    }

    private func isProbableDuplicate(_ lhs: TrainingActivity, _ rhs: TrainingActivity) -> Bool {
        guard activityTypesAreCompatible(lhs, rhs) else {
            return false
        }

        guard abs(lhs.startDate.timeIntervalSince(rhs.startDate)) <= startTolerance else {
            return false
        }

        if let lhsDuration = lhs.durationSeconds,
           let rhsDuration = rhs.durationSeconds,
           abs(lhsDuration - rhsDuration) > durationTolerance {
            return false
        }

        if let lhsDistance = lhs.distanceMeters,
           let rhsDistance = rhs.distanceMeters,
           !valuesAreClose(lhsDistance, rhsDistance, absoluteTolerance: 100, relativeTolerance: 0.05) {
            return false
        }

        return true
    }

    private func activityTypesAreCompatible(_ lhs: TrainingActivity, _ rhs: TrainingActivity) -> Bool {
        TrainingActivityTypeCategory(activity: lhs) == TrainingActivityTypeCategory(activity: rhs)
            || (isSwimming(lhs) && isSwimming(rhs))
    }

    private func isSwimming(_ activity: TrainingActivity) -> Bool {
        switch activity.activityType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "swimming", "lap_swimming", "open_water_swimming":
            return true
        default:
            return false
        }
    }

    private func valuesAreClose(
        _ lhs: Double,
        _ rhs: Double,
        absoluteTolerance: Double,
        relativeTolerance: Double
    ) -> Bool {
        let difference = abs(lhs - rhs)
        let relativeBase = max(abs(lhs), abs(rhs), 1)
        return difference <= max(absoluteTolerance, relativeBase * relativeTolerance)
    }

    private func merged(existing: TrainingActivity, incoming: TrainingActivity) -> TrainingActivity {
        let preferred = preferredActivity(existing, incoming)
        let fallback = preferred.id == existing.id ? incoming : existing

        var result = existing
        result.name = preferred.name.isEmpty ? fallback.name : preferred.name
        result.activityType = mergedActivityType(preferred: preferred, fallback: fallback)
        result.sportType = preferred.sportType ?? fallback.sportType
        result.startDate = preferred.startDate
        result.durationSeconds = preferred.durationSeconds ?? fallback.durationSeconds
        result.caloriesKilocalories = mergedCalories(preferred: preferred, fallback: fallback)
        result.distanceMeters = preferred.distanceMeters ?? fallback.distanceMeters
        result.primarySource = preferred.primarySource
        result.addSourceReferences(existing.sourceReferences)
        result.addSourceReferences(incoming.sourceReferences)
        return result
    }

    private func mergedActivityType(preferred: TrainingActivity, fallback: TrainingActivity) -> String {
        if isSwimming(preferred), isSwimming(fallback) {
            if fallback.activityType == "open_water_swimming" {
                return fallback.activityType
            }

            if preferred.activityType == "swimming", !fallback.activityType.isEmpty {
                return fallback.activityType
            }
        }

        return preferred.activityType.isEmpty ? fallback.activityType : preferred.activityType
    }

    private func mergedCalories(preferred: TrainingActivity, fallback: TrainingActivity) -> Double? {
        if isGarminExport(preferred), let calories = preferred.caloriesKilocalories {
            return calories
        }

        if isGarminExport(fallback), let calories = fallback.caloriesKilocalories {
            return calories
        }

        return preferred.caloriesKilocalories ?? fallback.caloriesKilocalories
    }

    private func isGarminExport(_ activity: TrainingActivity) -> Bool {
        switch activity.primarySource {
        case .garminOfficialExport, .bundledGarminExport:
            return true
        case .appleHealth:
            return false
        }
    }

    private func preferredActivity(_ lhs: TrainingActivity, _ rhs: TrainingActivity) -> TrainingActivity {
        if lhs.primarySource.priority == rhs.primarySource.priority {
            return lhs
        }

        return lhs.primarySource.priority > rhs.primarySource.priority ? lhs : rhs
    }
}
