import SwiftUI

// MARK: - ThemePreview

/// A comprehensive preview of all design system components
public struct ThemePreview: View {
    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public var body: some View {
        TabView(selection: self.$selectedTab) {
            ColorPreview()
                .tabItem {
                    Label("Colors", systemImage: "paintpalette")
                }
                .tag(0)

            TypographyPreview()
                .tabItem {
                    Label("Typography", systemImage: "textformat")
                }
                .tag(1)

            ComponentsPreview()
                .tabItem {
                    Label("Components", systemImage: "square.grid.2x2")
                }
                .tag(2)

            SpacingPreview()
                .tabItem {
                    Label("Spacing", systemImage: "ruler")
                }
                .tag(3)

            EffectsPreview()
                .tabItem {
                    Label { Text("Effects") } icon: {
                        Image("aiSummary").resizable().aspectRatio(contentMode: .fit).frame(width: 16, height: 16)
                    }
                }
                .tag(4)

            GradientsPreview()
                .tabItem {
                    Label("Gradients", systemImage: "rectangle.righthalf.inset.filled")
                }
                .tag(5)
        }
        .environment(\.theme, DefaultTheme(colorScheme: self.colorScheme))
    }

    // MARK: Private

    @State private var selectedTab = 0
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var colorScheme
}

// MARK: - ColorPreview

struct ColorPreview: View {
    // MARK: Internal

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Colors")
                    .font(.largeTitle.bold())
                    .padding(.horizontal)

                // Primary colors
                ColorSection(title: "Primary Colors", colors: [
                    ("Primary", self.theme.colors.primary),
                    ("Secondary", self.theme.colors.secondary),
                    ("Tertiary", self.theme.colors.tertiary)
                ])

                // Surface colors with new levels
                ColorSection(title: "Surface Colors", colors: [
                    ("Background", self.theme.colors.background),
                    ("Surface0", self.theme.colors.surface0),
                    ("Surface1", self.theme.colors.surface1),
                    ("Surface2", self.theme.colors.surface2),
                    ("Surface3", self.theme.colors.surface3),
                    ("Surface4", self.theme.colors.surface4),
                    ("Surface5", self.theme.colors.surface5)
                ])

                // System surfaces
                ColorSection(title: "System Surfaces", colors: [
                    ("Grouped", self.theme.colors.systemGroupedBackground),
                    ("Secondary", self.theme.colors.systemSecondaryBackground),
                    ("Tertiary", self.theme.colors.systemTertiaryBackground)
                ])

                // Fill colors
                ColorSection(title: "Fill Colors", colors: [
                    ("Primary", self.theme.colors.fillPrimary),
                    ("Secondary", self.theme.colors.fillSecondary),
                    ("Tertiary", self.theme.colors.fillTertiary),
                    ("Quaternary", self.theme.colors.fillQuaternary)
                ])

                // Semantic colors
                ColorSection(title: "Semantic Colors", colors: [
                    ("Success", self.theme.colors.success),
                    ("Warning", self.theme.colors.warning),
                    ("Error", self.theme.colors.error),
                    ("Info", self.theme.colors.info)
                ])

                // Text colors
                ColorSection(title: "Text Colors", colors: [
                    ("Primary", self.theme.colors.textPrimary),
                    ("Secondary", self.theme.colors.textSecondary),
                    ("Tertiary", self.theme.colors.textTertiary),
                    ("Disabled", self.theme.colors.textDisabled),
                    ("Inverse", self.theme.colors.textInverse)
                ])

                // Border colors
                ColorSection(title: "Border Colors", colors: [
                    ("Primary", self.theme.colors.borderPrimary),
                    ("Secondary", self.theme.colors.borderSecondary),
                    ("Tertiary", self.theme.colors.borderTertiary),
                    ("Focus", self.theme.colors.borderFocus),
                    ("Error", self.theme.colors.borderError)
                ])

