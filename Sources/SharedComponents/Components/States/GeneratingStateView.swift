import SwiftUI

// MARK: - GeneratingContext

/// Context types for AI/LLM generation states
public enum GeneratingContext: Sendable {
    /// AI-generated summary or insight
    case aiSummary

    /// Meal plan generation
    case mealPlan

    /// Workout plan generation
    case workout

    /// Recipe generation or suggestion
    case recipe

    /// General AI processing
    case general

    /// Custom context with specific messaging
    case custom(icon: String, title: String, message: String)

    // MARK: Internal

    var icon: String {
        switch self {
        case .aiSummary: "brain.head.profile"
        case .mealPlan: "mealPrep"
        case .workout: "liftWeight"
        case .recipe: "book.closed"
        case .general: "sparkles"
        case let .custom(icon, _, _): icon
        }
    }

    var isSystemIcon: Bool {
        switch self {
        case .workout, .mealPlan: false
        case .aiSummary, .recipe, .general, .custom: true
        }
    }

    var title: String {
        switch self {
        case .aiSummary: String(localized: "Generating Insights", comment: "AI summary generation title")
        case .mealPlan: String(localized: "Creating Your Meal Plan", comment: "Meal plan generation title")
        case .workout: String(localized: "Building Your Workout", comment: "Workout generation title")
        case .recipe: String(localized: "Finding Perfect Recipes", comment: "Recipe search generation title")
        case .general: String(localized: "Processing", comment: "General processing title")
        case let .custom(_, title, _): title
        }
    }

    var message: String {
        switch self {
        case .aiSummary: String(
                localized: "Analyzing your data to provide personalized insights...",
                comment: "AI summary generation message"
            )
        case .mealPlan: String(
                localized: "Crafting a balanced meal plan tailored to your goals...",
                comment: "Meal plan generation message"
            )
        case .workout: String(
                localized: "Designing an effective workout based on your preferences...",
                comment: "Workout generation message"
            )
        case .recipe: String(
                localized: "Searching for recipes that match your dietary needs...",
                comment: "Recipe search generation message"
            )
        case .general: String(
                localized: "Please wait while we process your request...",
                comment: "General processing message"
            )
        case let .custom(_, _, message): message
        }
    }

    var accentColor: Color {
        switch self {
        case .aiSummary: ColorPalette.Brand.primary
        case .mealPlan: ColorPalette.NutritionCategories.carbs
        case .workout: ColorPalette.Fitness.calories
        case .recipe: ColorPalette.NutritionCategories.protein
        case .general: ColorPalette.Brand.secondary
        case .custom: ColorPalette.Brand.primary
        }
    }
}

// MARK: - GeneratingStyle

/// Visual style for the generating state view
public enum GeneratingStyle: Sendable {
    /// Full screen centered display
    case fullScreen

    /// Inline display within content
    case inline

    /// Card-style with background
    case card

    /// Compact indicator
    case compact

    /// Overlay on existing content
    case overlay
}

// MARK: - GeneratingStateView

/// A component for displaying AI/LLM processing states with animations
public struct GeneratingStateView: View {
    // MARK: Lifecycle

    // MARK: - Initialization

    public init(
        context: GeneratingContext,
        style: GeneratingStyle = .fullScreen,
        progress: Double? = nil,
        tips: [String] = [],
        onCancel: (() -> Void)? = nil
    ) {
        self.context = context
        self.style = style
        self.progress = progress
        self.tips = tips
        self.onCancel = onCancel
    }

    // MARK: Public

    // MARK: - Body

    public var body: some View {
        Group {
            switch self.style {
            case .fullScreen:
                self.fullScreenContent
            case .inline:
                self.inlineContent
            case .card:
                self.cardContent
            case .compact:
                self.compactContent
            case .overlay:
                self.overlayContent
            }
        }
        .onAppear {
            self.startAnimations()
        }
    }

    // MARK: Private

    @Environment(\.theme) private var theme
    @State private var iconRotation: Double = 0
    @State private var iconScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.3
    @State private var textOpacity: Double = 0
    @State private var currentTipIndex: Int = 0
    @State private var tipOpacity: Double = 1.0

    private let context: GeneratingContext
    private let style: GeneratingStyle
    private let progress: Double?
    private let onCancel: (() -> Void)?
    private let tips: [String]

    // MARK: - Full Screen Style

