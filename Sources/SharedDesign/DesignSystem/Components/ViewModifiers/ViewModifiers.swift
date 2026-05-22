import SwiftUI

// MARK: - SectionBackgroundModifier

public struct SectionBackgroundModifier: ViewModifier {
    // MARK: Lifecycle

    public init() { }

    public func body(content: Content) -> some View {
        content
            .background(self.theme.colors.background)
    }

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - CardBackgroundModifier

public struct CardBackgroundModifier: ViewModifier {
    // MARK: Lifecycle

    public init() { }

    public func body(content: Content) -> some View {
        content
            .background(self.theme.colors.surface)
            .cornerRadius(self.theme.sizing.cornerRadius.large)
            .shadow(
                color: Color.black.opacity(0.05),
                radius: 8,
                x: 0,
                y: 2
            )
    }

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - IconBackgroundModifier

public struct IconBackgroundModifier: ViewModifier {
    // MARK: Lifecycle

    public init(color: Color, size: CGFloat = 32) {
        self.color = color
        self.size = size
    }

    public func body(content: Content) -> some View {
        ZStack {
            Circle()
                .fill(self.color.opacity(0.1))
                .frame(width: self.size, height: self.size)

            content
        }
    }

    // MARK: Internal

    let color: Color
    let size: CGFloat

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - ContentMaskModifier

public struct ContentMaskModifier: ViewModifier {
    // MARK: Lifecycle

    public init(
        isContentAccessible: Bool,
        title: String? = nil,
        description: String? = nil,
        actionTitle: String? = nil,
        onUpgradeAction: @escaping () -> Void = { }
    ) {
        self.isContentAccessible = isContentAccessible
        self.title = title ?? String(
            localized: "premium.mask.title",
            defaultValue: "Premium Feature",
            bundle: .module,
            comment: "Premium content mask overlay title"
        )
        self.description = description ?? String(
            localized: "premium.mask.description",
            defaultValue: "Upgrade to access this feature",
            bundle: .module,
            comment: "Premium content mask overlay description"
        )
        self.actionTitle = actionTitle ?? String(
            localized: "premium.mask.action",
            defaultValue: "Upgrade Now",
            bundle: .module,
            comment: "Premium content mask upgrade button title"
        )
        self.onUpgradeAction = onUpgradeAction
    }

    public func body(content: Content) -> some View {
        ZStack {
            content
                .blur(radius: self.isContentAccessible ? 0 : 8)
                .disabled(!self.isContentAccessible)

            if !self.isContentAccessible {
                MaskedContentOverlay(
                    title: self.title,
                    description: self.description,
                    actionTitle: self.actionTitle,
                    onUpgradeAction: self.onUpgradeAction
                )
            }
        }
    }

    // MARK: Internal

    let isContentAccessible: Bool
    let title: String
    let description: String
    let actionTitle: String
    let onUpgradeAction: () -> Void

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - MaskedContentOverlay

struct MaskedContentOverlay: View {
    @Environment(\.theme) private var theme

    let title: String
    let description: String
    let actionTitle: String
    let onUpgradeAction: () -> Void

    var body: some View {
        Rectangle()
            .fill(Color.black.opacity(0.5))
            .overlay {
                VStack(spacing: self.theme.spacing.lg) {
                    // Lock icon with premium styling
                    ZStack {
                        Circle()
                            .fill(self.theme.colors.primary.opacity(0.1))
                            .frame(width: 64, height: 64)

                        Image("lock")
                            .resizable().aspectRatio(contentMode: .fit)
                            .frame(width: 34, height: 34)
                            .foregroundColor(self.theme.colors.primary)
                    }

                    VStack(spacing: self.theme.spacing.sm) {
                        Text(self.title)
                            .font(self.theme.typography.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(self.theme.colors.textPrimary)
                            .multilineTextAlignment(.center)

                        Text(self.description)
                            .font(self.theme.typography.body)
                            .foregroundColor(self.theme.colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    Button(action: self.onUpgradeAction) {
                        HStack(spacing: self.theme.spacing.xs) {
                            Image(systemName: "crown.fill")
                                .font(self.theme.typography.caption1)
                            Text(self.actionTitle)
                                .font(self.theme.typography.headline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(self.theme.colors.onPrimary)
                        .padding(.horizontal, self.theme.spacing.lg)
                        .padding(.vertical, self.theme.spacing.sm)
                        .background(self.theme.colors.primary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(self.theme.spacing.xl)
                .background(self.theme.colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.large))
                .shadow(
                    color: Color.black.opacity(0.1),
                    radius: 10,
                    x: 0,
                    y: 4
                )
                .padding(.horizontal, self.theme.spacing.xl)
            }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply section background styling
    public func sectionBackground() -> some View {
        modifier(SectionBackgroundModifier())
    }

    /// Apply card background styling with shadow
    public func cardBackground() -> some View {
        modifier(CardBackgroundModifier())
    }

    /// Apply icon background with circular color
    public func iconBackground(_ color: Color, size: CGFloat = 32) -> some View {
        modifier(IconBackgroundModifier(color: color, size: size))
    }

    /// Masks content behind a premium upgrade overlay when not accessible
    public func contentMask(
        isAccessible: Bool,
        title: String? = nil,
        description: String? = nil,
        actionTitle: String? = nil,
        onUpgradeAction: @escaping () -> Void = { }
    ) -> some View {
        modifier(ContentMaskModifier(
            isContentAccessible: isAccessible,
            title: title,
            description: description,
            actionTitle: actionTitle,
            onUpgradeAction: onUpgradeAction
        ))
    }
}

// MARK: - Animation Modifiers

extension View {
    /// Apply a subtle scale animation on tap
    public func scaleOnTap() -> some View {
        self.scaleEffect(1)
            .onTapGesture { }
            .scaleEffect(1)
            .animation(AnimationConstants.Easing.quickOut, value: true)
    }

    /// Apply a fade-in animation
    public func fadeIn(duration: Double = 0.3, delay: Double = 0) -> some View {
        self.opacity(1)
            .animation(AnimationConstants.Easing.quickOut.delay(delay), value: true)
    }
}

#if DEBUG
    struct ViewModifiers_Previews: PreviewProvider {
        static var previews: some View {
            VStack(spacing: 20) {
                Text("Section Background")
                    .padding()
                    .sectionBackground()

                Text("Card Background")
                    .padding()
                    .cardBackground()

                Image("star")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
                    .iconBackground(.orange)

                Text("Premium Content")
                    .padding()
                    .cardBackground()
                    .contentMask(
                        isAccessible: false,
                        title: "Premium Feature",
                        description: "Upgrade to unlock this content"
                    )
            }
            .padding()
            .environment(\.theme, DefaultTheme())
        }
    }
#endif
