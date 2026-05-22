import SwiftUI

// MARK: - PulsingView

/// Pulsing view for active/live indicators
public struct PulsingView<Content: View>: View {
    // MARK: Lifecycle

    public init(
        isActive: Bool = true,
        pulseColor: Color = .blue,
        pulseOpacity: Double = 0.5,
        pulseScale: CGFloat = 1.5,
        duration: Double = 1.5,
        @ViewBuilder content: () -> Content
    ) {
        self.isActive = isActive
        self.pulseColor = pulseColor
        self.pulseOpacity = pulseOpacity
        self.pulseScale = pulseScale
        self.duration = duration
        self.content = content()
    }

    // MARK: Public

    public var body: some View {
        ZStack {
            if self.isActive {
                // Pulsing background layers
                ForEach(0..<3) { index in
                    Circle()
                        .fill(self.pulseColor)
                        .opacity(self.isPulsing ? 0 : self.pulseOpacity)
                        .scaleEffect(self.isPulsing ? self.pulseScale : 1)
                        .animation(
                            Animation.easeOut(duration: self.duration)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * (self.duration / 3)),
                            value: self.isPulsing
                        )
                }
            }

            // Main content
            self.content
        }
        .onAppear {
            if self.isActive {
                self.isPulsing = true
            }
        }
        .onChange(of: self.isActive) { _, newValue in
            self.isPulsing = newValue
        }
    }

    // MARK: Private

    @State private var isPulsing = false

    private let content: Content
    private let pulseColor: Color
    private let pulseOpacity: Double
    private let pulseScale: CGFloat
    private let duration: Double
    private let isActive: Bool
}

// MARK: - LiveIndicator

/// Live indicator dot with pulsing animation
public struct LiveIndicator: View {
    // MARK: Lifecycle

    public init(
        size: CGFloat = 8,
        color: Color = .red,
        showText: Bool = true
    ) {
        self.size = size
        self.color = color
        self.showText = showText
    }

    // MARK: Public

    public var body: some View {
        HStack(spacing: 6) {
            PulsingView(
                pulseColor: self.color,
                pulseOpacity: 0.3,
                pulseScale: 2.5,
                duration: 1.5
            ) {
                Circle()
                    .fill(self.color)
                    .frame(width: self.size, height: self.size)
            }

            if self.showText {
                Text(L10n.string("common.live", defaultValue: "LIVE"))
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(self.color)
            }
        }
    }

    // MARK: Private

    @Environment(\.theme) private var theme
    @State private var isAnimating = false

    private let size: CGFloat
    private let color: Color
    private let showText: Bool
}

// MARK: - BreathingView

/// Breathing effect view
public struct BreathingView<Content: View>: View {
    // MARK: Lifecycle

    public init(
        isBreathing: Bool = true,
        minScale: CGFloat = 0.95,
        maxScale: CGFloat = 1.05,
        duration: Double = 3.0,
        @ViewBuilder content: () -> Content
    ) {
        self.isBreathing = isBreathing
        self.minScale = minScale
        self.maxScale = maxScale
        self.duration = duration
        self.content = content()
    }

    // MARK: Public

    public var body: some View {
        self.content
            .scaleEffect(self.scale)
            .opacity(self.opacity)
            .onAppear {
                if self.isBreathing {
                    self.startBreathing()
                }
            }
            .onChange(of: self.isBreathing) { _, newValue in
                if newValue {
                    self.startBreathing()
                } else {
                    self.stopBreathing()
                }
            }
    }

    // MARK: Private

    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0

    private let content: Content
    private let minScale: CGFloat
    private let maxScale: CGFloat
    private let duration: Double
    private let isBreathing: Bool

    private func startBreathing() {
        withAnimation(
            Animation.easeInOut(duration: self.duration / 2)
                .repeatForever(autoreverses: true)
        ) {
            self.scale = self.maxScale
            self.opacity = 0.9
        }
    }

    private func stopBreathing() {
        withAnimation(.easeOut(duration: 0.3)) {
            self.scale = 1.0
            self.opacity = 1.0
        }
    }
}

// MARK: - HeartbeatView

/// Heartbeat animation view
public struct HeartbeatView<Content: View>: View {
    // MARK: Lifecycle

