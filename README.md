# SharedDesign

A SwiftUI design system for iOS, watchOS, and macOS apps. Ships a complete set of design tokens (color, typography, spacing, sizing, shadow, elevation, gradient, animation) and polished SwiftUI component primitives built on top of them. Domain-agnostic — no business logic, no app-specific surfaces, no networking.

## Highlights

- **Two ready-made color palettes** (`LightColorPalette`, `DarkColorPalette`) plus the `ColorTokens` protocol for brand-specific palettes.
- **Two typography families** bundled as resources — Instrument Sans (display) + Manrope (body) — wired to a typography ramp (`largeTitle`, `title1`–`title3`, `body`, `caption`, …).
- **Theme protocol** that bundles every token category behind one environment value: `@Environment(\.theme) var theme`.
- **Component primitives** built on tokens — cards, buttons, charts, filter chips, loading states, error states, toasts, search headers, gallery sections, network banners.
- **Effects & accessibility helpers** — shimmer, glow, scaled font helpers, Dynamic Type hooks.
- **Kingfisher-backed media wrappers** for remote images.
- Localizable string catalog (`Localizable.xcstrings`) and a confetti `.xcassets` for celebratory states.

## Requirements

- Swift 6.0+
- iOS 17 / watchOS 10 / macOS 14 or later
- Xcode 15+

## Installation

Add as a Swift Package dependency in Xcode (`File ▸ Add Package Dependencies…`):

```
https://github.com/3theories/SharedDesign.git
```

Or declare it in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/3theories/SharedDesign.git", branch: "main"),
],
targets: [
    .target(
        name: "MyApp",
        dependencies: [
            .product(name: "SharedDesign", package: "SharedDesign"),
        ]
    ),
]
```

Pin to a tagged release in production; `branch: main` is for active co-development.

## Quick start

### 1. Host the theme at your app root

```swift
import SwiftUI
import SharedDesign

@main
struct MyApp: App {
    @Environment(\.colorScheme) private var colorScheme

    var body: some Scene {
        WindowGroup {
            RootView()
                .theme(DefaultTheme(colorScheme: colorScheme))
        }
    }
}
```

### 2. Read tokens via the environment

```swift
struct WelcomeCard: View {
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text("Welcome back")
                .font(theme.typography.title2)
                .foregroundStyle(theme.colors.textPrimary)

            Text("Pick up where you left off.")
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.textSecondary)
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface1, in: RoundedRectangle(cornerRadius: theme.sizing.cornerRadiusM))
        .shadow(theme.shadows.elevation2)
    }
}
```

`@Environment(\.colorScheme)` flips the active palette automatically when the system appearance or a `.preferredColorScheme(...)` modifier changes.

## Layout

```
Sources/SharedDesign/
├── DesignSystem/
│   ├── Core/                Theme protocol, environment keys,
│   │                        bundle helpers.
│   ├── Foundations/         Tokens:
│   │   ├── Colors/             ColorPalette, LightColorPalette,
│   │   │                       DarkColorPalette, Gradients,
│   │   │                       SemanticColors.
│   │   ├── Typography/         FontTokens, TextStyles.
│   │   ├── Effects/            Shadows, elevations, blurs.
│   │   ├── Layout/             Spacing, sizing, breakpoints.
│   │   └── Dimensions.swift    Standard sizes.
│   ├── Components/          Token-driven primitives:
│   │   ├── Buttons/            PrimaryButton, SecondaryButton, …
│   │   ├── Cards/              Card containers + variants.
│   │   ├── Charts/             Trend/comparison/sparkline.
│   │   ├── Display/            EmptyStateView, …
│   │   ├── Forms/              Inputs, pickers.
│   │   ├── Loading/            LoadingView, shimmer placeholders.
│   │   ├── States/             Error, empty, loading state views.
│   │   ├── ViewModifiers/      Reusable modifiers.
│   │   ├── Activity/           Activity / stat tiles.
│   │   ├── FilterChipView      Filter chip + group.
│   │   ├── ErrorStateView      Inline error UI.
│   │   ├── GallerySection      Horizontal gallery wrapper.
│   │   ├── GridCell            Square grid item.
│   │   ├── NetworkStatusBanner Online/offline banner.
│   │   ├── SearchResultsHeader Result count + sort.
│   │   └── Toast               Toast / snackbar.
│   ├── Effects/             Shimmer, glow, gradients in motion.
│   ├── Extensions/          Color / View / Font helpers.
│   ├── Icons/               SF Symbol mappings, custom icons.
│   ├── Accessibility/       Dynamic Type, contrast helpers.
│   ├── ColorPaletteDemo     Built-in palette demo View.
│   └── ThemePreview         Built-in token gallery View.
├── Components/              Higher-level composites layered on
│   │                        the design system primitives:
│   ├── Buttons/                e.g. icon + label combos.
│   ├── Display/                Headers, badges, status pills.
│   ├── Media/                  Kingfisher-backed remote images.
│   └── States/                 Skeleton / shimmer composites.
├── Services/
│   └── Localization/        L10n string lookups.
└── Resources/
    ├── Fonts/               Instrument Sans + Manrope (.ttf).
    ├── Localizable.xcstrings
    └── ConfettiAssets.xcassets
