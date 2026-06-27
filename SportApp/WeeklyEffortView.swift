import SwiftUI

struct WeeklyEffortView: View {
    @State private var points: [WeeklyEffortPoint] = []
    @State private var selectedPoint: WeeklyEffortPoint?

    private let loader = GarminActivitiesLoader()
    private let calculator = WeeklyEffortCalculator()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Илья")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(.primary)

            Text("ты тренируешься уже \(points.count) недель")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            WeeklyEffortChartView(points: points, selectedPoint: $selectedPoint)
                .padding(.top, 28)
        }
        .padding(.horizontal, 18)
        .padding(.top, 26)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.systemBackground))
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