                // Feature colors
                VStack(alignment: .leading, spacing: 16) {
                    Text("Feature Colors")
                        .font(.headline)
                        .padding(.horizontal)

                    // Nutrition colors
                    ColorSection(title: "Macronutrients", colors: [
                        ("Protein", ColorPalette.Nutrition.protein),
                        ("Carbs", ColorPalette.Nutrition.carbs),
                        ("Fat", ColorPalette.Nutrition.fat),
                        ("Fiber", ColorPalette.Nutrition.fiber)
                    ])

                    // Fitness metrics
                    ColorSection(title: "Fitness Metrics", colors: [
                        ("Heart Rate", ColorPalette.Fitness.heartRate),
                        ("Calories", ColorPalette.Fitness.calories),
                        ("Steps", ColorPalette.Fitness.steps),
                        ("Distance", ColorPalette.Fitness.distance)
                    ])
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - ColorSection

struct ColorSection: View {
    let title: String
    let colors: [(String, Color)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(self.title)
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(self.colors, id: \.0) { name, color in
                        ColorCard(name: name, color: color)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - ColorCard

struct ColorCard: View {
    // MARK: Internal

    let name: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(self.color)
                .frame(width: 100, height: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(self.theme.colors.borderSecondary, lineWidth: 1)
                )

            Text(self.name)
                .font(.caption)
                .foregroundColor(self.theme.colors.textSecondary)
        }
    }

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - TypographyPreview

struct TypographyPreview: View {
    @Environment(\.theme) private var theme

    let sampleText = "The quick brown fox jumps over the lazy dog"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                Text("Typography")
                    .font(.largeTitle.bold())
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 20) {
                    TypeRow(name: "Large Title", font: self.theme.typography.largeTitle)
                    TypeRow(name: "Title 1", font: self.theme.typography.title1)
                    TypeRow(name: "Title 2", font: self.theme.typography.title2)
                    TypeRow(name: "Title 3", font: self.theme.typography.title3)
                    TypeRow(name: "Headline", font: self.theme.typography.headline)
                    TypeRow(name: "Body", font: self.theme.typography.body)
                    TypeRow(name: "Callout", font: self.theme.typography.callout)
                    TypeRow(name: "Subheadline", font: self.theme.typography.subheadline)
                    TypeRow(name: "Footnote", font: self.theme.typography.footnote)
                    TypeRow(name: "Caption 1", font: self.theme.typography.caption1)
                    TypeRow(name: "Caption 2", font: self.theme.typography.caption2)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

// MARK: - TypeRow

struct TypeRow: View {
    let name: String
    let font: Font
    let sampleText = "The quick brown fox"

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(self.name)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(self.sampleText)
                .font(self.font)
        }
    }
}

// MARK: - ComponentsPreview

struct ComponentsPreview: View {
    // MARK: Internal

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Text("Components")
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Buttons
                VStack(alignment: .leading, spacing: 16) {
                    Text("Buttons")
                        .font(.headline)

                    SharedButton("Primary Button", style: .primary) { }
                    SharedButton("Secondary Button", style: .secondary) { }
                    SharedButton("Tertiary Button", style: .tertiary) { }
                    SharedButton("Destructive Button", style: .destructive) { }

                    HStack {
                        SharedButton("Small", size: .small) { }
                        SharedButton("Medium", size: .medium) { }
                        SharedButton("Large", size: .large) { }
                    }

                    SharedButton("Loading", isLoading: true) { }
                    SharedButton("Disabled", isEnabled: false) { }
                }

                Divider()

                // Icon Buttons
                VStack(alignment: .leading, spacing: 16) {
                    Text("Icon Buttons")
                        .font(.headline)

                    HStack(spacing: 16) {
                        IconButton(icon: "heart", style: .filled) { }
                        IconButton(icon: "star", style: .tinted) { }
                        IconButton(icon: "bell", style: .ghost) { }
                        IconButton(icon: "trash", style: .filled, color: \.error) { }
                    }
                }

                Divider()

                // Circular Icon Buttons
                VStack(alignment: .leading, spacing: 16) {
                    Text("Circular Icon Buttons")
                        .font(.headline)

                    HStack(spacing: 16) {
                        CircularIconButton.checkmark { }
                        CircularIconButton.close { }
                        CircularIconButton.edit { }
                        CircularIconButton(icon: "plus", color: .orange) { }
                    }
                }

                Divider()

                // Action Buttons
                VStack(alignment: .leading, spacing: 16) {
                    Text("Action Buttons")
                        .font(.headline)

                    ActionButton("Start Workout", icon: "play.fill") { }
                    ActionButton("Schedule", icon: "calendar", style: .secondary) { }
                    ActionButton("Complete", icon: "checkmark", style: .success) { }
                        .withShadow()
                    ActionButton("Delete", icon: "trash", style: .danger, size: .small) { }
                }

                Divider()

                // Button Styles
                VStack(alignment: .leading, spacing: 16) {
                    Text("Button Styles")
                        .font(.headline)

                    Button("Rounded Style Button") { }
                        .roundedStyle(backgroundColor: self.theme.colors.primary, height: 44)

                    HStack {
                        Button("Pill Style") { }
                            .pillStyle(backgroundColor: .green)
                        Button("Another Pill") { }
                            .pillStyle(backgroundColor: .blue)
                    }

                    Button(action: { }) {
                        Image(systemName: "plus")
                    }
                    .floatingActionStyle()
                }

                Divider()

                // Cards
                VStack(alignment: .leading, spacing: 16) {
                    Text("Cards")
                        .font(.headline)

                    Card {
                        Text("Basic Card")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Card(backgroundColor: self.theme.colors.surface2) {
                        Text("Custom Background Card")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Card(padding: self.theme.spacing.lg, cornerRadius: self.theme.sizing.cornerRadius.large) {
                        VStack(alignment: .leading, spacing: self.theme.spacing.sm) {
                            Text("Card with Custom Styling")
                                .font(.headline)
                            Text("This card has custom padding and corner radius")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                Divider()

                // Loading States
                VStack(alignment: .leading, spacing: 16) {
                    Text("Loading States")
                        .font(.headline)

                    HStack(spacing: 32) {
                        LoadingView(style: .circular)
                        LoadingView(style: .dots)
                        LoadingView(style: .pulse)
                    }

                    LoadingView(message: "Loading data...", style: .linear)
                }

                Divider()

                // Shimmer Effects
                VStack(alignment: .leading, spacing: 16) {
                    Text("Shimmer Effects")
                        .font(.headline)

                    // Card with shimmer
                    Card {
                        VStack(alignment: .leading, spacing: 12) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 20)
                                .frame(maxWidth: 200)
                                .shimmer()

                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 16)
                                .shimmer()

                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 16)
                                .frame(maxWidth: 150)
                                .shimmer()
                        }
                    }
                }

                Divider()

                // Empty States
                VStack(alignment: .leading, spacing: 16) {
                    Text("Empty States")
                        .font(.headline)

                    EmptyStateView.noData(
                        title: "No Workouts",
                        message: "Start your fitness journey by creating your first workout.",
                        actionTitle: "Create Workout"
                    ) {
                        print("Create workout tapped")
                    }
                }

                Divider()

                // Error States
                VStack(alignment: .leading, spacing: 16) {
                    Text("Error States")
                        .font(.headline)

                    // Error view
                    ErrorStateView(
                        title: "Unable to Load",
                        message: "There was a problem loading your data. Please try again."
                    )
                    .background(self.theme.colors.surface1)
                    .cornerRadius(self.theme.sizing.cornerRadius.medium)
                }

                #if !os(watchOS)
                    Divider()

                    // Toast Notifications
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Toast Notifications")
                            .font(.headline)

                        VStack(spacing: 12) {
                            Toast(message: "Success! Your changes have been saved.", type: .success)
                            Toast(message: "Warning: Low storage space", type: .warning)
                            Toast(message: "Error: Unable to connect", type: .error)
                            Toast(message: "New update available", type: .info)
                        }
                    }
                #endif
            }
            .padding()
        }
    }

