import SwiftUI

#if os(iOS)

    /// A premium time picker field component that matches the EditableTextField styling
    /// Includes icon support and consistent visual appearance with other form components
    public struct EditableTimeField: View {
        // MARK: Lifecycle

        public init(
            icon: String? = nil,
            label: String? = nil,
            selection: Binding<Date>
        ) {
            self.icon = icon
            self.label = label
            self._selection = selection
        }

        // MARK: Public

        public var body: some View {
            VStack(alignment: .leading, spacing: self.theme.spacing.xs) {
                if let label {
                    HStack(spacing: self.theme.spacing.xs) {
                        if let icon {
                            Text(icon)
                                .font(self.theme.typography.body)
                        }
                        Text(label)
                            .font(self.theme.typography.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(self.theme.colors.textPrimary)
                    }
                    .padding(.horizontal, self.theme.spacing.xs)
                }

                DatePicker(
                    "",
                    selection: self.$selection,
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(self.theme.colors.primary)
                .padding(.horizontal, self.theme.spacing.md)
                .padding(.vertical, self.theme.spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: 50)
                .background(
                    RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.medium)
                        .fill(self.theme.colors.systemSecondaryBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.medium)
                                .strokeBorder(self.theme.colors.borderSecondary, lineWidth: 1)
                        )
                )
            }
        }

        // MARK: Private

        @Environment(\.theme) private var theme

        @Binding private var selection: Date

        private let icon: String?
        private let label: String?
    }

    #if DEBUG
        struct EditableTimeField_Previews: PreviewProvider {
            static var previews: some View {
                VStack(spacing: 24) {
                    EditableTimeField(
                        label: "Start Time",
                        selection: .constant(Date())
                    )

                    EditableTimeField(
                        label: "End Time",
                        selection: .constant(Date())
                    )

                    EditableTimeField(
                        selection: .constant(Date())
                    )
                }
                .padding()
                .background(Color(.systemGroupedBackground))
                .environment(\.theme, DefaultTheme())
            }
        }
    #endif

#endif
