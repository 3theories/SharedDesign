import SwiftUI

// MARK: - ColorPaletteDemo

/// Demo showing the new color palette system
public struct ColorPaletteDemo: View {
    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Color Palette System")
                        .font(.largeTitle.bold())
                    Text("Currently using: \(self.colorScheme == .dark ? "DarkColorPalette" : "LightColorPalette")")
                        .font(.subheadline)
                        .foregroundColor(self.theme.colors.textSecondary)
                }
                .padding()

                // Card examples showing automatic adaptation
                VStack(alignment: .leading, spacing: 16) {
                    Text("Cards with Different Surface Levels")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach([
                        ("Default Card (surface1)", self.theme.colors.surface1),
                        ("Elevated Card (surface2)", self.theme.colors.surface2),
                        ("Higher Elevation (surface3)", self.theme.colors.surface3)
                    ], id: \.0) { title, color in
                        Card(backgroundColor: color) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(title)
                                    .font(.headline)
                                    .foregroundColor(self.theme.colors.textPrimary)
                                Text("This card automatically adapts its background color")
                                    .font(.caption)
                                    .foregroundColor(self.theme.colors.textSecondary)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Metric card example
                VStack(alignment: .leading, spacing: 16) {
                    Text("Metric Cards")
                        .font(.headline)
                        .padding(.horizontal)

                    HStack(spacing: 16) {
                        Card {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image("fire")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 16, height: 16)
                                        .foregroundColor(self.theme.colors.primary)
                                    Text("Calories")
                                        .font(.caption)
                                        .foregroundColor(self.theme.colors.textSecondary)
                                }
                                Text(verbatim: "450")
                                    .font(.title2.bold())
                                    .foregroundColor(self.theme.colors.textPrimary)
                            }
                        }

                        Card {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image("love")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 16, height: 16)
                                        .foregroundColor(self.theme.colors.error)
                                    Text("Heart Rate")
                                        .font(.caption)
                                        .foregroundColor(self.theme.colors.textSecondary)
                                }
                                Text("72 bpm")
                                    .font(.title2.bold())
                                    .foregroundColor(self.theme.colors.textPrimary)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Color swatches
                VStack(alignment: .leading, spacing: 16) {
                    Text("Key Colors")
                        .font(.headline)
                        .padding(.horizontal)

                    VStack(spacing: 8) {
                        ColorRow(name: "Background", color: self.theme.colors.background)
                        ColorRow(name: "Surface1 (Cards)", color: self.theme.colors.surface1)
                        ColorRow(name: "Surface2 (Elevated)", color: self.theme.colors.surface2)
                        ColorRow(name: "Primary Text", color: self.theme.colors.textPrimary)
                        ColorRow(name: "Secondary Text", color: self.theme.colors.textSecondary)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(self.theme.colors.background)
    }

    // MARK: Private

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.theme) private var theme
}

// MARK: - ColorRow

struct ColorRow: View {
    // MARK: Internal

    let name: String
    let color: Color

    var body: some View {
        HStack {
            Rectangle()
                .fill(self.color)
                .frame(width: 40, height: 40)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(self.theme.colors.borderPrimary, lineWidth: 1)
                )

            Text(self.name)
                .font(.subheadline)
                .foregroundColor(self.theme.colors.textPrimary)

            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: Private

    @Environment(\.theme) private var theme
}

#Preview("Light Mode") {
    ColorPaletteDemo()
        .environment(\.theme, DefaultTheme(colorScheme: .light))
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    ColorPaletteDemo()
        .environment(\.theme, DefaultTheme(colorScheme: .dark))
        .preferredColorScheme(.dark)
}
