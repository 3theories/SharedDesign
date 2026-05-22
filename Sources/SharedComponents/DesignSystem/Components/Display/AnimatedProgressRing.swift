import SwiftUI

// MARK: - AnimatedProgressRing

/// Animated circular progress ring with physics-based animation and touch interactions
public struct AnimatedProgressRing: View {
    // MARK: Lifecycle

    public init(
        progress: Double,
        lineWidth: CGFloat = 10,
        size: CGFloat = 100,
        startColor: Color? = nil,
        endColor: Color? = nil,
        backgroundOpacity: Double = 0.2,
        trackColor: Color? = nil,
        showPercentage: Bool = true,
        font: Font = .headline,
        segmentCount: Int = 1,
        enableInteraction: Bool = false,
        showCelebration: Bool = false,
        useAngularGradient: Bool = false,
        ringShadow: Bool = false,
        goalProgress: Double? = nil, // 0..1
        tickMarks: Int = 0,
        onSegmentTap: ((Int) -> Void)? = nil
    ) {
        self.progress = min(max(progress, 0), 1) // Clamp between 0 and 1
        self.lineWidth = lineWidth
        self.size = size
        self.startColor = startColor ?? Color.blue
        self.endColor = endColor ?? Color.purple
        self.backgroundOpacity = backgroundOpacity
        self.trackColor = trackColor
        self.showPercentage = showPercentage
        self.font = font
        self.segmentCount = max(1, segmentCount)
        self.enableInteraction = enableInteraction
        self.showCelebration = showCelebration
        self.onSegmentTap = onSegmentTap
        self.useAngularGradient = useAngularGradient
        self.ringShadow = ringShadow
        self.goalProgress = goalProgress
        self.tickMarks = max(0, tickMarks)
    }

    // MARK: Public

