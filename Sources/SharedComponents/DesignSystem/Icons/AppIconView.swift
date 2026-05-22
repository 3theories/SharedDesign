import SwiftUI

// MARK: - AppIconView

/// A view that renders either an SF Symbol or a custom asset icon.
/// Use this when you need to display icons that could be either type.
///
/// Usage:
/// ```swift
/// AppIconView(name: sportType.icon, isSystemIcon: sportType.isSystemIcon)
///     .frame(width: 20, height: 20)
///     .foregroundColor(.blue)
/// ```
public struct AppIconView: View {
    // MARK: Lifecycle

    public init(name: String, isSystemIcon: Bool) {
        self.name = name
        self.isSystemIcon = isSystemIcon
    }

    /// Convenience init for custom icons from the AppIcon catalog.
    /// Automatically sets `isSystemIcon` to `false`.
    public init(icon: AppIcon) {
        self.name = icon.rawValue
        self.isSystemIcon = false
    }

    // MARK: Public

    public var body: some View {
        if self.isSystemIcon {
            Image(systemName: self.name)
                .accessibilityHidden(true)
        } else {
            Image(self.name)
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .accessibilityHidden(true)
        }
    }

    // MARK: Private

    private let name: String
    private let isSystemIcon: Bool
}
