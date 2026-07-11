import Foundation
import Testing
@testable import SportApp

struct WeeklyEffortChartAxisTests {
    @Test func formatsXAxisDatesAsDayMonthYearWithoutLeadingDayZero() {
        #expect(WeeklyEffortPoint.axisDateFormatter.string(from: date("2026-06-07")) == "70626")
        #expect(WeeklyEffortPoint.axisDateFormatter.string(from: date("2024-04-12")) == "120424")
    }

    @Test func producesFourXAxisValuesFromFirstTwoIntermediateAndLastPoints() {
        let points = (0..<10).map { index in
            WeeklyEffortPoint(
                weekStart: date("2026-01-\(String(format: "%02d", index + 1))"),
                weekEnd: date("2026-01-\(String(format: "%02d", index + 7))"),
                value: Double(index)
            )
        }

        let values = WeeklyEffortChartAxisValues.xAxisLabels(for: points)

        #expect(values.count == 4)
        #expect(values.map(\.index) == [0, 3, 6, 9])
    }

    @Test func producesFourYAxisValuesFromZeroToMax() {
        let values = WeeklyEffortChartAxisValues.yAxisLabels(maxValue: 90)

        #expect(values == [0, 30, 60, 90])
    }

    private func date(_ value: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = WeeklyEffortCalculator.makeMondayFirstCalendar()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)!
    }
}