    public var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    self.trackColor ?? self.theme.colors.surface3,
                    style: StrokeStyle(
                        lineWidth: self.lineWidth,
                        lineCap: .round
                    )
                )
                .frame(width: self.size, height: self.size)
                .opacity(self.backgroundOpacity)

            // Interactive segments (for touch areas)
            if self.enableInteraction {
                ForEach(0..<self.segmentCount, id: \.self) { segment in
                    self.segmentView(for: segment)
                }
            }

            // Progress ring
            Circle()
                .trim(from: 0, to: self.animatedProgress)
                .stroke(
                    self.useAngularGradient
                        ? AnyShapeStyle(AngularGradient(
                            gradient: Gradient(colors: [self.startColor, self.endColor]),
                            center: .center
                        ))
                        : AnyShapeStyle(LinearGradient(
                            gradient: Gradient(colors: [self.startColor, self.endColor]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )),
                    style: StrokeStyle(
                        lineWidth: self.lineWidth,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .frame(width: self.size, height: self.size)
                .rotationEffect(.degrees(-90))
                .animation(AnimationConstants.Spring.smooth, value: self.animatedProgress)
                .shadow(
                    color: self.ringShadow ? self.endColor.opacity(0.35) : .clear,
                    radius: self.ringShadow ? 6 : 0,
                    x: 0,
                    y: 0
                )

            // Tick marks
            if self.tickMarks > 0 {
                ForEach(0..<self.tickMarks, id: \.self) { i in
                    let frac = Double(i) / Double(self.tickMarks)
                    let len: CGFloat = (i % 5 == 0) ? self.lineWidth * 0.55 : self.lineWidth * 0.35
                    RoundedRectangle(cornerRadius: 2)
                        .fill(self.theme.colors.surface3.opacity(0.6))
                        .frame(width: 2, height: len)
                        .offset(y: -(self.size / 2))
                        .rotationEffect(.degrees(360 * frac))
                }
            }

            // End dot indicator with enhanced glow on goal completion
            if self.animatedProgress > 0 {
                Circle()
                    .fill(self.endColor)
                    .frame(
                        width: self.lineWidth * (self.animatedProgress >= 1.0 ? 1.5 : 1.2),
                        height: self.lineWidth * (self.animatedProgress >= 1.0 ? 1.5 : 1.2)
                    )
                    .offset(y: -self.size / 2)
                    .rotationEffect(.degrees(min(360 * self.animatedProgress, 360) - 90))
                    .animation(AnimationConstants.Spring.smooth, value: self.animatedProgress)
                    .shadow(
                        color: self.endColor.opacity(self.animatedProgress >= 1.0 ? 0.8 : 0.5),
                        radius: self.animatedProgress >= 1.0 ? 8 : 4
                    )
            }

            // Goal marker
            if let g = goalProgress, g > 0, g <= 1 {
                Circle()
                    .fill(self.endColor)
                    .frame(width: self.lineWidth * 0.6, height: self.lineWidth * 0.6)
                    .offset(y: -self.size / 2)
                    .rotationEffect(.degrees(min(360 * g, 360) - 90))
                    .opacity(0.9)
            }

            // Percentage text with scale animation
            if self.showPercentage {
                VStack(spacing: 4) {
                    AnimatedNumberText(
                        value: self.animatedProgress * 100,
                        format: .integer,
                        font: self.font,
                        color: self.theme.colors.textPrimary
                    )

                    Text(verbatim: "%")
                        .font(.caption)
                        .foregroundColor(self.theme.colors.textSecondary)
                }
                .scaleEffect(self.scale)
            }
        }
        .scaleEffect(self.scale)
        .confettiBurst(trigger: self.showingCelebration, particleCount: 25, colors: [self.startColor, self.endColor])
        .onAppear {
            withAnimation(AnimationConstants.Spring.smooth.delay(0.1)) {
                self.animatedProgress = self.progress
            }
        }
        .onChange(of: self.progress) { oldValue, newValue in
            let wasComplete = oldValue >= 1.0
            let isNowComplete = newValue >= 1.0

            withAnimation(AnimationConstants.Spring.smooth) {
                self.animatedProgress = newValue

                // Scale effect for completion
                if !wasComplete && isNowComplete && self.showCelebration {
                    self.triggerCelebration()
                }
            }
        }
    }

    // MARK: Private

    @Environment(\.theme) private var theme
    @State private var animatedProgress: Double = 0
    @State private var isAnimating = false
    @State private var selectedSegment: Int?
    @State private var showingCelebration = false
    @State private var scale: CGFloat = 1.0

    private let progress: Double
    private let lineWidth: CGFloat
    private let size: CGFloat
    private let startColor: Color
    private let endColor: Color
    private let backgroundOpacity: Double
    private let trackColor: Color?
    private let showPercentage: Bool
    private let font: Font
    private let onSegmentTap: ((Int) -> Void)?
    private let segmentCount: Int
    private let showCelebration: Bool
    private let enableInteraction: Bool
    // UI enhancements
    private let useAngularGradient: Bool
    private let ringShadow: Bool
    private let goalProgress: Double?
    private let tickMarks: Int

    // MARK: - Helper Views

    @ViewBuilder
    private func segmentView(for segment: Int) -> some View {
        let segmentAngle = 360.0 / Double(self.segmentCount)
        let startAngle = Double(segment) * segmentAngle - 90
        let endAngle = startAngle + segmentAngle

        Circle()
            .trim(from: startAngle / 360, to: endAngle / 360)
            .stroke(
                Color.clear,
                style: StrokeStyle(lineWidth: self.lineWidth + 10, lineCap: .round)
            )
            .frame(width: self.size, height: self.size)
            .contentShape(
                Circle()
                    .trim(from: startAngle / 360, to: endAngle / 360)
                    .stroke(
                        style: StrokeStyle(lineWidth: self.lineWidth + 10, lineCap: .round)
                    )
            )
            .scaleEffect(self.selectedSegment == segment ? 1.05 : 1.0)
            .onTapGesture {
                self.handleSegmentTap(segment)
            }
            .animation(AnimationConstants.Spring.quick, value: self.selectedSegment)
    }

    // MARK: - Helper Methods

    private func handleSegmentTap(_ segment: Int) {
        self.selectedSegment = segment
        self.onSegmentTap?(segment)

        // Haptic feedback for segment tap
        HapticManager.shared.trigger(.selection)

        // Scale animation
        withAnimation(AnimationConstants.Spring.bouncy) {
            self.scale = 1.1
        }

        withAnimation(AnimationConstants.Spring.quick.delay(0.1)) {
            self.scale = 1.0
            self.selectedSegment = nil
        }
    }

    private func triggerCelebration() {
        // Celebration haptic for goal completion
        HapticManager.shared.trigger(.success)

        // Scale bounce
        withAnimation(AnimationConstants.Spring.bouncy) {
            self.scale = 1.2
        }

        withAnimation(AnimationConstants.Spring.smooth.delay(0.2)) {
            self.scale = 1.0
        }

        // Confetti burst
        self.showingCelebration = true

        // Reset celebration state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.showingCelebration = false
        }
    }
}

// MARK: - SegmentedProgressRing

