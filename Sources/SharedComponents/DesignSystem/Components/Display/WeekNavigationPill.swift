import SwiftUI

#if os(iOS)

    @available(iOS 26.0, *)
    public struct WeekNavigationPill: View {
        // MARK: Lifecycle

        public init(
            weekDates: [Date],
            canNavigateNext: Bool,
            canNavigatePrevious: Bool,
            onNextTap: @escaping () -> Void,
            onPreviousTap: @escaping () -> Void,
            isCompact: Bool,
            onLabelTap: (() -> Void)? = nil,
            showReturnToCurrent: Bool = false,
            onReturnToCurrentTap: (() -> Void)? = nil,
            isPastWeek: Bool = false
        ) {
            self.weekDates = weekDates
            self.canNavigateNext = canNavigateNext
            self.canNavigatePrevious = canNavigatePrevious
            self.onNextTap = onNextTap
            self.onPreviousTap = onPreviousTap
            self.isCompact = isCompact
            self.onLabelTap = onLabelTap
            self.showReturnToCurrent = showReturnToCurrent
            self.onReturnToCurrentTap = onReturnToCurrentTap
            self.isPastWeek = isPastWeek
        }

        // MARK: Public

        public let weekDates: [Date]
        public let canNavigateNext: Bool
        public let canNavigatePrevious: Bool
        public let onNextTap: () -> Void
        public let onPreviousTap: () -> Void
        public var isCompact: Bool
        public var onLabelTap: (() -> Void)?

        public var showReturnToCurrent: Bool
        public var onReturnToCurrentTap: (() -> Void)?
        public var isPastWeek: Bool

        public var body: some View {
            HStack(spacing: self.theme.spacing.sm) {
                self.previousButton

                if !self.isCompact {
                    VStack(spacing: self.theme.spacing.xxs) {
                        Text(self.weekRange)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(self.theme.colors.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .contentShape(Rectangle())
                            .onTapGesture { self.onLabelTap?() }
                            .accessibilityLabel(String(
                                localized: "weekNav.accessibility.weekRange",
                                defaultValue: "Week range",
                                bundle: .module,
                                comment: "Week navigation pill accessibility label for week range"
                            ))
                            .accessibilityHint(String(
                                localized: "weekNav.accessibility.tapToPickWeek",
                                defaultValue: "Tap to pick a week",
                                bundle: .module,
                                comment: "Week navigation pill accessibility hint for week picker"
                            ))
                            .accessibilityValue(self.weekRange)

                        if self.showReturnToCurrent {
                            self.returnToCurrentButton
                                .transition(
                                    .asymmetric(
                                        insertion: .scale(scale: 0.8).combined(with: .opacity)
                                            .combined(with: .offset(y: -4)),
                                        removal: .scale(scale: 0.9).combined(with: .opacity)
                                    )
                                )
                        }
                    }
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0.1),
                        value: self.showReturnToCurrent
                    )
                }

                self.nextButton
            }
            .padding(.horizontal, self.isCompact ? self.theme.spacing.md : self.theme.spacing.lg)
            .padding(.vertical, self.isCompact ? self.theme.spacing.xs : self.theme.spacing.sm)
            .glassEffect(.regular, in: Capsule())
        }

        // MARK: Private

        @Environment(\.theme) private var theme

        private var weekRange: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"

            guard let startDate = weekDates.first,
                  let endDate = weekDates.last else {
                return String(
                    localized: "weekNav.invalidWeek",
                    defaultValue: "Invalid Week",
                    bundle: .module,
                    comment: "Week navigation pill fallback text when dates are invalid"
                )
            }

            return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
        }

        // MARK: - Button Components

        private var previousButton: some View {
            Button(action: {
                HapticManager.shared.trigger(.selection)
                self.onPreviousTap()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: self.isCompact ? 14 : 16, weight: .semibold))
                    .foregroundStyle(
                        self.canNavigatePrevious
                            ? self.theme.colors.primary
                            : self.theme.colors.textDisabled
                    )
                    .frame(width: self.isCompact ? 28 : 34, height: self.isCompact ? 28 : 34)
                    .contentShape(Circle())
                    .accessibilityHidden(true)
                    .accessibilityHidden(true)
            }
            .buttonStyle(.plain)
            .disabled(!self.canNavigatePrevious)
            .glassEffect(.regular.tint(self.theme.colors.primary.opacity(0.15)).interactive(), in: Circle())
            .accessibilityLabel(String(
                localized: "weekNav.accessibility.previousWeek",
                defaultValue: "Previous week",
                bundle: .module,
                comment: "Week navigation previous button accessibility label"
            ))
            .accessibilityHint(
                self.canNavigatePrevious
                    ? String(
                        localized: "weekNav.accessibility.movesToPrevious",
                        defaultValue: "Moves to previous week",
                        bundle: .module,
                        comment: "Week navigation previous button accessibility hint when enabled"
                    )
                    : String(
                        localized: "weekNav.accessibility.cannotNavigate",
                        defaultValue: "Cannot navigate further",
                        bundle: .module,
                        comment: "Week navigation button accessibility hint when disabled"
                    )
            )
        }

        private var nextButton: some View {
            Button(action: {
                HapticManager.shared.trigger(.selection)
                self.onNextTap()
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: self.isCompact ? 14 : 16, weight: .semibold))
                    .foregroundStyle(self.canNavigateNext ? self.theme.colors.primary : self.theme.colors.textDisabled)
                    .frame(width: self.isCompact ? 28 : 34, height: self.isCompact ? 28 : 34)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(!self.canNavigateNext)
            .glassEffect(.regular.tint(self.theme.colors.primary.opacity(0.15)).interactive(), in: Circle())
            .accessibilityLabel(String(
                localized: "weekNav.accessibility.nextWeek",
                defaultValue: "Next week",
                bundle: .module,
                comment: "Week navigation next button accessibility label"
            ))
            .accessibilityHint(
                self.canNavigateNext
                    ? String(
                        localized: "weekNav.accessibility.movesToNext",
                        defaultValue: "Moves to next week",
                        bundle: .module,
                        comment: "Week navigation next button accessibility hint when enabled"
                    )
                    : String(
                        localized: "weekNav.accessibility.cannotNavigate",
                        defaultValue: "Cannot navigate further",
                        bundle: .module,
                        comment: "Week navigation button accessibility hint when disabled"
                    )
            )
        }

        private var returnToCurrentButton: some View {
            Button(action: {
                HapticManager.shared.trigger(.selection)
                self.onReturnToCurrentTap?()
            }) {
                HStack(spacing: 6) {
                    if self.isPastWeek {
                        Text(String(
                            localized: "weekNav.thisWeek",
                            defaultValue: "This Week",
                            bundle: .module,
                            comment: "Week navigation return to current week button"
                        ))
                        .font(.footnote.weight(.semibold))
                        Image(systemName: "arrow.uturn.right")
                            .font(.footnote.bold())
                            .accessibilityHidden(true)
                    } else {
                        Image(systemName: "arrow.uturn.left")
                            .font(.footnote.bold())
                            .accessibilityHidden(true)
                        Text(String(
                            localized: "weekNav.thisWeek",
                            defaultValue: "This Week",
                            bundle: .module,
                            comment: "Week navigation return to current week button"
                        ))
                        .font(.footnote.weight(.semibold))
                    }
                }
                .foregroundStyle(self.theme.colors.info)
                .padding(.horizontal, self.theme.spacing.md)
                .padding(.vertical, self.theme.spacing.xs - 2)
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.tint(self.theme.colors.info.opacity(0.15)).interactive(), in: Capsule())
            .accessibilityLabel(String(
                localized: "weekNav.accessibility.returnToCurrent",
                defaultValue: "Return to current week",
                bundle: .module,
                comment: "Week navigation return to current week accessibility label"
            ))
        }
    }

#endif
