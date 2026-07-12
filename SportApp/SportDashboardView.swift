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
    @State private var visibleDataStatusMessage: String?
    @AppStorage("trainingRecentCustomPeriods") private var recentCustomPeriodsData: Data = Data()

    private let store = LocalTrainingActivityStore()
    private let garminImporter = GarminOfficialExportImporter()
    private let healthSource = HealthKitTrainingActivitySource()
    private let calendar = WeeklyEffortCalculator.makeMondayFirstCalendar()
    private let palette = SportAppVisualStyle.palette

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Text("Илья")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(palette.primaryText), Color(palette.cyanGlow)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Spacer()

                NeonIconButton(
                    systemName: "gearshape",
                    accessibilityLabel: "Настройки данных"
                ) {
                    isShowingSettingsSheet = true
                }
            }

            SportDashboardTabBar(selectedTab: $selectedTab)
                .padding(.top, 18)

            filterBar
                .padding(.top, 14)

            if let visibleDataStatusMessage {
                TrainingDataStatusBanner(message: visibleDataStatusMessage) {
                    self.visibleDataStatusMessage = nil
                }
                .padding(.top, 12)
            }

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
        .background(SportAppBackground())
        .preferredColorScheme(.dark)
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
                },
                onClearLocalData: clearLocalData
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
                    .foregroundStyle(Color(palette.primaryText))
                    .lineLimit(1)
                    .accessibilityIdentifier("SelectedPeriodTitle")

                Text(typeSummary)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(palette.secondaryText))
                    .lineLimit(1)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isShowingPeriodSheet = true
            }

            Spacer(minLength: 8)

            NeonIconButton(
                systemName: "calendar",
                accessibilityLabel: "Настроить период"
            ) {
                isShowingPeriodSheet = true
            }

            NeonIconButton(
                systemName: "line.3.horizontal.decrease.circle",
                accessibilityLabel: "Фильтр типов тренировок"
            ) {
                isShowingTypeSheet = true
            }
        }
        .frame(minHeight: 38)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(palette.panel), in: RoundedRectangle(cornerRadius: SportAppVisualStyle.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: SportAppVisualStyle.cardRadius)
                .stroke(Color(palette.panelStroke), lineWidth: 1)
        }
        .shadow(color: Color(palette.electricCyan).opacity(palette.panelGlowOpacity), radius: 16, x: 0, y: 8)
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
                showDataStatus("Apple Health: \(summaryText(summary))")
            } catch {
                showDataStatus("Apple Health недоступен: \(error.localizedDescription)")
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
            showDataStatus(TrainingImportStatusText.garminImport(summary))
        } catch {
            showDataStatus("Garmin import не выполнен: \(error.localizedDescription)")
        }
    }

    private func clearLocalData(confirmationCode: String) -> Bool {
        guard TrainingDataClearance.canClear(with: confirmationCode) else {
            showDataStatus("Очистка отменена: неверный сервисный код")
            return false
        }

        do {
            try store.clearActivities()
            activities = []
            selectedTypes = .all
            showDataStatus("Локальное хранилище очищено")
            return true
        } catch {
            showDataStatus("Очистка не выполнена: \(error.localizedDescription)")
            return false
        }
    }

    private func summaryText(_ summary: TrainingImportSummary) -> String {
        TrainingImportStatusText.summary(summary)
    }

    private func showDataStatus(_ message: String) {
        dataStatusMessage = message
        visibleDataStatusMessage = message
    }
}

private enum SportDashboardTab: String, CaseIterable, Identifiable {
    case trainings = "Тренировки"
    case chart = "График"

    var id: String { rawValue }
}

private struct SportDashboardTabBar: View {
    @Binding var selectedTab: SportDashboardTab
    private let palette = SportAppVisualStyle.palette

