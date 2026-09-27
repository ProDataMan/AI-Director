import Foundation
import Testing
@testable import StudioCore

@Test func studioStateCodableRoundTrip() throws {
    let encoded = try JSONEncoder().encode(StudioState.recording)
    let decoded = try JSONDecoder().decode(StudioState.self, from: encoded)
    #expect(decoded == .recording)
}

@Test func colorPaletteRoundTrip() throws {
    let palette = ColorPalette(
        background: RGBColor(red: 0.1, green: 0.1, blue: 0.1),
        surface: RGBColor(red: 0.2, green: 0.2, blue: 0.2),
        primary: RGBColor(red: 0.3, green: 0.4, blue: 0.9),
        secondary: RGBColor(red: 0.2, green: 0.7, blue: 0.8),
        accent: RGBColor(red: 1.0, green: 0.5, blue: 0.2),
        text: RGBColor(red: 1.0, green: 1.0, blue: 1.0)
    )
    let data = try JSONEncoder().encode(palette)
    #expect(try JSONDecoder().decode(ColorPalette.self, from: data) == palette)
}