/// Segmented progress ring with multiple values
public struct SegmentedProgressRing: View {
    // MARK: Lifecycle

    public init(
        segments: [Segment],
        lineWidth: CGFloat = 10,
        size: CGFloat = 100,
        spacing: CGFloat = 2
    ) {
        self.segments = segments
        self.lineWidth = lineWidth
        self.size = size
        self.spacing = spacing
    }

    // MARK: Public

    public struct Segment: Equatable {
        // MARK: Lifecycle

        public init(value: Double, color: Color, label: String? = nil) {
            self.value = value
            self.color = color
            self.label = label
        }

        // MARK: Public

        public let value: Double
        public let color: Color
        public let label: String?

        public static func == (lhs: Segment, rhs: Segment) -> Bool {
            lhs.value == rhs.value &&
                lhs.color == rhs.color &&
                lhs.label == rhs.label
        }
    }

    public var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    self.theme.colors.surface3,
                    style: StrokeStyle(
                        lineWidth: self.lineWidth,
                        lineCap: .round
                    )
                )
                .frame(width: self.size, height: self.size)
                .opacity(0.2)

            // Segmented rings
            ForEach(Array(self.animatedSegments.enumerated()), id: \.offset) { index, animatedSegment in
                let startAngle = startAngle(for: index)
                let endAngle = startAngle + (animatedSegment.animatedValue * 360)

                Circle()
                    .trim(
                        from: startAngle / 360,
                        to: endAngle / 360
                    )
                    .stroke(
                        animatedSegment.segment.color,
                        style: StrokeStyle(
                            lineWidth: self.lineWidth,
                            lineCap: .round
                        )
                    )
                    .frame(width: self.size, height: self.size)
                    .rotationEffect(.degrees(-90))
                    .animation(
                        AnimationConstants.Spring.smooth
                            .delay(Double(index) * 0.1),
                        value: animatedSegment.animatedValue
                    )
            }
        }
        .onAppear {
            self.setupAnimatedSegments()
            self.animateSegments()
        }
        .onChange(of: self.segments) { _, _ in
            self.setupAnimatedSegments()
            self.animateSegments()
        }
    }

    // MARK: Private

    private struct AnimatedSegment {
        let segment: Segment
        var animatedValue: Double = 0
    }

    @Environment(\.theme) private var theme
    @State private var animatedSegments: [AnimatedSegment] = []

    private let segments: [Segment]
    private let lineWidth: CGFloat
    private let size: CGFloat
    private let spacing: CGFloat

    private func setupAnimatedSegments() {
        self.animatedSegments = self.segments.map { AnimatedSegment(segment: $0, animatedValue: 0) }
    }

    private func animateSegments() {
        for index in self.animatedSegments.indices {
            withAnimation(
                AnimationConstants.Spring.smooth
                    .delay(Double(index) * 0.1)
            ) {
                self.animatedSegments[index].animatedValue = self.segments[index].value
            }
        }
    }

    private func startAngle(for index: Int) -> Double {
        guard index > 0 else {
            return 0
        }

        var angle: Double = 0
        for i in 0..<index {
            angle += self.segments[i].value * 360
            angle += self.spacing
        }
        return angle
    }
}

// MARK: - ActivityRing

/// Activity ring style progress indicator
public struct ActivityRing: View {
    // MARK: Lifecycle

    public init(
        progress: Double,
        goal: Double = 1.0,
        color: Color,
        size: CGFloat = 60,
        lineWidth: CGFloat = 8
    ) {
        self.progress = progress
        self.goal = goal
        self.color = color
        self.size = size
        self.lineWidth = lineWidth
    }

    // MARK: Public

