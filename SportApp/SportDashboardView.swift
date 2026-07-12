import SwiftUI
import UniformTypeIdentifiers

struct SportDashboardView: View {
    @State private var selectedTab: SportDashboardTab = .trainings
    @State private var activities: [TrainingActivity] = []
    @State private var selectedPeriod: TrainingPeriodSelection = .preset(.oneWeek)
    @State private var selectedPreset: TrainingPeriodSelection.Preset = .oneWeek
    @State private var isCustomPeriod = false
    @State private var selectedTypes = TrainingActivityTypeSelection.all
    @State private var chartScale = WeeklyEffortChartScale.standard
    @State private var recentCustomPeriods = TrainingRecentCustomPeriods()
    @State private var isShowingPeriodSheet = false
    @State private var isShowingTypeSheet = false
    @State private var isShowingSettingsSheet = false
    @State private var isImportingGarminFile = false
    @State private var isSyncingHealth = false
    @State private var dataStatusMessage = "Локальное хранилище готово"
    @AppStorage("trainingRecentCustomPeriods") private var recentCustomPeriodsData: Data = Data()

    private let store = LocalTrainingActivityStore()
    private let garminImporter = GarminOfficialExportImporter()
    private let healthSource = HealthKitTrainingActivitySource()
    private let calendar = WeeklyEffortCalculator.makeMondayFirstCalendar()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Text("Илья")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.primary)

                Spacer()

                Button {
                    isShowingSettingsSheet = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(width: 34, height: 34)
                        .background(Color(.secondarySystemBackground), in: Circle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)
                .accessibilityLabel("Настройки данных")
            }

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
        .sheet(isPresented: $isShowingSettingsSheet) {
            TrainingDataSettingsView(
                activityCount: activities.count,
                statusMessage: dataStatusMessage,
                isSyncingHealth: isSyncingHealth,
                onSyncHealth: syncHealth,
                onImportGarmin: {
                    isShowingSettingsSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        isImportingGarminFile = true
                    }
                }
            )
        }
        .fileImporter(
            isPresented: $isImportingGarminFile,
            allowedContentTypes: [.zip, .folder],
            allowsMultipleSelection: false,
            onCompletion: handleGarminImport
        )
        .task {
            loadActivities()
            recentCustomPeriods = TrainingRecentCustomPeriods.decoded(from: recentCustomPeriodsData)
            syncHealth()
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
        if let storedActivities = try? store.loadActivities(), !storedActivities.isEmpty {
            activities = storedActivities
            dataStatusMessage = "В локальном хранилище: \(storedActivities.count)"
            return
        }

        guard let bundledActivities = try? garminImporter.importBundledActivities() else {
            activities = []
            dataStatusMessage = "Нет данных"
            return
        }

        _ = try? store.merge(bundledActivities)
        activities = (try? store.loadActivities()) ?? bundledActivities
        dataStatusMessage = "Загружена встроенная история: \(activities.count)"
    }

    private func syncHealth() {
        guard !isSyncingHealth else { return }
        isSyncingHealth = true

        Task {
            defer { isSyncingHealth = false }
            do {
                let healthActivities = try await healthSource.requestAuthorizationAndFetch()
                let summary = try store.merge(healthActivities)
                loadActivities()
                dataStatusMessage = "Apple Health: \(summaryText(summary))"
            } catch {
                dataStatusMessage = "Apple Health недоступен: \(error.localizedDescription)"
            }
        }
    }

    private func handleGarminImport(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            let hasSecurityAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasSecurityAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let importedActivities: [TrainingActivity]
            if url.pathExtension.lowercased() == "zip" {
                importedActivities = try garminImporter.importZip(at: url)
            } else {
                importedActivities = try garminImporter.importFolder(at: url)
            }

            let summary = try store.merge(importedActivities)
            loadActivities()
            dataStatusMessage = "Garmin import: \(summaryText(summary))"
        } catch {
            dataStatusMessage = "Garmin import не выполнен: \(error.localizedDescription)"
        }
    }

    private func summaryText(_ summary: TrainingImportSummary) -> String {
        "добавлено \(summary.added), обновлено \(summary.updated), дублей \(summary.skippedDuplicates), ошибок \(summary.errors)"
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

private struct TrainingDataSettingsView: View {
    let activityCount: Int
    let statusMessage: String
    let isSyncingHealth: Bool
    let onSyncHealth: () -> Void
    let onImportGarmin: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Данные") {
                    HStack {
                        Text("Тренировок")
                        Spacer()
                        Text("\(activityCount)")
                            .foregroundStyle(.secondary)
                    }

                    Text(statusMessage)
                        .foregroundStyle(.secondary)
                }

                Section("Источники") {
                    Button {
                        onSyncHealth()
                    } label: {
                        Label(isSyncingHealth ? "Синхронизация..." : "Синхронизировать Apple Health", systemImage: "heart.text.square")
                    }
                    .disabled(isSyncingHealth)

                    Button {
                        onImportGarmin()
                        dismiss()
                    } label: {
                        Label("Импорт Garmin ZIP/папка", systemImage: "square.and.arrow.down")
                    }
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
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
