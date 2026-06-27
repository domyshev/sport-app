import Testing
@testable import SportApp

struct TrainingActivityFilterTests {
    @Test func defaultFilterAllowsRealTrainingActivities() {
        let activity = GarminActivity(
            activityId: 1,
            name: "Pool Swim",
            activityType: "lap_swimming",
            sportType: "SWIMMING",
            startTimeLocal: 1_750_000_000_000,
            startTimeGmt: 1_750_000_000_000,
            duration: 600_000,
            calories: 120
        )

        #expect(TrainingActivityFilter.default.includes(activity))
    }

    @Test func defaultFilterRejectsInvalidRestTrackMeAndMeditation() {
        let blocked = [
            GarminActivity(activityId: 1, name: "Rest", activityType: "other", sportType: "INVALID", startTimeLocal: 0, startTimeGmt: 0, duration: 600_000, calories: 10),
            GarminActivity(activityId: 2, name: "Track Me", activityType: "other", sportType: "GENERIC", startTimeLocal: 0, startTimeGmt: 0, duration: 600_000, calories: 10),
            GarminActivity(activityId: 3, name: "Meditating 5min", activityType: "meditation", sportType: "MEDITATION", startTimeLocal: 0, startTimeGmt: 0, duration: 300_000, calories: nil),
            GarminActivity(activityId: 4, name: "Valencia Meditation", activityType: "other", sportType: "INVALID", startTimeLocal: 0, startTimeGmt: 0, duration: 300_000, calories: nil)
        ]

        for activity in blocked {
            #expect(!TrainingActivityFilter.default.includes(activity))
        }
    }
}
