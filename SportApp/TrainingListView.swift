import SwiftUI

struct TrainingListView: View {
    @State private var preferences = TrainingActivityFieldPreferences()
    @AppStorage("trainingActivityFieldPreferences") private var preferencesData: Data = Data()

    let activities: [GarminActivity]
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

#Preview {
    TrainingListView(
        activities: [],
        selectedPeriod: .preset(.oneWeek),
        selectedTypes: .all
    )
        .padding()
}
