import SwiftUI

// MARK: - ButtonState

/// Represents the current state of a button
public enum ButtonState: Sendable, Equatable {
    /// Normal idle state
    case idle

    /// Loading/processing state
    case loading

    /// Success state with optional message
    case success(message: String? = nil)

    /// Failure state with optional message
    case failure(message: String? = nil)

    // MARK: Public

    public static func == (lhs: ButtonState, rhs: ButtonState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): true
        case (.loading, .loading): true
        case (.success, .success): true
        case (.failure, .failure): true
        default: false
        }
    }
}

// MARK: - SharedButton

/// A customizable button component that follows the design system
public struct SharedButton: View {
    // MARK: Lifecycle

    // MARK: - Initialization

    public init(
        _ title: String,
        icon: String? = nil,
        iconPosition: IconPosition = .leading,
        style: Style = .primary,
        size: Size = .medium,
        isFullWidth: Bool = false,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        useGlassEffect: Bool = false,
        glassEffectTint: Color? = nil,
        state: ButtonState = .idle,
        autoResetDelay: Double? = 2.0,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.iconPosition = iconPosition
        self.style = style
        self.size = size
        self.isFullWidth = isFullWidth
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.useGlassEffect = useGlassEffect
        self.glassEffectTint = glassEffectTint
        self.buttonState = state
        self.autoResetDelay = autoResetDelay
        self.action = action
    }

    // MARK: Public

    // MARK: - Types

    public enum Style {
        case primary
        case secondary
        case tertiary
        case destructive
        case ghost
    }

    public enum Size {
        case small
        case medium
        case large
    }

    public enum IconPosition {
        case leading
        case trailing
    }

    // MARK: - Body