    public var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    self.color.opacity(0.2),
                    style: StrokeStyle(
                        lineWidth: self.lineWidth,
                        lineCap: .round
                    )
                )
                .frame(width: self.size, height: self.size)

            // Progress ring
            Circle()
                .trim(from: 0, to: min(self.animatedProgress / self.goal, 1))
                .stroke(
                    self.color,
                    style: StrokeStyle(
                        lineWidth: self.lineWidth,
                        lineCap: .round
                    )
                )
                .frame(width: self.size, height: self.size)
                .rotationEffect(.degrees(-90))
                .animation(AnimationConstants.Spring.smooth, value: self.animatedProgress)

            // Over-goal indicator
            if self.isOverGoal {
                Circle()
                    .trim(from: 0, to: (self.animatedProgress - self.goal) / self.goal)
                    .stroke(
                        self.color,
                        style: StrokeStyle(
                            lineWidth: self.lineWidth * 0.6,
                            lineCap: .round
                        )
                    )
                    .frame(width: self.size + self.lineWidth * 2, height: self.size + self.lineWidth * 2)
                    .rotationEffect(.degrees(-90))
                    .animation(AnimationConstants.Spring.bouncy, value: self.animatedProgress)
                    .opacity(0.8)
            }
        }
        .onAppear {
            withAnimation(AnimationConstants.Spring.smooth.delay(0.1)) {
                self.animatedProgress = self.progress
                self.isOverGoal = self.progress > self.goal
            }
        }
        .onChange(of: self.progress) { _, newValue in
            withAnimation(AnimationConstants.Spring.smooth) {
                self.animatedProgress = newValue
                self.isOverGoal = newValue > self.goal
            }
        }
    }

    // MARK: Private

    @State private var animatedProgress: Double = 0
    @State private var isOverGoal = false

    private let progress: Double
    private let goal: Double
    private let color: Color
    private let size: CGFloat
    private let lineWidth: CGFloat
}

// MARK: - AnimatedProgressRing_Previews

struct AnimatedProgressRing_Previews: PreviewProvider {
    struct PreviewContent: View {
        // MARK: Internal

        var body: some View {
            ScrollView {
                VStack(spacing: 40) {
                    Text("Enhanced Progress Rings")
                        .font(.title2.bold())
                        .padding()

                    // Standard Progress Ring
                    VStack(spacing: 16) {
                        Text("Standard Progress Ring")
                            .font(.headline)

                        AnimatedProgressRing(
                            progress: self.progress,
                            startColor: .blue,
                            endColor: .purple
                        )
                    }

                    // Interactive Progress Ring
                    VStack(spacing: 16) {
                        Text("Interactive Progress Ring")
                            .font(.headline)

                        AnimatedProgressRing(
                            progress: self.interactiveProgress,
                            size: 120,
                            startColor: .green,
                            endColor: .mint,
                            segmentCount: 4,
                            enableInteraction: true
                        ) { segment in
                            self.selectedSegmentInfo = "Tapped segment \(segment + 1)"
                        }

                        Text(self.selectedSegmentInfo)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Celebration Progress Ring
                    VStack(spacing: 16) {
                        Text("Celebration Progress Ring")
                            .font(.headline)

                        AnimatedProgressRing(
                            progress: self.celebrationProgress,
                            size: 140,
                            startColor: .orange,
                            endColor: .red,
                            showCelebration: true
                        )

                        Button("Complete Goal!") {
                            self.celebrationProgress = 1.0
                        }
                        .disabled(self.celebrationProgress >= 1.0)
                    }

                    SegmentedProgressRing(segments: self.segments)

                    HStack(spacing: 20) {
                        ActivityRing(progress: self.activityProgress, goal: 1.0, color: .red)
                        ActivityRing(progress: 1.3, goal: 1.0, color: .green)
                        ActivityRing(progress: 0.5, goal: 1.0, color: .blue)
                    }

                    VStack(spacing: 16) {
                        Button("Randomize All") {
                            self.progress = Double.random(in: 0...1)
                            self.interactiveProgress = Double.random(in: 0...1)
                            self.celebrationProgress = Double.random(in: 0...0.95)
                            self.activityProgress = Double.random(in: 0...1.5)
                            self.segments = [
                                SegmentedProgressRing.Segment(value: Double.random(in: 0.2...0.4), color: .red),
                                SegmentedProgressRing.Segment(value: Double.random(in: 0.2...0.4), color: .green),
                                SegmentedProgressRing.Segment(value: Double.random(in: 0.1...0.3), color: .blue)
                            ]
                        }

                        Button("Reset Celebration") {
                            self.celebrationProgress = 0.95
                        }
                        .disabled(self.celebrationProgress < 1.0)
                    }
                }
                .padding()
            }
        }

        // MARK: Private

        @State private var progress = 0.75
        @State private var interactiveProgress = 0.5
        @State private var celebrationProgress = 0.95
        @State private var segments = [
            SegmentedProgressRing.Segment(value: 0.3, color: .red, label: "Protein"),
            SegmentedProgressRing.Segment(value: 0.4, color: .green, label: "Carbs"),
            SegmentedProgressRing.Segment(value: 0.2, color: .blue, label: "Fat")
        ]
        @State private var activityProgress = 0.8
        @State private var selectedSegmentInfo = "Tap segments to interact"
    }

    static var previews: some View {
        PreviewContent()
            .theme(DefaultTheme())
    }
}
