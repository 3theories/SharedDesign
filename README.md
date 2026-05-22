# SharedComponents

Reusable iOS / watchOS UI design system shared across our apps (Niora, Avyra).
Extracted from the Niora monorepo so multiple apps can consume the same tokens
+ components without coupling to Niora's domain code.

## Products

* **`SharedDesign`** — cross-app design system. Color palettes (light + dark),
  typography (Instrument Sans + Manrope), spacing / sizing tokens, gradients,
  shadows, elevations, animations, plus polished component primitives
  (`Card`, `EmptyStateView`, `ErrorStateView`, `LoadingView`, `FilterChipView`,
  `SharedBadge`, `SharedButton`, charts, gallery section, etc). **No
  domain-specific dependencies.**

* **`SharedComponents`** — Niora-only extras built on top of `SharedDesign`.
  Sync helpers, AppIntents, Widget / LiveActivity bridges, Recipe-domain UI,
  SessionMesh-coupled connectivity services. **Niora consumes this; other
  apps should depend on `SharedDesign` only.**

A re-export shim (`Compatibility/SharedDesignReExport.swift`) inside
`SharedComponents` does `@_exported import SharedDesign` so any code that
imported the legacy combined target still compiles.

## Consuming the package

Add as a Swift Package dependency in Xcode:

```
https://github.com/3theories/SharedComponents.git
```

Pin to the appropriate version tag. Apps that don't need the Niora-only
extras should only link `SharedDesign`.

## Versioning

Semver. Breaking API changes bump the major; additive / non-breaking
changes bump minor.

## License

Internal.
