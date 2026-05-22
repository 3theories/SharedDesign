import SwiftUI

#if os(iOS)

    /// A premium text field component with clear visual affordance for editability
    /// Includes icon support, focus states, and minimum 44pt touch target.
    ///
    /// Usage:
    /// ```swift
    /// EditableTextField(
    ///     label: "Name",
    ///     placeholder: "Enter name",
    ///     text: $name
    /// )
    /// ```
    public struct EditableTextField: View {
        // MARK: Lifecycle

        /// Creates an EditableTextField.
        ///
        /// - Parameters:
        ///   - icon: Optional emoji or text icon to display
        ///   - label: Optional label text above the field
        ///   - placeholder: Placeholder text when field is empty
        ///   - text: Binding to the text value
        ///   - keyboardType: The keyboard type to use
        ///   - textInputAutocapitalization: Text capitalization behavior
        ///   - autocorrectionDisabled: Whether to disable autocorrection
        ///   - multilineTextAlignment: Text alignment within the field
        ///   - accessibilityIdentifier: Optional accessibility identifier
        public init(
            icon: String? = nil,
            label: String? = nil,
            placeholder: String,
            text: Binding<String>,
            keyboardType: UIKeyboardType = .default,
            textInputAutocapitalization: TextInputAutocapitalization = .sentences,
            autocorrectionDisabled: Bool = false,
            multilineTextAlignment: TextAlignment = .leading,
            accessibilityIdentifier: String? = nil
        ) {
            self.icon = icon
            self.label = label
            self.placeholder = placeholder
            self._text = text
            self.keyboardType = keyboardType
            self.textInputAutocapitalization = textInputAutocapitalization
            self.autocorrectionDisabled = autocorrectionDisabled
            self.multilineTextAlignment = multilineTextAlignment
            self.accessibilityIdentifier = accessibilityIdentifier
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

                HStack(spacing: self.theme.spacing.sm) {
                    if self.icon != nil, self.label == nil {
                        Text(self.icon!)
                            .font(self.theme.typography.title3)
                            .frame(width: 28)
                    }

                    TextField(self.placeholder, text: self.$text)
                        .font(self.theme.typography.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(self.theme.colors.textPrimary)
                        .textInputAutocapitalization(self.textInputAutocapitalization)
                        .autocorrectionDisabled(self.autocorrectionDisabled)
                        .keyboardType(self.keyboardType)
                        .multilineTextAlignment(self.multilineTextAlignment)
                        .focused(self.$isFocused)
                        .tint(self.theme.colors.primary)
                        .accessibilityIdentifier(self.accessibilityIdentifier ?? "")

                    if self.isFocused && !self.text.isEmpty {
                        Button(action: { self.text = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(self.theme.colors.textSecondary)
                                .imageScale(.medium)
                        }
                        .accessibilityLabel("Clear text")
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, self.theme.spacing.md)
                .padding(.vertical, self.theme.spacing.md)
                .frame(minHeight: 50)
                .background(
                    RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.medium)
                        .fill(self.theme.colors.systemSecondaryBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.medium)
                                .strokeBorder(
                                    self.isFocused
                                        ? self.theme.colors.primary
                                        : self.theme.colors.borderSecondary,
                                    lineWidth: self.isFocused ? 2 : 1
                                )
                        )
                )
                .shadow(
                    color: self.isFocused ? self.theme.colors.primary.opacity(0.1) : .clear,
                    radius: 8,
                    x: 0,
                    y: 4
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: self.isFocused)
            }
        }

        // MARK: Private

        @Environment(\.theme) private var theme
        @FocusState private var isFocused: Bool
        @Binding private var text: String

        private let icon: String?
        private let label: String?
        private let placeholder: String
        private let keyboardType: UIKeyboardType
        private let textInputAutocapitalization: TextInputAutocapitalization
        private let autocorrectionDisabled: Bool
        private let multilineTextAlignment: TextAlignment
        private let accessibilityIdentifier: String?
    }

    #if DEBUG
        struct EditableTextField_Previews: PreviewProvider {
            static var previews: some View {
                VStack(spacing: 24) {
                    EditableTextField(
                        icon: "📝",
                        label: "Recipe Name",
                        placeholder: "Enter recipe name",
                        text: .constant("")
                    )

                    EditableTextField(
                        icon: "👤",
                        label: "Your Name",
                        placeholder: "Enter your name",
                        text: .constant("John Doe")
                    )

                    EditableTextField(
                        label: "Email",
                        placeholder: "you@example.com",
                        text: .constant(""),
                        keyboardType: .emailAddress,
                        textInputAutocapitalization: .never
                    )

                    EditableTextField(
                        placeholder: "Search...",
                        text: .constant("")
                    )
                }
                .padding()
                .background(Color(.systemGroupedBackground))
                .environment(\.theme, DefaultTheme())
            }
        }
    #endif

#endif
