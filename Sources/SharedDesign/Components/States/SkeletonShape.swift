import SwiftUI

// MARK: - SkeletonShapeType

/// Shape types for skeleton placeholders
public enum SkeletonShapeType: Sendable {
    /// Rectangular shape with rounded corners
    case rect

    /// Circular shape
    case circle

    /// Capsule/pill shape
    case capsule

    /// Text line placeholder
    case textLine
}

// MARK: - SkeletonSizePreset

/// Predefined size presets for skeleton shapes
public enum SkeletonSizePreset: Sendable {
    /// Small icon/avatar (24x24)
    case iconSmall

    /// Medium icon/avatar (32x32)
    case iconMedium

    /// Large icon/avatar (48x48)
    case iconLarge

    /// Extra large avatar (64x64)
    case avatarLarge

    /// Title text line
    case titleText

    /// Body text line
    case bodyText

    /// Caption text line
    case captionText

    /// Small button
    case buttonSmall

    /// Medium button
    case buttonMedium

    /// Large button
    case buttonLarge

    /// Custom size
    case custom(width: CGFloat?, height: CGFloat)

    // MARK: Internal

    var height: CGFloat {
        switch self {
        case .iconSmall: 24
        case .iconMedium: 32
        case .iconLarge: 48
        case .avatarLarge: 64
        case .titleText: 20
        case .bodyText: 16
        case .captionText: 12
        case .buttonSmall: 32
        case .buttonMedium: 44
        case .buttonLarge: 56
        case let .custom(_, height): height
        }
    }

    var width: CGFloat? {
        switch self {
        case .iconSmall: 24
        case .iconMedium: 32
        case .iconLarge: 48
        case .avatarLarge: 64
        case .titleText: nil // Flexible
        case .bodyText: nil // Flexible
        case .captionText: nil // Flexible
        case .buttonSmall: nil // Flexible
        case .buttonMedium: nil // Flexible
        case .buttonLarge: nil // Flexible
        case let .custom(width, _): width
        }
    }
}

// MARK: - SkeletonShape

/// A flexible skeleton placeholder shape with automatic shimmer effect.
/// Building block for creating consistent loading states.
public struct SkeletonShape: View {
    // MARK: Lifecycle

    public init(
        _ shapeType: SkeletonShapeType = .rect,
        size: SkeletonSizePreset = .bodyText,
        widthFraction: CGFloat? = nil,
        cornerRadius: CGFloat? = nil
    ) {
        self.shapeType = shapeType
        self.size = size
        self.widthFraction = widthFraction
        self.cornerRadius = cornerRadius
    }

    // MARK: Public

    public var body: some View {
        GeometryReader { geometry in
            let width: CGFloat = {
                if let fixedWidth = size.width {
                    return fixedWidth
                }
                if let fraction = widthFraction {
                    return geometry.size.width * fraction
                }
                return geometry.size.width
            }()

            RoundedRectangle(cornerRadius: self.effectiveCornerRadius)
                .fill(self.theme.colors.surface3)
                .frame(width: width, height: self.size.height)
                .shimmer()
        }
        .frame(height: self.size.height)
        .frame(maxWidth: self.size.width ?? .infinity)
    }

    // MARK: Internal

    let shapeType: SkeletonShapeType
    let size: SkeletonSizePreset
    let widthFraction: CGFloat?
    let cornerRadius: CGFloat?

    // MARK: Private

    @Environment(\.theme) private var theme

    private var effectiveCornerRadius: CGFloat {
        if let cornerRadius {
            return cornerRadius
        }

        switch self.shapeType {
        case .rect:
            return self.theme.sizing.cornerRadius.small
        case .circle:
            return self.size.height / 2
        case .capsule:
            return self.size.height / 2
        case .textLine:
            return 4
        }
    }
}

// MARK: - Convenience Builders

