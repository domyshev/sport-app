import Foundation
import Testing
@testable import SportApp

struct WeeklyEffortChartAxisTests {
    @Test func formatsXAxisDatesAsDayMonthYearWithSlashes() {
        #expect(WeeklyEffortPoint.axisDateFormatter.string(from: date("2026-06-07")) == "07/06/2026")
        #expect(WeeklyEffortPoint.axisDateFormatter.string(from: date("2024-04-12")) == "12/04/2024")
    }

    @Test func spacesXAxisLabelsForFourLabelsPerVisibleWidth() {
        let points = (0..<20).map { index in
            WeeklyEffortPoint(
                weekStart: date("2026-01-\(String(format: "%02d", index + 1))"),
                weekEnd: date("2026-01-\(String(format: "%02d", index + 1))"),
                value: Double(index)
            )
        }

        let values = WeeklyEffortChartAxisValues.xAxisLabels(
            for: points,
            visibleWidth: 408,
            pointSpacing: 34
        )

        #expect(zip(values.map(\.index), values.dropFirst().map(\.index)).allSatisfy { lhs, rhs in rhs - lhs >= 4 })
    }

    @Test func chartScaleCanZoomOutResetAndZoomIn() {
        #expect(WeeklyEffortChartScale.standard.zoomedOut().pointSpacing < WeeklyEffortChartScale.standard.pointSpacing)
        #expect(WeeklyEffortChartScale.standard.zoomedIn().pointSpacing > WeeklyEffortChartScale.standard.pointSpacing)
        #expect(WeeklyEffortChartScale.standard.zoomedIn().reset() == .standard)
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
