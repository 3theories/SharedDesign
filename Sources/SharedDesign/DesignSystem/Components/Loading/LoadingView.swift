import SwiftUI

// MARK: - LoadingView

/// A customizable loading view component
public struct LoadingView: View {
    // MARK: Lifecycle

    // MARK: - Initialization

    public init(
        message: String? = nil,
        style: Style = .circular,
        size: CGFloat = 40,
        context: Context? = nil,
        tint: Color? = nil
    ) {
        self.context = context
        self.message = message ?? context?.message
        self.style = context?.style ?? style
        self.size = size
        self.tint = tint
    }

    // MARK: Public

    // MARK: - Types

    public enum Style {
        case circular
        case linear
        case dots
        case pulse
        case workout // Dumbbell icon animation
        case nutrition // Food icon animation
        case water // Water drop animation
        case ai // Brain/AI animation
    }

    public enum Context {
        case `default`
        case workout
        case nutrition
        case water
        case ai
        case sync

        // MARK: Internal

        var style: Style {
            switch self {
            case .default: .circular
            case .workout: .workout
            case .nutrition: .nutrition
            case .water: .water
            case .ai: .ai
            case .sync: .dots
            }
        }

        var message: String? {
            switch self {
            case .default: nil
            case .workout: String(localized: "Loading workout...", comment: "Loading state message for workout context")
            case .nutrition: String(
                    localized: "Loading nutrition data...",
                    comment: "Loading state message for nutrition context"
                )
            case .water: String(
                    localized: "Loading hydration data...",
                    comment: "Loading state message for water/hydration context"
                )
            case .ai: String(localized: "AI is thinking...", comment: "Loading state message for AI processing")
            case .sync: String(localized: "Syncing...", comment: "Loading state message for data sync")
            }
        }
    }

    // MARK: - Body

    public var body: some View {
        let loaderTint = self.tint ?? self.theme.colors.primary

        VStack(spacing: self.theme.spacing.md) {
            switch self.style {
            case .circular:
                self.circularLoader(tint: loaderTint)
            case .linear:
                linearLoader(tint: loaderTint)
            case .dots:
                dotsLoader(tint: loaderTint)
            case .pulse:
                pulseLoader(tint: loaderTint)
            case .workout:
                workoutLoader(tint: loaderTint)
            case .nutrition:
                nutritionLoader(tint: loaderTint)
            case .water:
                waterLoader(tint: loaderTint)
            case .ai:
                aiLoader(tint: loaderTint)
            }

            if let message {
                Text(message)
                    .font(self.theme.typography.subheadline)
                    .foregroundColor(self.theme.colors.onSurface.opacity(0.6))
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .onAppear {
            self.isAnimating = true
        }
        .onDisappear {
            self.isAnimating = false
        }
    }

    // MARK: - Loader Styles

    // MARK: Private

    @Environment(\.theme) private var theme
    @State private var isAnimating = false

    private let message: String?
    private let style: Style
    private let size: CGFloat
    private let context: Context?
    private let tint: Color?
}

// MARK: - CircularLoaderView

/// Separate view to ensure proper state management
/// Uses TimelineView for reliable animation on all platforms (especially watchOS)
private struct CircularLoaderView: View {
    // MARK: Internal

    let size: CGFloat
    let theme: Theme
    let tint: Color

    var body: some View {
        TimelineView(.animation) { timeline in
            let rotation = self.calculateRotation(for: timeline.date)

            ZStack {
                // Background track
                Circle()
                    .stroke(
                        self.tint.opacity(0.2),
                        lineWidth: self.strokeWidth
                    )

                // Progress arc
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        self.tint,
                        style: StrokeStyle(
                            lineWidth: self.strokeWidth,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(rotation))
            }
            .frame(width: self.size * 0.9, height: self.size * 0.9)
        }
    }

    // MARK: Private

    private let animationDuration: Double = 1.5

    private var strokeWidth: CGFloat {
        #if os(watchOS)
            return 3
        #else
            return 4
        #endif
    }

    private func calculateRotation(for date: Date) -> Double {
        let seconds = date.timeIntervalSinceReferenceDate
        let progress = seconds.truncatingRemainder(dividingBy: self.animationDuration)
        return (progress / self.animationDuration) * 360
    }
}

// MARK: - LinearLoaderView

private struct LinearLoaderView: View {
    // MARK: Internal

    let size: CGFloat
    let theme: Theme
    let tint: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(self.tint.opacity(0.2))
                    .frame(height: 6)

                RoundedRectangle(cornerRadius: 3)
                    .fill(self.tint)
                    .frame(width: geometry.size.width * 0.3, height: 6)
                    .offset(x: self.offset)
                    .onAppear {
                        withAnimation(
                            .linear(duration: 1.5)
                                .repeatForever(autoreverses: false)
                        ) {
                            self.offset = geometry.size.width * 0.7
                        }
                    }
            }
        }
        .frame(width: self.size * 3, height: 6)
    }

    // MARK: Private

    @State private var offset: CGFloat = 0
}