    public init(
        isBeating: Bool = true,
        beatScale: CGFloat = 1.2,
        @ViewBuilder content: () -> Content
    ) {
        self.isBeating = isBeating
        self.beatScale = beatScale
        self.content = content()
    }

    // MARK: Public

    public var body: some View {
        self.content
            .scaleEffect(self.scale)
            .onAppear {
                if self.isBeating {
                    self.startHeartbeat()
                }
            }
            .onChange(of: self.isBeating) { _, newValue in
                if newValue {
                    self.startHeartbeat()
                } else {
                    self.stopHeartbeat()
                }
            }
    }

    // MARK: Private

    @State private var scale: CGFloat = 1.0

    private let content: Content
    private let beatScale: CGFloat
    private let isBeating: Bool

    private func startHeartbeat() {
        // First beat
        withAnimation(.easeInOut(duration: 0.1)) {
            self.scale = self.beatScale
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.1)) {
                self.scale = 1.0
            }
        }

        // Second beat
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.1)) {
                self.scale = self.beatScale * 0.9
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeInOut(duration: 0.1)) {
                self.scale = 1.0
            }
        }

        // Repeat
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if self.isBeating {
                self.startHeartbeat()
            }
        }
    }

    private func stopHeartbeat() {
        withAnimation(.easeOut(duration: 0.2)) {
            self.scale = 1.0
        }
    }
}

// MARK: - RadarPulse

/// Radar pulse effect
public struct RadarPulse: View {
    // MARK: Lifecycle

    public init(
        size: CGFloat = 100,
        color: Color = .blue,
        pulseCount: Int = 3,
        duration: Double = 2.0
    ) {
        self.size = size
        self.color = color
        self.pulseCount = pulseCount
        self.duration = duration
    }

    // MARK: Public

    public var body: some View {
        ZStack {
            ForEach(0..<self.pulseCount, id: \.self) { index in
                Circle()
                    .stroke(self.color, lineWidth: 2)
                    .scaleEffect(self.animationProgress.indices.contains(index) ? self.animationProgress[index] : 0)
                    .opacity(self.opacities.indices.contains(index) ? self.opacities[index] : 0)
                    .animation(
                        Animation.easeOut(duration: self.duration)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * (self.duration / Double(self.pulseCount))),
                        value: self.animationProgress.indices.contains(index) ? self.animationProgress[index] : 0
                    )
            }
        }
        .frame(width: self.size, height: self.size)
        .onAppear {
            self.animationProgress = Array(repeating: 0, count: self.pulseCount)
            self.opacities = Array(repeating: 1, count: self.pulseCount)

            for index in 0..<self.pulseCount {
                DispatchQueue.main
                    .asyncAfter(deadline: .now() + Double(index) * (self.duration / Double(self.pulseCount))) {
                        self.animationProgress[index] = 2
                        self.opacities[index] = 0
                    }
            }
        }
    }

    // MARK: Private

    @State private var animationProgress: [CGFloat] = []
    @State private var opacities: [Double] = []

    private let size: CGFloat
    private let color: Color
    private let pulseCount: Int
    private let duration: Double
}

// MARK: - PulsingView_Previews

struct PulsingView_Previews: PreviewProvider {
    struct PreviewContent: View {
        // MARK: Internal

        var body: some View {
            VStack(spacing: 40) {
                // Pulsing view with icon
                PulsingView(
                    isActive: self.isActive,
                    pulseColor: .blue,
                    pulseScale: 1.8
                ) {
                    Image(systemName: "wifi")
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                }

                // Live indicator
                LiveIndicator()

                // Breathing view
                BreathingView(isBreathing: self.isBreathing) {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.purple.gradient)
                        .frame(width: 100, height: 100)
                }

                // Heartbeat view
                HeartbeatView(isBeating: self.isBeating) {
                    Image("love")
                        .resizable().aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                        .foregroundColor(.red)
                }

                // Radar pulse
                RadarPulse(color: .green)

                // Controls
                VStack {
                    Toggle("Active", isOn: self.$isActive)
                    Toggle("Breathing", isOn: self.$isBreathing)
                    Toggle("Heartbeat", isOn: self.$isBeating)
                }
                .padding()
            }
            .padding()
        }

        // MARK: Private

        @State private var isActive = true
        @State private var isBreathing = true
        @State private var isBeating = true
    }

    static var previews: some View {
        PreviewContent()
            .theme(DefaultTheme())
    }
}
