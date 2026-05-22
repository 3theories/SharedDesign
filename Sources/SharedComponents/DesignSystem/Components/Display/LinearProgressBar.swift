import SwiftUI

// MARK: - LinearProgressBar

/// A linear progress bar with smooth animations and customizable appearance
public struct LinearProgressBar: View {
    // MARK: Lifecycle

    public init(
        progress: Double,
        height: CGFloat = 8,
        showPercentage: Bool = false,
        gradientColors: [Color]? = nil
    ) {
        self.progress = min(max(progress, 0), 1)
        self.height = height
        self.showPercentage = showPercentage
        self.gradientColors = gradientColors
    }

    // MARK: Public

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(self.theme.colors.surface3)
                    .frame(height: self.height)

                // Progress fill
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: self.gradientColors ?? [self.theme.colors.primary, self.theme.colors.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * self.animatedProgress, height: self.height)
                    .animation(AnimationConstants.Spring.smooth, value: self.animatedProgress)

                // Percentage label if requested
                if self.showPercentage {
                    Text(verbatim: "\(Int(self.animatedProgress * 100))%")
                        .font(self.theme.typography.caption1)
                        .foregroundStyle(self.theme.colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, self.theme.spacing.sm)
                }
            }
        }
        .frame(height: self.height)
        .onAppear {
            self.animatedProgress = self.progress
        }
        .onChange(of: self.progress) { _, newValue in
            self.animatedProgress = newValue
        }
    }

    // MARK: Internal

    let progress: Double
    let height: CGFloat
    let showPercentage: Bool
    let gradientColors: [Color]?

    // MARK: Private

    @Environment(\.theme) private var theme
    @State private var animatedProgress: Double = 0
}

// MARK: - TimedLinearProgressBar

/// A variant that shows live time-based progress
public struct TimedLinearProgressBar: View {
    // MARK: Lifecycle

    public init(
        duration: TimeInterval,
        isActive: Bool,
        onComplete: (() -> Void)? = nil
    ) {
        self.duration = duration
        self.isActive = isActive
        self.onComplete = onComplete
    }

    // MARK: Public

    public var body: some View {
        VStack(spacing: self.theme.spacing.sm) {
            LinearProgressBar(
                progress: self.progress,
                height: 12,
                showPercentage: false,
                gradientColors: [self.theme.colors.primary, self.theme.colors.accent]
            )

            // Time remaining
            HStack {
                Text(self.formatTime(elapsed: self.progress * self.duration))
                    .font(self.theme.typography.caption1)
                    .foregroundStyle(self.theme.colors.textSecondary)
                    .monospacedDigit()

                Spacer()

                Text(self.formatTime(elapsed: self.duration))
                    .font(self.theme.typography.caption1)
                    .foregroundStyle(self.theme.colors.textTertiary)
                    .monospacedDigit()
            }
        }
        .onAppear {
            if self.isActive {
                self.startTimer()
            }
        }
        .onDisappear {
            self.timer?.invalidate()
        }
        .onChange(of: self.isActive) { _, newValue in
            if newValue {
                self.startTimer()
            } else {
                self.pauseTimer()
            }
        }
    }

    // MARK: Internal

    let duration: TimeInterval
    let isActive: Bool
    let onComplete: (() -> Void)?

    // MARK: Private

    @Environment(\.theme) private var theme
    @State private var progress: Double = 0
    @State private var timer: Timer?
    @State private var startTime: Date?
    @State private var pausedProgress: Double = 0

    private func startTimer() {
        // If we have paused progress, resume from there
        if self.pausedProgress > 0 {
            self.progress = self.pausedProgress
            self.startTime = Date().addingTimeInterval(-self.pausedProgress * self.duration)
        } else {
            self.startTime = Date()
        }

        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            guard let start = startTime else {
                return
            }
            let elapsed = Date().timeIntervalSince(start)
            let newProgress = min(elapsed / self.duration, 1.0)

            withAnimation(.linear(duration: 0.1)) {
                self.progress = newProgress
            }

            if newProgress >= 1.0 {
                self.timer?.invalidate()
                self.onComplete?()
            }
        }
    }

    private func pauseTimer() {
        self.pausedProgress = self.progress
        self.timer?.invalidate()
        self.timer = nil
    }

    private func formatTime(elapsed: TimeInterval) -> String {
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Preview

#Preview("Linear Progress Bar") {
    VStack(spacing: 20) {
        LinearProgressBar(progress: 0.3)
        LinearProgressBar(progress: 0.6, showPercentage: true)
        LinearProgressBar(
            progress: 0.8,
            height: 16,
            gradientColors: [.purple, .pink]
        )

        TimedLinearProgressBar(
            duration: 30,
            isActive: true
        )
    }
    .padding()
}
