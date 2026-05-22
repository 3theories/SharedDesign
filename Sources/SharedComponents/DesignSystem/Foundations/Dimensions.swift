import SwiftUI

// MARK: - BlurLevel

// Note: ElevationLevel is defined in ElevationTokens.swift

/// Blur radius levels
public enum BlurLevel: CGFloat {
    case none = 0
    case subtle = 2
    case light = 4
    case medium = 8
    case heavy = 16
    case extreme = 32

    // MARK: Public

    /// Material blur effects
    public static let ultraThin: CGFloat = 2
    public static let thin: CGFloat = 4
    public static let regular: CGFloat = 8
    public static let thick: CGFloat = 16
    public static let ultraThick: CGFloat = 32
}

// MARK: - ContentSize

/// Content size categories
public enum ContentSize {
    case extraSmall
    case small
    case medium
    case large
    case extraLarge

    // MARK: Public

    /// Get multiplier for dynamic sizing
    public var multiplier: CGFloat {
        switch self {
        case .extraSmall: 0.8
        case .small: 0.9
        case .medium: 1.0
        case .large: 1.1
        case .extraLarge: 1.2
        }
    }
}

// MARK: - CornerRadiusScale

/// Extended corner radius options
public struct CornerRadiusScale {
    public enum ComponentType {
        case button
        case card
        case input
        case chip
        case modal
        case toast
    }

    public let none: CGFloat = 0
    public let small: CGFloat = 4
    public let medium: CGFloat = 8
    public let large: CGFloat = 12
    public let xl: CGFloat = 16
    public let xxl: CGFloat = 20
    public let pill: CGFloat = 9999

    /// Get corner radius for a specific component
    public func radius(for component: ComponentType) -> CGFloat {
        switch component {
        case .button: self.medium
        case .card: self.large
        case .input: self.medium
        case .chip: self.pill
        case .modal: self.xl
        case .toast: self.large
        }
    }
}

// MARK: - LayoutDensity

/// Layout density options
public enum LayoutDensity {
    case compact
    case comfortable
    case spacious

    // MARK: Public

    public var spacingMultiplier: CGFloat {
        switch self {
        case .compact: 0.75
        case .comfortable: 1.0
        case .spacious: 1.5
        }
    }

    public var componentSizeMultiplier: CGFloat {
        switch self {
        case .compact: 0.85
        case .comfortable: 1.0
        case .spacious: 1.15
        }
    }
}

// MARK: - ComponentSize

/// Component size options
public enum ComponentSize: CaseIterable {
    case mini
    case small
    case medium
    case large
    case jumbo

    // MARK: Public

    /// Height for interactive components
    public var height: CGFloat {
        switch self {
        case .mini: 24
        case .small: 32
        case .medium: 40
        case .large: 48
        case .jumbo: 56
        }
    }

    /// Padding for components
    public var padding: CGFloat {
        switch self {
        case .mini: 4
        case .small: 8
        case .medium: 12
        case .large: 16
        case .jumbo: 20
        }
    }

    /// Font size multiplier
    public var fontScale: CGFloat {
        switch self {
        case .mini: 0.75
        case .small: 0.875
        case .medium: 1.0
        case .large: 1.125
        case .jumbo: 1.25
        }
    }
}

// MARK: - IconSizeScale

/// Icon size scale
public struct IconSizeScale {
    public let mini: CGFloat = 12
    public let small: CGFloat = 16
    public let medium: CGFloat = 20
    public let large: CGFloat = 24
    public let xl: CGFloat = 32
    public let xxl: CGFloat = 48
    public let jumbo: CGFloat = 64

    /// Get icon size for component size
    public func size(for componentSize: ComponentSize) -> CGFloat {
        switch componentSize {
        case .mini: self.mini
        case .small: self.small
        case .medium: self.medium
        case .large: self.large
        case .jumbo: self.xl
        }
    }
}

// MARK: - LineHeight

/// Line height scale
public enum LineHeight: CGFloat {
    case tight = 1.2
    case normal = 1.5
    case relaxed = 1.75
    case loose = 2.0
}

// MARK: - View Extensions

extension View {
    // Note: elevation(_:) is defined in ElevationTokens.swift

    /// Apply blur effect
    public func blur(_ level: BlurLevel) -> some View {
        self.blur(radius: level.rawValue)
    }

    /// Apply adaptive corner radius
    public func adaptiveCornerRadius(_ radius: CGFloat, density: LayoutDensity = .comfortable) -> some View {
        self.cornerRadius(radius * density.componentSizeMultiplier)
    }
}

// MARK: - LayoutDensityKey

private struct LayoutDensityKey: EnvironmentKey {
    static let defaultValue: LayoutDensity = .comfortable
}

extension EnvironmentValues {
    public var layoutDensity: LayoutDensity {
        get { self[LayoutDensityKey.self] }
        set { self[LayoutDensityKey.self] = newValue }
    }
}
