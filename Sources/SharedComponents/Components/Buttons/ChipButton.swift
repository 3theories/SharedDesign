import SwiftUI

// MARK: - ChipContentType

/// The type of leading content displayed in a chip
public enum ChipContentType: Sendable {
    /// No leading content, text only
    case text

    /// SF Symbol icon
    case icon(String)

    /// Emoji character
    case emoji(String)

    /// Flag emoji (country code)
    case flag(String)
}

// MARK: - ChipStyle

/// Visual style variants for ChipButton
public enum ChipStyle: Sendable {
    /// Solid fill when selected, outlined when not
    case solid

    /// Subtle tinted background with border
    case tinted

    /// Glass effect background (iOS 26+)
    case glass

    /// Always outlined with border
    case outlined
}

// MARK: - ChipSize

/// Size presets for ChipButton
public enum ChipSize: Sendable {
    case small
    case medium
    case large

    // MARK: Internal

    var fontSize: CGFloat {
        switch self {
        case .small: 12
        case .medium: 14
        case .large: 16
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .small: 10
        case .medium: 12
        case .large: 14
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .small: 10
        case .medium: 14
        case .large: 18
        }
    }

    var verticalPadding: CGFloat {
        switch self {
        case .small: 6
        case .medium: 8
        case .large: 10
        }
    }
}

// MARK: - ChipButton

/// A versatile, selectable chip button supporting multiple content types and styles.
/// Consolidates ChipButton, CuisineChip, and FilterChip into a single component.
public struct ChipButton: View {
    // MARK: Lifecycle

    public init(
        title: String,
        contentType: ChipContentType = .text,
        isSelected: Bool,
        style: ChipStyle = .solid,
        size: ChipSize = .medium,
        color: Color? = nil,
        scaleOnSelect: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.contentType = contentType
        self.isSelected = isSelected
        self.style = style
        self.size = size
        self.color = color
        self.scaleOnSelect = scaleOnSelect
        self.action = action
    }

    /// Convenience initializer with SF Symbol icon
    public init(
        title: String,
        icon: String,
        isSelected: Bool,
        style: ChipStyle = .solid,
        size: ChipSize = .medium,
        color: Color? = nil,
        scaleOnSelect: Bool = false,
        action: @escaping () -> Void
    ) {
        self.init(
            title: title,
            contentType: .icon(icon),
            isSelected: isSelected,
            style: style,
            size: size,
            color: color,
            scaleOnSelect: scaleOnSelect,
            action: action
        )
    }

    /// Convenience initializer with emoji
    public init(
        title: String,
        emoji: String,
        isSelected: Bool,
        style: ChipStyle = .tinted,
        size: ChipSize = .medium,
        scaleOnSelect: Bool = true,
        action: @escaping () -> Void
    ) {
        self.init(
            title: title,
            contentType: .emoji(emoji),
            isSelected: isSelected,
            style: style,
            size: size,
            color: nil,
            scaleOnSelect: scaleOnSelect,
            action: action
        )
    }

    // MARK: Public

