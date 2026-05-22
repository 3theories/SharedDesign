import SwiftUI

// MARK: - View Extensions

extension View {
    /// Hides decorative elements from VoiceOver
    public func accessibilityDecorative() -> some View {
        self.accessibilityHidden(true)
    }

    /// Marks as section header for VoiceOver navigation
    public func accessibleSectionHeader(_ label: String) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isHeader)
    }
}
