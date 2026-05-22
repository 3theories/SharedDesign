import SwiftUI

// MARK: - DefaultAnimationTokens

/// Default implementation of animation tokens
public struct DefaultAnimationTokens: AnimationTokens {
    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public var spring: Animation {
        .spring(response: 0.3, dampingFraction: 0.7)
    }

    public var smooth: Animation {
        .easeInOut(duration: 0.3)
    }

    public var quick: Animation {
        .easeOut(duration: 0.2)
    }

    public var bounce: Animation {
        .spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0)
    }

    public var easeIn: Animation {
        .easeIn(duration: 0.25)
    }

    public var easeOut: Animation {
        .easeOut(duration: 0.25)
    }
}

// MARK: - AnimationPresets

/// Extended animation configurations
public enum AnimationPresets {
    /// Micro interactions (100-200ms)
    public enum Micro {
        public static let tap = Animation.easeOut(duration: 0.1)
        public static let hover = Animation.easeOut(duration: 0.15)
        public static let press = Animation.easeIn(duration: 0.1)
    }

    /// Standard transitions (200-400ms)
    public enum Standard {
        public static let fade = Animation.easeInOut(duration: 0.25)
        public static let slide = Animation.easeOut(duration: 0.3)
        public static let scale = Animation.spring(response: 0.3, dampingFraction: 0.7)
        public static let rotation = Animation.easeInOut(duration: 0.3)
    }

    /// Emphasized animations (400-600ms)
    public enum Emphasized {
        public static let entrance = Animation.spring(response: 0.4, dampingFraction: 0.8)
        public static let exit = Animation.easeIn(duration: 0.4)
        public static let morph = Animation.easeInOut(duration: 0.5)
    }

    /// Hero animations (600ms+)
    public enum Hero {
        public static let pageTransition = Animation.easeInOut(duration: 0.6)
        public static let reveal = Animation.spring(response: 0.6, dampingFraction: 0.8)
        public static let parallax = Animation.easeOut(duration: 0.8)
    }

    /// Physics-based animations
    public enum Physics {
        public static let bounce = Animation.spring(response: 0.3, dampingFraction: 0.6)
        public static let elastic = Animation.spring(response: 0.4, dampingFraction: 0.5)
        public static let gravity = Animation.timingCurve(0.5, 0, 1, 1, duration: 0.5)
    }

    /// Interactive animations
    public enum Interactive {
        public static let drag = Animation.interactiveSpring()
        public static let gesture = Animation.spring(response: 0.15, dampingFraction: 0.86)
        public static let rubberBand = Animation.spring(response: 0.3, dampingFraction: 0.5)
    }
}

// MARK: - TimingFunctions

/// Animation timing functions
public enum TimingFunctions {
    /// Ease curves
    public static let easeInSine = Animation.timingCurve(0.47, 0, 0.745, 0.715, duration: 0.3)
    public static let easeOutSine = Animation.timingCurve(0.39, 0.575, 0.565, 1, duration: 0.3)
    public static let easeInOutSine = Animation.timingCurve(0.445, 0.05, 0.55, 0.95, duration: 0.3)

    public static let easeInQuad = Animation.timingCurve(0.55, 0.085, 0.68, 0.53, duration: 0.3)
    public static let easeOutQuad = Animation.timingCurve(0.25, 0.46, 0.45, 0.94, duration: 0.3)
    public static let easeInOutQuad = Animation.timingCurve(0.455, 0.03, 0.515, 0.955, duration: 0.3)

    public static let easeInCubic = Animation.timingCurve(0.55, 0.055, 0.675, 0.19, duration: 0.3)
    public static let easeOutCubic = Animation.timingCurve(0.215, 0.61, 0.355, 1, duration: 0.3)
    public static let easeInOutCubic = Animation.timingCurve(0.645, 0.045, 0.355, 1, duration: 0.3)

    /// Material Design curves
    public static let materialStandard = Animation.timingCurve(0.4, 0, 0.2, 1, duration: 0.3)
    public static let materialDeceleration = Animation.timingCurve(0, 0, 0.2, 1, duration: 0.3)
    public static let materialAcceleration = Animation.timingCurve(0.4, 0, 1, 1, duration: 0.3)
}

// MARK: - AnimationProgress

/// Animation progress tracker for SwiftUI
@Observable
public final class AnimationProgress {
    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public var value: Double = 0
    public var isComplete: Bool = false

