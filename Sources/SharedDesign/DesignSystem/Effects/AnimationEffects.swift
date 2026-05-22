import SwiftUI

// MARK: - AnimationEffects

/// Common animation effects and utilities
public enum AnimationEffects {
    /// Pulse animation for drawing attention
    public struct PulseEffect: ViewModifier {
        // MARK: Lifecycle

        public init(
            isAnimating: Bool = true,
            minScale: CGFloat = 0.95,
            maxScale: CGFloat = 1.05
        ) {
            self.isAnimating = isAnimating
            self.minScale = minScale
            self.maxScale = maxScale
        }

        public func body(content: Content) -> some View {
            content
                .scaleEffect(self.scale)
                .opacity(self.opacity)
                .onAppear {
                    if self.isAnimating {
                        withAnimation(
                            AnimationConstants.Easing.smooth
                                .repeatForever(autoreverses: true)
                        ) {
                            self.scale = self.maxScale
                            self.opacity = 0.8
                        }
                    }
                }
                .onChange(of: self.isAnimating) { _, newValue in
                    if newValue {
                        withAnimation(
                            AnimationConstants.Easing.smooth
                                .repeatForever(autoreverses: true)
                        ) {
                            self.scale = self.maxScale
                            self.opacity = 0.8
                        }
                    } else {
                        withAnimation(AnimationConstants.Easing.quickOut) {
                            self.scale = 1.0
                            self.opacity = 1.0
                        }
                    }
                }
        }

        // MARK: Internal

        let isAnimating: Bool
        let minScale: CGFloat
        let maxScale: CGFloat

        // MARK: Private

        @State private var scale: CGFloat = 1.0
        @State private var opacity: Double = 1.0
    }

    /// Bounce animation for interactive elements
    public struct BounceEffect: ViewModifier {
        @State private var scale: CGFloat = 1.0

        let trigger: Bool

        public func body(content: Content) -> some View {
            content
                .scaleEffect(self.scale)
                .onChange(of: self.trigger) { _, _ in
                    withAnimation(AnimationConstants.Spring.stiff) {
                        self.scale = 1.1
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + AnimationConstants.Duration.instant) {
                        withAnimation(AnimationConstants.Spring.stiff) {
                            self.scale = 1.0
                        }
                    }
                }
        }
    }

    /// Shake animation for errors or attention
    public struct ShakeEffect: ViewModifier {
        // MARK: Lifecycle

        public init(trigger: Bool, amplitude: CGFloat = 10) {
            self.trigger = trigger
            self.amplitude = amplitude
        }

        public func body(content: Content) -> some View {
            content
                .offset(x: self.offset, y: 0)
                .onChange(of: self.trigger) { _, _ in
                    withAnimation(
                        Animation.linear(duration: AnimationConstants.Duration.instant / 3)
                            .repeatCount(5, autoreverses: true)
                    ) {
                        self.offset = self.amplitude
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + AnimationConstants.Duration.quick) {
                        self.offset = 0
                    }
                }
        }

        // MARK: Internal

        let trigger: Bool
        let amplitude: CGFloat

        // MARK: Private

        @State private var offset: CGFloat = 0
    }

    /// Slide and fade transition
    public struct SlideAndFade: ViewModifier {
        // MARK: Lifecycle

        public init(isVisible: Bool, from edge: Edge = .bottom) {
            self.isVisible = isVisible
            self.edge = edge
        }

        public func body(content: Content) -> some View {
            content
                .offset(self.isVisible ? .zero : self.offset)
                .opacity(self.isVisible ? 1 : 0)
                .animation(AnimationConstants.Easing.quickOut, value: self.isVisible)
        }

        // MARK: Internal

        let isVisible: Bool
        let edge: Edge

        // MARK: Private

        private var offset: CGSize {
            switch self.edge {
            case .top: CGSize(width: 0, height: -AnimationConstants.Offset.medium)
            case .bottom: CGSize(width: 0, height: AnimationConstants.Offset.medium)
            case .leading: CGSize(width: -AnimationConstants.Offset.medium, height: 0)
            case .trailing: CGSize(width: AnimationConstants.Offset.medium, height: 0)
            }
        }
    }

}

// MARK: - ScaleOnTapModifier

/// Scale on tap modifier with haptic feedback
public struct ScaleOnTapModifier: ViewModifier {
    // MARK: Lifecycle

