import SwiftUI

// MARK: - SpacingScale

/// Semantic spacing scale using T-shirt sizing
public enum SpacingScale: CaseIterable {
    case none // 0
    case xxs // 4
    case xs // 8
    case sm // 12
    case md // 16
    case lg // 24
    case xl // 32
    case xxl // 48
    case xxxl // 64

    // MARK: Public

    /// The raw spacing value
    public var value: CGFloat {
        switch self {
        case .none: 0
        case .xxs: 4
        case .xs: 8
        case .sm: 12
        case .md: 16
        case .lg: 24
        case .xl: 32
        case .xxl: 48
        case .xxxl: 64
        }
    }

    /// Semantic name for the spacing
    public var name: String {
        switch self {
        case .none: "None"
        case .xxs: "Extra Extra Small"
        case .xs: "Extra Small"
        case .sm: "Small"
        case .md: "Medium"
        case .lg: "Large"
        case .xl: "Extra Large"
        case .xxl: "Extra Extra Large"
        case .xxxl: "Extra Extra Extra Large"
        }
    }

    /// Common use cases for this spacing
    public var useCase: String {
        switch self {
        case .none: "No spacing"
        case .xxs: "Minimal spacing for tight layouts"
        case .xs: "Small spacing between related elements"
        case .sm: "Compact spacing for grouped items"
        case .md: "Standard spacing (default padding)"
        case .lg: "Large spacing between sections"
        case .xl: "Extra large spacing for major sections"
        case .xxl: "Huge spacing for prominent separation"
        case .xxxl: "Maximum spacing for hero sections"
        }
    }
}

/// Convenience extensions for using spacing scale
extension View {
    /// Apply padding using spacing scale
    public func padding(_ scale: SpacingScale) -> some View {
        self.padding(scale.value)
    }

    /// Apply padding to specific edges using spacing scale
    public func padding(_ edges: Edge.Set, _ scale: SpacingScale) -> some View {
        self.padding(edges, scale.value)
    }

    /// Apply horizontal padding using spacing scale
    public func paddingHorizontal(_ scale: SpacingScale) -> some View {
        self.padding(.horizontal, scale.value)
    }

    /// Apply vertical padding using spacing scale
    public func paddingVertical(_ scale: SpacingScale) -> some View {
        self.padding(.vertical, scale.value)
    }
}

/// Convenience extensions for stacks
extension VStack {
    /// Create a VStack with spacing scale
    public init(alignment: HorizontalAlignment = .center, spacing: SpacingScale, @ViewBuilder content: () -> Content)
        where Content: View {
        self.init(alignment: alignment, spacing: spacing.value, content: content)
    }
}

extension HStack {
    /// Create an HStack with spacing scale
    public init(alignment: VerticalAlignment = .center, spacing: SpacingScale, @ViewBuilder content: () -> Content)
        where Content: View {
        self.init(alignment: alignment, spacing: spacing.value, content: content)
    }
}

extension LazyVStack {
    /// Create a LazyVStack with spacing scale
    public init(
        alignment: HorizontalAlignment = .center,
        spacing: SpacingScale,
        pinnedViews: PinnedScrollableViews = .init(),
        @ViewBuilder content: () -> Content
    ) where Content: View {
        self.init(alignment: alignment, spacing: spacing.value, pinnedViews: pinnedViews, content: content)
    }
}

extension LazyHStack {
    /// Create a LazyHStack with spacing scale
    public init(
        alignment: VerticalAlignment = .center,
        spacing: SpacingScale,
        pinnedViews: PinnedScrollableViews = .init(),
        @ViewBuilder content: () -> Content
    ) where Content: View {
        self.init(alignment: alignment, spacing: spacing.value, pinnedViews: pinnedViews, content: content)
    }
}