    /// Trigger animation progress from 0 to 1
    @MainActor
    public func animate(with animation: Animation = .linear) {
        self.value = 0
        self.isComplete = false

        withAnimation(animation) {
            self.value = 1
        }
    }

    /// Reset to initial state
    @MainActor
    public func reset() {
        self.value = 0
        self.isComplete = false
    }
}

// MARK: - AnimationCompletionModifier

/// Animation completion using animatable progress
public struct AnimationCompletionModifier: ViewModifier {
    // MARK: Lifecycle

    public func body(content: Content) -> some View {
        content
            .onChange(of: self.trigger) { _, newValue in
                if newValue && !self.isTracking {
                    self.isTracking = true
                    self.animationProgress = 0

                    withAnimation(self.animation) {
                        self.animationProgress = 1.0
                    }
                }
            }
            .modifier(AnimationCompletionTracker(
                progress: self.animationProgress,
                isTracking: self.isTracking
            ) {
                self.isTracking = false
                self.onComplete()
            })
    }

    // MARK: Internal

    let trigger: Bool
    let animation: Animation
    let onComplete: () -> Void

    // MARK: Private

    @State private var animationProgress: Double = 0
    @State private var isTracking = false
}

// MARK: - AnimationCompletionTracker

/// Internal modifier to track animation completion via AnimatableData
private struct AnimationCompletionTracker: AnimatableModifier {
    // MARK: Lifecycle

    func body(content: Content) -> some View {
        content
    }

    // MARK: Internal

    var progress: Double
    let isTracking: Bool
    let onComplete: () -> Void

    var animatableData: Double {
        get { self.progress }
        set {
            self.progress = newValue
            if self.isTracking && self.progress >= 0.99 {
                self.onComplete()
            }
        }
    }
}

// MARK: - AnimationPhase

/// Simple animation phases
public enum AnimationPhase: CaseIterable {
    case initial
    case active
    case complete

    // MARK: Public

    public var next: AnimationPhase {
        switch self {
        case .initial: .active
        case .active: .complete
        case .complete: .initial
        }
    }
}

// MARK: - PhaseAnimationView

/// Phase-based animation helper
public struct PhaseAnimationView<Content: View>: View {
    // MARK: Lifecycle

    public init(
        animation: Animation = .default,
        @ViewBuilder content: @escaping (AnimationPhase) -> Content
    ) {
        self.animation = animation
        self.content = content
    }

    // MARK: Public

    public var body: some View {
        self.content(self.currentPhase)
            .onTapGesture {
                withAnimation(self.animation) {
                    self.currentPhase = self.currentPhase.next
                }
            }
    }

    // MARK: Internal

    let content: (AnimationPhase) -> Content
    let animation: Animation

    // MARK: Private

    @State private var currentPhase: AnimationPhase = .initial
}

// MARK: - AnimatableProgress

/// Animation value tracking using AnimatableData
public struct AnimatableProgress: Animatable {
    // MARK: Lifecycle

    public init(_ value: Double = 0) {
        self.value = value
    }

    // MARK: Public

    public var value: Double

    public var animatableData: Double {
        get { self.value }
        set { self.value = newValue }
    }
}

// MARK: - ProgressAnimationModifier

/// Progress animation modifier using AnimatableModifier
public struct ProgressAnimationModifier: AnimatableModifier {
    // MARK: Lifecycle

    public func body(content: Content) -> some View {
        content
    }

    // MARK: Public

    public var animatableData: Double {
        get { self.progress }
        set {
            self.progress = newValue
            self.onProgressChange(self.progress)
        }
    }

    // MARK: Internal

    var progress: Double
    let onProgressChange: (Double) -> Void
}

extension View {
    /// Track animation completion
    public func onAnimationComplete(
        trigger: Bool,
        animation: Animation = .default,
        onComplete: @escaping () -> Void
    ) -> some View {
        modifier(AnimationCompletionModifier(
            trigger: trigger,
            animation: animation,
            onComplete: onComplete
        ))
    }

    /// Track animation progress changes
    public func animationProgress(
        _ progress: Double,
        onProgressChange: @escaping (Double) -> Void
    ) -> some View {
        modifier(ProgressAnimationModifier(
            progress: progress,
            onProgressChange: onProgressChange
        ))
    }

    /// Apply phase-based animation
    public func phaseAnimation(
        animation: Animation = .default,
        @ViewBuilder content: @escaping (AnimationPhase) -> some View
    ) -> some View {
        PhaseAnimationView(animation: animation, content: content)
    }
}
