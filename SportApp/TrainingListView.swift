import SwiftUI

struct TrainingListView: View {
    @State private var activities: [GarminActivity] = []
    @State private var selectedPeriod: TrainingPeriodSelection = .preset(.oneWeek)
    @State private var selectedPeriodTitle = "1 неделя"
    @State private var selectedPreset: TrainingPeriodSelection.Preset = .oneWeek
    @State private var isCustomPeriod = false
    @State private var preferences = TrainingActivityFieldPreferences()
    @State private var isShowingPeriodSheet = false
    @AppStorage("trainingActivityFieldPreferences") private var preferencesData: Data = Data()

    private let loader = GarminActivitiesLoader()
    private let builder = TrainingActivityListBuilder()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(selectedPeriodTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    isShowingPeriodSheet = true
                } label: {
                    Image(systemName: "calendar")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 34, height: 34)
                        .background(Color(.secondarySystemBackground), in: Circle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)
                .accessibilityLabel("Настроить период")
            }

            let cards = builder.buildCards(from: activities, period: selectedPeriod)
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
        .sheet(isPresented: $isShowingPeriodSheet) {
            TrainingPeriodSelectionView(
                selection: $selectedPeriod,
                title: $selectedPeriodTitle,
                selectedPreset: $selectedPreset,
                isCustom: $isCustomPeriod
            )
        }
        .task {
            loadActivities()
            loadPreferences()
        }
        .onChange(of: preferences) { _, newValue in
            preferencesData = (try? newValue.encode()) ?? Data()
        }
    }

    private func loadActivities() {
        activities = (try? loader.load()) ?? []
    }

    private func loadPreferences() {
        guard !preferencesData.isEmpty,
              let decoded = try? TrainingActivityFieldPreferences.decode(from: preferencesData) else { return }
        preferences = decoded
    }
}

private struct TrainingPeriodSelectionView: View {
    @Binding var selection: TrainingPeriodSelection
    @Binding var title: String
    @Binding var selectedPreset: TrainingPeriodSelection.Preset
    @Binding var isCustom: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var startDate = Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? Date()
    @State private var endDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Период") {
                    ForEach(TrainingPeriodSelection.Preset.allCases, id: \.title) { preset in
                        Button {
                            selectedPreset = preset
                            isCustom = false
                        } label: {
                            HStack {
                                Text(preset.title)
                                Spacer()
                                if !isCustom && selectedPreset == preset {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                    Button {
                        isCustom = true
                    } label: {
                        HStack {
                            Text("Свой период")
                            Spacer()
                            if isCustom { Image(systemName: "checkmark") }
                        }
                    }
                    .foregroundStyle(.primary)
                }

                if isCustom {
                    Section("Даты") {
                        DatePicker("С", selection: $startDate, displayedComponents: .date)
                        DatePicker("По", selection: $endDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Период")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        selection = isCustom ? .custom(start: startDate, end: endDate) : .preset(selectedPreset)
                        title = isCustom ? "Свой период" : selectedPreset.title
                        dismiss()
                    }
                }
            }
        }
    }
}

private extension TrainingPeriodSelection.Preset {
    var title: String {
        switch self {
        case .oneWeek: return "1 неделя"
        case .twoWeeks: return "2 недели"
        case .oneMonth: return "1 месяц"
        case .threeMonths: return "3 месяца"
        case .sixMonths: return "6 месяцев"
        case .oneYear: return "1 год"
        }
    }
}

#Preview {
    TrainingListView()
        .padding()
}
