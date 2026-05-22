import SwiftUI

// MARK: - CelebrationEffects

/// Celebration and success animation effects for achievements and milestones
public enum CelebrationEffects {
    // MARK: Public

    // MARK: - Confetti Shape Types

    /// Controls particle scale, count, and duration as a single preset
    public enum ConfettiIntensity {
        case subtle
        case standard
        case epic

        // MARK: Public

        /// Scale multiplier applied to particle sizes
        public var scaleFactor: CGFloat {
            switch self {
            case .subtle: 0.7
            case .standard: 1.0
            case .epic: 1.4
            }
        }

        /// Default particle count for this intensity
        public var particleCount: Int {
            switch self {
            case .subtle: 25
            case .standard: 45
            case .epic: 80
            }
        }

        /// Default animation duration for this intensity
        public var duration: Double {
            switch self {
            case .subtle: 1.8
            case .standard: 3.0
            case .epic: 4.5
            }
        }
    }

    /// Shape types matching the Figma confetti design
    public enum ConfettiShape: CaseIterable {
        case squiggle
        case star
        case square
        case triangle
        case stick
        case circle
        case diamond

        // MARK: Internal

        /// Asset catalog name in SharedComponents bundle
        var assetName: String {
            switch self {
            case .squiggle: "confetti_squiggle"
            case .star: "confetti_star"
            case .square: "confetti_square"
            case .triangle: "confetti_triangle"
            case .stick: "confetti_stick"
            case .circle: "confetti_circle"
            case .diamond: "confetti_diamond"
            }
        }

        /// Base display size for this shape type
        var baseSize: CGSize {
            switch self {
            case .squiggle: CGSize(width: 14, height: 22)
            case .star: CGSize(width: 14, height: 14)
            case .square: CGSize(width: 8, height: 8)
            case .triangle: CGSize(width: 10, height: 9)
            case .stick: CGSize(width: 16, height: 3)
            case .circle: CGSize(width: 8, height: 6)
            case .diamond: CGSize(width: 10, height: 10)
            }
        }
    }

    /// Confetti particle for burst animation
    public struct ConfettiParticle: Identifiable {
        // MARK: Lifecycle

        init(
            color: Color,
            startPosition: CGPoint,
            shape: ConfettiShape,
            phase: ParticlePhase,
            intensityScale: CGFloat = 1.0
        ) {
            self.color = color
            self.shape = shape
            self.phase = phase
            self.startPosition = startPosition
            self.position = startPosition

            switch phase {
            case .burst:
                // Burst outward from center
                let angle = Double.random(in: 0...(2 * .pi))
                let speed = CGFloat.random(in: 250...450)
                self.velocity = CGVector(
                    dx: cos(angle) * speed,
                    dy: sin(angle) * speed - 150 // Bias upward
                )
                self.scale = CGFloat.random(in: 0.6...1.2) * intensityScale
            case .shower:
                // Drift downward with gentle lateral sway
                self.velocity = CGVector(
                    dx: CGFloat.random(in: -30...30),
                    dy: CGFloat.random(in: 80...180)
                )
                self.scale = CGFloat.random(in: 0.5...1.0) * intensityScale
            }

            self.rotation = Double.random(in: 0...360)
            self.rotationSpeed = Double.random(in: -360...360)
            self.opacity = 1.0
            self.swayPhase = Double.random(in: 0...(2 * .pi))
            self.swayAmplitude = CGFloat.random(in: 20...60)
            self.elapsed = 0
        }

        // MARK: Public

        public let id = UUID()

        // MARK: Internal

        enum ParticlePhase {
            case burst
            case shower
        }

        let color: Color
        let shape: ConfettiShape
        let phase: ParticlePhase
        let startPosition: CGPoint
        let swayPhase: Double
        let swayAmplitude: CGFloat
        var scale: CGFloat
        var position: CGPoint
        var velocity: CGVector
        var rotation: Double
        var rotationSpeed: Double
        var opacity: Double
        var elapsed: Double
    }

    /// Confetti burst effect modifier with two-phase animation
    public struct ConfettiBurstModifier: ViewModifier {
        // MARK: Lifecycle

