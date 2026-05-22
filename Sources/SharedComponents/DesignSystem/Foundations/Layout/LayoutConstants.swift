import SwiftUI

// MARK: - LayoutConstants

/// Layout constants for consistent layouts across the app
public enum LayoutConstants {
    /// Container configurations
    public enum Container {
        public static let maxWidth: CGFloat = 428 // Standard iPhone width
        public static let maxWidthTablet: CGFloat = 768
        public static let maxWidthDesktop: CGFloat = 1200
        public static let minTouchTarget: CGFloat = 44 // Apple HIG minimum
    }

    /// Grid system
    public enum Grid {
        public static let columns: Int = 12
        public static let gutterPhone: CGFloat = 16
        public static let gutterTablet: CGFloat = 24
        public static let marginPhone: CGFloat = 16
        public static let marginTablet: CGFloat = 32
    }

    /// List configurations
    public enum List {
        public static let rowMinHeight: CGFloat = 44
        public static let rowStandardHeight: CGFloat = 60
        public static let rowExpandedHeight: CGFloat = 80
        public static let sectionHeaderHeight: CGFloat = 28
        public static let sectionFooterHeight: CGFloat = 28
        public static let separatorInset: CGFloat = 16
    }

    /// Sheet configurations
    public enum Sheet {
        public static let cornerRadius: CGFloat = 16
        public static let grabberWidth: CGFloat = 36
        public static let grabberHeight: CGFloat = 5
        public static let detentSmall: CGFloat = 0.25
        public static let detentMedium: CGFloat = 0.5
        public static let detentLarge: CGFloat = 0.95
    }

    /// Animation timings
    public enum Animation {
        public static let instant: Double = 0
        public static let fast: Double = 0.15
        public static let regular: Double = 0.25
        public static let slow: Double = 0.35
        public static let verySlow: Double = 0.5
    }

    /// Z-index layers
    public enum ZIndex {
        public static let background: Double = -1
        public static let content: Double = 0
        public static let elevated: Double = 1
        public static let overlay: Double = 10
        public static let modal: Double = 100
        public static let alert: Double = 1000
        public static let system: Double = 10000
    }
}

#if os(iOS)
    /// Adaptive layout utilities
    public enum AdaptiveLayout {
        /// Get appropriate value based on horizontal size class
        public static func value<T>(
            compact: T,
            regular: T,
            horizontalSizeClass: UserInterfaceSizeClass?
        ) -> T {
            switch horizontalSizeClass {
            case .compact, .none:
                return compact
            case .regular:
                return regular
            @unknown default:
                return compact
            }
        }

        // Get appropriate value based on device idiom
        #if canImport(UIKit) && !os(watchOS)
            public static func value<T>(
                phone: T,
                pad: T,
                idiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom
            ) -> T {
                switch idiom {
                case .phone:
                    phone
                case .pad:
                    pad
                default:
                    phone
                }
            }
        #else
            public static func value<T>(
                phone: T,
                pad: T
            ) -> T {
                // Default to phone values on platforms without UIDevice
                phone
            }
        #endif

        /// Check if current device is compact
        public static func isCompact(horizontalSizeClass: UserInterfaceSizeClass?) -> Bool {
            horizontalSizeClass == .compact || horizontalSizeClass == nil
        }
    }

    /// Safe area utilities
    public enum SafeAreaUtils {
        /// Standard keyboard avoidance padding
        public static let keyboardPadding: CGFloat = 16

        /// Get safe area with minimum padding
        public static func safeAreaWithMinimum(
            _ edges: Edge.Set,
            minimum: CGFloat = 16
        ) -> some View {
            ModifiedContent(
                content: Color.clear,
                modifier: SafeAreaModifier(edges: edges, minimum: minimum)
            )
        }
    }

    /// Safe area modifier with minimum padding
    struct SafeAreaModifier: ViewModifier {
        // MARK: Lifecycle

        func body(content: Content) -> some View {
            content
                .padding(self.edges, self.minimum)
                .ignoresSafeArea(.container, edges: self.edges)
        }

        // MARK: Internal

        let edges: Edge.Set
        let minimum: CGFloat
    }

#endif
