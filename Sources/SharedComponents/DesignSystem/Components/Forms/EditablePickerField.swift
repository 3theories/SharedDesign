import SwiftUI

#if os(iOS)

    /// A premium picker field component that matches the EditableTextField styling
    /// Includes icon support, focus states, and minimum 44pt touch target
    public struct EditablePickerField<SelectionValue: Hashable>: View {
        // MARK: Lifecycle

        public init(
            icon: String? = nil,
            label: String? = nil,
            placeholder: String? = nil,
            selection: Binding<SelectionValue>,
            options: [SelectionValue],
            optionLabel: @escaping (SelectionValue) -> String
        ) {
            self.icon = icon
            self.label = label
            self.placeholder = placeholder ?? String(
                localized: "picker.placeholder.select",
                defaultValue: "Select",
                bundle: .module,
                comment: "Picker field default placeholder text"
            )
            self._selection = selection
            self.options = options
            self.optionLabel = optionLabel
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

                Menu {
                    ForEach(self.options, id: \.self) { option in
                        Button {
                            self.selection = option
                        } label: {
                            HStack {
                                Text(self.optionLabel(option))
                                if option == self.selection {
                                    Image(systemName: "checkmark")
                                        .accessibilityHidden(true)
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: self.theme.spacing.sm) {
                        if let icon, label == nil {
                            Text(icon)
                                .font(self.theme.typography.title3)
                                .frame(width: 28)
                        }

                        Spacer()

                        Text(self.optionLabel(self.selection))
                            .font(self.theme.typography.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(self.theme.colors.textPrimary)

                        Image(systemName: "chevron.up.chevron.down")
                            .font(self.theme.typography.caption1)
                            .foregroundColor(self.theme.colors.textSecondary)
                            .accessibilityHidden(true)
                    }
                    .padding(.horizontal, self.theme.spacing.md)
                    .padding(.vertical, self.theme.spacing.md)
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
                .buttonStyle(.plain)
            }
        }

        // MARK: Private

        @Environment(\.theme) private var theme

        @Binding private var selection: SelectionValue

        private let icon: String?
        private let label: String?
        private let placeholder: String
        private let options: [SelectionValue]
        private let optionLabel: (SelectionValue) -> String
    }

    /// String-based convenience initializer for EditablePickerField
    extension EditablePickerField where SelectionValue == String {
        public init(
            icon: String? = nil,
            label: String? = nil,
            placeholder: String? = nil,
            selection: Binding<String>,
            options: [String]
        ) {
            self.icon = icon
            self.label = label
            self.placeholder = placeholder ?? String(
                localized: "picker.placeholder.select",
                defaultValue: "Select",
                bundle: .module,
                comment: "Picker field default placeholder text"
            )
            self._selection = selection
            self.options = options
            self.optionLabel = { $0 }
        }
    }

    #if DEBUG
        struct EditablePickerField_Previews: PreviewProvider {
            static var previews: some View {
                VStack(spacing: 24) {
                    EditablePickerField(
                        label: "Cuisine",
                        selection: .constant("Italian"),
                        options: ["Italian", "Mexican", "Chinese", "Japanese", "Indian"]
                    )

                    EditablePickerField(
                        label: "Difficulty",
                        selection: .constant("Easy"),
                        options: ["Easy", "Medium", "Hard"]
                    )

                    EditablePickerField(
                        label: "Category",
                        selection: .constant("Breakfast"),
                        options: ["Breakfast", "Lunch", "Dinner", "Snack"]
                    )
                }
                .padding()
                .background(Color(.systemGroupedBackground))
                .environment(\.theme, DefaultTheme())
            }
        }
    #endif

#endif
