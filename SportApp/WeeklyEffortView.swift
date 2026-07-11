import SwiftUI

struct WeeklyEffortView: View {
    @State private var points: [WeeklyEffortPoint] = []
    @State private var selectedPoint: WeeklyEffortPoint?

    private let loader = GarminActivitiesLoader()
    private let calculator = WeeklyEffortCalculator()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("ты тренируешься уже \(points.count) недель")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.secondary)

            WeeklyEffortChartView(points: points, selectedPoint: $selectedPoint)
                .padding(.top, 28)
        }
        .task {
            loadPoints()
        }
    }

    private func loadPoints() {
        do {
            let activities = try loader.load()
            points = calculator.calculate(from: activities)
            selectedPoint = nil
        } catch {
            points = []
            selectedPoint = nil
        }
    }
}

#Preview {
    WeeklyEffortView()
}