    public init(
        scale: CGFloat = AnimationConstants.Scale.cardPress,
        hapticStyle: HapticStyle = .light
    ) {
        self.scale = scale
        self.hapticStyle = hapticStyle
    }

    public func body(content: Content) -> some View {
        content
            .scaleEffect(self.isPressed ? self.scale : 1.0)
            .animation(AnimationConstants.Spring.stiff, value: self.isPressed)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) {
                // Long press completed
            } onPressingChanged: { pressing in
                if pressing {
                    HapticManager.shared.trigger(self.hapticStyle)
                }
                self.isPressed = pressing
            }
    }

    // MARK: Internal

    let scale: CGFloat
    let hapticStyle: HapticStyle

    // MARK: Private

    @State private var isPressed = false
}

// MARK: - StaggeredAppearModifier

/// Staggered appearance modifier for list items
public struct StaggeredAppearModifier: ViewModifier {
    // MARK: Lifecycle

    public func body(content: Content) -> some View {
        content
            .opacity(self.hasAppeared ? 1 : 0)
            .offset(y: self.hasAppeared ? 0 : AnimationConstants.Offset.medium)
            .onAppear {
                withAnimation(
                    AnimationConstants.Spring.smooth
                        .delay(AnimationConstants.staggerDelay(index: self.index, total: self.total))
                ) {
                    self.hasAppeared = true
                }
            }
    }

    // MARK: Internal

    let index: Int
    let total: Int

    // MARK: Private

    @State private var hasAppeared = false
}

// MARK: - CelebrationCompletionModifier

/// Celebration completion animation
public struct CelebrationCompletionModifier: ViewModifier {
    // MARK: Lifecycle

    public func body(content: Content) -> some View {
        content
            .scaleEffect(self.scale)
            .rotationEffect(.degrees(self.rotation))
            .opacity(self.opacity)
            .onChange(of: self.trigger) { _, newValue in
                if newValue {
                    // Success haptic
                    HapticManager.shared.trigger(.success)

                    // Animate celebration
                    withAnimation(AnimationConstants.Spring.bouncy) {
                        self.scale = 1.2
                        self.rotation = 15
                    }

                    withAnimation(AnimationConstants.Spring.bouncy.delay(0.1)) {
                        self.scale = 1.0
                        self.rotation = 0
                    }
                }
            }
    }

    // MARK: Internal

    let trigger: Bool

    // MARK: Private

    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1.0
}

// MARK: - RubberBandScrollModifier

/// Rubber band scroll effect
public struct RubberBandScrollModifier: ViewModifier {
    // MARK: Lifecycle

    public func body(content: Content) -> some View {
        content
            .offset(y: self.offset + self.dragOffset.height * 0.3)
            .gesture(
                DragGesture()
                    .updating(self.$dragOffset) { value, state, _ in
                        state = value.translation
                    }
                    .onEnded { _ in
                        withAnimation(AnimationConstants.Spring.rubberBand) {
                            self.offset = 0
                        }
                    }
            )
    }

    // MARK: Private

    @GestureState private var dragOffset: CGSize = .zero
    @State private var offset: CGFloat = 0
}

// MARK: - HeroTransitionModifier

/// Hero transition helper
public struct HeroTransitionModifier: ViewModifier {
    // MARK: Lifecycle

    public func body(content: Content) -> some View {
        content
            .matchedGeometryEffect(
                id: self.id,
                in: self.namespace,
                properties: .frame,
                anchor: .center,
                isSource: self.isSource
            )
    }

    // MARK: Internal

    let id: String
    let namespace: Namespace.ID
    let isSource: Bool
}

// MARK: - FloatingAnimationModifier

/// Creates a gentle floating animation effect
public struct FloatingAnimationModifier: ViewModifier {
    // MARK: Lifecycle

    public init(delay: Double = 0) {
        self.delay = delay
    }

    public func body(content: Content) -> some View {
        content
            .offset(y: self.isFloating ? -3 : 3)
            .animation(
                Animation.easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
                    .delay(self.delay),
                value: self.isFloating
            )
            .onAppear {
                self.isFloating = true
            }
    }

    // MARK: Internal

    let delay: Double

    // MARK: Private

    @State private var isFloating = false
}

// MARK: - View Extensions