extension SkeletonShape {
    /// Create a text line skeleton
    public static func textLine(
        height: CGFloat = 16,
        widthFraction: CGFloat = 1.0
    ) -> SkeletonShape {
        SkeletonShape(
            .textLine,
            size: .custom(width: nil, height: height),
            widthFraction: widthFraction
        )
    }

    /// Create a title text skeleton
    public static func title(widthFraction: CGFloat = 0.7) -> SkeletonShape {
        SkeletonShape(.textLine, size: .titleText, widthFraction: widthFraction)
    }

    /// Create a body text skeleton
    public static func body(widthFraction: CGFloat = 1.0) -> SkeletonShape {
        SkeletonShape(.textLine, size: .bodyText, widthFraction: widthFraction)
    }

    /// Create a caption text skeleton
    public static func caption(widthFraction: CGFloat = 0.5) -> SkeletonShape {
        SkeletonShape(.textLine, size: .captionText, widthFraction: widthFraction)
    }

    /// Create a circular avatar skeleton
    public static func avatar(size: CGFloat = 48) -> SkeletonShape {
        SkeletonShape(.circle, size: .custom(width: size, height: size))
    }

    /// Create an icon skeleton
    public static func icon(size: CGFloat = 24) -> SkeletonShape {
        SkeletonShape(.rect, size: .custom(width: size, height: size), cornerRadius: 6)
    }

    /// Create a card skeleton
    public static func card(height: CGFloat = 120) -> SkeletonShape {
        SkeletonShape(.rect, size: .custom(width: nil, height: height))
    }

    /// Create a button skeleton
    public static func button(height: CGFloat = 44) -> SkeletonShape {
        SkeletonShape(.capsule, size: .custom(width: nil, height: height))
    }

    /// Create a chip/tag skeleton
    public static func chip(width: CGFloat = 80, height: CGFloat = 32) -> SkeletonShape {
        SkeletonShape(.capsule, size: .custom(width: width, height: height))
    }

    /// Create an image placeholder skeleton
    public static func image(height: CGFloat = 200, cornerRadius: CGFloat = 12) -> SkeletonShape {
        SkeletonShape(.rect, size: .custom(width: nil, height: height), cornerRadius: cornerRadius)
    }
}

// MARK: - SkeletonTextBlock

/// Multiple lines of skeleton text
public struct SkeletonTextBlock: View {
    // MARK: Lifecycle

    public init(
        lineCount: Int = 3,
        lineHeight: CGFloat = 14,
        spacing: CGFloat = 8,
        lastLineFraction: CGFloat = 0.6
    ) {
        self.lineCount = max(1, lineCount)
        self.lineHeight = lineHeight
        self.spacing = spacing
        self.lastLineFraction = lastLineFraction
    }

    // MARK: Public

    public var body: some View {
        VStack(alignment: .leading, spacing: self.spacing) {
            ForEach(0..<self.lineCount, id: \.self) { index in
                let isLast = index == self.lineCount - 1
                SkeletonShape.textLine(
                    height: self.lineHeight,
                    widthFraction: isLast ? self.lastLineFraction : 1.0
                )
            }
        }
    }

    // MARK: Internal

    let lineCount: Int
    let lineHeight: CGFloat
    let spacing: CGFloat
    let lastLineFraction: CGFloat

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - SkeletonRow

/// A skeleton row with optional leading icon and text lines
public struct SkeletonRow: View {
    // MARK: Lifecycle

    public init(
        showLeadingIcon: Bool = true,
        iconSize: CGFloat = 44,
        lineCount: Int = 2,
        showTrailing: Bool = false
    ) {
        self.showLeadingIcon = showLeadingIcon
        self.iconSize = iconSize
        self.lineCount = lineCount
        self.showTrailing = showTrailing
    }

    // MARK: Public

