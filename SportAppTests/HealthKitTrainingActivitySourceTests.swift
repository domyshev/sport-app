import HealthKit
import Testing
@testable import SportApp

struct HealthKitTrainingActivitySourceTests {
    @Test func mapsCommonHealthKitWorkoutTypesToTrainingActivityTypes() {
        #expect(HealthKitTrainingActivityMapper.activityType(for: .cycling, metadata: [:]) == "cycling")
        #expect(HealthKitTrainingActivityMapper.activityType(for: .running, metadata: [:]) == "running")
        #expect(HealthKitTrainingActivityMapper.activityType(for: .walking, metadata: [:]) == "walking")
        #expect(HealthKitTrainingActivityMapper.activityType(for: .traditionalStrengthTraining, metadata: [:]) == "strength_training")
    }

    @Test func mapsSwimmingLocationMetadataToPoolOrOpenWater() {
        #expect(
            HealthKitTrainingActivityMapper.activityType(
                for: .swimming,
                metadata: [HKMetadataKeySwimmingLocationType: HKWorkoutSwimmingLocationType.pool.rawValue]
            ) == "lap_swimming"
        )
        #expect(
            HealthKitTrainingActivityMapper.activityType(
                for: .swimming,
                metadata: [HKMetadataKeySwimmingLocationType: HKWorkoutSwimmingLocationType.openWater.rawValue]
            ) == "open_water_swimming"
        )
    }

    @Test func mapsSwimmingWithoutLocationMetadataToGenericSwimming() {
        #expect(HealthKitTrainingActivityMapper.activityType(for: .swimming, metadata: [:]) == "swimming")
    }

    @Test func mapsSwimmingWithLapLengthMetadataToPoolWhenLocationIsMissing() {
        #expect(
            HealthKitTrainingActivityMapper.activityType(
                for: .swimming,
                metadata: [HKMetadataKeyLapLength: HKQuantity(unit: .meter(), doubleValue: 25)]
            ) == "lap_swimming"
        )
    }
}