// MARK: - DotsLoaderView

private struct DotsLoaderView: View {
    // MARK: Internal

    let size: CGFloat
    let theme: Theme
    let tint: Color

    var body: some View {
        HStack(spacing: self.size / 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(self.tint)
                    .frame(width: self.size / 4, height: self.size / 4)
                    .scaleEffect(self.scale[index])
                    .opacity(self.opacity[index])
                    .onAppear {
                        self.animateDot(at: index)
                    }
            }
        }
    }

    // MARK: Private

    @State private var scale: [CGFloat] = [0.5, 0.5, 0.5]
    @State private var opacity: [Double] = [0.3, 0.3, 0.3]

    private func animateDot(at index: Int) {
        withAnimation(
            .easeInOut(duration: 0.6)
                .repeatForever()
                .delay(Double(index) * 0.2)
        ) {
            self.scale[index] = 1.0
            self.opacity[index] = 1.0
        }
    }
}

// MARK: - PulseLoaderView

private struct PulseLoaderView: View {
    // MARK: Internal

    let size: CGFloat
    let theme: Theme
    let tint: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(self.tint.opacity(0.2))
                .frame(width: self.size, height: self.size)
                .scaleEffect(self.scale)
                .opacity(self.opacity)
                .onAppear {
                    withAnimation(
                        .easeOut(duration: 1.0)
                            .repeatForever(autoreverses: false)
                    ) {
                        self.scale = 1.5
                        self.opacity = 0
                    }
                }

            Circle()
                .fill(self.tint)
                .frame(width: self.size * 0.6, height: self.size * 0.6)
        }
    }

    // MARK: Private

    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
}

extension LoadingView {
    private func circularLoader(tint: Color) -> some View {
        CircularLoaderView(size: self.size, theme: self.theme, tint: tint)
    }

    private func linearLoader(tint: Color) -> some View {
        LinearLoaderView(size: self.size, theme: self.theme, tint: tint)
    }

    private func dotsLoader(tint: Color) -> some View {
        DotsLoaderView(size: self.size, theme: self.theme, tint: tint)
    }

    private func pulseLoader(tint: Color) -> some View {
        PulseLoaderView(size: self.size, theme: self.theme, tint: tint)
    }

    private func workoutLoader(tint: Color) -> some View {
        WorkoutLoaderView(size: self.size, theme: self.theme, tint: tint)
    }

    private func nutritionLoader(tint: Color) -> some View {
        NutritionLoaderView(size: self.size, theme: self.theme, tint: tint)
    }

    private func waterLoader(tint: Color) -> some View {
        WaterLoaderView(size: self.size, theme: self.theme, tint: tint)
    }

    private func aiLoader(tint: Color) -> some View {
        AILoaderView(size: self.size, theme: self.theme, tint: tint)
    }
}

// MARK: - WorkoutLoaderView

private struct WorkoutLoaderView: View {
    // MARK: Internal

    let size: CGFloat
    let theme: Theme
    let tint: Color

    var body: some View {
        Image("dumbell").resizable().aspectRatio(contentMode: .fit).frame(width: 16, height: 16)
            .foregroundStyle(self.tint)
            .rotationEffect(.degrees(self.rotation))
            .scaleEffect(self.scale)
            .accessibilityHidden(true)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true)
                ) {
                    self.rotation = 15
                    self.scale = 1.1
                }
            }
    }

    // MARK: Private

    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
}

// MARK: - NutritionLoaderView

private struct NutritionLoaderView: View {
    // MARK: Internal