    // MARK: Private

    @State private var isLoading = false
    @State private var showingSheet = false
    @Environment(\.theme) private var theme
}

// MARK: - SpacingPreview

struct SpacingPreview: View {
    // MARK: Internal

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                Text("Spacing")
                    .font(.largeTitle.bold())
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 24) {
                    SpacingRow(name: "XXS", value: self.theme.spacing.xxs)
                    SpacingRow(name: "XS", value: self.theme.spacing.xs)
                    SpacingRow(name: "SM", value: self.theme.spacing.sm)
                    SpacingRow(name: "MD", value: self.theme.spacing.md)
                    SpacingRow(name: "LG", value: self.theme.spacing.lg)
                    SpacingRow(name: "XL", value: self.theme.spacing.xl)
                    SpacingRow(name: "XXL", value: self.theme.spacing.xxl)
                    SpacingRow(name: "XXXL", value: self.theme.spacing.xxxl)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - SpacingRow

struct SpacingRow: View {
    // MARK: Internal

    let name: String
    let value: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(self.name): \(Int(self.value))pt")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 0) {
                Rectangle()
                    .fill(self.theme.colors.primary)
                    .frame(width: self.value, height: 32)

                Spacer()
            }
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(4)
        }
    }

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - EffectsPreview

struct EffectsPreview: View {
    // MARK: Internal

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                Text("Effects")
                    .font(.largeTitle.bold())
                    .padding(.horizontal)

