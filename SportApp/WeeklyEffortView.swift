import SwiftUI

struct WeeklyEffortView: View {
    let activities: [TrainingActivity]
    let selectedPeriod: TrainingPeriodSelection
    let selectedPeriodTitle: String
    let selectedTypes: TrainingActivityTypeSelection
    @Binding var chartScale: WeeklyEffortChartScale

    @State private var selectedPoint: WeeklyEffortPoint?

    private let calculator = WeeklyEffortCalculator()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Text(selectedPeriodTitle)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer()

                chartScaleControls
            }

            WeeklyEffortChartView(points: points, selectedPoint: $selectedPoint, chartScale: chartScale)
                .padding(.top, 28)
        }
        .onChange(of: selectedPeriod) { _, _ in
            selectedPoint = nil
        }
        .onChange(of: selectedTypes) { _, _ in
            selectedPoint = nil
        }
    }

    private var points: [WeeklyEffortPoint] {
        calculator.calculate(
            from: activities,
            period: selectedPeriod,
            typeSelection: selectedTypes
        )
    }

    private var chartScaleControls: some View {
        HStack(spacing: 4) {
            Button {
                chartScale = chartScale.zoomedOut()
            } label: {
                Image(systemName: "minus")
                    .frame(width: 30, height: 30)
            }
            .disabled(!chartScale.canZoomOut)

            Button {
                chartScale = chartScale.reset()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .frame(width: 30, height: 30)
            }
            .disabled(chartScale == .standard)

            Button {
                chartScale = chartScale.zoomedIn()
            } label: {
                Image(systemName: "plus")
                    .frame(width: 30, height: 30)
            }
            .disabled(!chartScale.canZoomIn)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .foregroundStyle(.primary)
    }
}

#Preview {
    WeeklyEffortView(
        activities: [],
        selectedPeriod: .preset(.oneWeek),
        selectedPeriodTitle: "1 неделя",
        selectedTypes: .all,
        chartScale: .constant(.standard)
    )
}