    let size: CGFloat
    let theme: Theme
    let tint: Color

    var body: some View {
        Image("serving")
            .resizable().aspectRatio(contentMode: .fit)
            .frame(width: self.size * 0.7, height: self.size * 0.7)
            .foregroundStyle(self.tint)
            .offset(y: self.bounce)
            .accessibilityHidden(true)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true)
                ) {
                    self.bounce = -10
                }
            }
    }

    // MARK: Private

    @State private var bounce: CGFloat = 0
}

// MARK: - WaterLoaderView

private struct WaterLoaderView: View {
    // MARK: Internal

    let size: CGFloat
    let theme: Theme
    let tint: Color

    var body: some View {
        ZStack {
            Image("waterdrop")
                .resizable().aspectRatio(contentMode: .fit)
                .frame(width: self.size * 0.8, height: self.size * 0.8)
                .foregroundStyle(self.tint.opacity(0.3))
                .accessibilityHidden(true)

            Image("waterdrop")
                .resizable().aspectRatio(contentMode: .fit)
                .frame(width: self.size * 0.8, height: self.size * 0.8)
                .foregroundStyle(self.tint)
                .mask(
                    Rectangle()
                        .frame(height: self.size * self.fillLevel)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: self.fillLevel)
                )
                .rotationEffect(.degrees(self.rotation))
                .accessibilityHidden(true)
        }
        .onAppear {
            self.fillLevel = 1.0
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                self.rotation = 360
            }
        }
    }

    // MARK: Private

    @State private var fillLevel: CGFloat = 0.2
    @State private var rotation: Double = 0
}

// MARK: - AILoaderView

private struct AILoaderView: View {
    // MARK: Internal

    let size: CGFloat
    let theme: Theme
    let tint: Color

    var body: some View {
        ZStack {
            ForEach(0..<3) { index in
                let ringGradient = LinearGradient(
                    colors: [self.tint, self.tint.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                let ringSize = self.size * (0.6 + CGFloat(index) * 0.2)
                let rotationDegrees = self.phase * Double(index + 1) * 30

                Circle()
                    .stroke(ringGradient, lineWidth: 2)
                    .frame(width: ringSize, height: ringSize)
                    .rotationEffect(.degrees(rotationDegrees))
                    .opacity(self.opacity)
            }

            Image(systemName: "brain")
                .font(.system(size: self.size * 0.4))
                .foregroundStyle(self.tint)
                .scaleEffect(self.opacity == 1.0 ? 1.1 : 1.0)
                .accessibilityHidden(true)
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                self.phase = 1
            }
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                self.opacity = 1.0
            }
        }
    }

    // MARK: Private

    @State private var phase: CGFloat = 0
    @State private var opacity: Double = 0.3
}

// MARK: - LoadingOverlay

/// A full-screen loading overlay
public struct LoadingOverlay: View {
    // MARK: Lifecycle

    public init(isLoading: Bool, message: String? = nil) {
        self.isLoading = isLoading
        self.message = message
    }

    // MARK: Public

    public var body: some View {
        if self.isLoading {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                Card(backgroundColor: self.theme.colors.surface3) {
                    LoadingView(message: self.message)
                        .padding(self.theme.spacing.md)
                }
                .fixedSize()
            }
            .transition(.opacity)
        }
    }

    // MARK: Private

    @Environment(\.theme) private var theme

    private let isLoading: Bool
    private let message: String?
}

// MARK: - View Extension

extension View {
    /// Add a loading overlay to any view
    public func loadingOverlay(isLoading: Bool, message: String? = nil) -> some View {
        overlay(LoadingOverlay(isLoading: isLoading, message: message))
    }
}

// MARK: - LoadingView_Previews

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 40) {
                // Basic styles
                LoadingView(message: "Loading...", style: .circular)

                LoadingView(style: .linear)

                LoadingView(style: .dots)

                LoadingView(style: .pulse)

                Divider()

                // Context-aware loaders
                LoadingView(context: .workout)

                LoadingView(context: .nutrition)

                LoadingView(context: .water)

                LoadingView(context: .ai)

                LoadingView(context: .sync)

                LoadingView(
                    message: "Custom message",
                    style: .circular,
                    size: 60
                )
            }
            .padding()
        }
        .environment(\.theme, DefaultTheme())
    }
}
