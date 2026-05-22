import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif

// MARK: - AnimationConstants

/// Central animation constants and configurations for consistent animation behavior
public enum AnimationConstants {
    // MARK: - Duration Constants

    /// Standard animation durations for consistent timing across the app
    public enum Duration {
        /// Immediate feedback (150ms) - for instant user feedback
        public static let instant: Double = 0.15

        /// Quick transitions (300ms) - for small UI changes
        public static let quick: Double = 0.3

        /// Smooth transitions (500ms) - standard animation duration
        public static let smooth: Double = 0.5

        /// Gentle movements (600ms) - for larger transitions
        public static let gentle: Double = 0.6

        /// Celebration moments (800ms) - for success states
        public static let celebration: Double = 0.8

        /// Maximum sequence duration (1200ms) - upper limit for chained animations
        public static let maxSequence: Double = 1.2
    }

    // MARK: - Spring Configurations

    /// Pre-configured spring animations for consistent physics
    public enum Spring {
        /// Quick spring (300ms response, 0.8 damping) - snappy interactions
        public static let quick = Animation.spring(response: 0.3, dampingFraction: 0.8)

        /// Smooth spring (500ms response, 0.8 damping) - standard spring
        public static let smooth = Animation.spring(response: 0.5, dampingFraction: 0.8)

        /// Gentle spring (600ms response, 0.9 damping) - subtle movements
        public static let gentle = Animation.spring(response: 0.6, dampingFraction: 0.9)

        /// Bouncy spring (400ms response, 0.6 damping) - playful bounce
        public static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)

        /// Rubber band effect (400ms response, 0.5 damping) - elastic feel
        public static let rubberBand = Animation.spring(response: 0.4, dampingFraction: 0.5)

        /// Stiff spring (200ms response, 0.85 damping) - minimal oscillation
        public static let stiff = Animation.spring(response: 0.2, dampingFraction: 0.85)

        /// Soft spring (700ms response, 0.7 damping) - slow and smooth
        public static let soft = Animation.spring(response: 0.7, dampingFraction: 0.7)
    }

    // MARK: - Scale Values

    /// Standard scale values for press states and interactions
    public enum Scale {
        /// Card press scale (0.96-0.98)
        public static let cardPress: CGFloat = 0.96

        /// Button press scale
        public static let buttonPress: CGFloat = 0.95

        /// Hover effect scale
        public static let hover: CGFloat = 1.02

        /// Focus scale
        public static let focus: CGFloat = 1.05

        /// Selection scale
        public static let selected: CGFloat = 0.98

        /// Error shake amplitude
        public static let errorShake: CGFloat = 10
    }

    // MARK: - Easing Curves

    /// Custom easing curves for specific animations
    public enum Easing {
        /// Material Design standard curve
        public static let material = Animation.timingCurve(0.4, 0, 0.2, 1, duration: Duration.quick)

        /// Deceleration curve - fast start, slow end
        public static let decelerate = Animation.timingCurve(0, 0, 0.2, 1, duration: Duration.quick)

        /// Acceleration curve - slow start, fast end
        public static let accelerate = Animation.timingCurve(0.4, 0, 1, 1, duration: Duration.quick)

        /// Smooth ease in-out
        public static let smooth = Animation.easeInOut(duration: Duration.smooth)

        /// Quick ease out
        public static let quickOut = Animation.easeOut(duration: Duration.quick)

        /// Gentle ease in-out
        public static let gentle = Animation.easeInOut(duration: Duration.gentle)
    }

    // MARK: - Offset Values

    /// Standard offset values for slide animations
    public enum Offset {
        /// Small offset for subtle movements
        public static let small: CGFloat = 10

        /// Medium offset for standard slides
        public static let medium: CGFloat = 20

        /// Large offset for dramatic entrances
        public static let large: CGFloat = 40

        /// Extra large offset for full-screen transitions
        public static let xl: CGFloat = 60
    }

    // MARK: - Opacity Values

    /// Standard opacity values for fade animations
    public enum Opacity {
        /// Disabled state opacity
        public static let disabled: Double = 0.5

        /// Secondary content opacity
        public static let secondary: Double = 0.7

        /// Hover state opacity
        public static let hover: Double = 0.9

        /// Pressed state opacity
        public static let pressed: Double = 0.8

        /// Background overlay opacity
        public static let overlay: Double = 0.3
    }

    // MARK: - Animation Presets

    /// Pre-configured animation combinations for common use cases
    public enum Presets {
        /// Hero transition for navigation
        public static let heroTransition = Spring.smooth

        /// List item appearance
        public static let listAppearance = Spring.quick

        /// Card interaction
        public static let cardInteraction = Spring.stiff

        /// Number counter animation
        public static let numberCounter = Easing.smooth

        /// Progress bar fill
        public static let progressFill = Spring.gentle

        /// Sheet presentation
        public static let sheetPresentation = Spring.smooth

        /// Tab transition
        public static let tabTransition = Spring.quick

        /// Error shake
        public static let errorShake = Spring.bouncy

        /// Success celebration
        public static let celebration = Spring.bouncy
    }

    // MARK: - Stagger Configuration

    /// Calculate stagger delay for list animations
    /// - Parameters:
    ///   - index: The index of the item in the list
    ///   - total: Total number of items
    ///   - maxDelay: Maximum delay for the last item (default 0.3s)
    /// - Returns: Calculated delay for the item
    public static func staggerDelay(index: Int, total: Int, maxDelay: Double = 0.3) -> Double {
        guard total > 0 else {
            return 0
        }
        let delay = Double(index) * (maxDelay / Double(max(total - 1, 1)))
        return min(delay, maxDelay)
    }

    /// Calculate cascade delay for sequential animations
    /// - Parameters:
    ///   - index: The index of the item
    ///   - itemDelay: Delay between each item (default 0.05s)
    ///   - maxDelay: Maximum total delay (default 0.5s)
    /// - Returns: Calculated cascade delay
    public static func cascadeDelay(index: Int, itemDelay: Double = 0.05, maxDelay: Double = 0.5) -> Double {
        let delay = Double(index) * itemDelay
        return min(delay, maxDelay)
    }
}

