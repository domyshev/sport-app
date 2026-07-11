import SwiftUI

struct SportDashboardView: View {
    @State private var selectedTab: SportDashboardTab = .trainings
    @State private var activities: [GarminActivity] = []
    @State private var selectedPeriod: TrainingPeriodSelection = .preset(.oneWeek)
    @State private var selectedPreset: TrainingPeriodSelection.Preset = .oneWeek
    @State private var isCustomPeriod = false
    @State private var selectedTypes = TrainingActivityTypeSelection.all
    @State private var chartScale = WeeklyEffortChartScale.standard
    @State private var recentCustomPeriods = TrainingRecentCustomPeriods()
    @State private var isShowingPeriodSheet = false
    @State private var isShowingTypeSheet = false
    @AppStorage("trainingRecentCustomPeriods") private var recentCustomPeriodsData: Data = Data()

    private let loader = GarminActivitiesLoader()
    private let calendar = WeeklyEffortCalculator.makeMondayFirstCalendar()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Илья")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.primary)

            SportDashboardTabBar(selectedTab: $selectedTab)
                .padding(.top, 18)

            filterBar
                .padding(.top, 14)

            Group {
                switch selectedTab {
                case .trainings:
                    TrainingListView(
                        activities: activities,
                        selectedPeriod: selectedPeriod,
                        selectedTypes: selectedTypes
                    )
                case .chart:
                    WeeklyEffortView(
                        activities: activities,
                        selectedPeriod: selectedPeriod,
                        selectedPeriodTitle: selectedPeriod.title(calendar: calendar),
                        selectedTypes: selectedTypes,
                        chartScale: $chartScale
                    )
                }
            }
            .padding(.top, 16)
        }
        .padding(.horizontal, 18)
        .padding(.top, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.systemBackground))
        .sheet(isPresented: $isShowingPeriodSheet) {
            TrainingPeriodSelectionView(
                selection: $selectedPeriod,
                selectedPreset: $selectedPreset,
                isCustom: $isCustomPeriod,
                recentCustomPeriods: $recentCustomPeriods,
                calendar: calendar
            )
        }
        .sheet(isPresented: $isShowingTypeSheet) {
            TrainingTypeSelectionView(
                categories: availableTypeCategories,
                selection: $selectedTypes
            )
        }
        .task {
            loadActivities()
            recentCustomPeriods = TrainingRecentCustomPeriods.decoded(from: recentCustomPeriodsData)
        }
        .onChange(of: recentCustomPeriods) { _, newValue in
            recentCustomPeriodsData = newValue.encoded()
        }
    }

    private var availableTypeCategories: [TrainingActivityTypeCategory] {
        TrainingActivityTypeCategory.availableCategories(from: activities)
    }

    private var filterBar: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedPeriod.title(calendar: calendar))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .accessibilityIdentifier("SelectedPeriodTitle")

                Text(typeSummary)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isShowingPeriodSheet = true
            }

            Spacer(minLength: 8)

            Button {
                isShowingPeriodSheet = true
            } label: {
                Image(systemName: "calendar")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 34, height: 34)
                    .background(Color(.secondarySystemBackground), in: Circle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
            .accessibilityLabel("Настроить период")

            Button {
                isShowingTypeSheet = true
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 34, height: 34)
                    .background(Color(.secondarySystemBackground), in: Circle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
            .accessibilityLabel("Фильтр типов тренировок")
        }
        .frame(minHeight: 38)
    }

    private var typeSummary: String {
        let categories = availableTypeCategories
        guard !categories.isEmpty else {
            return "Нет типов"
        }

        if selectedTypes.isAll || selectedTypes.selectedCount == categories.count {
            return "Все типы"
        }

        if selectedTypes.selectedCount == 0 {
            return "Типы не выбраны"
        }

        if selectedTypes.selectedCount == 1,
           let selected = selectedTypes.categories?.first {
            return selected.title
        }

        return "\(selectedTypes.selectedCount) типов"
    }

    private func loadActivities() {
        activities = (try? loader.load()) ?? []
    }
}

private enum SportDashboardTab: String, CaseIterable, Identifiable {
    case trainings = "Тренировки"
    case chart = "График"

    var id: String { rawValue }
}

private struct SportDashboardTabBar: View {
    @Binding var selectedTab: SportDashboardTab

    var body: some View {
        HStack(spacing: 8) {
            ForEach(SportDashboardTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 15, weight: .semibold))
                        .frame(height: 34)
                        .padding(.horizontal, 16)
                        .foregroundStyle(selectedTab == tab ? .white : .secondary)
                        .background {
                            Capsule()
                                .fill(selectedTab == tab ? Color.accentColor : Color(.secondarySystemBackground))
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    SportDashboardView()
}

private struct TrainingPeriodSelectionView: View {
    @Binding var selection: TrainingPeriodSelection
    @Binding var selectedPreset: TrainingPeriodSelection.Preset
    @Binding var isCustom: Bool
    @Binding var recentCustomPeriods: TrainingRecentCustomPeriods
    let calendar: Calendar

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
                            selection = .preset(preset)
                            dismiss()
                        } label: {
                            HStack {
                                Text(preset.title)
                                Spacer()
                                if !isCustom && selection == .preset(preset) {
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

                if !recentCustomPeriods.items.isEmpty {
                    Section("Последние") {
                        ForEach(recentCustomPeriods.items) { period in
                            Button {
                                selection = period.selection()
                                isCustom = false
                                dismiss()
                            } label: {
                                HStack {
                                    Text(period.title(calendar: calendar))
                                    Spacer()
                                    if selection == period.selection() {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
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
                        if let customPeriod = selection.customPeriod {
                            recentCustomPeriods.remember(customPeriod, calendar: calendar)
                        }
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let customPeriod = selection.customPeriod {
                    startDate = customPeriod.start
                    endDate = customPeriod.end
                }
            }
        }
    }
}

private struct TrainingTypeSelectionView: View {
    let categories: [TrainingActivityTypeCategory]
    @Binding var selection: TrainingActivityTypeSelection
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Типы") {
                    Button {
                        selection = selection.toggledAll(availableCategories: categories)
                    } label: {
                        HStack {
                            TrainingTypeCheckbox(isSelected: selection.selectsAll(availableCategories: categories))
                            Text("Все")
                            Spacer()
                        }
                    }
                    .foregroundStyle(.primary)

                    ForEach(categories) { category in
                        Button {
                            selection = selection.toggled(category, availableCategories: categories)
                        } label: {
                            HStack {
                                TrainingTypeCheckbox(isSelected: selection.contains(category))
                                Text(category.title)
                                Spacer()
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
            .navigationTitle("Типы тренировок")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct TrainingTypeCheckbox: View {
    let isSelected: Bool

    var body: some View {
        Image(systemName: isSelected ? "checkmark.square.fill" : "square")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            .frame(width: 24, height: 24)
            .accessibilityHidden(true)
    }
}
