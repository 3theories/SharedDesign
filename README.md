# SharedDesign

Cross-app iOS / watchOS / macOS design system. Color palettes (light + dark), typography (Instrument Sans + Manrope), spacing / sizing / shadow / elevation / gradient tokens, plus polished SwiftUI component primitives. Domain-agnostic — no business logic, no SessionMesh, no app-specific surfaces.

> Renamed from `SharedComponents` to `SharedDesign` to avoid SPM package-identity collision with downstream apps' own local `SharedComponents` packages, and to make the scope obvious to consumers: this is the design layer, nothing more.

## What's in here

```
Sources/SharedComponents/
├── DesignSystem/         Theme protocol + Light/Dark color palettes,
│                         typography, spacing, sizing, shadows,
│                         elevations, gradients, animations.
├── Components/           Generic SwiftUI primitives that compose
│   ├── Buttons/          on the design tokens above:
│   ├── Display/             • Card, EmptyStateView, ErrorStateView,
│   ├── Media/                 LoadingView, FilterChipView, SharedBadge
│   └── States/              • Image / media wrappers (Kingfisher-backed)
├── Services/
│   └── Localization/     L10n helper for cross-app strings.
└── Resources/
    ├── Fonts/            Instrument Sans + Manrope (.ttf).
    ├── Localizable.xcstrings
    └── ConfettiAssets.xcassets
```

What's deliberately **not** here (lives in the consuming app's own package):

- Domain models (workout, nutrition, fasting types)
- Sync adapters / SessionMesh-coupled services
- AppIntents (Siri shortcuts) — those carry app identity
- Widget data providers
- LiveActivity attributes
- Recipe-specific UI
- Anything that knows what app you're shipping

## Products

```
.library(name: "SharedDesign", targets: ["SharedDesign"])
```

One product. One target. Zero third-party deps beyond Kingfisher.

## Usage

Add as a Swift Package dependency in Xcode:

```
git@github.com:3theories/SharedDesign.git
```

Or in `Package.swift`:

```swift
.package(url: "git@github.com:3theories/SharedDesign.git", branch: "main"),
```

Then in your target:

```swift
.product(name: "SharedDesign", package: "SharedDesign"),
```

Pin to a tagged release in production — `branch: main` only for active co-development. Tags follow semver; the major bumps when palette / typography token shape changes break callers.

## Consuming apps

| App | How it consumes | Notes |
|---|---|---|
| **Niora** | Via `iOS/SharedComponents/` local package which depends on this repo for `SharedDesign` and re-exports it for legacy `import SharedComponents` callers (see `Compatibility/SharedDesignReExport.swift`). | Niora-specific Sync / AppIntents / Widget / LiveActivity / Recipe surfaces live in the local package, not here. |
| **Avyra** | Direct dependency in `Apps/AvyraApp/Avyra.xcodeproj`. | Avyra imports `SharedDesign` directly. |

## Color palettes

Two palettes ship by default:

- **`LightColorPalette`** — Niora's warm vital orange + sage green + lavender accents.
- **`DarkColorPalette`** — corresponding dark-mode tokens with elevated surface tinting.

Apps that want their own brand palette implement `ColorTokens` and forward neutrals via composition (see `AvyraLightPalette` / `AvyraDarkPalette` in the Avyra app for the canonical example).

## Theming

`Theme` is the umbrella protocol bundling `colors`, `typography`, `spacing`, `sizing`, `shadows`, `elevations`, `animations`, and `gradients`. Apps inject one at the root:

```swift
AvyraThemeHost {
    rootView
}
.theme(AvyraTheme(colorScheme: colorScheme))
```

Screens read tokens via the environment:

```swift
struct MyScreen: View {
    @Environment(\.theme) private var theme

    var body: some View {
        Text("Hello")
            .font(theme.typography.title2)
            .foregroundStyle(theme.colors.textPrimary)
            .padding(theme.spacing.md)
    }
}
```

`@Environment(\.colorScheme)` flips the active palette automatically when the system or a `.preferredColorScheme(...)` modifier changes appearance. The `AvyraThemeHost`-style wrapper pattern is the recommended way to host the theme at the app root so SwiftUI re-evaluates the body on appearance changes.

## Versioning

Semver:

- **Major** — breaking API in design tokens (color enum rename, typography ramp restructure, spacing scale changes).
- **Minor** — additive (new component primitive, new palette, new gradient preset).
- **Patch** — bug fixes (typo in token name, wrong contrast value).

`branch: main` is acceptable during a refactor; production consumers should pin to a tag.

## Migration from `SharedComponents`

The repo was previously named `SharedComponents` and shipped two products:

- `SharedDesign` — what's now this whole repo
- `SharedComponents` — Niora-specific add-ons that pulled SessionMesh as a transitive dep

The `SharedComponents` product carried Niora-specific surfaces — Sync adapters, AppIntents, Widget plumbing, LiveActivity attributes, Recipe UI, and three SessionMesh-coupled services. Cross-app consumers that only ever linked `SharedDesign` still paid the SessionMesh resolution cost because SPM flattens package-level dependencies regardless of which product is consumed. That broke CI for consumers without an SSH key for the private SessionMesh repo.

**The fix:** move the Niora-specific surfaces into Niora's own `iOS/SharedComponents` local package (where they can pull SessionMesh as a local concern), strip them from this repo, and rename it to `SharedDesign` to match the slimmed scope.

Consumers that pinned an old tag (1.x) continue to work against that historical content. Consumers that want the slimmed-down repo:

1. Update the repo URL: `git@github.com:3theories/SharedComponents.git` → `git@github.com:3theories/SharedDesign.git` (GitHub redirects from the old URL for a transitional period, but explicit is better).
2. Update the product link from `SharedComponents` → `SharedDesign`.
3. Bump to a `2.x` tag (or `branch: main`).

## License

Internal.
