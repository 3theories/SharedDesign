import SwiftUI

// MARK: - CircularLiquidProgress

/// Circular liquid progress
public struct CircularLiquidProgress: View {
    // MARK: Lifecycle

    public init(
        progress: Double,
        size: CGFloat = 100,
        fillColor: Color = .blue,
        backgroundColor: Color = Color.gray.opacity(0.2)
    ) {
        self.progress = min(max(progress, 0), 1)
        self.size = size
        self.fillColor = fillColor
        self.backgroundColor = backgroundColor
    }

    // MARK: Public

    public var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(self.backgroundColor)
                .frame(width: self.size, height: self.size)

            // Liquid fill
            Circle()
                .fill(self.fillColor)
                .frame(width: self.size, height: self.size)
                .mask(
                    GeometryReader { geometry in
                        VStack(spacing: 0) {
                            Spacer(minLength: geometry.size.height * (1 - self.animatedProgress))

                            WaveShape(phase: self.wavePhase, waveHeight: 5)
                                .fill(Color.black)
                                .frame(height: geometry.size.height * self.animatedProgress)
                        }
                    }
                )

            // Percentage text
            AnimatedNumberText(
                value: self.animatedProgress * 100,
                format: .integer,
                font: .system(size: self.size / 4, weight: .bold),
                color: self.animatedProgress > 0.5 ? .white : self.fillColor
            )
        }
        .onAppear {
            self.animatedProgress = self.progress
            self.startWaveAnimation()
        }
        .onChange(of: self.progress) { _, newValue in
            withAnimation(AnimationConstants.Spring.smooth) {
                self.animatedProgress = newValue
            }
        }
    }

    // MARK: Private

    @State private var animatedProgress: Double = 0
    @State private var wavePhase: CGFloat = 0

    private let progress: Double
    private let size: CGFloat
    private let fillColor: Color
    private let backgroundColor: Color

    private func startWaveAnimation() {
        withAnimation(
            Animation.linear(duration: 2)
                .repeatForever(autoreverses: false)
        ) {
            self.wavePhase = .pi * 2
        }
    }
}

// MARK: - WaveShape

/// Wave shape for liquid effects
private struct WaveShape: Shape {
    var phase: CGFloat
    var waveHeight: CGFloat = 10

    var animatableData: CGFloat {
        get { self.phase }
        set { self.phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let waveLength = rect.width

        path.move(to: CGPoint(x: 0, y: rect.minY))

        for x in stride(from: 0, to: rect.width, by: 1) {
            let relativeX = x / waveLength
            let sine = sin(relativeX * .pi * 2 + self.phase)
            let y = rect.minY + sine * self.waveHeight
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()

        return path
    }
}

// MARK: - CircularLiquidProgress_Previews

struct CircularLiquidProgress_Previews: PreviewProvider {
    struct PreviewContent: View {
        // MARK: Internal

        var body: some View {
            VStack(spacing: 30) {
                // Circular liquid progress
                HStack(spacing: 20) {
                    CircularLiquidProgress(progress: self.progress1, fillColor: .orange)
                    CircularLiquidProgress(progress: self.progress2, fillColor: .green)
                    CircularLiquidProgress(progress: self.progress3, fillColor: .purple)
                }

                Button("Randomize") {
                    self.progress1 = Double.random(in: 0...1)
                    self.progress2 = Double.random(in: 0...1)
                    self.progress3 = Double.random(in: 0...1)
                }
            }
            .padding()
        }

        // MARK: Private

        @State private var progress1 = 0.75
        @State private var progress2 = 0.5
        @State private var progress3 = 0.3
    }

    static var previews: some View {
        PreviewContent()
            .theme(DefaultTheme())
    }
}
