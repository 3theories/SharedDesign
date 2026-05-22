import Kingfisher
import SwiftUI

// MARK: - CachedAsyncImage

/// A cached async image component using Kingfisher for efficient image loading and caching.
/// Use this for displaying remote images with automatic caching, placeholder support, and fade transitions.
public struct CachedAsyncImage<Placeholder: View>: View {
    // MARK: Lifecycle

    /// Creates a cached async image with a custom placeholder.
    /// - Parameters:
    ///   - url: The URL of the image to load. If nil, shows placeholder.
    ///   - contentMode: How the image should be scaled. Defaults to `.fill`.
    ///   - placeholder: A view builder for the placeholder shown while loading or on error.
    public init(
        url: URL?,
        contentMode: SwiftUI.ContentMode = .fill,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.contentMode = contentMode
        self.placeholder = placeholder
    }

    // MARK: Public

    public var body: some View {
        KFImage(self.url)
            .fade(duration: 0.25)
            .placeholder { _ in
                self.placeholder()
            }
            .resizable()
            .aspectRatio(contentMode: self.contentMode)
    }

    // MARK: Private

    private let url: URL?
    private let placeholder: () -> Placeholder
    private let contentMode: SwiftUI.ContentMode
}

// MARK: - Convenience Initializers

extension CachedAsyncImage where Placeholder == AnyView {
    /// Creates a cached async image with a system image placeholder.
    /// - Parameters:
    ///   - url: The URL of the image to load.
    ///   - contentMode: How the image should be scaled. Defaults to `.fill`.
    ///   - placeholderSystemImage: SF Symbol name for placeholder. Defaults to "photo".
    public init(
        url: URL?,
        contentMode: SwiftUI.ContentMode = .fill,
        placeholderSystemImage: String = "photo"
    ) {
        self.url = url
        self.contentMode = contentMode
        self.placeholder = {
            AnyView(
                Image(systemName: placeholderSystemImage)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .foregroundStyle(.secondary)
            )
        }
    }

    /// Creates a cached async image from a URL string.
    /// - Parameters:
    ///   - urlString: The URL string of the image to load.
    ///   - contentMode: How the image should be scaled. Defaults to `.fill`.
    ///   - placeholderSystemImage: SF Symbol name for placeholder. Defaults to "photo".
    public init(
        urlString: String?,
        contentMode: SwiftUI.ContentMode = .fill,
        placeholderSystemImage: String = "photo"
    ) {
        self.init(
            url: urlString.flatMap { URL(string: $0) },
            contentMode: contentMode,
            placeholderSystemImage: placeholderSystemImage
        )
    }
}

// MARK: - CachedPhaseImage

/// A cached async image that supports separate loading and failure views.
/// Uses Kingfisher for disk + memory caching while providing phase-aware rendering
/// similar to `AsyncImage`, unlike `CachedAsyncImage` which shows the same placeholder
/// for both loading and failure states.
public struct CachedPhaseImage<Loading: View, Failure: View>: View {
    // MARK: Lifecycle

    /// Creates a cached phase image with separate loading and failure views.
    /// - Parameters:
    ///   - url: The URL of the image to load. If nil, shows failure view immediately.
    ///   - contentMode: How the image should be scaled. Defaults to `.fill`.
    ///   - loading: A view builder for the loading state (shown while downloading).
    ///   - failure: A view builder for the failure state (shown on error or nil URL).
    public init(
        url: URL?,
        contentMode: SwiftUI.ContentMode = .fill,
        @ViewBuilder loading: @escaping () -> Loading,
        @ViewBuilder failure: @escaping () -> Failure
    ) {
        self.url = url
        self.contentMode = contentMode
        self.loading = loading
        self.failure = failure
    }

    // MARK: Public

    public var body: some View {
        if let url = self.url, !self.didFail {
            KFImage(url)
                .fade(duration: 0.25)
                .onFailure { _ in self.didFail = true }
                .placeholder { _ in
                    self.loading()
                }
                .resizable()
                .aspectRatio(contentMode: self.contentMode)
        } else {
            self.failure()
        }
    }

    // MARK: Private

    @State private var didFail = false

    private let url: URL?
    private let contentMode: SwiftUI.ContentMode
    private let loading: () -> Loading
    private let failure: () -> Failure
}

// MARK: - Preview

#Preview("Cached Async Image") {
    VStack(spacing: 20) {
        // With URL
        CachedAsyncImage(
            url: URL(string: "https://picsum.photos/200"),
            contentMode: .fill,
            placeholderSystemImage: "photo"
        )
        .frame(width: 100, height: 100)
        .clipShape(RoundedRectangle(cornerRadius: 12))

        // Nil URL (shows placeholder)
        CachedAsyncImage(
            url: nil,
            contentMode: .fit,
            placeholderSystemImage: "fork.knife"
        )
        .frame(width: 100, height: 100)
        .background(Color.gray.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .padding()
}
