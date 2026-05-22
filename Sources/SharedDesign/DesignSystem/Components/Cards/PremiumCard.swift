import SwiftUI

/// PremiumCard: a richer visual container with subtle gradient stroke and depth
/// Use for feature areas that should feel elevated (analytics, insights, etc.).
public struct PremiumCard<Content: View>: View {
    // MARK: Lifecycle

    public init(
        padding: CGFloat = 16,
        cornerRadius: CGFloat = 16,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content
    }

    // MARK: Public

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            self.content()
                .padding(self.padding)
        }
        .background(
            // Base
            RoundedRectangle(cornerRadius: self.cornerRadius)
                .fill(self.theme.colors.surface1)
                .overlay(
                    // Soft gradient stroke for a premium edge
                    RoundedRectangle(cornerRadius: self.cornerRadius)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    self.theme.colors.overlayLight.opacity(0.25),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: self.theme.colors.overlayLight.opacity(0.25), radius: 10, x: 0, y: 6)
                .shadow(color: self.theme.colors.overlayLight.opacity(0.06), radius: 20, x: 0, y: 20)
        )
        .clipShape(RoundedRectangle(cornerRadius: self.cornerRadius))
    }

    // MARK: Internal

    let content: () -> Content
    let padding: CGFloat
    let cornerRadius: CGFloat

    // MARK: Private

    @Environment(\.theme) private var theme
}

#Preview("PremiumCard") {
    PremiumCard {
        VStack(alignment: .leading, spacing: 8) {
            Text("Premium Card")
                .font(.headline)
            Text("Subtle gradient stroke and depth for elevated UI.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    .padding()
}
