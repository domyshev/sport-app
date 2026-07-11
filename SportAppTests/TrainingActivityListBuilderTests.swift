import Foundation
import Testing
@testable import SportApp

struct TrainingActivityListBuilderTests {
    private let calendar = WeeklyEffortCalculator.makeMondayFirstCalendar()

    @Test func decodesOptionalDistanceFromGarminSummary() throws {
        let json = """
        [
          {
            "summarizedActivitiesExport": [
              {
                "activityId": 1,
                "name": "Sea swim",
                "activityType": "open_water_swimming",
                "sportType": "SWIMMING",
                "startTimeLocal": 1780704000000,
                "startTimeGmt": 1780704000000,
                "duration": 1800000,
                "calories": 200,
                "distance": 1500
              }
            ]
          }
        ]
        """

        let activities = try GarminActivitiesLoader.decodeActivities(from: Data(json.utf8))

        #expect(activities.first?.distance == 1500)
    }

    @Test func mapsGarminActivityTypesToRussianTitles() {
        #expect(TrainingActivityPresentation.title(for: activity(id: 1, type: "open_water_swimming", name: "Sea")) == "Плавание Море")
        #expect(TrainingActivityPresentation.title(for: activity(id: 2, type: "lap_swimming", name: "Pool")) == "Бассейн")
        #expect(TrainingActivityPresentation.title(for: activity(id: 3, type: "cycling", name: "Ride")) == "Велик")
        #expect(TrainingActivityPresentation.title(for: activity(id: 4, type: "other", name: "Rest")) == "Отдых")
        #expect(TrainingActivityPresentation.title(for: activity(id: 5, type: "indoor_cycling", name: "Indoor Ride")) == "Велик")
        #expect(TrainingActivityPresentation.title(for: activity(id: 6, type: "strength_training", name: "Gym")) == "Силовая")
        #expect(TrainingActivityPresentation.title(for: activity(id: 7, type: "elliptical", name: "Elliptical")) == "Эллипс")
        #expect(TrainingActivityPresentation.title(for: activity(id: 8, type: "stand_up_paddleboarding_v2", name: "SUP")) == "SUP")
        #expect(TrainingActivityPresentation.title(for: activity(id: 9, type: "other", name: "Morning Rest Day")) == "Отдых")
    }

    @Test func formatsGarminDistanceStoredInCentimeters() {
        #expect(TrainingActivityPresentation.distanceText(forGarminCentimeters: 130_000) == "1,3 км")
    }

    @Test func buildsNewestFirstCardsForDefaultWeekEndingAtLatestActivity() {
        let activities = [
            activity(id: 1, type: "running", name: "Old", date: "2026-06-01", distance: 100_000),
            activity(id: 2, type: "cycling", name: "Latest", date: "2026-06-14", distance: 1_200_000),
            activity(id: 3, type: "lap_swimming", name: "Pool", date: "2026-06-08", distance: 80_000),
            activity(id: 4, type: "walking", name: "Too old", date: "2026-06-07", distance: 50_000)
        ]

        let cards = TrainingActivityListBuilder(calendar: calendar).buildCards(
            from: activities,
            period: .preset(.oneWeek)
        )

        #expect(cards.map(\.id) == [2, 3])
        #expect(cards[0].title == "Велик")
        #expect(cards[0].distanceText == "12 км")
        #expect(cards[1].title == "Бассейн")
        #expect(cards[1].distanceText == "800 м")
    }

    @Test func buildsCardsForCustomDateRangeInclusive() {
        let activities = [
            activity(id: 1, type: "running", name: "Before", date: "2026-06-01", distance: 100_000),
            activity(id: 2, type: "running", name: "Inside", date: "2026-06-10", distance: 200_000),
            activity(id: 3, type: "running", name: "After", date: "2026-06-20", distance: 300_000)
        ]
        let start = date("2026-06-09")
        let end = date("2026-06-10")

        let cards = TrainingActivityListBuilder(calendar: calendar).buildCards(
            from: activities,
            period: .custom(start: start, end: end)
        )

        #expect(cards.map(\.id) == [2])
    }

    private func activity(
        id: Int64,
        type: String,
        name: String,
        date: String = "2026-06-14",
        distance: Double? = nil,
        durationMinutes: Double = 45
    ) -> GarminActivity {
        let timestamp = self.date(date).timeIntervalSince1970 * 1000
        return GarminActivity(
            activityId: id,
            name: name,
            activityType: type,
            sportType: nil,
            startTimeLocal: timestamp,
            startTimeGmt: timestamp,
            duration: durationMinutes * 60_000,
            calories: 300,
            distance: distance
        )
    }

    private func date(_ value: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)!
    }
}