                // Shadows
                VStack(alignment: .leading, spacing: 16) {
                    Text("Shadows")
                        .font(.headline)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 24) {
                            ShadowCard(name: "Small", shadow: self.theme.shadows.small)
                            ShadowCard(name: "Medium", shadow: self.theme.shadows.medium)
                            ShadowCard(name: "Large", shadow: self.theme.shadows.large)
                            ShadowCard(name: "XL", shadow: self.theme.shadows.xl)
                        }
                        .padding(.horizontal)
                    }
                }

                Divider()

                // Elevation Levels
                VStack(alignment: .leading, spacing: 16) {
                    Text("Elevation Levels")
                        .font(.headline)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 24) {
                            ElevationCard(level: .none, name: "None")
                            ElevationCard(level: .low, name: "Low")
                            ElevationCard(level: .medium, name: "Medium")
                            ElevationCard(level: .high, name: "High")
                            ElevationCard(level: .overlay, name: "Overlay")
                        }
                        .padding(.horizontal)
                    }
                }

                Divider()

                // Animations
                VStack(alignment: .leading, spacing: 16) {
                    Text("Animations")
                        .font(.headline)
                        .padding(.horizontal)

                    VStack(spacing: 24) {
                        AnimationDemo(
                            title: "Spring",
                            animation: self.theme.animations.spring,
                            isAnimating: self.$animateScale
                        ) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(self.theme.colors.primary)
                                .frame(width: 60, height: 60)
                                .scaleEffect(self.animateScale ? 1.3 : 1.0)
                        }

                        AnimationDemo(
                            title: "Smooth",
                            animation: self.theme.animations.smooth,
                            isAnimating: self.$animateRotation
                        ) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(self.theme.colors.secondary)
                                .frame(width: 60, height: 60)
                                .rotationEffect(.degrees(self.animateRotation ? 180 : 0))
                        }

                        AnimationDemo(
                            title: "Bounce",
                            animation: self.theme.animations.bounce,
                            isAnimating: self.$animateSlide
                        ) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(self.theme.colors.tertiary)
                                .frame(width: 60, height: 60)
                                .offset(x: self.animateSlide ? 100 : 0)
                        }
                    }
                    .padding(.horizontal)
                }

                Divider()

                // Animation Effects
                VStack(alignment: .leading, spacing: 16) {
                    Text("Animation Effects")
                        .font(.headline)
                        .padding(.horizontal)

                    VStack(spacing: 24) {
                        HStack(spacing: 32) {
                            // Pulse effect
                            VStack {
                                Circle()
                                    .fill(self.theme.colors.primary)
                                    .frame(width: 60, height: 60)
                                    .pulse(isAnimating: self.animatePulse)
                                Text("Pulse")
                                    .font(.caption)
                            }
                            .onTapGesture {
                                self.animatePulse.toggle()
                            }

                            // Bounce effect
                            VStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(self.theme.colors.secondary)
                                    .frame(width: 60, height: 60)
                                    .bounce(trigger: self.animateBounce)
                                Text("Bounce")
                                    .font(.caption)
                            }
                            .onTapGesture {
                                self.animateBounce.toggle()
                            }

                            // Shake effect
                            VStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(self.theme.colors.error)
                                    .frame(width: 60, height: 60)
                                    .shake(trigger: self.animateShake)
                                Text("Shake")
                                    .font(.caption)
                            }
                            .onTapGesture {
                                self.animateShake.toggle()
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: Private

    @Environment(\.theme) private var theme
    @State private var animateScale = false
    @State private var animateRotation = false
    @State private var animateSlide = false
    @State private var animatePulse = false
    @State private var animateBounce = false
    @State private var animateShake = false
}

// MARK: - ShadowCard

struct ShadowCard: View {
    // MARK: Internal

    let name: String
    let shadow: ShadowStyle

    var body: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(self.theme.colors.surface)
                .frame(width: 100, height: 100)
                .shadow(
                    color: self.shadow.color,
                    radius: self.shadow.radius,
                    x: self.shadow.x,
                    y: self.shadow.y
                )

            Text(self.name)
                .font(.caption)
                .foregroundColor(self.theme.colors.textSecondary)
        }
    }

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - ElevationCard

struct ElevationCard: View {
    // MARK: Internal

    let level: ElevationLevel
    let name: String

    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(self.theme.colors.surface)
                .frame(width: 100, height: 100)
                .elevation(self.level, from: self.theme.elevations)

            Text(self.name)
                .font(.caption)
                .foregroundColor(self.theme.colors.textSecondary)
        }
    }

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - AnimationDemo

struct AnimationDemo<Content: View>: View {
    let title: String
    let animation: Animation
    @Binding var isAnimating: Bool
    let content: () -> Content

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(self.title)
                    .font(.subheadline)

