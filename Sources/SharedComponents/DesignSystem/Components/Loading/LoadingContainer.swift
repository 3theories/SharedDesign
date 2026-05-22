import SwiftUI

// MARK: - LoadingContainer

/// Container that manages loading states with skeleton and overlay support
public struct LoadingContainer<Content: View, Skeleton: View>: View {
    // MARK: Lifecycle

    public init(
        state: LoadingState,
        content: @escaping () -> Content,
        skeleton: @escaping () -> Skeleton
    ) {
        self.state = state
        self.content = content
        self.skeleton = skeleton
    }

    // MARK: Public

    public var body: some View {
        switch self.state {
        case .initial:
            self.skeleton()
        case .refreshing:
            self.content()
                .loadingOverlay(
                    isLoading: true,
                    message: "Refreshing..."
                )
        case .ready, .loadingMore:
            self.content()
        }
    }

    // MARK: Internal

    let state: LoadingState
    let content: () -> Content
    let skeleton: () -> Skeleton
}

// MARK: - LoadingState

public enum LoadingState: Equatable {
    case initial
    case refreshing
    case ready
    case loadingMore
}
