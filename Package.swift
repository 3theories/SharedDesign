// swift-tools-version: 5.9
import PackageDescription

// SharedDesign — domain-agnostic design system + generic UI
// components shared across our apps. Color tokens (light + dark),
// typography (Instrument Sans + Manrope), spacing / sizing /
// shadows / elevations / gradients, plus polished primitives
// like `Card`, `EmptyStateView`, `LoadingView`, `FilterChipView`,
// `SharedBadge`, `SharedButton`, charts, gallery section.
//
// The repo USED to also vend a `SharedComponents` product
// containing Niora-specific Sync / AppIntents / Widget /
// LiveActivity / Recipe / SessionMesh-coupled services. Those
// surfaces have been moved into Niora's own local
// `iOS/SharedComponents` package so cross-app consumers (Avyra
// and friends) don't pull SessionMesh, watch connectivity, or
// any other domain-coupled dependency along with the design
// tokens.
let package = Package(
    name: "SharedDesign",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "SharedDesign",
            targets: ["SharedDesign"]
        ),
    ],
    dependencies: [
        // Kingfisher backs the image-loading UI primitives
        // (`AsyncBrandedImageView`, the gallery section). No
        // other third-party deps — keeping the design system's
        // surface narrow is what lets every app in the family
        // depend on it without worrying about pulled-in
        // transitives.
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "8.0.0"),
    ],
    targets: [
        .target(
            name: "SharedDesign",
            dependencies: [
                .product(name: "Kingfisher", package: "Kingfisher"),
            ],
            // SPM convention is `path: nil` (defaults to
            // `Sources/<target name>`), which matches our layout
            // now that the source directory was renamed from
            // `Sources/SharedComponents` → `Sources/SharedDesign`.
            // Explicit anyway so future readers see the convention.
            path: "Sources/SharedDesign",
            resources: [
                .process("Resources/Fonts"),
                .process("Resources/Localizable.xcstrings"),
                .process("Resources/ConfettiAssets.xcassets"),
            ]
        ),
    ]
)
