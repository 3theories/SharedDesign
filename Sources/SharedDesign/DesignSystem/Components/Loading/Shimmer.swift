import SwiftUI

// MARK: - ShimmerModifier

/// A shimmer/skeleton loading effect using view modifier approach
public struct ShimmerModifier: ViewModifier {
    // MARK: Lifecycle

    public init(
        isLoading: Bool = true,
        baseColor: Color? = nil,
        highlightColor: Color? = nil
    ) {
        self.isLoading = isLoading
        self.baseColor = baseColor
        self.highlightColor = highlightColor
    }

    public func body(content: Content) -> some View {
        if self.isLoading {
            content
                .hidden()
                .overlay(
                    GeometryReader { geometry in
                        // For small views (< 100px), use wider gradient (0.6-0.8)
                        // For medium views (100-200px), use medium gradient (0.4-0.6)
                        // For large views (> 200px), use narrower gradient (0.3-0.4)
                        let gradientWidth: CGFloat =
                            if geometry.size.width < 100 {
                                0.7
                            } else if geometry.size.width < 200 {
                                0.5
                            } else {
                                0.35
                            }

                        Rectangle()
                            .fill(self.effectiveBaseColor)
                            .overlay(
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(stops: [
                                                .init(color: self.effectiveHighlightColor.opacity(0), location: 0),
                                                .init(color: self.effectiveHighlightColor.opacity(0.3), location: 0.4),
                                                .init(color: self.effectiveHighlightColor, location: 0.5),
                                                .init(color: self.effectiveHighlightColor.opacity(0.3), location: 0.6),
                                                .init(color: self.effectiveHighlightColor.opacity(0), location: 1)
                                            ]),
                                            startPoint: UnitPoint(x: self.phase - gradientWidth, y: 0.5),
                                            endPoint: UnitPoint(x: self.phase + gradientWidth, y: 0.5)
                                        )
                                    )
                                    .animation(
                                        Animation.linear(duration: 2.5)
                                            .repeatForever(autoreverses: false),
                                        value: self.phase
                                    )
                            )
                            .onAppear {
                                self.phase = 1.3
                            }
                    }
                )
        } else {
            content
        }
    }

    // MARK: Private

    @State private var phase: CGFloat = 0
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.theme) private var theme

    private let isLoading: Bool
    private let baseColor: Color?
    private let highlightColor: Color?

    private var effectiveBaseColor: Color {
        self.baseColor ?? (
            self.colorScheme == .dark
                ? self.theme.colors.surface3
                : self.theme.colors.surface4
        )
    }

    private var effectiveHighlightColor: Color {
        self.highlightColor ?? (
            self.colorScheme == .dark
                ? self.theme.colors.surface5
                : Color.white.opacity(0.8)
        )
    }
}

// MARK: - View Extension

extension View {
    /// Apply shimmer loading effect
    public func shimmer(
        isLoading: Bool = true,
        baseColor: Color? = nil,
        highlightColor: Color? = nil
    ) -> some View {
        modifier(ShimmerModifier(
            isLoading: isLoading,
            baseColor: baseColor,
            highlightColor: highlightColor
        ))
    }

    /// Apply shimmer with rounded corners
    public func shimmerWithCornerRadius(
        _ radius: CGFloat,
        isLoading: Bool = true,
        baseColor: Color? = nil,
        highlightColor: Color? = nil
    ) -> some View {
        self
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .shimmer(
                isLoading: isLoading,
                baseColor: baseColor,
                highlightColor: highlightColor
            )
    }
}

// MARK: - ShimmerListItem

/// A pre-built shimmer component for list items
public struct ShimmerListItem: View {
    // MARK: Lifecycle

    public init(
        showAvatar: Bool = true,
        lineCount: Int = 2
    ) {
        self.showAvatar = showAvatar
        self.lineCount = lineCount
    }

    // MARK: Public

    public var body: some View {
        HStack(alignment: .top, spacing: self.theme.spacing.md) {
            if self.showAvatar {
                Circle()
                    .frame(width: 48, height: 48)
                    .shimmer()
            }

            VStack(alignment: .leading, spacing: self.theme.spacing.sm) {
                // Title
                Capsule()
                    .frame(height: 16)
                    .frame(maxWidth: .infinity)
                    .shimmer()

                // Subtitle lines
                ForEach(0..<self.lineCount, id: \.self) { index in
                    Capsule()
                        .frame(height: 12)
                        .frame(maxWidth: index == self.lineCount - 1 ? 120 : .infinity)
                        .shimmer()
                }
            }
        }
        .padding(self.theme.spacing.md)
    }

    // MARK: Private

    @Environment(\.theme) private var theme

    private let showAvatar: Bool
    private let lineCount: Int
}

// MARK: - ShimmerCard

/// A pre-built shimmer component for cards
public struct ShimmerCard: View {
    // MARK: Lifecycle

    public init(
        aspectRatio: CGFloat? = nil,
        showContent: Bool = true
    ) {
        self.aspectRatio = aspectRatio
        self.showContent = showContent
    }

    // MARK: Public

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image placeholder
            if let aspectRatio {
                Rectangle()
                    .aspectRatio(aspectRatio, contentMode: .fit)
                    .shimmer()
            }

            // Content
            if self.showContent {
                VStack(alignment: .leading, spacing: self.theme.spacing.sm) {
                    Capsule()
                        .frame(height: 20)
                        .frame(maxWidth: 200)
                        .shimmer()

                    Capsule()
                        .frame(height: 14)
                        .shimmer()

                    Capsule()
                        .frame(height: 14)
                        .frame(maxWidth: 150)
                        .shimmer()
                }
                .padding(self.theme.spacing.md)
            }
        }
        .background(self.theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.medium))
    }

    // MARK: Private

    @Environment(\.theme) private var theme

    private let aspectRatio: CGFloat?
    private let showContent: Bool
}

// MARK: - ShimmerView_Previews

struct ShimmerView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Basic shapes
                Text("Basic Shapes")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 20) {
                    Rectangle()
                        .frame(width: 100, height: 100)
                        .shimmer()

                    Circle()
                        .frame(width: 100, height: 100)
                        .shimmer()

                    Capsule()
                        .frame(width: 100, height: 40)
                        .shimmer()
                }

                Divider()

                // List items
                Text("List Items")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 0) {
                    ForEach(0..<3) { _ in
                        ShimmerListItem()
                        Divider()
                    }
                }
                .background(Color.white)
                .cornerRadius(12)

                Divider()

                // Cards
                Text("Cards")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(0..<4) { _ in
                        ShimmerCard(aspectRatio: 16 / 9)
                    }
                }

                Divider()

                // Usage with real content
                Text("With Real Content")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Simulating loading state
                @State var isLoading = true

                VStack {
                    Toggle("Loading", isOn: $isLoading)
                        .padding(.bottom)

                    Text("Hello World")
                        .font(.title)
                        .shimmer(isLoading: isLoading)

                    Image("star")
                        .resizable().aspectRatio(contentMode: .fit)
                        .frame(width: 34, height: 34)
                        .shimmer(isLoading: isLoading)
                }
            }
            .padding()
        }
        .background(Color.gray.opacity(0.1))
        .environment(\.theme, DefaultTheme())
    }
}
