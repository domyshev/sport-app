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
        guard TrainingActivityTypeCategory(activity: lhs) == TrainingActivityTypeCategory(activity: rhs) else {
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

        if let lhsCalories = lhs.caloriesKilocalories,
           let rhsCalories = rhs.caloriesKilocalories,
           !valuesAreClose(lhsCalories, rhsCalories, absoluteTolerance: 50, relativeTolerance: 0.1) {
            return false
        }

        return true
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
        result.activityType = preferred.activityType.isEmpty ? fallback.activityType : preferred.activityType
        result.sportType = preferred.sportType ?? fallback.sportType
        result.startDate = preferred.startDate
        result.durationSeconds = preferred.durationSeconds ?? fallback.durationSeconds
        result.caloriesKilocalories = preferred.caloriesKilocalories ?? fallback.caloriesKilocalories
        result.distanceMeters = preferred.distanceMeters ?? fallback.distanceMeters
        result.primarySource = preferred.primarySource
        result.addSourceReferences(existing.sourceReferences)
        result.addSourceReferences(incoming.sourceReferences)
        return result
    }

    private func preferredActivity(_ lhs: TrainingActivity, _ rhs: TrainingActivity) -> TrainingActivity {
        if lhs.primarySource.priority == rhs.primarySource.priority {
            return lhs
        }

        return lhs.primarySource.priority > rhs.primarySource.priority ? lhs : rhs
    }
}
