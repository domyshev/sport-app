import Foundation
import Testing
@testable import SportApp

struct GarminActivitiesLoaderTests {
    @Test func decodesActivitiesFromExportJSONData() throws {
        let json = """
        [
          {
            "summarizedActivitiesExport": [
              {
                "activityId": 1,
                "name": "Valencia Cycling",
                "activityType": "cycling",
                "sportType": "CYCLING",
                "startTimeLocal": 1750000000000,
                "startTimeGmt": 1750000000000,
                "duration": 600000,
                "calories": 100
              }
            ]
          }
        ]
        """

        let activities = try GarminActivitiesLoader.decodeActivities(from: Data(json.utf8))

        #expect(activities.count == 1)
        #expect(activities[0].activityType == "cycling")
        #expect(activities[0].calories == 100)
    }

    @Test func loadsBundledActivities() throws {
        let activities = try GarminActivitiesLoader().load()

        #expect(!activities.isEmpty)
        #expect(activities.contains { $0.activityType == "cycling" || $0.activityType == "lap_swimming" })
    }
}