// MARK: - Animation Extensions

extension Animation {
    /// Create a standard interaction animation
    public static var interaction: Animation {
        AnimationConstants.Spring.quick
    }

    /// Create a standard transition animation
    public static var transition: Animation {
        AnimationConstants.Spring.smooth
    }

    /// Create a celebration animation
    public static var celebration: Animation {
        AnimationConstants.Spring.bouncy
    }

    /// Create an error animation
    public static var error: Animation {
        AnimationConstants.Spring.rubberBand
    }
}

// MARK: - Previews

#if DEBUG
    import SwiftUI

    struct AnimationConstants_Previews: PreviewProvider {
        struct PreviewContent: View {
            // MARK: Internal

            enum SpringType: String, CaseIterable {
                case quick, smooth, gentle, bouncy, rubberBand, stiff, soft

                // MARK: Internal

                var animation: Animation {
                    switch self {
                    case .quick: AnimationConstants.Spring.quick
                    case .smooth: AnimationConstants.Spring.smooth
                    case .gentle: AnimationConstants.Spring.gentle
                    case .bouncy: AnimationConstants.Spring.bouncy
                    case .rubberBand: AnimationConstants.Spring.rubberBand
                    case .stiff: AnimationConstants.Spring.stiff
                    case .soft: AnimationConstants.Spring.soft
                    }
                }
            }

            enum EasingType: String, CaseIterable {
                case material, decelerate, accelerate, smooth, quickOut, gentle

                // MARK: Internal

                var animation: Animation {
                    switch self {
                    case .material: AnimationConstants.Easing.material
                    case .decelerate: AnimationConstants.Easing.decelerate
                    case .accelerate: AnimationConstants.Easing.accelerate
                    case .smooth: AnimationConstants.Easing.smooth
                    case .quickOut: AnimationConstants.Easing.quickOut
                    case .gentle: AnimationConstants.Easing.gentle
                    }
                }
            }

            var body: some View {
                ScrollView {
                    VStack(spacing: 40) {
                        Text("Animation Constants Preview")
                            .font(.title2.bold())
                            .padding()

                        // Spring Animations
                        #if !os(watchOS)
                            GroupBox("Spring Animations") {
                                self.SpringAnimationsContent()
                            }
                        #else
                            VStack(spacing: 16) {
                                Text("Spring Animations")
                                    .font(.headline)
                                    .padding(.bottom, 8)

                                self.SpringAnimationsContent()
                            }
                            .padding()
                            .background(.quaternary.opacity(0.5))
                            .cornerRadius(12)
                        #endif

                        // Easing Animations
                        #if !os(watchOS)
                            GroupBox("Easing Animations") {
                                self.EasingAnimationsContent()
                            }
                        #else
                            VStack(spacing: 16) {
                                Text("Easing Animations")
                                    .font(.headline)
                                    .padding(.bottom, 8)

                                self.EasingAnimationsContent()
                            }
                            .padding()
                            .background(.quaternary.opacity(0.5))
                            .cornerRadius(12)
                        #endif

                        // Animation Presets
                        #if !os(watchOS)
                            GroupBox("Animation Presets") {
                                self.AnimationPresetsContent()
                            }
                        #else
                            VStack(spacing: 16) {
                                Text("Animation Presets")
                                    .font(.headline)
                                    .padding(.bottom, 8)

                                self.AnimationPresetsContent()
                            }
                            .padding()
                            .background(.quaternary.opacity(0.5))
                            .cornerRadius(12)
                        #endif

                        // Scale Values Demo
                        #if !os(watchOS)
                            GroupBox("Scale Values") {
                                self.ScaleValuesContent()
                            }
                        #else
                            VStack(spacing: 16) {
                                Text("Scale Values")
                                    .font(.headline)
                                    .padding(.bottom, 8)

                                self.ScaleValuesContent()
                            }
                            .padding()
                            .background(.quaternary.opacity(0.5))
                            .cornerRadius(12)
                        #endif
                    }
                    .padding()
                }
            }

            // MARK: Private

            @State private var isAnimating = false
            @State private var selectedSpring: SpringType = .quick
            @State private var selectedEasing: EasingType = .smooth
            @State private var offset: CGFloat = 0
            @State private var scale: CGFloat = 1.0
            @State private var rotation: Double = 0

            @ViewBuilder
            private func SpringAnimationsContent() -> some View {
                VStack(spacing: 20) {
                    Picker("Spring Type", selection: self.$selectedSpring) {
                        ForEach(SpringType.allCases, id: \.self) { spring in
                            Text(spring.rawValue.capitalized).tag(spring)
                        }
                    }
                    #if os(watchOS)
                    .pickerStyle(.wheel)
                    #else
                    .pickerStyle(.segmented)
                    #endif

                    Circle()
                        .fill(.blue.gradient)
                        .frame(width: 60, height: 60)
                        .scaleEffect(self.isAnimating ? 1.3 : 1.0)
                        .animation(self.selectedSpring.animation, value: self.isAnimating)

                    Button("Test Spring") {
                        self.isAnimating.toggle()

                        // Reset after delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self.isAnimating = false
                        }
                    }
                    .padding()
                    .background(.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding()
            }

            @ViewBuilder
            private func EasingAnimationsContent() -> some View {
                VStack(spacing: 20) {
                    Picker("Easing Type", selection: self.$selectedEasing) {
                        ForEach(EasingType.allCases, id: \.self) { easing in
                            Text(easing.rawValue.capitalized).tag(easing)
                        }
                    }
                    #if os(watchOS)
                    .pickerStyle(.wheel)
                    #else
                    .pickerStyle(.segmented)
                    #endif

                    RoundedRectangle(cornerRadius: 8)
                        .fill(.green.gradient)
                        .frame(width: 80, height: 40)
                        .offset(x: self.offset)
                        .animation(self.selectedEasing.animation, value: self.offset)

                    Button("Test Easing") {
                        self.offset = self.offset == 0 ? 100 : 0
                    }
                    .padding()
                    .background(.green.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding()
            }

            @ViewBuilder
            private func AnimationPresetsContent() -> some View {
                VStack(spacing: 16) {
                    Text("Common animation patterns used in the app")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        self.PresetButton("Hero Transition", animation: AnimationConstants.Presets.heroTransition)
                        self.PresetButton("List Appearance", animation: AnimationConstants.Presets.listAppearance)
                        self.PresetButton("Card Interaction", animation: AnimationConstants.Presets.cardInteraction)
                        self.PresetButton("Number Counter", animation: AnimationConstants.Presets.numberCounter)
                        self.PresetButton("Progress Fill", animation: AnimationConstants.Presets.progressFill)
                        self.PresetButton("Celebration", animation: AnimationConstants.Presets.celebration)
                    }
                }
                .padding()
            }

            @ViewBuilder
            private func ScaleValuesContent() -> some View {
                VStack(spacing: 16) {
                    Text("Standard scale values for interactions")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 20) {
                        self.ScaleDemo("Card Press", scale: AnimationConstants.Scale.cardPress)
                        self.ScaleDemo("Button Press", scale: AnimationConstants.Scale.buttonPress)
                        self.ScaleDemo("Hover", scale: AnimationConstants.Scale.hover)
                        self.ScaleDemo("Focus", scale: AnimationConstants.Scale.focus)
                    }
                }
                .padding()
            }

            @ViewBuilder
            private func PresetButton(_ title: String, animation: Animation) -> some View {
                Button(title) {
                    withAnimation(animation) {
                        self.scale = self.scale == 1.0 ? 1.2 : 1.0
                        self.rotation += 45
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(.purple.opacity(0.1))
                .cornerRadius(6)
                .scaleEffect(self.scale)
                .rotationEffect(.degrees(self.rotation))
            }

            @ViewBuilder
            private func ScaleDemo(_ title: String, scale: CGFloat) -> some View {
                VStack(spacing: 8) {
                    Circle()
                        .fill(.orange.gradient)
                        .frame(width: 40, height: 40)
                        .scaleEffect(self.isAnimating ? scale : 1.0)
                        .animation(.spring(response: 0.3), value: self.isAnimating)

                    Text(title)
                        .font(.caption2)
                        .multilineTextAlignment(.center)

                    Text(verbatim: String(format: "%.2f", scale))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .onTapGesture {
                    self.isAnimating.toggle()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.isAnimating = false
                    }
                }
            }
        }

        static var previews: some View {
            PreviewContent()
                .preferredColorScheme(.light)

            PreviewContent()
                .preferredColorScheme(.dark)
        }
    }
#endif