        public init(
            trigger: Bool,
            intensity: ConfettiIntensity = .standard,
            particleCount: Int? = nil,
            colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange],
            duration: Double? = nil
        ) {
            self.trigger = trigger
            self.intensity = intensity
            self.particleCount = particleCount ?? intensity.particleCount
            self.colors = colors
            self.duration = duration ?? intensity.duration
        }

        public func body(content: Content) -> some View {
            content
                .overlay(
                    GeometryReader { geometry in
                        ZStack {
                            ForEach(self.particles) { particle in
                                ConfettiShapeView(
                                    shape: particle.shape,
                                    color: particle.color,
                                    scale: particle.scale
                                )
                                .rotationEffect(.degrees(particle.rotation))
                                .position(particle.position)
                                .opacity(particle.opacity)
                            }
                        }
                        .allowsHitTesting(false)
                        .onChange(of: self.trigger) { _, newValue in
                            if newValue {
                                self.startConfetti(in: geometry.size)
                            }
                        }
                    }
                )
        }

        // MARK: Internal

        let trigger: Bool
        let intensity: ConfettiIntensity
        let particleCount: Int
        let colors: [Color]
        let duration: Double

        // MARK: Private

        @State private var particles: [ConfettiParticle] = []
        @State private var animationTimer: Timer?

        private func startConfetti(in size: CGSize) {
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let burstCount = Int(Double(self.particleCount) * 0.6)
            let showerCount = self.particleCount - burstCount
            let shapes = ConfettiShape.allCases

            let scaleFactor = self.intensity.scaleFactor

            // Phase 1: Burst particles from center
            var allParticles: [ConfettiParticle] = (0..<burstCount).map { _ in
                ConfettiParticle(
                    color: self.colors.randomElement() ?? .blue,
                    startPosition: center,
                    shape: shapes.randomElement() ?? .square,
                    phase: .burst,
                    intensityScale: scaleFactor
                )
            }

            // Phase 2: Shower particles from top (spawned with delay via negative y)
            let showerParticles: [ConfettiParticle] = (0..<showerCount).map { _ in
                let spawnX = CGFloat.random(in: 0...size.width)
                let spawnY = CGFloat.random(in: -40...(-10))
                var particle = ConfettiParticle(
                    color: self.colors.randomElement() ?? .blue,
                    startPosition: CGPoint(x: spawnX, y: spawnY),
                    shape: shapes.randomElement() ?? .square,
                    phase: .shower,
                    intensityScale: scaleFactor
                )
                // Stagger shower spawn: particles wait before becoming visible
                particle.opacity = 0
                particle.elapsed = -Double.random(in: 0.3...0.8) // Negative elapsed = delayed start
                return particle
            }

            allParticles.append(contentsOf: showerParticles)
            self.particles = allParticles

            // Animate particles
            let fadeStartFraction = 0.7
            self.animationTimer?.invalidate()
            let timer = Timer(timeInterval: 0.016, repeats: true) { timer in
                self.updateParticles(
                    duration: self.duration,
                    fadeStartFraction: fadeStartFraction,
                    containerSize: size
                )

                // Stop when all faded
                if self.particles.allSatisfy({ $0.opacity <= 0 && $0.elapsed >= 0 }) {
                    timer.invalidate()
                    self.particles.removeAll()
                }
            }
            // Add to .common mode so animation continues during scrolling
            RunLoop.current.add(timer, forMode: .common)
            self.animationTimer = timer
        }