extension View {
    /// Apply pulse animation
    public func pulse(
        isAnimating: Bool = true,
        minScale: CGFloat = 0.95,
        maxScale: CGFloat = 1.05
    ) -> some View {
        modifier(AnimationEffects.PulseEffect(
            isAnimating: isAnimating,
            minScale: minScale,
            maxScale: maxScale
        ))
    }

    /// Apply bounce animation
    public func bounce(trigger: Bool) -> some View {
        modifier(AnimationEffects.BounceEffect(trigger: trigger))
    }

    /// Apply shake animation
    public func shake(trigger: Bool, amplitude: CGFloat = 10) -> some View {
        modifier(AnimationEffects.ShakeEffect(
            trigger: trigger,
            amplitude: amplitude
        ))
    }

    /// Apply slide and fade transition
    public func slideAndFade(isVisible: Bool, from edge: Edge = .bottom) -> some View {
        modifier(AnimationEffects.SlideAndFade(
            isVisible: isVisible,
            from: edge
        ))
    }

    /// Apply scale on tap with haptic feedback
    public func scaleOnTap(
        scale: CGFloat = AnimationConstants.Scale.cardPress,
        hapticStyle: HapticStyle = .light
    ) -> some View {
        modifier(ScaleOnTapModifier(scale: scale, hapticStyle: hapticStyle))
    }

    /// Apply staggered appearance for list items
    public func staggeredAppear(index: Int, total: Int) -> some View {
        modifier(StaggeredAppearModifier(index: index, total: total))
    }

    /// Apply celebration animation on completion
    public func celebrateCompletion(_ trigger: Bool) -> some View {
        modifier(CelebrationCompletionModifier(trigger: trigger))
    }

    /// Apply rubber band scroll effect
    public func rubberBandScroll() -> some View {
        modifier(RubberBandScrollModifier())
    }

    /// Apply animated number transition
    /// Note: Use this modifier on Text views that display numbers
    /// You need to provide the value parameter for the animation to work
    public func animatedNumber(value: some Equatable) -> some View {
        self
            .contentTransition(.numericText())
            .animation(AnimationConstants.Presets.numberCounter, value: value)
    }

    /// Apply hero transition
    public func heroTransition(id: String, in namespace: Namespace.ID, isSource: Bool = true) -> some View {
        modifier(HeroTransitionModifier(id: id, namespace: namespace, isSource: isSource))
    }

    /// Apply progress ring animation effect
    /// - Parameters:
    ///   - progress: The progress value from 0 to 1
    ///   - lineWidth: The width of the progress ring
    ///   - tint: The color of the progress ring
    /// - Returns: A view with animated progress ring overlay
    public func progressRing(
        progress: Double,
        lineWidth: CGFloat = 3,
        tint: Color = .accentColor
    ) -> some View {
        modifier(ProgressRingModifier(
            progress: progress,
            lineWidth: lineWidth,
            tint: tint
        ))
    }

    /// Apply floating animation effect
    /// - Parameter delay: Delay before starting the animation
    /// - Returns: A view with gentle floating animation
    public func floatingAnimation(delay: Double = 0) -> some View {
        modifier(FloatingAnimationModifier(delay: delay))
    }
}

// MARK: - ProgressRingModifier

/// Progress ring animation modifier
public struct ProgressRingModifier: ViewModifier {
    // MARK: Lifecycle

    public init(
        progress: Double,
        lineWidth: CGFloat = 3,
        tint: Color = .accentColor
    ) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.tint = tint
    }

    public func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .trim(from: 0, to: self.animatedProgress)
                    .stroke(
                        self.tint,
                        style: StrokeStyle(
                            lineWidth: self.lineWidth,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(AnimationConstants.Presets.progressFill, value: self.animatedProgress)
            )
            .onAppear {
                self.animatedProgress = self.progress
            }
            .onChange(of: self.progress) { _, newValue in
                self.animatedProgress = newValue
            }
    }

    // MARK: Internal

    let progress: Double
    let lineWidth: CGFloat
    let tint: Color

    // MARK: Private

    @State private var animatedProgress: Double = 0
}

// MARK: - Transition Extensions

extension AnyTransition {
    /// Scale and fade transition
    public static var scaleAndFade: AnyTransition {
        AnyTransition.scale.combined(with: .opacity)
    }

