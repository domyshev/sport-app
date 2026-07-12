import Foundation
import HealthKit

struct HealthKitTrainingActivitySource {
    enum SourceError: Error {
        case healthDataUnavailable
        case authorizationDenied
    }

    private let healthStore: HKHealthStore

    init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
    }

    func requestAuthorizationAndFetch() async throws -> [TrainingActivity] {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw SourceError.healthDataUnavailable
        }

        try await healthStore.requestAuthorization(toShare: [], read: Self.readTypes())
        return try await fetchWorkouts()
    }

    private static func readTypes() -> Set<HKObjectType> {
        var types: Set<HKObjectType> = [HKObjectType.workoutType()]
        let quantityTypes: [HKQuantityTypeIdentifier] = [
            .activeEnergyBurned,
            .distanceWalkingRunning,
            .distanceCycling,
            .distanceSwimming
        ]

        for identifier in quantityTypes {
            if let type = HKQuantityType.quantityType(forIdentifier: identifier) {
                types.insert(type)
            }
        }

        return types
    }

    private func fetchWorkouts() async throws -> [TrainingActivity] {
        try await withCheckedThrowingContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: nil,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let workouts = (samples as? [HKWorkout]) ?? []
                continuation.resume(returning: workouts.map(HealthKitTrainingActivityMapper.trainingActivity))
            }

            healthStore.execute(query)
        }
    }
}

enum HealthKitTrainingActivityMapper {
    nonisolated static func trainingActivity(from workout: HKWorkout) -> TrainingActivity {
        TrainingActivity(
            id: UUID(),
            name: title(for: workout.workoutActivityType),
            activityType: activityType(for: workout.workoutActivityType, metadata: workout.metadata ?? [:]),
            sportType: nil,
            startDate: workout.startDate,
            durationSeconds: workout.duration,
            caloriesKilocalories: activeEnergyKilocalories(from: workout),
            distanceMeters: workout.totalDistance?.doubleValue(for: .meter()),
            primarySource: .appleHealth,
            sourceReferences: [
                TrainingActivitySourceReference(source: .appleHealth, id: workout.uuid.uuidString)
            ]
        )
    }

    nonisolated static func activityType(for type: HKWorkoutActivityType, metadata: [String: Any]) -> String {
        switch type {
        case .cycling:
            return "cycling"
        case .running:
            return "running"
        case .walking:
            return "walking"
        case .traditionalStrengthTraining, .functionalStrengthTraining:
            return "strength_training"
        case .elliptical:
            return "elliptical"
        case .swimming:
            return swimmingActivityType(metadata: metadata)
        default:
            return "other"
        }
    }

    private nonisolated static func activeEnergyKilocalories(from workout: HKWorkout) -> Double? {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return nil
        }

        return workout.statistics(for: energyType)?.sumQuantity()?.doubleValue(for: .kilocalorie())
    }

    private nonisolated static func swimmingActivityType(metadata: [String: Any]) -> String {
        guard let rawValue = metadata[HKMetadataKeySwimmingLocationType] as? Int,
              let location = HKWorkoutSwimmingLocationType(rawValue: rawValue)
        else {
            return "lap_swimming"
        }

        switch location {
        case .openWater:
            return "open_water_swimming"
        case .pool, .unknown:
            return "lap_swimming"
        @unknown default:
            return "lap_swimming"
        }
    }

    private nonisolated static func title(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .cycling:
            return "Велик"
        case .running:
            return "Бег"
        case .walking:
            return "Ходьба"
        case .swimming:
            return "Плавание"
        case .traditionalStrengthTraining, .functionalStrengthTraining:
            return "Силовая"
        case .elliptical:
            return "Эллипс"
        default:
            return "Тренировка"
        }
    }
}