        private func updateParticles(
            duration: Double,
            fadeStartFraction: Double,
            containerSize: CGSize
        ) {
            let dt = 0.016

            for i in self.particles.indices {
                self.particles[i].elapsed += dt

                // Shower particles wait before appearing
                if self.particles[i].elapsed < 0 {
                    continue
                }

                // Make shower particles visible once their delay is over
                if self.particles[i].phase == .shower && self.particles[i].opacity == 0 &&
                    self.particles[i].elapsed >= 0 {
                    self.particles[i].opacity = 1.0
                }

                switch self.particles[i].phase {
                case .burst:
                    // Update position with velocity
                    self.particles[i].position.x += self.particles[i].velocity.dx * dt
                    self.particles[i].position.y += self.particles[i].velocity.dy * dt
                    // Gravity
                    self.particles[i].velocity.dy += 500 * dt
                    // Air resistance
                    self.particles[i].velocity.dx *= 0.98
                    self.particles[i].velocity.dy *= 0.98

                case .shower:
                    // Gentle downward drift with sinusoidal sway
                    self.particles[i].position.y += self.particles[i].velocity.dy * dt
                    let swayOffset = sin(
                        self.particles[i].elapsed * 3 + self.particles[i].swayPhase
                    ) * self.particles[i].swayAmplitude * dt
                    self.particles[i].position.x += swayOffset + self.particles[i].velocity.dx * dt
                }

                // Rotation
                self.particles[i].rotation += self.particles[i].rotationSpeed * dt

                // Fade out in the final portion of the duration
                let fadeStart = duration * fadeStartFraction
                if self.particles[i].elapsed > fadeStart {
                    let fadeDuration = duration * (1.0 - fadeStartFraction)
                    let fadeProgress = (self.particles[i].elapsed - fadeStart) / fadeDuration
                    self.particles[i].opacity = max(0, 1.0 - fadeProgress)
                }
            }
        }
    }

    // MARK: Internal

    // MARK: - Confetti Shape Views

    /// Renders a confetti shape using SVG assets from the bundle
    struct ConfettiShapeView: View {
        let shape: ConfettiShape
        let color: Color
        let scale: CGFloat

        var body: some View {
            Image(self.shape.assetName, bundle: .module)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(self.color)
                .frame(
                    width: self.shape.baseSize.width * self.scale,
                    height: self.shape.baseSize.height * self.scale
                )
        }
    }
}

// MARK: - CheckmarkShape

/// Checkmark shape for success animations
public struct CheckmarkShape: Shape {
    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: width * 0.2, y: height * 0.5))
        path.addLine(to: CGPoint(x: width * 0.4, y: height * 0.7))
        path.addLine(to: CGPoint(x: width * 0.8, y: height * 0.3))

        return path
    }
}

// MARK: - View Extensions

extension View {
    /// Apply confetti burst effect with two-phase animation (burst + shower)
    /// - Parameters:
    ///   - trigger: Toggle to start the animation
    ///   - intensity: Preset controlling scale, count, and duration (.subtle, .standard, .epic)
    ///   - particleCount: Override the intensity's default particle count
    ///   - colors: Colors to randomly assign to particles
    ///   - duration: Override the intensity's default duration
    public func confettiBurst(
        trigger: Bool,
        intensity: CelebrationEffects.ConfettiIntensity = .standard,
        particleCount: Int? = nil,
        colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange],
        duration: Double? = nil
    ) -> some View {
        modifier(CelebrationEffects.ConfettiBurstModifier(
            trigger: trigger,
            intensity: intensity,
            particleCount: particleCount,
            colors: colors,
            duration: duration
        ))
    }
}

// MARK: - Preview Provider

#if DEBUG
    struct CelebrationEffects_Previews: PreviewProvider {
        struct PreviewContent: View {
            // MARK: Internal

            var body: some View {
                VStack(spacing: 30) {
                    Text("Confetti Celebration")
                        .font(.title2.bold())
                        .padding(.top)

                    Text("Tap the button to trigger the confetti burst + shower")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Celebrate!") {
                        self.showConfetti.toggle()
                    }
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .background(Color.blue.opacity(self.showConfetti ? 0.2 : 0.1))
                    .foregroundStyle(.blue)
                    .cornerRadius(12)
                    .confettiBurst(
                        trigger: self.showConfetti,
                        particleCount: 60,
                        colors: [.purple, .pink, .green, .cyan, .yellow, .mint],
                        duration: 3.0
                    )
                }
                .padding()
            }

            // MARK: Private

            @State private var showConfetti = false
        }

        static var previews: some View {
            PreviewContent()
                .preferredColorScheme(.light)

            PreviewContent()
                .preferredColorScheme(.dark)
        }
    }
#endif
