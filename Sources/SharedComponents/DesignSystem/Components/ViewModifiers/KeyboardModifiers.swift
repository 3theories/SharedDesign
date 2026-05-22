import SwiftUI

#if os(iOS)

    // MARK: - Keyboard Dismiss Toolbar Modifier

    /// A simple keyboard toolbar with a dismiss button.
    /// Provides a consistent way to dismiss the keyboard across the app.
    ///
    /// Usage:
    /// ```swift
    /// TextField("Name", text: $name)
    ///     .keyboardDismissToolbar()
    ///
    /// // With callback:
    /// TextField("Search", text: $query)
    ///     .keyboardDismissToolbar {
    ///         performSearch()
    ///     }
    /// ```
    public struct KeyboardDismissToolbarModifier: ViewModifier {
        // MARK: Lifecycle

        public init(onDismiss: (() -> Void)? = nil) {
            self.onDismiss = onDismiss
        }

        public func body(content: Content) -> some View {
            content
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()

                        Button {
                            self.hideKeyboard()
                            self.onDismiss?()
                        } label: {
                            Image(systemName: "keyboard.chevron.compact.down")
                        }
                    }
                }
        }

        // MARK: Internal

        let onDismiss: (() -> Void)?

        // MARK: Private

        @Environment(\.theme) private var theme

        private func hideKeyboard() {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }
    }

    // MARK: - Rich Text Keyboard Toolbar Modifier

    /// A keyboard toolbar for rich text editing with custom formatting controls and a dismiss button.
    ///
    /// Usage:
    /// ```swift
    /// TextEditor(text: $text)
    ///     .richTextKeyboardToolbar(isFocused: $isFocused) {
    ///         FormatButton(icon: "bold", action: toggleBold)
    ///         FormatButton(icon: "italic", action: toggleItalic)
    ///     }
    /// ```
    public struct RichTextKeyboardToolbarModifier<FormattingContent: View>: ViewModifier {
        // MARK: Lifecycle

        public init(
            isFocused: Binding<Bool>,
            @ViewBuilder formattingContent: @escaping () -> FormattingContent
        ) {
            self._isFocused = isFocused
            self.formattingContent = formattingContent
        }

        public func body(content: Content) -> some View {
            content
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        self.formattingContent()

                        Spacer()

                        Button {
                            self.hideKeyboard()
                            self.isFocused = false
                        } label: {
                            Image(systemName: "keyboard.chevron.compact.down")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(self.theme.colors.primary)
                        }
                        .frame(minWidth: 44, minHeight: 44)
                    }
                }
        }

        // MARK: Internal

        @Binding var isFocused: Bool

        let formattingContent: () -> FormattingContent

        // MARK: Private

        @Environment(\.theme) private var theme

        private func hideKeyboard() {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }
    }

    // MARK: - View Extensions

    extension View {
        /// Adds a keyboard toolbar with a dismiss button.
        ///
        /// Use this modifier to provide a consistent keyboard dismiss experience.
        ///
        /// - Parameter onDismiss: Optional callback when dismiss is tapped
        public func keyboardDismissToolbar(onDismiss: (() -> Void)? = nil) -> some View {
            modifier(KeyboardDismissToolbarModifier(onDismiss: onDismiss))
        }

        /// Adds a keyboard toolbar with a dismiss button.
        /// Alias for `keyboardDismissToolbar` for backward compatibility.
        ///
        /// - Parameter onDone: Optional callback when dismiss is tapped
        public func keyboardDoneToolbar(onDone: (() -> Void)? = nil) -> some View {
            modifier(KeyboardDismissToolbarModifier(onDismiss: onDone))
        }

        /// Adds a keyboard toolbar for rich text editing with custom formatting controls.
        ///
        /// - Parameters:
        ///   - isFocused: Binding to the focus state
        ///   - formatting: ViewBuilder for formatting controls
        public func richTextKeyboardToolbar(
            isFocused: Binding<Bool>,
            @ViewBuilder formatting: @escaping () -> some View
        ) -> some View {
            modifier(RichTextKeyboardToolbarModifier(
                isFocused: isFocused,
                formattingContent: formatting
            ))
        }
    }

    // MARK: - Preview

    #if DEBUG
        struct KeyboardModifiers_Previews: PreviewProvider {
            static var previews: some View {
                NavigationStack {
                    KeyboardModifiersPreviewContent()
                }
                .environment(\.theme, DefaultTheme())
            }
        }

        private struct KeyboardModifiersPreviewContent: View {
            // MARK: Internal

            var body: some View {
                Form {
                    TextField("Name", text: self.$name)

                    TextField("Email", text: self.$email)

                    TextEditor(text: self.$notes)
                        .frame(height: 100)
                        .focused(self.$isFocused)
                }
                .keyboardDismissToolbar()
                .navigationTitle("Keyboard Dismiss")
            }

            // MARK: Private

            @State private var name = ""
            @State private var email = ""
            @State private var notes = ""
            @FocusState private var isFocused: Bool
        }
    #endif

#endif