    /// Slide from edge with fade
    public static func slideFromEdge(_ edge: Edge) -> AnyTransition {
        let insertion = AnyTransition.move(edge: edge).combined(with: .opacity)
        let removal = AnyTransition.move(edge: edge).combined(with: .opacity)
        return .asymmetric(insertion: insertion, removal: removal)
    }

    /// Blur transition
    public static var blur: AnyTransition {
        .modifier(
            active: BlurModifier(radius: 10),
            identity: BlurModifier(radius: 0)
        )
    }
}

// MARK: - BlurModifier

private struct BlurModifier: ViewModifier {
    // MARK: Lifecycle

    func body(content: Content) -> some View {
        content
            .blur(radius: self.radius)
    }

    // MARK: Internal

    let radius: CGFloat
}

// MARK: - Previews

#if DEBUG
    import SwiftUI

    struct AnimationEffects_Previews: PreviewProvider {
        struct PreviewContent: View {
            // MARK: Internal

            var body: some View {
                ScrollView {
                    VStack(spacing: 40) {
                        Text("Animation Effects Preview")
                            .font(.title2.bold())
                            .padding()

                        // Pulse Animation
                        VStack(spacing: 16) {
                            Text("Pulse Effect")
                                .font(.headline)

                            Button("Toggle Pulse") {
                                self.showPulse.toggle()
                            }
                            .pulse(isAnimating: self.showPulse)
                            .padding()
                            .background(.blue.opacity(0.1))
                            .cornerRadius(8)
                        }

                        // Shake Animation
                        VStack(spacing: 16) {
                            Text("Shake Effect")
                                .font(.headline)

                            Button("Trigger Shake") {
                                self.showShake.toggle()
                            }
                            .shake(trigger: self.showShake)
                            .padding()
                            .background(.red.opacity(0.1))
                            .cornerRadius(8)
                        }

                        // Bounce Animation
                        VStack(spacing: 16) {
                            Text("Bounce Effect")
                                .font(.headline)

                            Button("Trigger Bounce") {
                                self.showBounce.toggle()
                            }
                            .bounce(trigger: self.showBounce)
                            .padding()
                            .background(.green.opacity(0.1))
                            .cornerRadius(8)
                        }

                        // Shimmer Animation
                        VStack(spacing: 16) {
                            Text("Shimmer Effect")
                                .font(.headline)

                            RoundedRectangle(cornerRadius: 8)
                                .fill(.gray.opacity(0.3))
                                .frame(height: 60)
                                .shimmer(isLoading: self.showShimmer)
                                .onTapGesture {
                                    self.showShimmer.toggle()
                                }
                        }

                        // Pulse Variation (Float)
                        VStack(spacing: 16) {
                            Text("Pulse Effect (Small)")
                                .font(.headline)

                            Circle()
                                .fill(.purple.opacity(0.6))
                                .frame(width: 60, height: 60)
                                .pulse(isAnimating: self.showFloat)
                                .onTapGesture {
                                    self.showFloat.toggle()
                                }
                        }

                        // Pulse Variation (Breathe)
                        VStack(spacing: 16) {
                            Text("Pulse Effect (Large)")
                                .font(.headline)

                            Circle()
                                .fill(.mint.opacity(0.6))
                                .frame(width: 80, height: 80)
                                .pulse(isAnimating: self.showBreathe, minScale: 0.8, maxScale: 1.2)
                                .onTapGesture {
                                    self.showBreathe.toggle()
                                }
                        }

                        // Animated Number
                        VStack(spacing: 16) {
                            Text("Animated Number")
                                .font(.headline)

                            Text(verbatim: "\(self.animatedNumber)")
                                .font(.title.monospacedDigit())
                                .animatedNumber(value: self.animatedNumber)

                            Button("Increment") {
                                self.animatedNumber += 1
                            }
                            .padding()
                            .background(.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                }
            }

            // MARK: Private

            @State private var showPulse = false
            @State private var showShake = false
            @State private var showBounce = false
            @State private var showShimmer = false
            @State private var showFloat = false
            @State private var showBreathe = false
            @State private var animatedNumber = 0
        }

        static var previews: some View {
            PreviewContent()
                .preferredColorScheme(.light)

            PreviewContent()
                .preferredColorScheme(.dark)
        }
    }
#endif
