// MARK: - SharedDesign re-export

// Legacy `import SharedComponents` in Niora needs to keep seeing
// DesignSystem + Components/{Buttons, Display, Media, States}
// types. Those moved into the `SharedDesign` target (so Avyra can
// depend on the design system without pulling SessionMesh /
// Sync / Niora-specific Widget + AppIntents code).
//
// `@_exported import` re-publishes SharedDesign's public surface
// through `SharedComponents`, so call sites don't need to add a
// second import. When Niora gets refactored to import SharedDesign
// directly everywhere, this file can be deleted and the SharedComponents
// target loses its `Compatibility/` source dir from `exclude:`.
@_exported import SharedDesign
