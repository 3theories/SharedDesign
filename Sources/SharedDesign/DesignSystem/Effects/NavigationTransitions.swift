import SwiftUI

// MARK: - Transition Presets

extension AnyTransition {
    /// Slide and scale transition
    public static var slideAndScale: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .scale(scale: 1.1).combined(with: .opacity)
        )
    }

    /// Push transition (slide from trailing)
    public static var push: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .move(edge: .trailing),
            removal: .move(edge: .leading)
        )
    }

    /// Cover transition (slide from bottom with scale)
    public static var cover: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .scale(scale: 0.95)),
            removal: .move(edge: .bottom).combined(with: .scale(scale: 1.05))
        )
    }

    /// Reveal transition (opposite of cover)
    public static var reveal: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .move(edge: .top).combined(with: .scale(scale: 1.05)),
            removal: .move(edge: .top).combined(with: .scale(scale: 0.95))
        )
    }

    /// Zoom fade transition
    public static var zoomFade: AnyTransition {
        AnyTransition.scale(scale: 0.5).combined(with: .opacity)
    }
}
