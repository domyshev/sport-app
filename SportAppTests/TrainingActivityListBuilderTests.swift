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

    @Test func typeCategoriesCombineCyclingVariantsAndUseRussianTitles() {
        let categories = TrainingActivityTypeCategory.availableCategories(from: [
            activity(id: 1, type: "cycling", name: "Outdoor"),
            activity(id: 2, type: "indoor_cycling", name: "Indoor"),
            activity(id: 3, type: "lap_swimming", name: "Pool")
        ])

        #expect(categories.map(\.title) == ["Бассейн", "Велик"])
    }

    @Test func activityTypeSelectionSupportsMultipleCategories() {
        let cycling = activity(id: 1, type: "cycling", name: "Ride")
        let pool = activity(id: 2, type: "lap_swimming", name: "Pool")
        let selection = TrainingActivityTypeSelection(selected: [
            TrainingActivityTypeCategory(activity: cycling)
        ])

        #expect(selection.includes(cycling))
        #expect(!selection.includes(pool))
    }

    @Test func activityTypeSelectionTogglesAllOffAndBackOn() {
        let categories = TrainingActivityTypeCategory.availableCategories(from: [
            activity(id: 1, type: "cycling", name: "Ride"),
            activity(id: 2, type: "lap_swimming", name: "Pool")
        ])
        let cycling = activity(id: 3, type: "cycling", name: "Another Ride")

        let emptySelection = TrainingActivityTypeSelection.all.toggledAll(availableCategories: categories)

        #expect(!emptySelection.isAll)
        #expect(emptySelection.selectedCount == 0)
        #expect(!emptySelection.includes(cycling))

        let allSelection = emptySelection.toggledAll(availableCategories: categories)

        #expect(allSelection.isAll)
        #expect(allSelection.includes(cycling))
    }

    @Test func listBuilderFiltersByPeriodAndActivityTypes() {
        let activities = [
            activity(id: 1, type: "running", name: "Run", date: "2026-06-14"),
            activity(id: 2, type: "cycling", name: "Ride", date: "2026-06-13"),
            activity(id: 3, type: "cycling", name: "Old Ride", date: "2026-06-01")
        ]
        let selection = TrainingActivityTypeSelection(selected: [
            TrainingActivityTypeCategory(activity: activities[1])
        ])

        let cards = TrainingActivityListBuilder(calendar: calendar).buildCards(
            from: activities,
            period: .preset(.oneWeek),
            typeSelection: selection
        )

        #expect(cards.map(\.id) == [2])
    }

    @Test func recentCustomPeriodsKeepFiveAndMoveDuplicateToTop() {
        let periods = (1...6).reduce(into: TrainingRecentCustomPeriods()) { result, day in
            result.remember(
                TrainingRecentCustomPeriod(
                    start: date("2026-06-\(String(format: "%02d", day))"),
                    end: date("2026-06-\(String(format: "%02d", day + 1))")
                ),
                calendar: calendar
            )
        }
        var updated = periods
        let duplicate = TrainingRecentCustomPeriod(start: date("2026-06-03"), end: date("2026-06-04"))

        updated.remember(duplicate, calendar: calendar)

        #expect(updated.items.count == 5)
        #expect(updated.items.first == duplicate)
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
