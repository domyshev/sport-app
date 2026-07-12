import Foundation
import Testing
@testable import SportApp

struct TrainingActivityFilterTests {
    @Test func defaultFilterAllowsRealTrainingActivities() {
        let activity = training(
            id: 1,
            name: "Pool Swim",
            activityType: "lap_swimming",
            sportType: "SWIMMING"
        )

        #expect(TrainingActivityFilter.default.includes(activity))
    }

    @Test func defaultFilterRejectsInvalidRestTrackMeAndMeditation() {
        let blocked = [
            training(id: 1, name: "Rest", activityType: "other", sportType: "INVALID"),
            training(id: 2, name: "Track Me", activityType: "other", sportType: "GENERIC"),
            training(id: 3, name: "Meditating 5min", activityType: "meditation", sportType: "MEDITATION"),
            training(id: 4, name: "Valencia Meditation", activityType: "other", sportType: "INVALID")
        ]

        for activity in blocked {
            #expect(!TrainingActivityFilter.default.includes(activity))
        }
    }

    private func training(
        id: Int64,
        name: String,
        activityType: String,
        sportType: String?
    ) -> TrainingActivity {
        TrainingActivity(
            id: UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012lld", id))")!,
            name: name,
            activityType: activityType,
            sportType: sportType,
            startDate: Date(timeIntervalSince1970: 1_750_000_000),
            durationSeconds: 600,
            caloriesKilocalories: 120,
            distanceMeters: nil,
            primarySource: .garminOfficialExport,
            sourceReferences: [.init(source: .garminOfficialExport, id: "\(id)")]
        )
    }
}
