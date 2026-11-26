import SwiftUI

/// Builds the spinner `SharedButton` shows while loading, given the button's style and foreground tint.
public typealias SharedButtonLoaderBuilder = @MainActor @Sendable (_ style: SharedButton.Style, _ tint: Color) -> AnyView

private struct SharedButtonLoaderKey: EnvironmentKey {
    static let defaultValue: SharedButtonLoaderBuilder? = nil
}

extension EnvironmentValues {
    /// When set, `SharedButton` draws this loader instead of the built-in `LoadingView`.
    public var sharedButtonLoader: SharedButtonLoaderBuilder? {
        get { self[SharedButtonLoaderKey.self] }
        set { self[SharedButtonLoaderKey.self] = newValue }
    }
}

extension View {
    /// Supplies the app's own loader for every `SharedButton` below this view.
    public func sharedButtonLoader(_ builder: @escaping SharedButtonLoaderBuilder) -> some View {
        environment(\.sharedButtonLoader, builder)
    }
}