    public var body: some View {
        Button {
            HapticManager.shared.trigger(.selection)
            self.action()
        } label: {
            self.chipContent
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(self.scaleOnSelect && self.isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: self.isSelected)
    }

    // MARK: Internal

    // Content
    let title: String
    let contentType: ChipContentType

    // Configuration
    let isSelected: Bool
    let style: ChipStyle
    let size: ChipSize
    let color: Color?
    let scaleOnSelect: Bool

    /// Action
    let action: () -> Void

    // MARK: Private

    @Environment(\.theme) private var theme

    private var accentColor: Color {
        self.color ?? self.theme.colors.primary
    }

    private var foregroundColor: Color {
        switch self.style {
        case .solid:
            self.isSelected ? self.theme.colors.onPrimary : self.theme.colors.textPrimary

        case .tinted:
            self.isSelected ? self.accentColor : self.theme.colors.textPrimary

        case .glass:
            self.isSelected ? self.theme.colors.onPrimary : self.theme.colors.textPrimary

        case .outlined:
            self.isSelected ? self.accentColor : self.theme.colors.textPrimary
        }
    }

    private var chipContent: some View {
        HStack(spacing: self.theme.spacing.xxs) {
            self.leadingContent

            Text(self.title)
                .font(.system(size: self.size.fontSize, weight: .medium))
        }
        .padding(.horizontal, self.size.horizontalPadding)
        .padding(.vertical, self.size.verticalPadding)
        .foregroundStyle(self.foregroundColor)
        .background(self.backgroundView)
        .clipShape(Capsule())
        .overlay(self.borderView)
    }

    @ViewBuilder
    private var leadingContent: some View {
        switch self.contentType {
        case .text:
            EmptyView()

        case let .icon(iconName):
            Image(systemName: iconName)
                .font(.system(size: self.size.iconSize, weight: .medium))

        case let .emoji(emoji):
            Text(emoji)
                .font(.system(size: self.size.fontSize))

        case let .flag(flag):
            Text(flag)
                .font(.system(size: self.size.fontSize + 2))
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch self.style {
        case .solid:
            if self.isSelected {
                self.accentColor
            } else {
                self.theme.colors.surface1
            }

        case .tinted:
            if self.isSelected {
                self.accentColor.opacity(0.15)
            } else {
                self.theme.colors.surface3
            }

        case .glass:
            // Glass effect handled by glassEffect modifier
            Color.clear

        case .outlined:
            Color.clear
        }
    }

    @ViewBuilder
    private var borderView: some View {
        switch self.style {
        case .solid:
            if !self.isSelected {
                Capsule()
                    .strokeBorder(self.theme.colors.borderSecondary, lineWidth: 1)
            }

        case .tinted:
            Capsule()
                .strokeBorder(
                    self.isSelected ? self.accentColor.opacity(0.3) : self.theme.colors.borderSecondary,
                    lineWidth: 1
                )

        case .glass:
            EmptyView() // Glass effect provides its own border

        case .outlined:
            Capsule()
                .strokeBorder(
                    self.isSelected ? self.accentColor : self.theme.colors.borderSecondary,
                    lineWidth: self.isSelected ? 2 : 1
                )
        }
    }
}

// MARK: - Glass Effect Extension

extension ChipButton {
    /// Apply glass effect for .glass style
    @ViewBuilder
    public func withGlassEffect() -> some View {
        if self.style == .glass {
            #if os(iOS)
                if #available(iOS 26.0, *) {
                    self.glassEffect(
                        .regular.tint(self.isSelected ? self.accentColor : self.theme.colors.surface2),
                        in: Capsule()
                    )
                } else {
                    self
                }
            #elseif os(watchOS)
                if #available(watchOS 26.0, *) {
                    self.glassEffect(
                        .regular.tint(self.isSelected ? self.accentColor : self.theme.colors.surface2),
                        in: Capsule()
                    )
                } else {
                    self
                }
            #else
                self
            #endif
        } else {
            self
        }
    }
}

// MARK: - Convenience Factory Methods

