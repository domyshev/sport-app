import Testing
@testable import SportApp

struct SportAppVisualStyleTests {
    @Test func paletteMatchesIconInspiredNeonLanguage() {
        let palette = SportAppPalette.iconInspired

        #expect(palette.background == SportAppColorToken(red: 0.015, green: 0.025, blue: 0.075))
        #expect(palette.panel == SportAppColorToken(red: 0.035, green: 0.09, blue: 0.19, opacity: 0.86))
        #expect(palette.electricCyan == SportAppColorToken(red: 0.0, green: 0.78, blue: 1.0))
        #expect(palette.emberOrange == SportAppColorToken(red: 1.0, green: 0.35, blue: 0.18))
        #expect(palette.lineGlowOpacity > palette.panelGlowOpacity)
    }
}