    private var fullScreenContent: some View {
        VStack(spacing: self.theme.spacing.xl) {
            Spacer()

            self.animatedIconView

            VStack(spacing: self.theme.spacing.md) {
                Text(self.context.title)
                    .font(self.theme.typography.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(self.theme.colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(self.context.message)
                    .font(self.theme.typography.body)
                    .foregroundStyle(self.theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .opacity(self.textOpacity)
            .padding(.horizontal, self.theme.spacing.xl)

            if let progress {
                self.progressBar(progress)
                    .padding(.horizontal, self.theme.spacing.xl)
            }

            if !self.tips.isEmpty {
                self.tipView
                    .padding(.horizontal, self.theme.spacing.xl)
            }

            Spacer()

            if let onCancel {
                self.cancelButton(action: onCancel)
                    .padding(.bottom, self.theme.spacing.xl)
            }
        }
        .frame(maxWidth: 400)
    }

    // MARK: - Inline Style

    private var inlineContent: some View {
        VStack(spacing: self.theme.spacing.lg) {
            self.animatedIconView

            VStack(spacing: self.theme.spacing.sm) {
                Text(self.context.title)
                    .font(self.theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(self.theme.colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(self.context.message)
                    .font(self.theme.typography.subheadline)
                    .foregroundStyle(self.theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(self.textOpacity)

            if let progress {
                self.progressBar(progress)
            }
        }
        .padding(self.theme.spacing.lg)
    }

    // MARK: - Card Style

    private var cardContent: some View {
        VStack(spacing: self.theme.spacing.md) {
            HStack(spacing: self.theme.spacing.md) {
                self.smallAnimatedIcon

                VStack(alignment: .leading, spacing: self.theme.spacing.xxs) {
                    Text(self.context.title)
                        .font(self.theme.typography.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(self.theme.colors.textPrimary)

                    Text(self.context.message)
                        .font(self.theme.typography.subheadline)
                        .foregroundStyle(self.theme.colors.textSecondary)
                        .lineLimit(2)
                }
                .opacity(self.textOpacity)

                Spacer()

                if let onCancel {
                    Button {
                        HapticManager.shared.trigger(.light)
                        onCancel()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(self.theme.colors.textTertiary)
                    }
                }
            }

            if let progress {
                self.progressBar(progress)
            }
        }
        .padding(self.theme.spacing.md)
        .background(self.theme.colors.surface1)
        .clipShape(RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.medium))
    }

    // MARK: - Compact Style

    private var compactContent: some View {
        HStack(spacing: self.theme.spacing.sm) {
            self.tinyAnimatedIcon

            Text(self.context.title)
                .font(self.theme.typography.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(self.theme.colors.textPrimary)

            if let progress {
                Text(verbatim: "\(Int(progress * 100))%")
                    .font(self.theme.typography.caption1)
                    .foregroundStyle(self.context.accentColor)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, self.theme.spacing.md)
        .padding(.vertical, self.theme.spacing.sm)
        .background(self.context.accentColor.opacity(0.1))
        .clipShape(Capsule())
    }

    // MARK: - Overlay Style

    private var overlayContent: some View {
        ZStack {
            // Background blur
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: self.theme.spacing.lg) {
                self.animatedIconView

                VStack(spacing: self.theme.spacing.sm) {
                    Text(self.context.title)
                        .font(self.theme.typography.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(self.theme.colors.textPrimary)

                    Text(self.context.message)
                        .font(self.theme.typography.body)
                        .foregroundStyle(self.theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(self.textOpacity)
                .padding(.horizontal, self.theme.spacing.xl)

                if let progress {
                    self.progressBar(progress)
                        .padding(.horizontal, self.theme.spacing.xl)
                }

                if let onCancel {
                    self.cancelButton(action: onCancel)
                }
            }
            .padding(self.theme.spacing.xl)
            .background(self.theme.colors.surface1)
            .clipShape(RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.large))
            .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
            .padding(self.theme.spacing.xl)
        }
    }

    // MARK: - Animated Icon Views

    private var animatedIconView: some View {
        ZStack {
            // Outer pulse rings
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(self.context.accentColor.opacity(0.2 - Double(index) * 0.05), lineWidth: 2)
                    .frame(width: 100 + CGFloat(index) * 30, height: 100 + CGFloat(index) * 30)
                    .opacity(self.pulseOpacity)
            }

            // Inner glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            self.context.accentColor.opacity(0.3),
                            self.context.accentColor.opacity(0.0)
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
                .scaleEffect(self.iconScale)

            // Icon background
            Circle()
                .fill(self.context.accentColor.opacity(0.15))
                .frame(width: 80, height: 80)

            // Main icon
            AppIconView(name: self.context.icon, isSystemIcon: self.context.isSystemIcon)
                .font(.system(size: 36, weight: .medium))
                .frame(width: 36, height: 36)
                .foregroundStyle(self.context.accentColor)
        }
    }

    private var smallAnimatedIcon: some View {
        ZStack {
            Circle()
                .fill(self.context.accentColor.opacity(0.15))
                .frame(width: 48, height: 48)

            AppIconView(name: self.context.icon, isSystemIcon: self.context.isSystemIcon)
                .font(.system(size: 20, weight: .medium))
                .frame(width: 20, height: 20)
                .foregroundStyle(self.context.accentColor)
        }
    }

    private var tinyAnimatedIcon: some View {
        ZStack {
            Circle()
                .fill(self.context.accentColor.opacity(0.15))
                .frame(width: 28, height: 28)

            AppIconView(name: self.context.icon, isSystemIcon: self.context.isSystemIcon)
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 12, height: 12)
                .foregroundStyle(self.context.accentColor)
                .symbolEffect(.pulse, options: .repeating)
        }
    }

    // MARK: - Tip View

    private var tipView: some View {
        VStack(spacing: self.theme.spacing.xs) {
            HStack(spacing: self.theme.spacing.xs) {
                Image("tips")
                    .resizable().aspectRatio(contentMode: .fit)
                    .frame(width: 12, height: 12)
                    .foregroundStyle(ColorPalette.Semantic.warning)

                Text(L10n.string("generating_state.tip_label"))
                    .font(self.theme.typography.caption1)
                    .fontWeight(.semibold)
                    .foregroundStyle(self.theme.colors.textSecondary)
            }

            Text(self.tips[self.currentTipIndex])
                .font(self.theme.typography.subheadline)
                .foregroundStyle(self.theme.colors.textSecondary)
                .multilineTextAlignment(.center)
                .opacity(self.tipOpacity)
                .animation(.easeInOut(duration: 0.5), value: self.tipOpacity)
        }
        .padding(self.theme.spacing.md)
        .background(ColorPalette.Semantic.warning.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.small))
        .onAppear {
            self.startTipRotation()
        }
    }

    // MARK: - Progress Bar

    private func progressBar(_ progress: Double) -> some View {
        VStack(spacing: self.theme.spacing.xs) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(self.theme.colors.surface3)
                        .frame(height: 8)

                    // Progress fill with gradient
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [
                                    self.context.accentColor,
                                    self.context.accentColor.opacity(0.7)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * min(progress, 1.0), height: 8)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 8)

            // Percentage text
            HStack {
                Spacer()
                Text(verbatim: "\(Int(progress * 100))%")
                    .font(self.theme.typography.caption1)
                    .foregroundStyle(self.theme.colors.textTertiary)
                    .monospacedDigit()
            }
        }
    }

    // MARK: - Cancel Button

    private func cancelButton(action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.shared.trigger(.medium)
            action()
        } label: {
            Text(L10n.string("common.action.cancel"))
                .font(self.theme.typography.body)
                .fontWeight(.medium)
                .foregroundStyle(self.theme.colors.textSecondary)
                .padding(.horizontal, self.theme.spacing.xl)
                .padding(.vertical, self.theme.spacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Animations

    private func startAnimations() {
        // Text fade in
        withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
            self.textOpacity = 1.0
        }

        // Pulse animation
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            self.pulseOpacity = 0.8
        }

        // Icon scale animation
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            self.iconScale = 1.1
        }
    }

    private func startTipRotation() {
        guard self.tips.count > 1 else {
            return
        }

        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            withAnimation {
                self.tipOpacity = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.currentTipIndex = (self.currentTipIndex + 1) % self.tips.count
                withAnimation {
                    self.tipOpacity = 1
                }
            }
        }
    }
}

// MARK: - Convenience Initializers

extension GeneratingStateView {
    /// AI summary/insight generation
    public static func aiSummary(
        progress: Double? = nil,
        onCancel: (() -> Void)? = nil
    ) -> GeneratingStateView {
        GeneratingStateView(
            context: .aiSummary,
            progress: progress,
            tips: [
                String(localized: "AI analyzes patterns in your recent activity", comment: "AI generation tip"),
                String(localized: "Insights are personalized to your goals", comment: "AI generation tip"),
                String(localized: "The more data you track, the better the insights", comment: "AI generation tip")
            ],
            onCancel: onCancel
        )
    }

    /// Meal plan generation
    public static func mealPlan(
        progress: Double? = nil,
        onCancel: (() -> Void)? = nil
    ) -> GeneratingStateView {
        GeneratingStateView(
            context: .mealPlan,
            progress: progress,
            tips: [
                String(localized: "Your dietary preferences are being considered", comment: "Meal plan generation tip"),
                String(localized: "Calorie and macro targets are factored in", comment: "Meal plan generation tip"),
                String(
                    localized: "Recipes are selected based on your cuisine preferences",
                    comment: "Meal plan generation tip"
                )
            ],
            onCancel: onCancel
        )
    }

    /// Workout generation
    public static func workout(
        progress: Double? = nil,
        onCancel: (() -> Void)? = nil
    ) -> GeneratingStateView {
        GeneratingStateView(
            context: .workout,
            progress: progress,
            tips: [
                String(localized: "Your fitness level is being considered", comment: "Workout generation tip"),
                String(localized: "Rest times are optimized for your goals", comment: "Workout generation tip"),
                String(localized: "Progressive overload is built into your plan", comment: "Workout generation tip")
            ],
            onCancel: onCancel
        )
    }

    /// Recipe suggestions
    public static func recipe(
        progress: Double? = nil,
        onCancel: (() -> Void)? = nil
    ) -> GeneratingStateView {
        GeneratingStateView(
            context: .recipe,
            progress: progress,
            tips: [
                String(localized: "Matching your available ingredients", comment: "Recipe generation tip"),
                String(localized: "Considering your dietary restrictions", comment: "Recipe generation tip"),
                String(localized: "Finding recipes that fit your schedule", comment: "Recipe generation tip")
            ],
            onCancel: onCancel
        )
    }

    /// Compact inline indicator
    public static func compactIndicator(
        context: GeneratingContext,
        progress: Double? = nil
    ) -> GeneratingStateView {
        GeneratingStateView(
            context: context,
            style: .compact,
            progress: progress
        )
    }

    /// Card-style generating indicator
    public static func card(
        context: GeneratingContext,
        progress: Double? = nil,
        onCancel: (() -> Void)? = nil
    ) -> GeneratingStateView {
        GeneratingStateView(
            context: context,
            style: .card,
            progress: progress,
            onCancel: onCancel
        )
    }

    /// Overlay generating indicator
    public static func overlay(
        context: GeneratingContext,
        progress: Double? = nil,
        onCancel: (() -> Void)? = nil
    ) -> GeneratingStateView {
        GeneratingStateView(
            context: context,
            style: .overlay,
            progress: progress,
            onCancel: onCancel
        )
    }
}

// MARK: - Preview

#Preview("GeneratingStateView Styles") {
    ScrollView {
        VStack(spacing: 40) {
            Text("GeneratingStateView Styles")
                .font(.title2.bold())

            // Full Screen
            VStack(alignment: .leading, spacing: 8) {
                Text("Full Screen (AI Summary)").font(.headline)
                GeneratingStateView.aiSummary(progress: 0.65) {
                    print("Cancelled")
                }
                .frame(height: 400)
                #if os(iOS)
                    .background(Color(.systemGroupedBackground))
                #else
                    .background(Color.gray.opacity(0.1))
                #endif
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Divider()

            // Card Style
            VStack(alignment: .leading, spacing: 8) {
                Text("Card Style").font(.headline)
                GeneratingStateView.card(context: .mealPlan, progress: 0.3) {
                    print("Cancelled")
                }
            }

            Divider()

            // Compact Style
            VStack(alignment: .leading, spacing: 8) {
                Text("Compact Style").font(.headline)
                HStack(spacing: 12) {
                    GeneratingStateView.compactIndicator(context: .workout)
                    GeneratingStateView.compactIndicator(context: .recipe, progress: 0.45)
                }
            }

            Divider()

            // Inline Style
            VStack(alignment: .leading, spacing: 8) {
                Text("Inline Style").font(.headline)
                GeneratingStateView(context: .workout, style: .inline, progress: 0.8)
                #if os(iOS)
                    .background(Color(.systemGroupedBackground))
                #else
                    .background(Color.gray.opacity(0.1))
                #endif
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Divider()

            // Custom Context
            VStack(alignment: .leading, spacing: 8) {
                Text("Custom Context").font(.headline)
                GeneratingStateView(
                    context: .custom(
                        icon: "wand.and.stars",
                        title: "Optimizing Your Profile",
                        message: "Fine-tuning recommendations based on your activity..."
                    ),
                    style: .card,
                    progress: 0.5
                )
            }
        }
        .padding()
    }
    .environment(\.theme, DefaultTheme())
}

#Preview("Overlay Style") {
    ZStack {
        // Background content
        VStack {
            Text("Content Behind")
                .font(.largeTitle)
            Text("The overlay appears on top")
        }

        GeneratingStateView.overlay(context: .aiSummary, progress: 0.4) {
            print("Cancelled")
        }
    }
    .environment(\.theme, DefaultTheme())
}
