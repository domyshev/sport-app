import SwiftUI

struct TodayEffortView: View {
    @State private var summary: TodayEffortSummary = .empty

    private let loader = GarminActivitiesLoader()
    private let calculator = TodayEffortCalculator()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ],
                spacing: 10
            ) {
                TodayMetricTile(title: "Тренировок", value: "\(summary.trainingCount)")
                TodayMetricTile(title: "Калории", value: caloriesText)
                TodayMetricTile(title: "Время", value: durationText)
                TodayMetricTile(title: "Ккал/мин", value: effortText)
            }

            Text("Garmin сегодня не подключен")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.tertiary)
                .padding(.top, 2)
        }
        .task {
            loadSummary()
        }
    }

    private var caloriesText: String {
        numberFormatter.string(from: NSNumber(value: summary.calories)) ?? "0"
    }

    private var durationText: String {
        "\(numberFormatter.string(from: NSNumber(value: summary.durationMinutes)) ?? "0") мин"
    }

    private var effortText: String {
        decimalFormatter.string(from: NSNumber(value: summary.effort)) ?? "0"
    }

    private func loadSummary() {
        do {
            let activities = try loader.load()
            summary = calculator.calculate(from: activities)
        } catch {
            summary = .empty
        }
    }

    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter
    }

    private var decimalFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        return formatter
    }
}

private struct TodayMetricTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
        .padding(.horizontal, 14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    TodayEffortView()
        .padding()
}
