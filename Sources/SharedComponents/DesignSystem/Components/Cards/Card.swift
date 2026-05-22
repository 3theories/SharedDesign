import SwiftUI

// MARK: - CardStyle

/// Style configuration for Card component
public enum CardStyle: Sendable {
    /// Standard card with surface background
    case standard

    /// Elevated card with shadow
    case elevated

    /// Outlined card with border
    case outlined

    /// Glass morphism effect
    case glass

    /// Gradient background
    case gradient(colors: [Color])
}

// MARK: - Card

/// A versatile card component that follows the design system
public struct Card<Content: View, Header: View, Accessory: View>: View {
    // MARK: Lifecycle

    public init(
        padding: CGFloat? = nil,
        cornerRadius: CGFloat? = nil,
        backgroundColor: Color? = nil,
        showShadow: Bool = false,
        elevation: ElevationLevel = .none,
        style: CardStyle = .standard,
        isInteractive: Bool = false,
        animateAppearance: Bool = false,
        action: (() -> Void)? = nil,
        @ViewBuilder header: () -> Header,
        @ViewBuilder accessory: () -> Accessory,
        @ViewBuilder content: () -> Content
    ) {
        self.header = header()
        self.accessory = accessory()
        self.content = content()
        self.backgroundColor = backgroundColor
        self.showShadow = showShadow
        self.elevation = elevation
        self.style = style
        self.isInteractive = isInteractive
        self.animateAppearance = animateAppearance
        self.action = action

        // Use metric card defaults to match existing UI
        self.padding = padding ?? 16
        self.cornerRadius = cornerRadius ?? 16
    }

    /// Convenience init without header and accessory
    public init(
        padding: CGFloat? = nil,
        cornerRadius: CGFloat? = nil,
        backgroundColor: Color? = nil,
        showShadow: Bool = false,
        elevation: ElevationLevel = .none,
        style: CardStyle = .standard,
        isInteractive: Bool = false,
        animateAppearance: Bool = false,
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) where Header == EmptyView, Accessory == EmptyView {
        self.header = nil
        self.accessory = nil
        self.content = content()
        self.backgroundColor = backgroundColor
        self.showShadow = showShadow
        self.elevation = elevation
        self.style = style
        self.isInteractive = isInteractive
        self.animateAppearance = animateAppearance
        self.action = action

        self.padding = padding ?? 16
        self.cornerRadius = cornerRadius ?? 16
    }

    /// Convenience init with just header
    public init(
        padding: CGFloat? = nil,
        cornerRadius: CGFloat? = nil,
        backgroundColor: Color? = nil,
        showShadow: Bool = false,
        elevation: ElevationLevel = .none,
        style: CardStyle = .standard,
        isInteractive: Bool = false,
        animateAppearance: Bool = false,
        action: (() -> Void)? = nil,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) where Accessory == EmptyView {
        self.header = header()
        self.accessory = nil
        self.content = content()
        self.backgroundColor = backgroundColor
        self.showShadow = showShadow
        self.elevation = elevation
        self.style = style
        self.isInteractive = isInteractive
        self.animateAppearance = animateAppearance
        self.action = action

        self.padding = padding ?? 16
        self.cornerRadius = cornerRadius ?? 16
    }

    // MARK: Public

