import SwiftUI
#if canImport(UIKit)
    import UIKit
#endif

#if os(iOS)

    // MARK: - AccessibilityAnnouncement

    /// Centralized VoiceOver announcement utilities
    public enum AccessibilityAnnouncement {
        /// Post a VoiceOver announcement with optional delay
        public static func announce(_ message: String, delay: TimeInterval = 0.1) {
            #if canImport(UIKit)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    UIAccessibility.post(notification: .announcement, argument: message)
                }
            #endif
        }

        /// Notify VoiceOver that the screen has changed (e.g., navigation transition)
        public static func screenChanged(_ message: String? = nil) {
            #if canImport(UIKit)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    UIAccessibility.post(notification: .screenChanged, argument: message)
                }
            #endif
        }

        /// Notify VoiceOver that the layout has changed (e.g., content update)
        public static func layoutChanged(_ element: Any? = nil) {
            #if canImport(UIKit)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    UIAccessibility.post(notification: .layoutChanged, argument: element)
                }
            #endif
        }
    }

#endif
