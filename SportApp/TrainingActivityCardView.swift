import SwiftUI

struct TrainingActivityCardView: View {
    let model: TrainingActivityCardModel
    @Binding var preferences: TrainingActivityFieldPreferences
    @State private var isShowingSettings = false
    private let palette = SportAppVisualStyle.palette

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(SportAppVisualStyle.activityAccent(for: model.activityType))
                .frame(width: 4)
                .shadow(color: SportAppVisualStyle.activityAccent(for: model.activityType).opacity(0.7), radius: 8, x: 0, y: 0)

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Text(model.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color(palette.primaryText))

                    Spacer(minLength: 8)

                    Button {
                        isShowingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(width: 30, height: 30)
                            .background(Color(palette.background).opacity(0.45), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color(palette.secondaryText))
                    .accessibilityLabel("Настроить поля")
                }

                LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)], alignment: .leading, spacing: 10) {
                    ForEach(preferences.fields(for: model.activityType)) { field in
                        fieldView(field)
                    }
                }
            }
        }
        .padding(14)
        .background(Color(palette.panel), in: RoundedRectangle(cornerRadius: SportAppVisualStyle.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: SportAppVisualStyle.cardRadius)
                .stroke(Color(palette.panelStroke), lineWidth: 1)
        }
        .shadow(color: Color(palette.electricCyan).opacity(palette.panelGlowOpacity), radius: 14, x: 0, y: 8)
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
                .foregroundStyle(Color(palette.secondaryText))
            Text(value(for: field))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(palette.primaryText))
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
