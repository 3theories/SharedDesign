import Foundation

// MARK: - SharedDesignBundle

/// Public accessor for the resource bundle that ships with the
/// `SharedDesign` SPM target. Code outside `SharedDesign` (the
/// Niora-only `SharedComponents` target, downstream apps that
/// depend on SharedDesign) can't synthesize `Bundle.module` —
/// SPM only generates that accessor inside the target it
/// belongs to. This wrapper exposes the same bundle through a
/// stable public name.
public enum SharedDesignBundle {
    /// The `Bundle` that contains SharedDesign's Localizable
    /// strings, fonts, and confetti assets. Use as
    /// `bundle: SharedDesignBundle.bundle` in place of
    /// `bundle: .module` from outside the target.
    public static let bundle: Bundle = .module
}
