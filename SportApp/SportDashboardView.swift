import SwiftUI

struct SportDashboardView: View {
    @State private var selectedTab: SportDashboardTab = .trainings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Илья")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.primary)

            SportDashboardTabBar(selectedTab: $selectedTab)
                .padding(.top, 18)

            Group {
                switch selectedTab {
                case .trainings:
                    TrainingListView()
                case .chart:
                    WeeklyEffortView()
                }
            }
            .padding(.top, 24)
        }
        .padding(.horizontal, 18)
        .padding(.top, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.systemBackground))
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