    public var body: some View {
        Button(action: {
            if !self.effectiveLoading && self.isEnabled && !self.isSuccessState && !self.isFailureState {
                HapticManager.shared.trigger(.light)
                self.action()
            }
        }) {
            ZStack {
                // Background
                self.backgroundView

                // Content — padded internally so the background fills the
                // full frame. Previously `.padding(.horizontal, ...)` sat
                // outside the maxWidth frame, which on `isFullWidth: true`
                // pulled the entire button inward by `theme.spacing.lg` on
                // each side (the visible "extra padding on leading and
                // trailing"). Non-fullWidth buttons still size to content
                // plus this internal padding, so their visual width is
                // unchanged.
                self.contentView
                    .padding(.horizontal, self.horizontalPadding)
            }
            .foregroundColor(self.effectiveForegroundColor)
            .frame(maxWidth: self.isFullWidth ? .infinity : nil)
            .frame(height: self.height)
        }
        .disabled(!self.isEnabled || self.effectiveLoading || self.isSuccessState || self.isFailureState)
        .scaleEffect(self.isPressed ? self.pressedScale : 1.0)
        .offset(x: self.shakeOffset)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: self.isPressed)
        .animation(.spring(response: 0.3, dampingFraction: 0.3), value: self.shakeOffset)
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                self.isPressed = pressing
            },
            perform: { }
        )
        .onChange(of: self.buttonState) { _, newState in
            self.handleStateChange(newState)
        }
    }

    // MARK: Private

    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    @State private var showSuccess = false
    @State private var showFailure = false
    @State private var shakeOffset: CGFloat = 0

    private let title: String
    private let icon: String?
    private let iconPosition: IconPosition
    private let style: Style
    private let size: Size
    private let isFullWidth: Bool
    private let isLoading: Bool
    private let isEnabled: Bool
    private let useGlassEffect: Bool
    private let glassEffectTint: Color?
    private let buttonState: ButtonState
    private let autoResetDelay: Double?
    private let action: () -> Void

    private var effectiveLoading: Bool {
        self.isLoading || self.buttonState == .loading
    }

    private var isSuccessState: Bool {
        if case .success = self.buttonState {
            return true
        }
        return self.showSuccess
    }

    private var isFailureState: Bool {
        if case .failure = self.buttonState {
            return true
        }
        return self.showFailure
    }

    private var successMessage: String? {
        if case let .success(message) = self.buttonState {
            return message
        }
        return nil
    }

    private var failureMessage: String? {
        if case let .failure(message) = self.buttonState {
            return message
        }
        return nil
    }

    private var progressScale: CGFloat {
        switch self.size {
        case .small: 0.6
        case .medium: 0.8
        case .large: 0.9
        }
    }

    private var effectiveForegroundColor: Color {
        if self.isSuccessState {
            return self.useGlassEffect ? ColorPalette.Semantic.success : self.foregroundColor
        }
        if self.isFailureState {
            return self.useGlassEffect ? ColorPalette.Semantic.error : self.foregroundColor
        }
        return self.foregroundColor
    }

    private var glassEffectTintColor: Color {
        if let tint = glassEffectTint {
            return tint
        }
        switch self.style {
        case .primary:
            return self.theme.colors.primary
        case .secondary:
            return self.theme.colors.primary
        case .tertiary:
            return self.theme.colors.tertiary
        case .destructive:
            return self.theme.colors.error
        case .ghost:
            return self.theme.colors.primary
        }
    }

    /// Glass effect opacity - consistent across all platforms
    /// Follows pattern used in RecipeActionSheet, CompactFastingRingView, and FastingRingView
    /// Uses 0.15 opacity for subtle yet visible glass effect in both light and dark modes
    private var glassEffectOpacity: Double {
        0.15
    }

    private var foregroundColor: Color {
        if self.useGlassEffect {
            return self.isEnabled ? self.glassEffectTintColor : self.glassEffectTintColor.opacity(0.5)
        }
        switch self.style {
        case .primary:
            return self.theme.colors.onPrimary
        case .secondary:
            return self.isEnabled ? self.theme.colors.primary : self.theme.colors.onSurface.opacity(0.5)
        case .tertiary:
            return self.theme.colors.onTertiary
        case .destructive:
            return Color.white
        case .ghost:
            return self.isEnabled ? self.theme.colors.primary : self.theme.colors.onSurface.opacity(0.5)
        }
    }

    private var height: CGFloat {
        switch self.size {
        case .small:
            self.theme.sizing.buttonHeight.small
        case .medium:
            self.theme.sizing.buttonHeight.medium
        case .large:
            self.theme.sizing.buttonHeight.large
        }
    }

    private var horizontalPadding: CGFloat {
        switch self.size {
        case .small:
            self.theme.spacing.sm
        case .medium:
            self.theme.spacing.md
        case .large:
            self.theme.spacing.lg
        }
    }

    private var textFont: Font {
        switch self.size {
        case .small:
            ExtendedTypography.buttonSmall
        case .medium:
            ExtendedTypography.buttonMedium
        case .large:
            ExtendedTypography.buttonLarge
        }
    }

    private var iconFont: Font {
        switch self.size {
        case .small:
            .system(size: 14, weight: .semibold)
        case .medium:
            .system(size: 16, weight: .semibold)
        case .large:
            .system(size: 18, weight: .semibold)
        }
    }

    private var cornerRadius: CGFloat {
        switch self.size {
        case .small:
            self.theme.sizing.cornerRadius.small
        case .medium:
            self.theme.sizing.cornerRadius.medium
        case .large:
            self.theme.sizing.cornerRadius.large
        }
    }

    private var pressedScale: CGFloat {
        if case .primary = self.style {
            return 0.98
        }
        return 0.96
    }

    private var buttonShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: self.cornerRadius)
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        if self.effectiveLoading {
            self.loadingContent
        } else if self.isSuccessState {
            self.successContent
        } else if self.isFailureState {
            self.failureContent
        } else {
            self.normalContent
        }
    }

    private var loadingContent: some View {
        HStack(spacing: self.theme.spacing.xs) {
            LoadingView(style: .circular, size: 16, tint: self.foregroundColor)
                .scaleEffect(self.progressScale)

            if self.size != .small {
                Text(L10n.string("shared.button.loading", defaultValue: "Loading..."))
                    .font(self.textFont)
                    .opacity(0.8)
            }
        }
    }

    private var successContent: some View {
        HStack(spacing: self.theme.spacing.xs) {
            Image(systemName: "checkmark.circle.fill")
                .font(self.iconFont)
                .symbolEffect(.bounce, value: self.isSuccessState)

            Text(self.successMessage ?? "Success")
                .font(self.textFont)
        }
        .transition(.scale.combined(with: .opacity))
    }

    private var failureContent: some View {
        HStack(spacing: self.theme.spacing.xs) {
            Image(systemName: "xmark.circle.fill")
                .font(self.iconFont)

            Text(self.failureMessage ?? "Failed")
                .font(self.textFont)
        }
        .transition(.scale.combined(with: .opacity))
    }

    private var normalContent: some View {
        HStack(spacing: self.theme.spacing.xs) {
            if let icon, self.iconPosition == .leading {
                Image(systemName: icon)
                    .font(self.iconFont)
            }

            Text(self.title)
                .font(self.textFont)

            if let icon, self.iconPosition == .trailing {
                Image(systemName: icon)
                    .font(self.iconFont)
            }
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        if self.useGlassEffect {
            if #available(iOS 26.0, watchOS 26.0, *) {
                self.buttonShape
                    .fill(.clear)
                    .glassEffect(
                        .regular.tint(self.glassEffectTintColor.opacity(self.glassEffectOpacity)).interactive(),
                        in: self.buttonShape
                    )
                    .opacity(self.isEnabled ? 1 : 0.5)
            }
        } else {
            switch self.style {
            case .primary:
                self.buttonShape
                    .fill(
                        self.theme.colors.primary
                            .shadow(.inner(color: .white.opacity(0.25), radius: 4.1, x: 0, y: -1))
                            .shadow(.inner(color: .white.opacity(0.12), radius: 1.5, x: 0, y: 1))
                            .shadow(.inner(color: .white.opacity(0.12), radius: 0.25, x: 0, y: 0.5))
                    )
                    .overlay(
                        self.buttonShape
                            .strokeBorder(Color.white.opacity(0.5), lineWidth: self.theme.sizing.borderWidth.small)
                    )
                    .opacity(self.isEnabled ? 1 : 0.5)
            case .secondary:
                self.buttonShape
                    .fill(self.theme.colors.surface)
                    .overlay(
                        self.buttonShape
                            .strokeBorder(self.theme.colors.primary, lineWidth: self.theme.sizing.borderWidth.medium)
                    )
                    .opacity(self.isEnabled ? 1 : 0.5)
            case .tertiary:
                self.buttonShape
                    .fill(
                        self.theme.colors.tertiary
                            .shadow(.inner(color: .white.opacity(0.15), radius: 6, x: 0, y: -1))
                            .shadow(.inner(color: .white.opacity(0.08), radius: 2, x: 0, y: 1))
                    )
                    .opacity(self.isEnabled ? 1 : 0.5)
            case .destructive:
                self.buttonShape
                    .fill(
                        self.theme.colors.error
                            .shadow(.inner(color: .white.opacity(0.15), radius: 6, x: 0, y: -1))
                            .shadow(.inner(color: .white.opacity(0.08), radius: 2, x: 0, y: 1))
                    )
                    .opacity(self.isEnabled ? 1 : 0.5)
            case .ghost:
                Color.clear
            }
        }
    }

    // MARK: - State Handling

    private func handleStateChange(_ newState: ButtonState) {
        switch newState {
        case .success:
            HapticManager.shared.trigger(.success)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                self.showSuccess = true
            }

        case .failure:
            HapticManager.shared.trigger(.error)
            self.triggerShakeAnimation()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                self.showFailure = true
            }

        case .idle:
            withAnimation(.easeOut(duration: 0.2)) {
                self.showSuccess = false
                self.showFailure = false
            }

        case .loading:
            break
        }
    }

    private func triggerShakeAnimation() {
        withAnimation(.spring(response: 0.1, dampingFraction: 0.2)) {
            self.shakeOffset = 10
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.1, dampingFraction: 0.2)) {
                self.shakeOffset = -8
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.1, dampingFraction: 0.2)) {
                self.shakeOffset = 5
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
                self.shakeOffset = 0
            }
        }
    }
}