    public var body: some View {
        let cardContent = VStack(alignment: .leading, spacing: 0) {
            // Optional header section
            if self.header != nil || self.accessory != nil {
                HStack(alignment: .top) {
                    if let header {
                        header
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let accessory {
                        accessory
                    }
                }
                .padding(self.padding)

                Divider()
                    .opacity(0.1)
            }

            // Main content
            self.content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(
                    self.header != nil || self.accessory != nil
                        ? EdgeInsets(top: 0, leading: self.padding, bottom: self.padding, trailing: self.padding)
                        :
                        EdgeInsets(
                            top: self.padding,
                            leading: self.padding,
                            bottom: self.padding,
                            trailing: self.padding
                        )
                )
        }
        .background(self.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: self.effectiveCornerRadius))
        .overlay(self.cardBorder)
        .if(self.elevation != .none) { view in
            view.cardShadow(for: self.elevation)
        }
        .if(self.showShadow && self.elevation == .none) { view in
            view.shadow(
                color: self.theme.colors.overlayLight,
                radius: 10,
                x: 0,
                y: 5
            )
        }
        .scaleEffect(self.isPressed ? 0.97 : 1.0)
        .opacity(self.animateAppearance ? (self.hasAppeared ? 1.0 : 0.0) : 1.0)
        .offset(y: self.animateAppearance ? (self.hasAppeared ? 0 : 20) : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: self.isPressed)

        if self.isInteractive || self.action != nil {
            cardContent
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !self.isPressed {
                                self.isPressed = true
                                HapticManager.shared.trigger(.light)
                            }
                        }
                        .onEnded { _ in
                            self.isPressed = false
                            self.action?()
                        }
                )
                .accessibilityAddTraits(.isButton)
                .onAppear {
                    if self.animateAppearance {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            self.hasAppeared = true
                        }
                    }
                }
        } else {
            cardContent
                .onAppear {
                    if self.animateAppearance {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            self.hasAppeared = true
                        }
                    }
                }
        }
    }

    // MARK: Internal

    let header: Header?
    let accessory: Accessory?
    let content: Content
    let padding: CGFloat
    let cornerRadius: CGFloat
    let backgroundColor: Color?
    let showShadow: Bool
    let elevation: ElevationLevel
    let style: CardStyle
    let isInteractive: Bool
    let animateAppearance: Bool
    let action: (() -> Void)?

    // MARK: Private

    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    @State private var hasAppeared = false

    private var effectiveCornerRadius: CGFloat {
        if self.elevation != .none {
            return self.theme.elevations.style(for: self.elevation).cornerRadius
        }
        return self.cornerRadius
    }

    private var effectiveBackgroundColor: Color {
        if let backgroundColor {
            return backgroundColor
        }
        if self.elevation != .none {
            return self.theme.elevations.style(for: self.elevation).backgroundColor
        }
        return self.theme.colors.surface1
    }

    // MARK: - Card Background

    @ViewBuilder
    private var cardBackground: some View {
        switch self.style {
        case .standard:
            RoundedRectangle(cornerRadius: self.effectiveCornerRadius)
                .fill(self.effectiveBackgroundColor)

        case .elevated:
            RoundedRectangle(cornerRadius: self.effectiveCornerRadius)
                .fill(self.effectiveBackgroundColor)

        case .outlined:
            RoundedRectangle(cornerRadius: self.effectiveCornerRadius)
                .fill(self.theme.colors.background)

        case .glass:
            RoundedRectangle(cornerRadius: self.effectiveCornerRadius)
                .fill(.ultraThinMaterial)

        case let .gradient(colors):
            RoundedRectangle(cornerRadius: self.effectiveCornerRadius)
                .fill(
                    LinearGradient(
                        colors: colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    // MARK: - Card Border

    @ViewBuilder
    private var cardBorder: some View {
        switch self.style {
        case .outlined:
            RoundedRectangle(cornerRadius: self.effectiveCornerRadius)
                .stroke(self.theme.colors.borderPrimary, lineWidth: 1)

        case .glass:
            RoundedRectangle(cornerRadius: self.effectiveCornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )

        default:
            if self.elevation != .none {
                let elevationStyle = self.theme.elevations.style(for: self.elevation)
                if elevationStyle.borderWidth > 0 {
                    RoundedRectangle(cornerRadius: self.effectiveCornerRadius)
                        .stroke(elevationStyle.borderColor, lineWidth: elevationStyle.borderWidth)
                }
            }
        }
    }
}

// MARK: - View Extension for Card Shadow

extension View {
    @ViewBuilder
    func cardShadow(for elevation: ElevationLevel) -> some View {
        switch elevation {
        case .none:
            self
        case .low:
            self.shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        case .medium:
            self.shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        case .high:
            self.shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)
        case .overlay:
            self.shadow(color: .black.opacity(0.18), radius: 24, x: 0, y: 12)
        }
    }
}

// Note: `if(_:transform:)` extension is defined in ElevationTokens.swift

#if os(iOS)

    // MARK: - Preview

    #Preview("Card Styles") {
        ScrollView {
            VStack(spacing: 24) {
                Text("Card Styles")
                    .font(.title2.bold())

                // Standard Card
                VStack(alignment: .leading, spacing: 8) {
                    Text("Standard").font(.headline)
                    Card {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Standard Card")
                                .font(.headline)
                            Text("Default card with surface background")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Elevation Levels
                VStack(alignment: .leading, spacing: 8) {
                    Text("Elevation Levels").font(.headline)
                    ForEach([ElevationLevel.low, .medium, .high], id: \.rawValue) { level in
                        Card(elevation: level) {
                            HStack {
                                Text("Elevation: \(level.rawValue)")
                                    .font(.subheadline)
                                Spacer()
                            }
                        }
                    }
                }

                // Card Styles
                VStack(alignment: .leading, spacing: 8) {
                    Text("Style Variants").font(.headline)

                    Card(style: .outlined) {
                        Text("Outlined Card")
                            .font(.subheadline)
                    }

                    Card(style: .glass) {
                        Text("Glass Card")
                            .font(.subheadline)
                    }

                    Card(style: .gradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)])) {
                        Text("Gradient Card")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                    }
                }

                // Interactive Card
                VStack(alignment: .leading, spacing: 8) {
                    Text("Interactive Cards").font(.headline)

                    Card(
                        elevation: .medium,
                        isInteractive: true,
                        action: { print("Card tapped!") }
                    ) {
                        HStack {
                            Image(systemName: "hand.tap.fill")
                                .foregroundStyle(.blue)
                            Text("Tap me - I have haptic feedback!")
                                .font(.subheadline)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Animated Appearance
                VStack(alignment: .leading, spacing: 8) {
                    Text("Animated Appearance").font(.headline)
                    Card(elevation: .low, animateAppearance: true) {
                        Text("This card animates in on appear")
                            .font(.subheadline)
                    }
                }

                // With Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("With Header").font(.headline)
                    Card(
                        elevation: .medium,
                        header: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Today's Overview")
                                    .font(.headline)
                                Text("January 15, 2024")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        },
                        content: {
                            Text("Card content goes here...")
                                .font(.body)
                        }
                    )
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .environment(\.theme, DefaultTheme())
    }
#endif
