import SwiftUI

#if os(iOS)

    /// A form field designed for editable settings with clear visual affordance
    /// that the value is tappable and editable
    public struct EditableFormField<Content: View>: View {
        // MARK: Lifecycle

        public init(
            icon: String,
            iconColor: Color? = nil,
            title: String,
            @ViewBuilder content: @escaping () -> Content
        ) {
            self.icon = icon
            self.iconColor = iconColor
            self.title = title
            self.content = content
        }

        // MARK: Public

        public var body: some View {
            HStack(spacing: self.theme.spacing.md) {
                // Icon with background
                Image(systemName: self.icon)
                    .font(self.theme.typography.title3)
                    .foregroundColor(self.iconColor ?? self.theme.colors.primary)
                    .iconBackground(self.iconColor ?? self.theme.colors.primary)
                    .accessibilityHidden(true)

                // Title
                Text(self.title)
                    .font(self.theme.typography.body)
                    .foregroundColor(self.theme.colors.textPrimary)

                Spacer()

                // Editable content area
                self.content()
            }
            .padding(.vertical, self.theme.spacing.sm)
        }

        // MARK: Private

        @Environment(\.theme) private var theme

        private let icon: String
        private let iconColor: Color?
        private let title: String
        private let content: () -> Content
    }

    /// A styled numeric input field for settings (compact, inline style)
    /// For richer nutrition/recipe inputs, use NumericInputField from NumericInputField.swift
    public struct SettingsNumericField: View {
        // MARK: Lifecycle

        public init(
            value: Binding<Int>,
            placeholder: String = "",
            unit: String,
            width: CGFloat = 80,
            accessibilityIdentifier: String? = nil
        ) {
            self._value = value
            self.placeholder = placeholder
            self.unit = unit
            self.width = width
            self.accessibilityIdentifier = accessibilityIdentifier
        }

        // MARK: Public

        public var body: some View {
            HStack(spacing: self.theme.spacing.sm) {
                TextField(self.placeholder, value: self.$value, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(self.theme.typography.body.weight(.medium))
                    .foregroundColor(self.theme.colors.textPrimary)
                    .frame(width: self.width)
                    .padding(.horizontal, self.theme.spacing.sm)
                    .padding(.vertical, self.theme.spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.small)
                            .fill(self.theme.colors.systemSecondaryBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.small)
                            .strokeBorder(
                                self.isFocused
                                    ? self.theme.colors.primary
                                    : self.theme.colors.borderSecondary,
                                lineWidth: self.isFocused ? 1.5 : 1
                            )
                    )
                    .focused(self.$isFocused)
                    .accessibilityIdentifier(self.accessibilityIdentifier ?? "")

                Text(self.unit)
                    .font(self.theme.typography.subheadline)
                    .foregroundColor(self.theme.colors.textSecondary)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }

        // MARK: Internal

        @Binding var value: Int

        let placeholder: String
        let unit: String
        let width: CGFloat
        let accessibilityIdentifier: String?

        // MARK: Private

        @Environment(\.theme) private var theme

        @FocusState private var isFocused: Bool
    }

    /// A styled numeric input field for Double values in settings (compact, inline style)
    /// For richer nutrition/recipe inputs, use NumericInputField from NumericInputField.swift
    public struct SettingsNumericDoubleField: View {
        // MARK: Lifecycle

        public init(
            value: Binding<Double>,
            placeholder: String = "",
            unit: String,
            width: CGFloat = 80,
            accessibilityIdentifier: String? = nil
        ) {
            self._value = value
            self.placeholder = placeholder
            self.unit = unit
            self.width = width
            self.accessibilityIdentifier = accessibilityIdentifier
        }

        // MARK: Public

        public var body: some View {
            HStack(spacing: self.theme.spacing.sm) {
                TextField(self.placeholder, value: self.$value, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(self.theme.typography.body.weight(.medium))
                    .foregroundColor(self.theme.colors.textPrimary)
                    .frame(width: self.width)
                    .padding(.horizontal, self.theme.spacing.sm)
                    .padding(.vertical, self.theme.spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.small)
                            .fill(self.theme.colors.systemSecondaryBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.small)
                            .strokeBorder(
                                self.isFocused
                                    ? self.theme.colors.primary
                                    : self.theme.colors.borderSecondary,
                                lineWidth: self.isFocused ? 1.5 : 1
                            )
                    )
                    .focused(self.$isFocused)
                    .accessibilityIdentifier(self.accessibilityIdentifier ?? "")

                Text(self.unit)
                    .font(self.theme.typography.subheadline)
                    .foregroundColor(self.theme.colors.textSecondary)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }

        // MARK: Internal

        @Binding var value: Double

        let placeholder: String
        let unit: String
        let width: CGFloat
        let accessibilityIdentifier: String?

        // MARK: Private

        @Environment(\.theme) private var theme

        @FocusState private var isFocused: Bool
    }

    /// A styled picker field that looks clearly interactive
    public struct PickerField<SelectionValue: Hashable, Content: View>: View {
        // MARK: Lifecycle

        public init(
            selection: Binding<SelectionValue>,
            accessibilityIdentifier: String? = nil,
            @ViewBuilder content: @escaping () -> Content
        ) {
            self._selection = selection
            self.accessibilityIdentifier = accessibilityIdentifier
            self.content = content
        }

        // MARK: Public

        public var body: some View {
            Picker("", selection: self.$selection) {
                self.content()
            }
            .pickerStyle(.menu)
            .tint(self.theme.colors.textPrimary)
            .padding(.horizontal, self.theme.spacing.sm)
            .padding(.vertical, self.theme.spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.small)
                    .fill(self.theme.colors.systemSecondaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.small)
                    .strokeBorder(self.theme.colors.borderSecondary, lineWidth: 1)
            )
            .accessibilityIdentifier(self.accessibilityIdentifier ?? "")
        }

        // MARK: Internal

        @Binding var selection: SelectionValue

        let accessibilityIdentifier: String?
        let content: () -> Content

        // MARK: Private

        @Environment(\.theme) private var theme
    }

    /// A styled date picker field that looks clearly interactive
    public struct DatePickerField: View {
        // MARK: Lifecycle

        public init(
            selection: Binding<Date>,
            displayedComponents: DatePickerComponents = .hourAndMinute,
            accessibilityIdentifier: String? = nil
        ) {
            self._selection = selection
            self.displayedComponents = displayedComponents
            self.accessibilityIdentifier = accessibilityIdentifier
        }

        // MARK: Public

        public var body: some View {
            DatePicker(
                "",
                selection: self.$selection,
                displayedComponents: self.displayedComponents
            )
            .labelsHidden()
            .tint(self.theme.colors.textPrimary)
            .padding(.horizontal, self.theme.spacing.sm)
            .padding(.vertical, self.theme.spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.small)
                    .fill(self.theme.colors.systemSecondaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.small)
                    .strokeBorder(self.theme.colors.borderSecondary, lineWidth: 1)
            )
            .accessibilityIdentifier(self.accessibilityIdentifier ?? "")
        }

        // MARK: Internal

        @Binding var selection: Date

        let displayedComponents: DatePickerComponents
        let accessibilityIdentifier: String?

        // MARK: Private

        @Environment(\.theme) private var theme
    }

    #if DEBUG
        struct EditableFormField_Previews: PreviewProvider {
            static var previews: some View {
                VStack(spacing: 16) {
                    EditableFormField(icon: "flame.fill", iconColor: .orange, title: "Daily Calories") {
                        SettingsNumericField(
                            value: .constant(2500),
                            placeholder: "2500",
                            unit: "cals"
                        )
                    }

                    EditableFormField(icon: "drop.fill", iconColor: .blue, title: "Daily Water") {
                        SettingsNumericDoubleField(
                            value: .constant(2500.0),
                            placeholder: "2500",
                            unit: "ml"
                        )
                    }

                    EditableFormField(icon: "clock", title: "Duration") {
                        PickerField(selection: .constant(45)) {
                            Text("30 min").tag(30)
                            Text("45 min").tag(45)
                            Text("60 min").tag(60)
                        }
                    }

                    EditableFormField(icon: "clock", title: "Start Time") {
                        DatePickerField(
                            selection: .constant(Date()),
                            displayedComponents: .hourAndMinute
                        )
                    }
                }
                .padding()
                .environment(\.theme, DefaultTheme())
            }
        }
    #endif

#endif