    public var body: some View {
        HStack(spacing: self.theme.spacing.md) {
            if self.showLeadingIcon {
                SkeletonShape(.rect, size: .custom(width: self.iconSize, height: self.iconSize))
            }

            VStack(alignment: .leading, spacing: self.theme.spacing.xs) {
                SkeletonShape.textLine(height: 16, widthFraction: 0.7)

                if self.lineCount > 1 {
                    SkeletonShape.textLine(height: 14, widthFraction: 0.5)
                }

                if self.lineCount > 2 {
                    SkeletonShape.textLine(height: 12, widthFraction: 0.3)
                }
            }

            if self.showTrailing {
                Spacer()
                SkeletonShape.icon(size: 20)
            }
        }
    }

    // MARK: Internal

    let showLeadingIcon: Bool
    let iconSize: CGFloat
    let lineCount: Int
    let showTrailing: Bool

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - SkeletonMetric

/// A skeleton for metric display (icon + value + label)
public struct SkeletonMetric: View {
    // MARK: Lifecycle

    public init(
        showIcon: Bool = true,
        showProgress: Bool = false
    ) {
        self.showIcon = showIcon
        self.showProgress = showProgress
    }

    // MARK: Public

    public var body: some View {
        VStack(alignment: .leading, spacing: self.theme.spacing.sm) {
            HStack(spacing: self.theme.spacing.sm) {
                if self.showIcon {
                    SkeletonShape(.circle, size: .iconMedium)
                }
                SkeletonShape.caption(widthFraction: 0.4)
                Spacer()
            }

            SkeletonShape.title(widthFraction: 0.5)

            if self.showProgress {
                SkeletonShape.textLine(height: 4, widthFraction: 1.0)
            }
        }
        .padding(self.theme.spacing.md)
        .background(self.theme.colors.surface1)
        .clipShape(RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.medium))
    }

    // MARK: Internal

    let showIcon: Bool
    let showProgress: Bool

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - Preview

#Preview("SkeletonShape Components") {
    ScrollView {
        VStack(spacing: 24) {
            Text("SkeletonShape Building Blocks")
                .font(.title2.bold())

            // Text Lines
            VStack(alignment: .leading, spacing: 8) {
                Text("Text Lines").font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    SkeletonShape.title()
                    SkeletonShape.body()
                    SkeletonShape.caption()
                }
            }

            Divider()

            // Icons & Avatars
            VStack(alignment: .leading, spacing: 8) {
                Text("Icons & Avatars").font(.headline)
                HStack(spacing: 16) {
                    SkeletonShape.icon(size: 24)
                    SkeletonShape.icon(size: 32)
                    SkeletonShape.avatar(size: 48)
                    SkeletonShape.avatar(size: 64)
                }
            }

            Divider()

            // Chips & Buttons
            VStack(alignment: .leading, spacing: 8) {
                Text("Chips & Buttons").font(.headline)
                HStack(spacing: 8) {
                    SkeletonShape.chip()
                    SkeletonShape.chip()
                    SkeletonShape.chip(width: 60)
                }
                SkeletonShape.button()
            }

            Divider()

            // Text Block
            VStack(alignment: .leading, spacing: 8) {
                Text("Text Block").font(.headline)
                SkeletonTextBlock(lineCount: 3)
            }

            Divider()

            // Rows
            VStack(alignment: .leading, spacing: 8) {
                Text("Rows").font(.headline)
                VStack(spacing: 12) {
                    SkeletonRow()
                    SkeletonRow(showLeadingIcon: false, lineCount: 3)
                    SkeletonRow(iconSize: 60, showTrailing: true)
                }
            }

            Divider()

            // Metrics
            VStack(alignment: .leading, spacing: 8) {
                Text("Metrics").font(.headline)
                HStack(spacing: 12) {
                    SkeletonMetric()
                    SkeletonMetric(showProgress: true)
                }
            }

            Divider()

            // Cards
            VStack(alignment: .leading, spacing: 8) {
                Text("Cards").font(.headline)
                SkeletonShape.card(height: 150)
                SkeletonShape.image(height: 200)
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