                Button("Animate") {
                    withAnimation(self.animation) {
                        self.isAnimating.toggle()
                    }
                }
                .font(.caption)
            }

            Spacer()

            self.content()
        }
    }
}

// MARK: - GradientsPreview

struct GradientsPreview: View {
    // MARK: Internal

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                Text("Gradients")
                    .font(.largeTitle.bold())
                    .padding(.horizontal)

                // Brand Gradients
                VStack(alignment: .leading, spacing: 16) {
                    Text("Brand Gradients")
                        .font(.headline)
                        .padding(.horizontal)

                    VStack(spacing: 16) {
                        GradientPreviewCard(title: "Primary", gradient: self.theme.gradients.brandPrimary)
                        GradientPreviewCard(title: "Secondary", gradient: self.theme.gradients.brandSecondary)
                        GradientPreviewCard(title: "Success", gradient: self.theme.gradients.success)
                    }
                    .padding(.horizontal)
                }

                Divider()

                // Premium Gradients
                VStack(alignment: .leading, spacing: 16) {
                    Text("Premium & Paywall")
                        .font(.headline)
                        .padding(.horizontal)

                    VStack(spacing: 16) {
                        GradientPreviewCard(title: "Premium", gradient: self.theme.gradients.premium)
                        GradientPreviewCard(title: "Premium Dark", gradient: self.theme.gradients.premiumDark)
                    }
                    .padding(.horizontal)
                }

                Divider()

                // Onboarding Gradients
                VStack(alignment: .leading, spacing: 16) {
                    Text("Onboarding")
                        .font(.headline)
                        .padding(.horizontal)

                    VStack(spacing: 16) {
                        GradientPreviewCard(
                            title: "Onboarding Primary",
                            gradient: self.theme.gradients.onboardingPrimary
                        )
                        GradientPreviewCard(
                            title: "Onboarding Background",
                            gradient: self.theme.gradients.onboardingBackground
                        )
                    }
                    .padding(.horizontal)
                }

                Divider()

                // Feature Gradients
                VStack(alignment: .leading, spacing: 16) {
                    Text("Feature Gradients")
                        .font(.headline)
                        .padding(.horizontal)

                    VStack(spacing: 16) {
                        GradientPreviewCard(title: "Fitness", gradient: self.theme.gradients.fitness)
                        GradientPreviewCard(title: "Nutrition", gradient: self.theme.gradients.nutrition)
                    }
                    .padding(.horizontal)
                }

                Divider()

                // Gradient Components
                VStack(alignment: .leading, spacing: 16) {
                    Text("Gradient Components")
                        .font(.headline)
                        .padding(.horizontal)

                    VStack(spacing: 16) {
                        // Gradient Button
                        GradientButton("Subscribe Now", icon: "crown.fill", gradientStyle: .premium) {
                            print("Subscribe tapped")
                        }

                        GradientButton("Get Started", icon: "arrow.right", gradientStyle: .primary) {
                            print("Get started tapped")
                        }

                        GradientButton("AI Assistant", icon: "sparkles", gradientStyle: .ai) {
                            print("AI tapped")
                        }

                        // Premium Badge
                        HStack {
                            PremiumBadge()
                            PremiumBadge("PREMIUM")
                            PremiumBadge("VIP")
                        }

                        // Gradient Card with content
                        GradientCard(gradient: self.theme.gradients.premium) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "crown.fill")
                                        .font(.title2)
                                    Text("Go Premium")
                                        .font(.title2.bold())
                                }
                                .foregroundColor(.white)

                                Text("Unlock all features and get personalized coaching")
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - GradientPreviewCard

struct GradientPreviewCard: View {
    // MARK: Lifecycle

    init(title: String, gradient: LinearGradient) {
        self.title = title
        self.gradient = gradient
    }

    // MARK: Internal

    let title: String
    let gradient: LinearGradient

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(self.title)
                .font(.caption)
                .foregroundColor(self.theme.colors.textSecondary)

            RoundedRectangle(cornerRadius: 12)
                .fill(self.gradient)
                .frame(height: 100)
                .overlay(
                    Text(self.title)
                        .font(.headline)
                        .foregroundColor(.white)
                )
        }
    }

    // MARK: Private

    @Environment(\.theme) private var theme
}

// MARK: - ThemePreview_Previews

struct ThemePreview_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ThemePreview()
                .environment(\.theme, DefaultTheme(colorScheme: .light))
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")

            ThemePreview()
                .environment(\.theme, DefaultTheme(colorScheme: .dark))
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
