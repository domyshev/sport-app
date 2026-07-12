import SwiftUI

struct TrainingListView: View {
    @State private var preferences = TrainingActivityFieldPreferences()
    @AppStorage("trainingActivityFieldPreferences") private var preferencesData: Data = Data()

    let activities: [TrainingActivity]
    let selectedPeriod: TrainingPeriodSelection
    let selectedTypes: TrainingActivityTypeSelection

    private let builder = TrainingActivityListBuilder()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            let cards = builder.buildCards(
                from: activities,
                period: selectedPeriod,
                typeSelection: selectedTypes
            )

            TrainingRecordCountChip(count: cards.count)

            if cards.isEmpty {
                Text("Нет тренировок за выбранный период")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 24)
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(cards) { card in
                            TrainingActivityCardView(model: card, preferences: $preferences)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .task {
            loadPreferences()
        }
        .onChange(of: preferences) { _, newValue in
            preferencesData = (try? newValue.encode()) ?? Data()
        }
    }

    private func loadPreferences() {
        guard !preferencesData.isEmpty,
              let decoded = try? TrainingActivityFieldPreferences.decode(from: preferencesData) else { return }
        preferences = decoded
    }
}

enum TrainingRecordCountText {
    static func text(for count: Int) -> String {
        let absoluteCount = abs(count)
        let lastTwoDigits = absoluteCount % 100
        let lastDigit = absoluteCount % 10
        let suffix: String

        if (11...14).contains(lastTwoDigits) {
            suffix = "записей"
        } else {
            switch lastDigit {
            case 1:
                suffix = "запись"
            case 2...4:
                suffix = "записи"
            default:
                suffix = "записей"
            }
        }

        return "\(count) \(suffix)"
    }
}

private struct TrainingRecordCountChip: View {
    let count: Int
    private let palette = SportAppVisualStyle.palette

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 12, weight: .semibold))

            Text(TrainingRecordCountText.text(for: count))
                .font(.system(size: 13, weight: .semibold))
        }
        .foregroundStyle(Color(palette.primaryText))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            LinearGradient(
                colors: [
                    Color(palette.electricCyan).opacity(0.24),
                    Color(palette.panel).opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: Capsule()
        )
        .overlay {
            Capsule()
                .stroke(Color(palette.cyanGlow).opacity(0.5), lineWidth: 1)
        }
        .shadow(color: Color(palette.electricCyan).opacity(0.2), radius: 10, x: 0, y: 4)
        .accessibilityLabel(TrainingRecordCountText.text(for: count))
    }
}

#Preview {
    TrainingListView(
        activities: [],
        selectedPeriod: .preset(.oneWeek),
        selectedTypes: .all
    )
        .padding()
}
