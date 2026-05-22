import SwiftUI

// MARK: - AnimatedCard

/// Animated card with built-in press effects and animations
public struct AnimatedCard<Content: View>: View {
    // MARK: Lifecycle

    public init(
        padding: CGFloat = 16,
        cornerRadius: CGFloat = 12,
        shadowRadius: CGFloat = 4,
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.onTap = onTap
    }

    // MARK: Public

    public var body: some View {
        self.content
            .padding(self.padding)
            .background(self.theme.colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: self.cornerRadius))
            .shadow(
                color: self.theme.colors.shadow.opacity(self.isPressed ? 0.1 : 0.2),
                radius: self.isPressed ? self.shadowRadius / 2 : self.shadowRadius,
                y: self.isPressed ? 1 : 2
            )
            .scaleEffect(
                self.isPressed
                    ? AnimationConstants.Scale.cardPress
                    : (self.isHovered ? AnimationConstants.Scale.hover : 1.0)
            )
            .animation(AnimationConstants.Spring.stiff, value: self.isPressed)
            .animation(AnimationConstants.Spring.quick, value: self.isHovered)
            .onTapGesture {
                self.onTap?()
            }
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) {
                // Long press completed
            } onPressingChanged: { pressing in
                if pressing {
                    HapticManager.shared.trigger(.light)
                }
                self.isPressed = pressing
            }
        #if !os(watchOS)
            .onHover { hovering in
                self.isHovered = hovering
            }
        #endif
    }

    // MARK: Private

    @Environment(\.theme) private var theme
    @State private var isPressed = false
    @State private var isHovered = false

    private let content: Content
    private let padding: CGFloat
    private let cornerRadius: CGFloat
    private let shadowRadius: CGFloat
    private let onTap: (() -> Void)?
}

// MARK: - ExpandableCard

/// Expandable card with animated content reveal
public struct ExpandableCard<Header: View, Content: View>: View {
    // MARK: Lifecycle

    public init(
        isExpanded: Binding<Bool>,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) {
        self.isExpanded = isExpanded
        self.header = header()
        self.content = content()
    }

    // MARK: Public

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                self.header

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(self.theme.colors.textSecondary)
                    .rotationEffect(.degrees(self.isExpanded.wrappedValue ? 180 : 0))
                    .animation(AnimationConstants.Spring.quick, value: self.isExpanded.wrappedValue)
                    .accessibilityHidden(true)
            }
            .padding()
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(AnimationConstants.Spring.smooth) {
                    self.isExpanded.wrappedValue.toggle()
                }
                HapticManager.shared.trigger(.light)
            }

            // Expandable content
            if self.isExpanded.wrappedValue {
                Divider()
                    .background(self.theme.colors.borderSecondary)
                    .transition(.asymmetric(
                        insertion: .push(from: .top).combined(with: .opacity),
                        removal: .push(from: .bottom).combined(with: .opacity)
                    ))

                self.content
                    .padding()
                    .transition(.asymmetric(
                        insertion: .push(from: .top).combined(with: .opacity),
                        removal: .push(from: .bottom).combined(with: .opacity)
                    ))
            }
        }
        .background(self.theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: self.theme.colors.shadow.opacity(0.1), radius: 4, y: 2)
    }

    // MARK: Private

    @Environment(\.theme) private var theme
    @Namespace private var namespace

    private let header: Header
    private let content: Content
    private let isExpanded: Binding<Bool>
}

// MARK: - FlippableCard

/// Flippable card with front and back views
public struct FlippableCard<Front: View, Back: View>: View {
    // MARK: Lifecycle

    public init(
        isFlipped: Binding<Bool>,
        flipDuration: Double = 0.6,
        @ViewBuilder front: () -> Front,
        @ViewBuilder back: () -> Back
    ) {
        self.isFlipped = isFlipped
        self.flipDuration = flipDuration
        self.front = front()
        self.back = back()
    }

    // MARK: Public

    public var body: some View {
        ZStack {
            if !self.isFlipped.wrappedValue {
                self.front
                    .rotation3DEffect(
                        .degrees(0),
                        axis: (x: 0, y: 1, z: 0)
                    )
            } else {
                self.back
                    .rotation3DEffect(
                        .degrees(180),
                        axis: (x: 0, y: 1, z: 0)
                    )
                    .scaleEffect(x: -1)
            }
        }
        .animation(.easeInOut(duration: self.flipDuration), value: self.isFlipped.wrappedValue)
        .onTapGesture {
            withAnimation(.easeInOut(duration: self.flipDuration)) {
                self.isFlipped.wrappedValue.toggle()
            }
            HapticManager.shared.trigger(.medium)
        }
    }

    // MARK: Private

    @Environment(\.theme) private var theme

    private let front: Front
    private let back: Back
    private let isFlipped: Binding<Bool>
    private let flipDuration: Double
}

// MARK: - DraggableCard

/// Draggable card with spring physics
public struct DraggableCard<Content: View>: View {
    // MARK: Lifecycle

