import SwiftUI

#if os(iOS)

    /// A premium numeric input field with unit support and larger touch targets
    /// Optimized for nutrition and measurement inputs with clear visual affordance.
    ///
    /// Usage:
    /// ```swift
    /// NumericInputField(
    ///     label: "Calories",
    ///     value: $calories,
    ///     unit: "kcal"
    /// )
    /// ```
    public struct NumericInputField<Value: Numeric & LosslessStringConvertible>: View {
        // MARK: Lifecycle

        /// Creates a NumericInputField.
        ///
        /// - Parameters:
        ///   - icon: Optional emoji or text icon to display
        ///   - label: Optional label text above the field
        ///   - placeholder: Placeholder text when field is empty
        ///   - value: Binding to the numeric value
        ///   - unit: Optional unit label (e.g., "kcal", "g", "min")
        ///   - keyboardType: The keyboard type to use
        ///   - formatter: Optional NumberFormatter for display formatting
        public init(
            icon: String? = nil,
            label: String? = nil,
            placeholder: String = "0",
            value: Binding<Value>,
            unit: String? = nil,
            keyboardType: UIKeyboardType = .decimalPad,
            formatter: NumberFormatter? = nil,
            accessibilityIdentifier: String? = nil
        ) {
            self.icon = icon
            self.label = label
            self.placeholder = placeholder
            self._value = value
            self.unit = unit
            self.keyboardType = keyboardType
            self.formatter = formatter
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

                    Spacer()

                    TextField(self.placeholder, text: self.textBinding)
                        .font(self.theme.typography.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(self.theme.colors.textPrimary)
                        .keyboardType(self.keyboardType)
                        .multilineTextAlignment(.trailing)
                        .focused(self.$isFocused)
                        .tint(self.theme.colors.primary)
                        .frame(minWidth: 80) // Larger touch target for better usability
                        .accessibilityIdentifier(self.accessibilityIdentifier ?? "")

                    if let unit {
                        Text(unit)
                            .font(self.theme.typography.body)
                            .fontWeight(.medium)
                            .foregroundColor(self.theme.colors.textSecondary)
                            .frame(width: 40, alignment: .leading)
                    }
                }
                .padding(.horizontal, self.theme.spacing.md)
                .padding(.vertical, self.theme.spacing.md)
                .frame(minHeight: 50) // Slightly larger for numeric inputs
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
        @Binding private var value: Value

        private let icon: String?
        private let label: String?
        private let placeholder: String
        private let unit: String?
        private let keyboardType: UIKeyboardType
        private let formatter: NumberFormatter?
        private let accessibilityIdentifier: String?

        private var displayValue: String {
            if let formatter = self.formatter {
                return formatter.string(for: self.value) ?? "\(self.value)"
            }
            return "\(self.value)"
        }

        private var textBinding: Binding<String> {
            Binding<String>(
                get: {
                    self.displayValue
                },
                set: { newValue in
                    if let numericValue = Value(newValue) {
                        self.value = numericValue
                    } else if newValue.isEmpty, let zero = Value(exactly: 0) {
                        // Safely set to zero if the field is cleared and zero is valid for this type
                        self.value = zero
                    }
                    // If empty and zero is not valid, keep the current value (better UX)
                }
            )
        }
    }

    /// Convenience initializers for common types
    extension NumericInputField where Value == Int {
        public init(
            icon: String? = nil,
            label: String? = nil,
            placeholder: String = "0",
            value: Binding<Int>,
            unit: String? = nil,
            accessibilityIdentifier: String? = nil
        ) {
            self.init(
                icon: icon,
                label: label,
                placeholder: placeholder,
                value: value,
                unit: unit,
                keyboardType: .numberPad,
                formatter: nil,
                accessibilityIdentifier: accessibilityIdentifier
            )
        }
    }

    extension NumericInputField where Value == Double {
        public init(
            icon: String? = nil,
            label: String? = nil,
            placeholder: String = "0",
            value: Binding<Double>,
            unit: String? = nil,
            accessibilityIdentifier: String? = nil
        ) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 1
            formatter.minimumFractionDigits = 0

            self.init(
                icon: icon,
                label: label,
                placeholder: placeholder,
                value: value,
                unit: unit,
                keyboardType: .decimalPad,
                formatter: formatter,
                accessibilityIdentifier: accessibilityIdentifier
            )
        }
    }

    #if DEBUG
        struct NumericInputField_Previews: PreviewProvider {
            static var previews: some View {
                VStack(spacing: 24) {
                    NumericInputField(
                        label: "Calories",
                        value: .constant(500),
                        unit: "kcal"
                    )

                    NumericInputField(
                        label: "Protein",
                        value: .constant(25.5),
                        unit: "g"
                    )

                    NumericInputField(
                        label: "Carbs",
                        value: .constant(30.0),
                        unit: "g"
                    )

                    NumericInputField(
                        label: "Fat",
                        value: .constant(15.0),
                        unit: "g"
                    )

                    NumericInputField(
                        label: "Preparation Time",
                        value: .constant(30),
                        unit: "min"
                    )
                }
                .padding()
                .background(Color(.systemGroupedBackground))
                .environment(\.theme, DefaultTheme())
            }
        }
    #endif

#endif