    var body: some View {
        HStack(spacing: 8) {
            ForEach(SportDashboardTab.allCases) { tab in
                let isSelected = selectedTab == tab
                Button {
                    selectedTab = tab
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 15, weight: .semibold))
                        .frame(height: 34)
                        .padding(.horizontal, 16)
                        .foregroundStyle(isSelected ? Color(palette.primaryText) : Color(palette.secondaryText))
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(palette.electricCyan).opacity(0.9),
                                                Color(palette.panel).opacity(0.95)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            } else {
                                Capsule()
                                    .fill(Color(palette.panel).opacity(0.72))
                            }
                        }
                        .overlay {
                            Capsule()
                                .stroke(
                                    isSelected ? Color(palette.cyanGlow).opacity(0.8) : Color(palette.panelStroke),
                                    lineWidth: 1
                                )
                        }
                        .shadow(
                            color: isSelected ? Color(palette.electricCyan).opacity(0.34) : .clear,
                            radius: 12,
                            x: 0,
                            y: 5
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct NeonIconButton: View {
    let systemName: String
    let accessibilityLabel: String
    let action: () -> Void

    private let palette = SportAppVisualStyle.palette

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 36, height: 36)
                .foregroundStyle(Color(palette.primaryText))
                .background(Color(palette.panel).opacity(0.9), in: Circle())
                .overlay {
                    Circle()
                        .stroke(Color(palette.panelStroke), lineWidth: 1)
                }
                .shadow(color: Color(palette.electricCyan).opacity(palette.panelGlowOpacity), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

private struct TrainingDataStatusBanner: View {
    let message: String
    let onDismiss: () -> Void

    private let palette = SportAppVisualStyle.palette

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(palette.electricCyan))
                .padding(.top, 1)

            Text(message)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(palette.primaryText))
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 8)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 28, height: 28)
                    .foregroundStyle(Color(palette.secondaryText))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Закрыть сообщение")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                colors: [
                    Color(palette.electricCyan).opacity(0.22),
                    Color(palette.panel).opacity(0.94)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: SportAppVisualStyle.cardRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: SportAppVisualStyle.cardRadius)
                .stroke(Color(palette.cyanGlow).opacity(0.55), lineWidth: 1)
        }
        .shadow(color: Color(palette.electricCyan).opacity(0.2), radius: 12, x: 0, y: 5)
        .accessibilityIdentifier("DataStatusBanner")
    }
}

private struct TrainingDataSettingsView: View {
    let activityCount: Int
    let statusMessage: String
    let isSyncingHealth: Bool
    let onSyncHealth: () -> Void
    let onImportGarmin: () -> Void
    let onClearLocalData: (String) -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var isShowingClearConfirmation = false
    @State private var clearConfirmationCode = ""
    @State private var clearErrorMessage: String?

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

                Section("Опасная зона") {
                    Button(role: .destructive) {
                        clearConfirmationCode = ""
                        clearErrorMessage = nil
                        isShowingClearConfirmation = true
                    } label: {
                        Label("Очистить локальное хранилище", systemImage: "trash")
                    }

                    Text("Удаляются только локально сохраненные тренировки на этом iPhone. Apple Health и файлы Garmin не изменяются.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if let clearErrorMessage {
                        Text(clearErrorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Очистить локальное хранилище?", isPresented: $isShowingClearConfirmation) {
                TextField("Сервисный код", text: $clearConfirmationCode)
                    .keyboardType(.numberPad)

                Button("Отмена", role: .cancel) {
                    clearConfirmationCode = ""
                }

                Button("Очистить", role: .destructive) {
                    if onClearLocalData(clearConfirmationCode) {
                        clearConfirmationCode = ""
                    } else {
                        clearErrorMessage = "Неверный сервисный код"
                    }
                }
                .disabled(!TrainingDataClearance.canClear(with: clearConfirmationCode))
            } message: {
                Text("Введите сервисный код 111. Действие удалит локально сохраненные тренировки из приложения.")
            }
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
