import SwiftUI

struct ConnectedServicesDocumentationView: View {
    let catalog: [ConnectedServiceDocumentation]

    private let palette = SportAppVisualStyle.palette

    init(catalog: [ConnectedServiceDocumentation] = ConnectedServiceDocumentationCatalog.services) {
        self.catalog = catalog
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Связанные сервисы") {
                    ForEach(catalog) { service in
                        NavigationLink {
                            ConnectedServiceDetailView(service: service)
                        } label: {
                            ServiceDocumentationRow(service: service)
                        }
                        .accessibilityLabel(service.title)
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(palette.background).ignoresSafeArea())
            .navigationTitle("Документация")
            .navigationBarTitleDisplayMode(.inline)
            .accessibilityLabel("Документация")
        }
        .preferredColorScheme(.dark)
    }
}

private struct ServiceDocumentationRow: View {
    let service: ConnectedServiceDocumentation

    private let palette = SportAppVisualStyle.palette

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: service.id == "appleHealth" ? "heart.text.square" : "figure.run.square.stack")
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 34, height: 34)
                .foregroundStyle(Color(palette.electricCyan))
                .background(Color(palette.panel).opacity(0.9), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(service.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(palette.primaryText))

                Text("\(service.allFields.count) полей")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(palette.secondaryText))
            }
        }
        .padding(.vertical, 4)
    }
}

struct ConnectedServiceDetailView: View {
    let service: ConnectedServiceDocumentation

    private let palette = SportAppVisualStyle.palette

    var body: some View {
        List {
            Section {
                Text(service.summary)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(palette.secondaryText))
                    .fixedSize(horizontal: false, vertical: true)
                    .listRowBackground(Color.clear)
            }

            ForEach(service.sections) { section in
                Section(section.title) {
                    ForEach(section.fields) { field in
                        DocumentationFieldDisclosureView(field: field)
                            .listRowBackground(Color.clear)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(palette.background).ignoresSafeArea())
        .navigationTitle(service.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DocumentationFieldDisclosureView: View {
    let field: ServiceDocumentationField

    private let palette = SportAppVisualStyle.palette

    var body: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 12) {
                Text(field.description)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(palette.primaryText))
                    .fixedSize(horizontal: false, vertical: true)

                SupportedTrainingTypeChips(types: field.supportedTypes)
            }
            .padding(.top, 10)
        } label: {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(field.humanName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(palette.primaryText))
                        .fixedSize(horizontal: false, vertical: true)

                    Text(field.systemName)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Color(palette.cyanGlow))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 10)

                Text("\(field.supportedTypes.count) типов")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(palette.background))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color(palette.emberOrange), in: Capsule())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(palette.panel).opacity(0.9), in: RoundedRectangle(cornerRadius: SportAppVisualStyle.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: SportAppVisualStyle.cardRadius)
                .stroke(Color(palette.panelStroke), lineWidth: 1)
        }
        .accessibilityLabel("\(field.humanName), \(field.systemName)")
    }
}

struct SupportedTrainingTypeChips: View {
    let types: [SupportedTrainingType]

    private let palette = SportAppVisualStyle.palette
    private let columns = [
        GridItem(.adaptive(minimum: 118), spacing: 8, alignment: .leading)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(types) { type in
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(palette.primaryText))
                        .lineLimit(1)

                    Text(type.id)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(Color(palette.secondaryText))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(palette.background).opacity(0.62), in: RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(palette.cyanGlow).opacity(0.26), lineWidth: 1)
                }
            }
        }
    }
}