// MARK: - Preview

#Preview("SharedButton Styles") {
    ScrollView {
        VStack(spacing: 20) {
            Text("SharedButton")
                .font(.title2.bold())

            // Styles
            VStack(alignment: .leading, spacing: 8) {
                Text("Styles").font(.headline)
                SharedButton("Primary", style: .primary) { }
                SharedButton("Secondary", style: .secondary) { }
                SharedButton("Tertiary", style: .tertiary) { }
                SharedButton("Destructive", style: .destructive) { }
                SharedButton("Ghost", style: .ghost) { }
            }

            Divider()

            // Sizes
            VStack(alignment: .leading, spacing: 8) {
                Text("Sizes").font(.headline)
                HStack(spacing: 12) {
                    SharedButton("Small", size: .small) { }
                    SharedButton("Medium", size: .medium) { }
                    SharedButton("Large", size: .large) { }
                }
            }

            Divider()

            // With icons
            VStack(alignment: .leading, spacing: 8) {
                Text("With Icons").font(.headline)
                SharedButton("Download", icon: "arrow.down.circle", style: .primary) { }
                SharedButton("Upload", icon: "arrow.up.circle", iconPosition: .trailing, style: .secondary) { }
            }

            Divider()

            // States
            VStack(alignment: .leading, spacing: 8) {
                Text("States").font(.headline)
                SharedButton("Loading", state: .loading) { }
                SharedButton("Success", state: .success(message: "Saved!")) { }
                SharedButton("Failure", state: .failure(message: "Try Again")) { }
                SharedButton("Disabled", isEnabled: false) { }
            }

            Divider()

            // Full width
            SharedButton("Full Width Button", isFullWidth: true) { }
        }
        .padding()
    }
    .environment(\.theme, DefaultTheme())
}

#Preview("Button State Demo") {
    struct StateDemoView: View {
        @State private var buttonState: ButtonState = .idle

        var body: some View {
            VStack(spacing: 24) {
                Text("Interactive Demo")
                    .font(.title2.bold())

                SharedButton(
                    "Submit",
                    icon: "paperplane.fill",
                    isFullWidth: true,
                    state: self.buttonState
                ) {
                    self.simulateSubmit()
                }

                HStack(spacing: 12) {
                    Button("Reset") {
                        self.buttonState = .idle
                    }
                    .buttonStyle(.bordered)

                    Button("Loading") {
                        self.buttonState = .loading
                    }
                    .buttonStyle(.bordered)

                    Button("Success") {
                        self.buttonState = .success()
                    }
                    .buttonStyle(.bordered)

                    Button("Failure") {
                        self.buttonState = .failure()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .environment(\.theme, DefaultTheme())
        }

        private func simulateSubmit() {
            self.buttonState = .loading

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if Bool.random() {
                    self.buttonState = .success(message: "Submitted!")
                } else {
                    self.buttonState = .failure(message: "Network Error")
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.buttonState = .idle
                }
            }
        }
    }

    return StateDemoView()
}
