import SwiftUI

struct SportAppColorToken: Equatable {
    let red: Double
    let green: Double
    let blue: Double
    let opacity: Double

    init(red: Double, green: Double, blue: Double, opacity: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }
}

struct SportAppPalette {
    let background: SportAppColorToken
    let panel: SportAppColorToken
    let panelStroke: SportAppColorToken
    let electricCyan: SportAppColorToken
    let cyanGlow: SportAppColorToken
    let emberOrange: SportAppColorToken
    let primaryText: SportAppColorToken
    let secondaryText: SportAppColorToken
    let mutedText: SportAppColorToken
    let lineGlowOpacity: Double
    let panelGlowOpacity: Double

    static let iconInspired = SportAppPalette(
        background: SportAppColorToken(red: 0.015, green: 0.025, blue: 0.075),
        panel: SportAppColorToken(red: 0.035, green: 0.09, blue: 0.19, opacity: 0.86),
        panelStroke: SportAppColorToken(red: 0.0, green: 0.43, blue: 0.95, opacity: 0.32),
        electricCyan: SportAppColorToken(red: 0.0, green: 0.78, blue: 1.0),
        cyanGlow: SportAppColorToken(red: 0.45, green: 0.92, blue: 1.0),
        emberOrange: SportAppColorToken(red: 1.0, green: 0.35, blue: 0.18),
        primaryText: SportAppColorToken(red: 0.92, green: 0.98, blue: 1.0),
        secondaryText: SportAppColorToken(red: 0.64, green: 0.78, blue: 0.92),
        mutedText: SportAppColorToken(red: 0.38, green: 0.52, blue: 0.7),
        lineGlowOpacity: 0.54,
        panelGlowOpacity: 0.18
    )
}

enum SportAppVisualStyle {
    static let palette = SportAppPalette.iconInspired
    static let cardRadius: CGFloat = 8

    static func activityAccent(for activityType: String) -> Color {
        let normalized = activityType.lowercased()
        if normalized.contains("swimming") {
            return Color(red: 0.18, green: 0.86, blue: 1.0)
        }
        if normalized.contains("cycling") {
            return Color(red: 0.0, green: 0.62, blue: 1.0)
        }
        if normalized.contains("running") || normalized.contains("walking") {
            return Color(red: 1.0, green: 0.35, blue: 0.18)
        }
        if normalized.contains("strength") {
            return Color(red: 0.76, green: 0.55, blue: 1.0)
        }
        return Color(palette.electricCyan)
    }
}

extension Color {
    init(_ token: SportAppColorToken) {
        self.init(red: token.red, green: token.green, blue: token.blue, opacity: token.opacity)
    }
}

struct SportAppBackground: View {
    private let palette = SportAppVisualStyle.palette

    var body: some View {
        ZStack {
            Color(palette.background)
            LinearGradient(
                colors: [
                    Color(palette.electricCyan).opacity(0.2),
                    Color(palette.emberOrange).opacity(0.08),
                    Color(palette.background).opacity(0.35),
                    Color(palette.background)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            SportAppEnergyLines()
        }
        .ignoresSafeArea()
    }
}

private struct SportAppEnergyLines: View {
    private let palette = SportAppVisualStyle.palette

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                ForEach(0..<5, id: \.self) { index in
                    Path { path in
                        let y = height * (0.16 + CGFloat(index) * 0.12)
                        path.move(to: CGPoint(x: -width * 0.16, y: y + CGFloat(index) * 14))
                        path.addLine(to: CGPoint(x: width * 0.92, y: y - width * 0.28))
                    }
                    .stroke(
                        LinearGradient(
                            colors: [
                                .clear,
                                Color(palette.electricCyan).opacity(0.18 - Double(index) * 0.022),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}