```

## Theming model

`Theme` is an umbrella protocol bundling every token category:

```swift
public protocol Theme: Sendable {
    var colors:      any ColorTokens      { get }
    var typography:  any TypographyTokens { get }
    var spacing:     any SpacingTokens    { get }
    var sizing:      any SizingTokens     { get }
    var shadows:     any ShadowTokens     { get }
    var elevations:  any ElevationTokens  { get }
    var animations:  any AnimationTokens  { get }
    var gradients:   any GradientTokens   { get }
}
```

Custom themes implement the underlying token protocols (most apps only override `ColorTokens` for brand) and forward the rest to the defaults. Inject via the `.theme(_:)` modifier; consume via `@Environment(\.theme)`.

### Brand palettes

Two palettes ship by default:

- **`LightColorPalette`** — warm vital orange + sage green + lavender accents, tuned for light mode.
- **`DarkColorPalette`** — the dark-mode counterpart with elevated surface tinting.

Apps wanting their own brand palette implement `ColorTokens` and forward neutrals via composition. The default light/dark palettes are exposed so app-specific palettes can delegate to them for shared neutrals.

## Components

Components consume tokens via `@Environment(\.theme)` — never hard-code colors, fonts, or spacing inside a component. Examples shipping in this package:

| Category | Components |
|---|---|
| **States** | `EmptyStateView`, `ErrorStateView`, `LoadingView`, `NetworkStatusBanner` |
| **Cards** | `Card` + variants |
| **Buttons** | Primary / secondary / tertiary / destructive styles |
| **Filters** | `FilterChipView` + filter groups |
| **Charts** | Trend, comparison, sparkline |
| **Forms** | Token-styled text fields, pickers |
| **Media** | Kingfisher-backed `RemoteImage`, gallery sections |
| **Feedback** | `Toast`, confetti overlay |
| **Effects** | Shimmer placeholders, glow modifiers |

Each component is a SwiftUI `View` — no controllers, no reducers, no state management beyond what the view itself owns.

## Dependencies

| Dependency | Used for |
|---|---|
| [Kingfisher](https://github.com/onevcat/Kingfisher) | Remote image fetching + caching in `Media/` wrappers. |

That's the entire third-party surface. The rest is Foundation + SwiftUI.

## Versioning

Semver:

- **Major** — breaking API in design tokens (color enum rename, typography ramp restructure, spacing scale changes).
- **Minor** — additive (new component primitive, new palette, new gradient preset).
- **Patch** — bug fixes (typo in token name, wrong contrast value, accessibility correction).

Pin to a tag in production. `branch: main` is acceptable during active co-development.

## Contributing

The package is consumed by a few iOS apps; design tokens evolve cautiously. When adding tokens or components:

- Don't bake brand-specific values into shared types — drive them through `ColorTokens` / `TypographyTokens`.
- Don't introduce business logic or domain models. The line is: if it only knows about pixels and the SwiftUI tree, it belongs here; if it knows what app it's shipping in, it doesn't.
- Don't add a third-party dependency without a clear justification — the dep graph is deliberately small.

## License

MIT — see [LICENSE](LICENSE).
