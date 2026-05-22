import SwiftUI

public struct CircularGaugeChartView: View {
    // MARK: Lifecycle

    public init(
        progress: Double,
        showValue: Bool,
        lineWidth: CGFloat,
        progressColor: Color? = nil,
        backgroundOpacity: Double? = nil
    ) {
        self.progress = progress
        self.showValue = showValue
        self.lineWidth = lineWidth
        self.progressColor = progressColor
        self.backgroundOpacity = backgroundOpacity
    }

    // MARK: Public

    /// Constants that define the gauge's appearance
    public enum Constants {
        public static let startAngle = -230.0
        public static let endAngle = 50.0
        public static let totalArc = abs(startAngle - endAngle)
        public static let backgroundOpacity = 0.2
    }

    public let progress: Double
    public let showValue: Bool
    public let lineWidth: CGFloat
    public let progressColor: Color?
    public let backgroundOpacity: Double?

    public var body: some View {
        ZStack {
            // Background Track
            Circle()
                .trim(from: 0, to: CGFloat(Constants.totalArc / 360.0))
                .stroke(
                    self.theme.colors.primary.opacity(self.backgroundOpacity ?? Constants.backgroundOpacity),
                    style: StrokeStyle(
                        lineWidth: self.lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(Constants.startAngle))

            // Progress Arc
            Circle()
                .trim(from: 0, to: CGFloat(Constants.totalArc / 360.0) * CGFloat(self.displayProgress))
                .stroke(
                    self.progressColor ?? self.theme.colors.primary,
                    style: StrokeStyle(
                        lineWidth: self.lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(Constants.startAngle))
                .opacity(self.displayProgress > 0 ? 1 : 0)

            // Percentage Text
            if self.showValue {
                Text(verbatim: "\(Int(self.displayProgress * 100))%")
                    .font(self.theme.typography.title1)
                    .fontWeight(.bold)
                    .foregroundColor(self.theme.colors.textPrimary)
            }
        }
        .onAppear {
            if !self.hasAnimated && self.progress > 0 {
                // Animate from 0 to current progress on first appearance
                self.animatedProgress = 0
                withAnimation(.easeInOut(duration: 0.5)) {
                    self.animatedProgress = self.progress
                    self.hasAnimated = true
                }
            } else {
                // No animation, just set the value
                self.animatedProgress = self.progress
            }
        }
        .onChange(of: self.progress) { oldValue, newValue in
            // Only animate if there's a meaningful change
            if abs(newValue - oldValue) > 0.001 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.animatedProgress = newValue
                }
                self.hasAnimated = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Int(self.displayProgress * 100)) percent")
    }

    // MARK: Private

    @State private var animatedProgress: Double = 0
    @State private var hasAnimated: Bool = false
    @Environment(\.theme) private var theme

    private var displayProgress: Double {
        let clamped = max(0, min(1, animatedProgress))
        // Ensure minimum visible progress when starting
        if clamped > 0 && clamped < 0.01 {
            return 0.01 // 1% minimum to ensure visibility
        }
        return clamped
    }
}

#Preview {
    struct PreviewContent: View {
        @State private var progress: Double = 0.75

        var body: some View {
            ScrollView {
                VStack(spacing: 40) {
                    Text("Circular Gauge Chart")
                        .font(.title2.bold())
                        .padding()

                    // Standard gauge
                    VStack(spacing: 16) {
                        Text("Progress Gauge")
                            .font(.headline)

                        CircularGaugeChartView(
                            progress: progress,
                            showValue: true,
                            lineWidth: 20,
                            progressColor: .blue
                        )
                        .frame(height: 200)

                        Slider(value: $progress, in: 0...1)
                            .padding(.horizontal)
                    }

                    // Multiple gauges demonstration
                    VStack(spacing: 16) {
                        Text("Multiple Gauges")
                            .font(.headline)

                        HStack(spacing: 30) {
                            VStack(spacing: 8) {
                                CircularGaugeChartView(
                                    progress: 0.8,
                                    showValue: true,
                                    lineWidth: 16,
                                    progressColor: .green
                                )
                                .frame(height: 120)

                                Text("Steps")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            VStack(spacing: 8) {
                                CircularGaugeChartView(
                                    progress: 0.45,
                                    showValue: true,
                                    lineWidth: 16,
                                    progressColor: .red
                                )
                                .frame(height: 120)

                                Text("Calories")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            VStack(spacing: 8) {
                                CircularGaugeChartView(
                                    progress: 0.6,
                                    showValue: true,
                                    lineWidth: 16,
                                    progressColor: .purple
                                )
                                .frame(height: 120)

                                Text("Exercise")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }

    return PreviewContent()
}
