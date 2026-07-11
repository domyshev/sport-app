import SwiftUI

struct TrainingActivityCardView: View {
    let model: TrainingActivityCardModel
    @Binding var preferences: TrainingActivityFieldPreferences
    @State private var isShowingSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Text(model.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)

                Spacer(minLength: 8)

                Button {
                    isShowingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Настроить поля")
            }

            LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)], alignment: .leading, spacing: 10) {
                ForEach(preferences.fields(for: model.activityType)) { field in
                    fieldView(field)
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
        .sheet(isPresented: $isShowingSettings) {
            TrainingActivityFieldSettingsView(
                activityTitle: model.title,
                preferences: $preferences,
                activityType: model.activityType
            )
        }
    }

    @ViewBuilder
    private func fieldView(_ field: TrainingActivityDisplayField) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(field.russianTitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            Text(value(for: field))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)
        }
    }

    private func value(for field: TrainingActivityDisplayField) -> String {
        switch field {
        case .distance: return model.distanceText
        case .duration: return model.durationText
        case .startTime: return model.startTimeText
        case .calories: return model.caloriesText
        }
    }
}

private struct TrainingActivityFieldSettingsView: View {
    let activityTitle: String
    @Binding var preferences: TrainingActivityFieldPreferences
    let activityType: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Поля карточки") {
                    ForEach(TrainingActivityDisplayField.allCases) { field in
                        Toggle(field.russianTitle, isOn: binding(for: field))
                    }
                }
            }
            .navigationTitle(activityTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }

    private func binding(for field: TrainingActivityDisplayField) -> Binding<Bool> {
        Binding(
            get: { preferences.fields(for: activityType).contains(field) },
            set: { isEnabled in
                var fields = preferences.fields(for: activityType)
                if isEnabled {
                    if !fields.contains(field) { fields.append(field) }
                } else {
                    fields.removeAll { $0 == field }
                }
                preferences.setFields(fields, for: activityType)
            }
        )
    }
}