extension ChipButton {
    /// Create a cuisine selection chip with emoji
    public static func cuisine(
        title: String,
        emoji: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> ChipButton {
        ChipButton(
            title: title,
            emoji: emoji,
            isSelected: isSelected,
            style: .tinted,
            size: .medium,
            scaleOnSelect: true,
            action: action
        )
    }

    /// Create a filter chip with optional icon
    public static func filter(
        title: String,
        icon: String? = nil,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> ChipButton {
        if let icon {
            ChipButton(
                title: title,
                icon: icon,
                isSelected: isSelected,
                style: .glass,
                size: .medium,
                action: action
            )
        } else {
            ChipButton(
                title: title,
                contentType: .text,
                isSelected: isSelected,
                style: .glass,
                size: .medium,
                action: action
            )
        }
    }

    /// Create a filter chip with country flag
    public static func countryFilter(
        title: String,
        flag: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> ChipButton {
        ChipButton(
            title: title,
            contentType: .flag(flag),
            isSelected: isSelected,
            style: .glass,
            size: .medium,
            action: action
        )
    }

    /// Create an issue/feedback chip
    public static func issue(
        title: String,
        icon: String? = nil,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> ChipButton {
        if let icon {
            ChipButton(
                title: title,
                icon: icon,
                isSelected: isSelected,
                style: .solid,
                size: .medium,
                action: action
            )
        } else {
            ChipButton(
                title: title,
                contentType: .text,
                isSelected: isSelected,
                style: .solid,
                size: .medium,
                action: action
            )
        }
    }

    /// Create a tag-style chip (small, outlined)
    public static func tag(
        title: String,
        color: Color? = nil,
        isSelected: Bool = false,
        action: @escaping () -> Void = { }
    ) -> ChipButton {
        ChipButton(
            title: title,
            contentType: .text,
            isSelected: isSelected,
            style: .outlined,
            size: .small,
            color: color,
            action: action
        )
    }
}

// MARK: - Preview

#Preview("ChipButton Styles") {
    ScrollView {
        VStack(spacing: 24) {
            Text("ChipButton Styles")
                .font(.title2.bold())

            // Solid Style
            VStack(alignment: .leading, spacing: 8) {
                Text("Solid").font(.headline)
                HStack(spacing: 8) {
                    ChipButton(
                        title: "Selected",
                        icon: "checkmark",
                        isSelected: true,
                        style: .solid
                    ) { }
                    ChipButton(
                        title: "Unselected",
                        icon: "circle",
                        isSelected: false,
                        style: .solid
                    ) { }
                }
            }

            // Tinted Style (for cuisines)
            VStack(alignment: .leading, spacing: 8) {
                Text("Tinted (Cuisine)").font(.headline)
                HStack(spacing: 8) {
                    ChipButton.cuisine(
                        title: "Italian",
                        emoji: "🍝",
                        isSelected: true
                    ) { }
                    ChipButton.cuisine(
                        title: "Japanese",
                        emoji: "🍣",
                        isSelected: false
                    ) { }
                    ChipButton.cuisine(
                        title: "Mexican",
                        emoji: "🌮",
                        isSelected: false
                    ) { }
                }
            }

            // Glass Style (for filters)
            VStack(alignment: .leading, spacing: 8) {
                Text("Glass (Filters)").font(.headline)
                HStack(spacing: 8) {
                    ChipButton.filter(
                        title: "All",
                        isSelected: true
                    ) { }
                        .withGlassEffect()
                    ChipButton.filter(
                        title: "Protein",
                        icon: "leaf.fill",
                        isSelected: false
                    ) { }
                        .withGlassEffect()
                    ChipButton.countryFilter(
                        title: "Italian",
                        flag: "🇮🇹",
                        isSelected: false
                    ) { }
                        .withGlassEffect()
                }
            }

            // Outlined Style (for tags)
            VStack(alignment: .leading, spacing: 8) {
                Text("Outlined (Tags)").font(.headline)
                HStack(spacing: 8) {
                    ChipButton.tag(title: "Breakfast", color: .orange, isSelected: true)
                    ChipButton.tag(title: "Lunch", color: .yellow)
                    ChipButton.tag(title: "Dinner", color: .red)
                }
            }

            // Size Variants
            VStack(alignment: .leading, spacing: 8) {
                Text("Sizes").font(.headline)
                HStack(spacing: 8) {
                    ChipButton(
                        title: "Small",
                        contentType: .text,
                        isSelected: true,
                        style: .solid,
                        size: .small
                    ) { }
                    ChipButton(
                        title: "Medium",
                        contentType: .text,
                        isSelected: true,
                        style: .solid,
                        size: .medium
                    ) { }
                    ChipButton(
                        title: "Large",
                        contentType: .text,
                        isSelected: true,
                        style: .solid,
                        size: .large
                    ) { }
                }
            }

            // Issue Chips (original ChipButton use case)
            VStack(alignment: .leading, spacing: 8) {
                Text("Issue Chips").font(.headline)
                HStack(spacing: 8) {
                    ChipButton.issue(
                        title: "Too long",
                        icon: "clock",
                        isSelected: false
                    ) { }
                    ChipButton.issue(
                        title: "Too easy",
                        icon: "arrow.up.circle",
                        isSelected: true
                    ) { }
                }
            }
        }
        .padding()
    }
    #if os(iOS)
    .background(Color(.systemGroupedBackground))
    #else
    .background(Color.gray.opacity(0.1))
    #endif
    .environment(\.theme, DefaultTheme())
}
