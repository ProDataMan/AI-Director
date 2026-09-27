public struct ColorPalette: Codable, Sendable, Equatable {
    public let background: RGBColor
    public let surface: RGBColor
    public let primary: RGBColor
    public let secondary: RGBColor
    public let accent: RGBColor
    public let text: RGBColor

    public init(
        background: RGBColor,
        surface: RGBColor,
        primary: RGBColor,
        secondary: RGBColor,
        accent: RGBColor,
        text: RGBColor
    ) {
        self.background = background
        self.surface = surface
        self.primary = primary
        self.secondary = secondary
        self.accent = accent
        self.text = text
    }
}
