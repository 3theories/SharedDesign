import SwiftUI

// MARK: - FilterChipView

public struct FilterChipView: View {
    // MARK: Lifecycle

    public init(
        title: String,
        icon: String? = nil,
        isSystemIcon: Bool = true,
        flag: String? = nil,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isSystemIcon = isSystemIcon
        self.flag = flag
        self.isSelected = isSelected
        self.action = action
    }

    // MARK: Public

    public var body: some View {
        Button(action: {
            HapticManager.shared.trigger(.selection)
            self.action()
        }) {
            self.styledChip
        }
    }

    // MARK: Private

    @Environment(\.theme) private var theme

    private let title: String
    private let icon: String?
    private let isSystemIcon: Bool
    private let flag: String?
    private let isSelected: Bool
    private let action: () -> Void

    private var chipLabel: some View {
        HStack(spacing: self.theme.spacing.xxs) {
            if let flag {
                Text(flag)
                    .font(.system(size: 16))
            } else if let icon {
                AppIconView(name: icon, isSystemIcon: self.isSystemIcon)
                    .font(.caption)
                    .frame(width: 14, height: 14)
            }
            Text(self.title)
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, self.theme.spacing.md)
        .padding(.vertical, self.theme.spacing.xs)
        .foregroundStyle(self.isSelected ? self.theme.colors.onPrimary : self.theme.colors.textPrimary)
    }

    @ViewBuilder
    private var styledChip: some View {
        #if os(iOS)
            if #available(iOS 26.0, *) {
                self.chipLabel
                    .glassEffect(
                        .regular.tint(self.isSelected ? self.theme.colors.primary : self.theme.colors.surface1),
                        in: Capsule()
                    )
                    .clipShape(Capsule())
                    .animation(self.theme.animations.smooth, value: self.isSelected)
            } else {
                self.chipLabel
                    .background(
                        Capsule().fill(self.isSelected ? self.theme.colors.primary : self.theme.colors.surface1)
                    )
                    .clipShape(Capsule())
                    .animation(self.theme.animations.smooth, value: self.isSelected)
            }
        #elseif os(watchOS)
            if #available(watchOS 26.0, *) {
                self.chipLabel
                    .glassEffect(
                        .regular.tint(self.isSelected ? self.theme.colors.primary : self.theme.colors.surface1),
                        in: Capsule()
                    )
                    .clipShape(Capsule())
                    .animation(self.theme.animations.smooth, value: self.isSelected)
            } else {
                self.chipLabel
                    .background(
                        Capsule().fill(self.isSelected ? self.theme.colors.primary : self.theme.colors.surface1)
                    )
                    .clipShape(Capsule())
                    .animation(self.theme.animations.smooth, value: self.isSelected)
            }
        #else
            self.chipLabel
                .background(
                    Capsule().fill(self.isSelected ? self.theme.colors.primary : self.theme.colors.surface1)
                )
                .clipShape(Capsule())
                .animation(self.theme.animations.smooth, value: self.isSelected)
        #endif
    }
}
