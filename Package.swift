// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SharedComponents",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        .macOS(.v14)
    ],
    products: [
        // Domain-agnostic design system + generic UI components.
        // Cross-app surface — Avyra depends on this directly.
        // Niora's existing `import SharedComponents` keeps working
        // because the legacy target re-exports SharedDesign via
        // `@_exported import` (see Compatibility/Re-export.swift).
        .library(
            name: "SharedDesign",
            targets: ["SharedDesign"]
        ),
        // Full SharedComponents surface — adds Niora-specific
        // Sync / AppIntents / Widget / LiveActivity / Recipe
        // composition on top of SharedDesign. Niora uses this.
        .library(
            name: "SharedComponents",
            targets: ["SharedComponents"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "8.0.0"),
        // SessionMesh is a separately-released package — the
        // remote version pin keeps this package
        // tag-consumable. Apps that only link the
        // `SharedDesign` product don't transitively pick up
        // SessionMesh anyway; the dependency is here for the
        // Niora-only `SharedComponents` target below.
        .package(url: "git@github.com:3theories/SessionMesh.git", from: "1.0.0")
    ],
    targets: [
        // Design system + domain-agnostic components only.
        // Disjoint source list from `SharedComponents` — SPM
        // requires non-overlapping `sources:` when two targets
        // share a path.
        .target(
            name: "SharedDesign",
            dependencies: [
                .product(name: "Kingfisher", package: "Kingfisher")
            ],
            path: "Sources/SharedComponents",
            exclude: [
                "Sync",
                "AppIntents",
                "Widget",
                "LiveActivity",
                "Components/Recipe",
                "Models",
                "Compatibility",
                // SessionMesh-coupled services stay in Niora's
                // target. Localization (`L10n`) is the only
                // generic piece of Services and rides along
                // because design components reference it.
                "Services/ConnectivityManager.swift",
                "Services/IncomingMessageBus.swift",
                "Services/WatchSyncManager.swift"
            ],
            resources: [
                .process("Resources/Fonts"),
                .process("Resources/Localizable.xcstrings"),
                .process("Resources/ConfettiAssets.xcassets")
            ]
        ),
        // Niora-only additions. Sources are the inverse of
        // SharedDesign's exclude list. `Compatibility/` holds
        // the `@_exported import SharedDesign` re-export so
        // legacy `import SharedComponents` callers in Niora still
        // see DesignSystem / Components types.
        .target(
            name: "SharedComponents",
            dependencies: [
                "SharedDesign",
                .product(name: "Kingfisher", package: "Kingfisher"),
                .product(name: "SessionMesh", package: "SessionMesh"),
                .product(name: "SessionMeshWatchConnectivity", package: "SessionMesh")
            ],
            path: "Sources/SharedComponents",
            exclude: [
                "DesignSystem",
                "Components/Buttons",
                "Components/Display",
                "Components/Media",
                "Components/States",
                "Services/Localization",
                "Resources"
            ]
        )
    ]
)