    public init(
        onDismiss: ((DismissDirection) -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.onDismiss = onDismiss
        self.content = content()
    }

    // MARK: Public

    public enum DismissDirection {
        case left, right, up, down
    }

    public var body: some View {
        self.content
            .offset(x: self.offset.width + self.dragOffset.width, y: self.offset.height + self.dragOffset.height)
            .rotationEffect(.degrees(Double(self.dragOffset.width / 20)))
            .scaleEffect(self.isDragging ? 0.95 : 1.0)
            .animation(AnimationConstants.Spring.quick, value: self.isDragging)
            .gesture(
                DragGesture()
                    .updating(self.$dragOffset) { value, state, _ in
                        state = value.translation
                    }
                    .onChanged { _ in
                        self.isDragging = true
                    }
                    .onEnded { value in
                        self.isDragging = false

                        let threshold: CGFloat = 100

                        if abs(value.translation.width) > threshold {
                            let direction: DismissDirection = value.translation.width > 0 ? .right : .left

                            withAnimation(AnimationConstants.Spring.quick) {
                                self.offset = CGSize(
                                    width: value.translation.width > 0 ? 500 : -500,
                                    height: value.translation.height
                                )
                            }

                            self.onDismiss?(direction)
                        } else if abs(value.translation.height) > threshold {
                            let direction: DismissDirection = value.translation.height > 0 ? .down : .up

                            withAnimation(AnimationConstants.Spring.quick) {
                                self.offset = CGSize(
                                    width: value.translation.width,
                                    height: value.translation.height > 0 ? 500 : -500
                                )
                            }

                            self.onDismiss?(direction)
                        } else {
                            withAnimation(AnimationConstants.Spring.rubberBand) {
                                self.offset = .zero
                            }
                        }
                    }
            )
    }

    // MARK: Private

    @Environment(\.theme) private var theme
    @GestureState private var dragOffset: CGSize = .zero
    @State private var offset: CGSize = .zero
    @State private var isDragging = false

    private let content: Content
    private let onDismiss: ((DismissDirection) -> Void)?
}

// MARK: - GradientAnimatedCard

/// Gradient animated card
public struct GradientAnimatedCard<Content: View>: View {
    // MARK: Lifecycle

    public init(
        colors: [Color]? = nil,
        startPoint: UnitPoint = .topLeading,
        endPoint: UnitPoint = .bottomTrailing,
        animateGradient: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.colors = colors ?? [Color.blue, Color.purple]
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.animateGradient = animateGradient
        self.content = content()
    }

    // MARK: Public

    public var body: some View {
        self.content
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: self.animateGradient ? self.shiftedColors : self.colors),
                    startPoint: self.startPoint,
                    endPoint: self.endPoint
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: self.colors.first?.opacity(0.3) ?? Color.clear, radius: 8, y: 4)
            .onAppear {
                if self.animateGradient {
                    withAnimation(
                        Animation.linear(duration: 3)
                            .repeatForever(autoreverses: true)
                    ) {
                        self.animationPhase = 1
                    }
                }
            }
    }

    // MARK: Private

    @Environment(\.theme) private var theme
    @State private var animationPhase: CGFloat = 0

    private let content: Content
    private let colors: [Color]
    private let startPoint: UnitPoint
    private let endPoint: UnitPoint
    private let animateGradient: Bool

    private var shiftedColors: [Color] {
        var shifted = self.colors
        if self.animationPhase > 0.5 {
            shifted.append(shifted.removeFirst())
        }
        return shifted
    }
}

// MARK: - AnimatedCard_Previews

struct AnimatedCard_Previews: PreviewProvider {
    struct PreviewContent: View {
        // MARK: Internal

        var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    AnimatedCard {
                        VStack(alignment: .leading) {
                            Text("Animated Card")
                                .font(.headline)
                            Text("Tap me for press effect")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    ExpandableCard(isExpanded: self.$isExpanded) {
                        Text("Expandable Card")
                            .font(.headline)
                    } content: {
                        Text("This is the expanded content that appears when you tap the card header.")
                            .font(.body)
                    }

                    FlippableCard(isFlipped: self.$isFlipped) {
                        AnimatedCard {
                            VStack {
                                Text("Front Side")
                                    .font(.headline)
                                Text("Tap to flip")
                                    .font(.caption)
                            }
                            .frame(height: 100)
                        }
                    } back: {
                        AnimatedCard {
                            VStack {
                                Text("Back Side")
                                    .font(.headline)
                                Text("Tap to flip back")
                                    .font(.caption)
                            }
                            .frame(height: 100)
                        }
                    }

                    DraggableCard {
                        AnimatedCard {
                            VStack {
                                Text("Draggable Card")
                                    .font(.headline)
                                Text("Swipe to dismiss")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(height: 100)
                        }
                    }

                    GradientAnimatedCard(
                        colors: [.purple, .pink, .orange],
                        animateGradient: true
                    ) {
                        VStack {
                            Text("Gradient Card")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("With animated gradient")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .frame(height: 100)
                    }
                }
                .padding()
            }
        }

        // MARK: Private

        @State private var isExpanded = false
        @State private var isFlipped = false
    }

    static var previews: some View {
        PreviewContent()
            .theme(DefaultTheme())
    }
}
