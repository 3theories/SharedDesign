import SwiftUI

#if os(iOS)

    // MARK: - GenerationStatusCapsule

    /// A compact, floating capsule for displaying AI generation progress.
    /// Designed to float above the WeekNavigationPill with matching glass styling.
    @available(iOS 26.0, *)
    public struct GenerationStatusCapsule: View {
        // MARK: Lifecycle

        public init(
            icon: String = "sparkles",
            statusText: String,
            progressText: String? = nil,
            isCancelling: Bool = false,
            onCancel: (() -> Void)? = nil
        ) {
            self.icon = icon
            self.statusText = statusText
            self.progressText = progressText
            self.isCancelling = isCancelling
            self.onCancel = onCancel
        }

        // MARK: Public

        public var body: some View {
            HStack(spacing: self.theme.spacing.sm) {
                // Status icon
                self.statusIcon

                // Status text (throttled) + optional progress count (live)
                HStack(spacing: self.theme.spacing.xs) {
                    Text(
                        self.isCancelling
                            ? String(
                                localized: "generation.status.cancelling",
                                defaultValue: "Cancelling...",
                                bundle: .module,
                                comment: "Generation status capsule cancelling state text"
                            )
                            : self.statusText
                    )
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(self.theme.colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: self.statusText)

                    if !self.isCancelling, let progressText {
                        Text(progressText)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(self.theme.colors.textSecondary)
                            .monospacedDigit()
                    }
                }

                // Cancel button - always show when not cancelling
                if !self.isCancelling, let onCancel {
                    Button {
                        onCancel()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(self.theme.colors.textSecondary)
                            .frame(width: 28, height: 28)
                            .contentShape(Circle())
                            .accessibilityLabel("Cancel")
                    }
                    .buttonStyle(.plain)
                    .glassEffect(
                        .regular.tint(self.theme.colors.textSecondary.opacity(0.15)).interactive(),
                        in: Circle()
                    )
                }
            }
            .padding(.horizontal, self.theme.spacing.md)
            .padding(.vertical, self.theme.spacing.sm)
            .glassEffect(.regular, in: Capsule())
        }

        // MARK: Private

        @Environment(\.theme) private var theme

        private let icon: String
        private let statusText: String
        private let progressText: String?
        private let isCancelling: Bool
        private let onCancel: (() -> Void)?

        @ViewBuilder
        private var statusIcon: some View {
            if self.isCancelling {
                LoadingView(size: 16)
            } else {
                Image(systemName: self.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(self.theme.colors.primary)
                    .symbolEffect(.pulse, options: .repeating)
                    .accessibilityHidden(true)
            }
        }
    }

    // MARK: - Convenience initializers

    @available(iOS 26.0, *)
    extension GenerationStatusCapsule {
        /// Creates a capsule for workout generation
        public static func workout(
            completedCount: Int,
            totalCount: Int,
            statusMessage: String? = nil,
            isCancelling: Bool,
            onCancel: @escaping () -> Void
        ) -> GenerationStatusCapsule {
            let statusText: String
            let progressText: String?

            if let statusMessage, !statusMessage.isEmpty {
                statusText = statusMessage
                progressText = completedCount > 0 && totalCount > 0
                    ? "(\(completedCount)/\(totalCount))"
                    : nil
            } else if completedCount >= totalCount && totalCount > 0 {
                statusText = String(
                    localized: "All \(totalCount) workouts ready",
                    comment: "Workout generation complete status"
                )
                progressText = nil
            } else if completedCount > 0 {
                statusText = String(localized: "Generating workouts...", comment: "Workout generation in progress")
                progressText = "(\(completedCount)/\(totalCount))"
            } else {
                statusText = String(localized: "Generating workouts...", comment: "Workout generation in progress")
                progressText = nil
            }

            return GenerationStatusCapsule(
                icon: "sparkles",
                statusText: statusText,
                progressText: progressText,
                isCancelling: isCancelling,
                onCancel: onCancel
            )
        }

        /// Creates a capsule for meal plan generation
        public static func mealPlan(
            completedCount: Int,
            totalCount: Int,
            statusMessage: String? = nil,
            isCancelling: Bool,
            onCancel: @escaping () -> Void
        ) -> GenerationStatusCapsule {
            let statusText: String
            let progressText: String?

            if let statusMessage, !statusMessage.isEmpty {
                statusText = statusMessage
                progressText = completedCount > 0 && totalCount > 0
                    ? "(\(completedCount)/\(totalCount))"
                    : nil
            } else if completedCount >= totalCount && totalCount > 0 {
                statusText = String(
                    localized: "All \(totalCount) meals ready",
                    comment: "Meal plan generation complete status"
                )
                progressText = nil
            } else if completedCount > 0 {
                statusText = String(localized: "Generating meals...", comment: "Meal plan generation in progress")
                progressText = "(\(completedCount)/\(totalCount))"
            } else {
                statusText = String(localized: "Generating meals...", comment: "Meal plan generation in progress")
                progressText = nil
            }

            return GenerationStatusCapsule(
                icon: "sparkles",
                statusText: statusText,
                progressText: progressText,
                isCancelling: isCancelling,
                onCancel: onCancel
            )
        }
    }

    #Preview("Workout Capsule") {
        VStack(spacing: 20) {
            if #available(iOS 26.0, *) {
                GenerationStatusCapsule.workout(
                    completedCount: 0,
                    totalCount: 5,
                    isCancelling: false
                ) { }

                GenerationStatusCapsule.workout(
                    completedCount: 3,
                    totalCount: 5,
                    isCancelling: false
                ) { }

                GenerationStatusCapsule.workout(
                    completedCount: 5,
                    totalCount: 5,
                    isCancelling: false
                ) { }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    #Preview("Meal Capsule") {
        VStack(spacing: 20) {
            if #available(iOS 26.0, *) {
                GenerationStatusCapsule.mealPlan(
                    completedCount: 0,
                    totalCount: 21,
                    isCancelling: false
                ) { }

                GenerationStatusCapsule.mealPlan(
                    completedCount: 12,
                    totalCount: 21,
                    isCancelling: false
                ) { }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    #Preview("Cancelling") {
        if #available(iOS 26.0, *) {
            GenerationStatusCapsule(
                statusText: "Generating...",
                isCancelling: true
            )
            .padding()
            .background(Color(.systemBackground))
        }
    }

#endif
