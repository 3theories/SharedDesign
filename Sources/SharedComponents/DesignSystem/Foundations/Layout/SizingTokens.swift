import SwiftUI

// MARK: - DefaultSizingTokens

/// Default implementation of sizing tokens
public struct DefaultSizingTokens: SizingTokens {
    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public var buttonHeight: SizeScale {
        SizeScale(small: 32, medium: 44, large: 56, xl: 64)
    }

    public var cornerRadius: SizeScale {
        SizeScale(small: 10, medium: 16, large: 20, xl: 24)
    }

    public var iconSize: SizeScale {
        SizeScale(small: 16, medium: 24, large: 32, xl: 48)
    }

    public var borderWidth: SizeScale {
        SizeScale(small: 0.5, medium: 1, large: 2, xl: 3)
    }
}

// MARK: - ComponentSizing

/// Component-specific sizing configurations
public enum ComponentSizing {
    /// Button sizes
    public enum Button: CGFloat, CaseIterable {
        case minWidth = 64
        case minHeight = 32
        case iconButtonSize = 44
        case floatingActionButtonSize = 56
    }

    /// Card height presets
    public enum CardHeight: CGFloat, CaseIterable {
        case min = 80
        case standard = 120
        case expanded = 200
        case large = 240
        case hero = 300
    }

    /// Avatar sizes
    public enum Avatar: CGFloat, CaseIterable {
        case tiny = 24
        case small = 32
        case medium = 40
        case large = 56
        case xl = 80
        case xxl = 120
    }

    /// Badge sizes
    public enum Badge: CGFloat, CaseIterable {
        case small = 16
        case medium = 20
        case large = 24
    }

    /// Progress indicator sizes
    public enum Progress: CGFloat, CaseIterable {
        case small = 20
        case medium = 40
        case large = 60
        case strokeWidth = 3
    }

    /// Input field heights
    public enum InputHeight: CGFloat, CaseIterable {
        case min = 44
        case standard = 48
        case multiline = 80
    }

    /// Navigation heights
    public enum Navigation: CGFloat, CaseIterable {
        case bar = 44
        case tabBar = 49
        case toolbar = 46 // Changed from 44 to avoid duplicate with bar
    }

    /// Divider widths
    public enum Divider: CGFloat, CaseIterable {
        case hairline = 0.5
        case thin = 1
        case medium = 2
        case thick = 4
    }
}

// MARK: - ResponsiveSizing

/// Responsive sizing utilities
public enum ResponsiveSizing {
    /// Size classes for adaptive layouts
    public enum SizeClass {
        case compact
        case regular
        case large

        // MARK: Public

        /// Get appropriate size based on size class
        public func size(compact: CGFloat, regular: CGFloat, large: CGFloat) -> CGFloat {
            switch self {
            case .compact: compact
            case .regular: regular
            case .large: large
            }
        }
    }

    /// Common breakpoints
    public enum Breakpoints {
        public static let phone: CGFloat = 390
        public static let tablet: CGFloat = 768
        public static let desktop: CGFloat = 1024
        public static let widescreen: CGFloat = 1440
    }
}
