import SwiftUI

// MARK: - AmbientGlowModifier

/// A subtle glow effect for active states in activity UI.
/// Creates a soft ambient glow around elements without heavy blur or glass effects.
///
/// Design principles:
/// - Subtle, not overwhelming
/// - Color-matched to element
/// - Animatable for active states
/// - Works well on dark backgrounds
public struct AmbientGlowModifier: ViewModifier {
    // MARK: Lifecycle

    /// Creates an ambient glow modifier
    /// - Parameters:
    ///   - color: The glow color
    ///   - radius: The blur radius (default: 20)
    ///   - intensity: The glow intensity level
    ///   - isActive: Whether the glow is currently active
    public init(
        color: Color,
        radius: CGFloat = 20,
        intensity: GlowIntensity = .medium,
        isActive: Bool = true
    ) {
        self.color = color
        self.radius = radius
        self.intensity = intensity
        self.isActive = isActive
    }

    public func body(content: Content) -> some View {
        content
            .background(
                self.glowBackground
                    .opacity(self.isActive ? self.intensity.opacity : 0)
                    .animation(.easeInOut(duration: 0.3), value: self.isActive)
            )
    }

    // MARK: Internal

    let color: Color
    let radius: CGFloat
    let intensity: GlowIntensity
    let isActive: Bool

    // MARK: Private

    @ViewBuilder
    private var glowBackground: some View {
        self.color
            .blur(radius: self.radius)
    }
}

// MARK: AmbientGlowModifier.GlowIntensity

extension AmbientGlowModifier {
    /// Intensity levels for ambient glow
    public enum GlowIntensity {
        /// Very subtle glow
        case subtle
        /// Light glow
        case light
        /// Medium glow
        case medium
        /// Strong glow
        case strong

        // MARK: Internal

        var opacity: Double {
            switch self {
            case .subtle:
                0.15
            case .light:
                0.25
            case .medium:
                0.35
            case .strong:
                0.5
            }
        }
    }
}

extension View {
    /// Apply an ambient glow effect
    /// - Parameters:
    ///   - color: The glow color
    ///   - radius: The blur radius (default: 20)
    ///   - intensity: The glow intensity level
    ///   - isActive: Whether the glow is currently active
    public func ambientGlow(
        color: Color,
        radius: CGFloat = 20,
        intensity: AmbientGlowModifier.GlowIntensity = .medium,
        isActive: Bool = true
    ) -> some View {
        modifier(
            AmbientGlowModifier(
                color: color,
                radius: radius,
                intensity: intensity,
                isActive: isActive
            )
        )
    }
}

// MARK: - ActivityStatusGlow

/// A specialized glow effect for activity status indication
public struct ActivityStatusGlow: View {
    // MARK: Lifecycle

    /// Creates an activity status glow indicator
    /// - Parameters:
    ///   - status: The current activity status
    ///   - size: The size of the glow circle
    public init(status: ActivityStatus, size: CGFloat = 80) {
        self.status = status
        self.size = size
    }

    // MARK: Public

    public var body: some View {
        Circle()
            .fill(self.statusColor.opacity(0.2))
            .frame(width: self.size, height: self.size)
            .blur(radius: self.size / 3)
            .overlay(
                Circle()
                    .fill(self.statusColor.opacity(0.4))
                    .frame(width: self.size * 0.5, height: self.size * 0.5)
                    .blur(radius: self.size / 6)
            )
            .accessibilityHidden(true)
    }

    // MARK: Internal

    let status: ActivityStatus
    let size: CGFloat

    // MARK: Private

    @Environment(\.theme) private var theme

    private var statusColor: Color {
        switch self.status {
        case .active:
            self.theme.colors.success
        case .paused:
            .orange
        case .completed:
            self.theme.colors.primary
        case .idle:
            self.theme.colors.textSecondary
        }
    }
}

// MARK: ActivityStatusGlow.ActivityStatus

extension ActivityStatusGlow {
    /// Activity states for status glow
    public enum ActivityStatus {
        case idle
        case active
        case paused
        case completed
    }
}

// MARK: - AnimatedAmbientBackground

/// A subtle animated ambient background for activity screens
public struct AnimatedAmbientBackground: View {
    // MARK: Lifecycle

    /// Creates an animated ambient background
    /// - Parameters:
    ///   - colors: The gradient colors to use
    ///   - isActive: Whether animation is active
    public init(colors: [Color], isActive: Bool = true) {
        self.colors = colors
        self.isActive = isActive
    }

    // MARK: Public

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base dark background
                Color.black

                // Animated gradient orbs
                ForEach(0..<3, id: \.self) { index in
                    self.gradientOrb(index: index, size: geometry.size)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            if self.isActive {
                withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                    self.phase = 1
                }
            }
        }
    }

    // MARK: Internal

    let colors: [Color]
    let isActive: Bool

    // MARK: Private

    @State private var phase: CGFloat = 0

    @ViewBuilder
    private func gradientOrb(index: Int, size: CGSize) -> some View {
        let orbSize = size.width * 0.8
        let offset = CGFloat(index) * 0.33
        let colorIndex = index % self.colors.count

        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        self.colors[colorIndex].opacity(0.3),
                        self.colors[colorIndex].opacity(0.0)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: orbSize / 2
                )
            )
            .frame(width: orbSize, height: orbSize)
            .offset(
                x: sin((self.phase + offset) * .pi * 2) * size.width * 0.3,
                y: cos((self.phase + offset) * .pi * 2) * size.height * 0.2
            )
            .blur(radius: 60)
    }
}

// MARK: - Preview

#Preview("Ambient Glow") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            // Status glows
            HStack(spacing: 40) {
                VStack {
                    ActivityStatusGlow(status: .active)
                    Text("Active")
                        .foregroundStyle(.white)
                }

                VStack {
                    ActivityStatusGlow(status: .paused)
                    Text("Paused")
                        .foregroundStyle(.white)
                }

                VStack {
                    ActivityStatusGlow(status: .completed)
                    Text("Done")
                        .foregroundStyle(.white)
                }
            }

            // Glow modifier demo
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue)
                .frame(width: 100, height: 100)
                .ambientGlow(color: .blue, radius: 30, intensity: .strong)

            // Text with glow
            Text(verbatim: "145")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .ambientGlow(color: .red, radius: 40, intensity: .medium)
        }
    }
}

#Preview("Animated Background") {
    AnimatedAmbientBackground(colors: [.blue, .purple, .cyan])
}
