import SwiftUI

// MARK: - Color Extensions

extension Color {
    /// Initialize a Color from a hex integer
    public init(hex: Int) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }

    /// Initialize a Color from a hex string (e.g. "#FF6B35" or "FF6B35").
    public init(hex string: String) {
        let hex = string.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - ColorPalette

/// Raw color palette - base colors used throughout the app
public enum ColorPalette {
    // MARK: - Figma Primitive Color Scales

    /// Sunrise Amber hue family (8 shades, 800=darkest, 100=lightest)
    public enum SunriseAmber {
        public static let shade800 = Color(hex: 0x6A2000)
        public static let shade700 = Color(hex: 0x422006)
        public static let shade600 = Color(hex: 0x713F12)
        public static let shade500 = Color(hex: 0xFFAC24)
        public static let shade400 = Color(hex: 0xFFCA4E)
        public static let shade300 = Color(hex: 0xFACC15)
        public static let shade200 = Color(hex: 0xFEF08A)
        public static let shade100 = Color(hex: 0xFEFCE8)
    }

    /// Vital Orange hue family (8 shades, 800=darkest, 100=lightest)
    public enum VitalOrange {
        public static let shade800 = Color(hex: 0x460D04)
        public static let shade700 = Color(hex: 0x431407)
        public static let shade600 = Color(hex: 0x7C2D12)
        public static let shade500 = Color(hex: 0xF7572D)
        public static let shade400 = Color(hex: 0xEA580C)
        public static let shade300 = Color(hex: 0xF97316)
        public static let shade200 = Color(hex: 0xFED7AA)
        public static let shade100 = Color(hex: 0xFFF7ED)
    }

    /// Pulse Purple hue family (8 shades, 800=darkest, 100=lightest)
    public enum PulsePurple {
        public static let shade800 = Color(hex: 0x13003D)
        public static let shade700 = Color(hex: 0x251065)
        public static let shade600 = Color(hex: 0x3B1D95)
        public static let shade500 = Color(hex: 0x673AED)
        public static let shade400 = Color(hex: 0x7349F5)
        public static let shade300 = Color(hex: 0x825CF6)
        public static let shade200 = Color(hex: 0xE0D6FE)
        public static let shade100 = Color(hex: 0xF6F3FF)
    }

    /// Deep Wellness Green hue family (8 shades, 800=darkest, 100=lightest)
    public enum DeepWellnessGreen {
        public static let shade800 = Color(hex: 0x002C0E)
        public static let shade700 = Color(hex: 0x003D2A)
        public static let shade600 = Color(hex: 0x10654A)
        public static let shade500 = Color(hex: 0x047954)
        public static let shade400 = Color(hex: 0x1D956F)
        public static let shade300 = Color(hex: 0x5CF6C5)
        public static let shade200 = Color(hex: 0xD6FEF1)
        public static let shade100 = Color(hex: 0xF3FFFB)
    }

    /// Sky Clarity Blue hue family (8 shades, 800=darkest, 100=lightest)
    public enum SkyClarityBlue {
        public static let shade800 = Color(hex: 0x042146)
        public static let shade700 = Color(hex: 0x072143)
        public static let shade600 = Color(hex: 0x12407C)
        public static let shade500 = Color(hex: 0x2D85F7)
        public static let shade400 = Color(hex: 0x0C6CEA)
        public static let shade300 = Color(hex: 0x1678F9)
        public static let shade200 = Color(hex: 0xAACEFE)
        public static let shade100 = Color(hex: 0xEDF5FF)
    }

    /// Grey Neutral scale (pure grey, 12 shades, 050=lightest, 600=darkest)
    public enum GreyNeutral {
        public static let shade050 = Color(hex: 0xFFFFFF)
        public static let shade100 = Color(hex: 0xFAFAFA)
        public static let shade150 = Color(hex: 0xEEEEEE)
        public static let shade200 = Color(hex: 0xD4D4D4)
        public static let shade250 = Color(hex: 0xAEAEAE)
        public static let shade300 = Color(hex: 0x808080)
        public static let shade350 = Color(hex: 0x5C5C5C)
        public static let shade400 = Color(hex: 0x3A3A3A)
        public static let shade450 = Color(hex: 0x242424)
        public static let shade500 = Color(hex: 0x161616)
        public static let shade550 = Color(hex: 0x080808)
        public static let shade600 = Color(hex: 0x000000)
    }

    /// Grey Cool scale (cool-tinted grey, 12 shades, 050=lightest, 600=darkest)
    public enum GreyCool {
        public static let shade050 = Color(hex: 0xFFFFFF)
        public static let shade100 = Color(hex: 0xFAFAFB)
        public static let shade150 = Color(hex: 0xEDEEF2)
        public static let shade200 = Color(hex: 0xD3D4D7)
        public static let shade250 = Color(hex: 0xACAEB1)
        public static let shade300 = Color(hex: 0x7F8083)
        public static let shade350 = Color(hex: 0x5B5C5F)
        public static let shade400 = Color(hex: 0x3A3A3D)
        public static let shade450 = Color(hex: 0x232426)
        public static let shade500 = Color(hex: 0x151618)
        public static let shade550 = Color(hex: 0x07080A)
        public static let shade600 = Color(hex: 0x000000)
    }

    /// Transparent Dark overlay scale (black + alpha, for light backgrounds)
    public enum TransparentDark {
        public static let opacity100 = Color.black.opacity(1.00)
        public static let opacity90 = Color.black.opacity(0.90)
        public static let opacity80 = Color.black.opacity(0.80)
        public static let opacity70 = Color.black.opacity(0.70)
        public static let opacity60 = Color.black.opacity(0.60)
        public static let opacity50 = Color.black.opacity(0.50)
        public static let opacity40 = Color.black.opacity(0.40)
        public static let opacity30 = Color.black.opacity(0.30)
        public static let opacity20 = Color.black.opacity(0.20)
        public static let opacity15 = Color.black.opacity(0.15)
        public static let opacity10 = Color.black.opacity(0.10)
        public static let opacity05 = Color.black.opacity(0.05)
    }

    /// Transparent Light overlay scale (white + alpha, for dark backgrounds)
    public enum TransparentLight {
        public static let opacity100 = Color.white.opacity(1.00)
        public static let opacity90 = Color.white.opacity(0.90)
        public static let opacity80 = Color.white.opacity(0.80)
        public static let opacity70 = Color.white.opacity(0.70)
        public static let opacity60 = Color.white.opacity(0.60)
        public static let opacity50 = Color.white.opacity(0.50)
        public static let opacity40 = Color.white.opacity(0.40)
        public static let opacity30 = Color.white.opacity(0.30)
        public static let opacity20 = Color.white.opacity(0.20)
        public static let opacity15 = Color.white.opacity(0.15)
        public static let opacity10 = Color.white.opacity(0.10)
        public static let opacity05 = Color.white.opacity(0.05)
    }

    // MARK: - Brand Colors (aliases into Figma scales)

    /// Brand colors - Niora Design System v2
    public enum Brand {
        public static let primary = Color(hex: 0xF97316) // Orange - main brand color (Figma: Primary)
        public static let primaryLight = Color(hex: 0xFF8E78) // Light Orange - secondary brand

        public static var secondary: Color { PulsePurple.shade400 }
        public static var tertiary: Color { DeepWellnessGreen.shade500 }
    }

    /// Grayscale - Optimized for dark theme based on app screenshots
    public enum Gray {
        public static let gray50 = Color(hex: 0xF2F2F7) // Light mode only
        public static let gray100 = Color(hex: 0xE5E5EA) // Light mode only
        public static let gray200 = Color(hex: 0xD1D1D6) // Light mode text
        public static let gray300 = Color(hex: 0xC7C7CC) // Light mode secondary

        public static var gray400: Color { Color(hex: 0x8E8E93) } // Disabled/tertiary text
        public static var gray500: Color { Color(hex: 0x636366) } // Secondary text dark
        public static var gray600: Color { Color(hex: 0x48484A) } // Quaternary fill
        public static var gray700: Color { GreyNeutral.shade400 } // Tertiary fill (~0x3A3A3A)
        public static var gray800: Color { Color(hex: 0x2C2C2E) } // Secondary fill/surface
        public static var gray850: Color { Color(hex: 0x1C1C1E) } // Primary surface
        public static var gray900: Color { GreyNeutral.shade600 } // True black background
    }

    /// Semantic colors - Niora Design System v2
    public enum Semantic {
        public static let error = Color(hex: 0xFF3B30) // Keep existing red

        public static var success: Color { DeepWellnessGreen.shade500 }
        public static var warning: Color { SunriseAmber.shade500 }
        public static var info: Color { SkyClarityBlue.shade200 }
    }

    /// Base colors for modules - Niora Design System v2
    public enum Base {
        // Core iOS colors (retained)
        public static let green = Color(hex: 0x34C759)
        public static let yellow = Color(hex: 0xFFCC00)
        public static let orange = Color(hex: 0xFF9500)
        public static let red = Color(hex: 0xFF3B30)
        public static let blue = Color(hex: 0x007AFF)
        public static let cyan = Color(hex: 0x32ADE6)
        public static let purple = Color(hex: 0x5856D6)
        public static let pink = Color(hex: 0xFF2D55)

        public static let lightOrange = Color(hex: 0xFF8E78)
        public static let midnightCharcoal = Color(hex: 0x1B1B1E)
        public static let mintEnergy = Color(hex: 0x4CE0B3)

        // Niora Design System v2 colors (aliases into Figma scales)
        public static var vitalOrange: Color { VitalOrange.shade500 }
        public static var deepGreen: Color { DeepWellnessGreen.shade500 }
        public static var sunriseAmber: Color { SunriseAmber.shade500 }
        public static var pulsePurple: Color { PulsePurple.shade400 }
        public static var skyBlue: Color { SkyClarityBlue.shade200 }
    }

    // Feature-specific colors - Based on app needs
    // DEPRECATED: Use NutritionCategories for macro colors
    // This namespace now redirects to NutritionCategories for consistency
    public enum Nutrition {
        // Meal timing (unique to this namespace)
        public static let breakfast = Color(hex: 0xFF9500) // Orange
        public static let dinner = Color(hex: 0xFF6B6B) // Red

        public static var lunch: Color { SunriseAmber.shade500 }
        public static var snack: Color { PulsePurple.shade400 }

        // Macronutrients - redirect to NutritionCategories for single source of truth
        public static var protein: Color { NutritionCategories.protein }
        public static var carbs: Color { NutritionCategories.carbs }
        public static var fat: Color { NutritionCategories.fats }
        public static var fiber: Color { NutritionCategories.fiber }
    }

    public enum Fitness {
        // Metrics - Industry Standard
        public static let heartRate = Color(hex: 0xFF3B30) // Red for heart rate (Apple Health standard)
        public static let calories = Color(hex: 0xFF9500) // Orange for calories (fire association)
        public static let steps = Color(hex: 0x34C759) // iOS green for steps
        public static let distance = Color(hex: 0x007AFF) // iOS blue for distance
        public static let duration = Color(hex: 0x5856D6) // Purple for time

        // Intensity levels
        public static let lowIntensity = Color(hex: 0x34C759) // Green
        public static let moderateIntensity = Color(hex: 0xFFCC00) // Yellow
        public static let highIntensity = Color(hex: 0xFF9500) // Orange
        public static let maxIntensity = Color(hex: 0xFF3B30) // Red
    }

    public enum Hydration {
        public static let water = Color(hex: 0x0A84FF) // Vibrant iOS blue
        public static let electrolytes = Color(hex: 0x32ADE6) // Cyan
        public static let caffeine = Color(hex: 0x8B4513) // Brown
        public static let alcohol = Color(hex: 0xAF52DE) // Purple
    }

    public enum Chart {
        // For data visualization - Niora Design System v2
        public static let primary = Color(hex: 0xFF9500) // Orange
        public static let quaternary = Color(hex: 0x4CE0B3) // Mint Energy

        public static var secondary: Color { PulsePurple.shade400 }
        public static var tertiary: Color { DeepWellnessGreen.shade500 }
        public static var quinary: Color { SkyClarityBlue.shade200 }
    }

    // MARK: - Workout Intensity Zones

    /// Heart rate and workout intensity zones for visualization
    public enum IntensityZones {
        public static let zone1 = Color(hex: 0x3B82F6) // Very Light - Blue
        public static let zone2 = Color(hex: 0x10B981) // Light - Green
        public static let zone3 = Color(hex: 0xF59E0B) // Moderate - Amber
        public static let zone4 = Color(hex: 0xEF4444) // Hard - Red
        public static let zone5 = Color(hex: 0x991B1B) // Maximum - Dark Red

        /// All zones in order for easy iteration
        public static let allZones = [zone1, zone2, zone3, zone4, zone5]

        /// Zone names for display
        public static let zoneNames = [
            "Recovery", "Aerobic Base", "Aerobic", "Lactate Threshold", "VO2 Max"
        ]

        /// Get color for zone number (1-5)
        public static func color(for zone: Int) -> Color {
            switch zone {
            case 1: self.zone1
            case 2: self.zone2
            case 3: self.zone3
            case 4: self.zone4
            case 5: self.zone5
            default: self.zone2 // Default to light intensity
            }
        }

        /// Get zone name for zone number (1-5)
        public static func name(for zone: Int) -> String {
            guard zone >= 1 && zone <= 5 else {
                return "Unknown"
            }
            return self.zoneNames[zone - 1]
        }
    }

    // MARK: - Enhanced Nutrition Categories

    /// Expanded nutrition visualization colors for detailed macro and micronutrient tracking
    public enum NutritionCategories {
        // Macronutrients - Industry Standard (MyFitnessPal style)
        public static let protein = Color(hex: 0x5AC8FA) // Blue (industry standard for protein)
        public static let carbs = Color(hex: 0x34C759) // Green (industry standard for carbs)
        public static let fats = Color(hex: 0xFF2D55) // Pink/Red (industry standard for fat)
        public static let fiber = Color(hex: 0x8E8E93) // Gray (dietary fiber)

        // Micronutrients
        public static let vitamins = Color(hex: 0x06B6D4) // Cyan
        public static let minerals = Color(hex: 0xEC4899) // Pink

        // Specific Nutrients
        public static let calcium = Color(hex: 0xF3F4F6) // Light Gray
        public static let vitaminC = Color(hex: 0xFDE047) // Bright Yellow
        public static let vitaminD = Color(hex: 0xFBBF24) // Amber
        public static let omega3 = Color(hex: 0x0EA5E9) // Sky Blue
        public static let antioxidants = Color(hex: 0xA855F7) // Violet
        // Quality Indicators
        public static let organic = Color(hex: 0x84CC16) // Lime
        public static let processed = Color(hex: 0xEF4444) // Red
        public static let wholeFoods = Color(hex: 0x059669) // Emerald

        /// All macro colors in typical display order
        public static let macros = [protein, carbs, fats, fiber]

        /// All vitamin/mineral colors
        public static let micronutrients = [vitamins, minerals, calcium, iron, vitaminC, vitaminD]

        /// Quality indicator colors
        public static let qualityIndicators = [organic, processed, wholeFoods]

        public static var iron: Color { VitalOrange.shade600 } // Brown (~0x7C2D12)
    }

    // MARK: - Sleep Quality Zones

    /// Sleep stage and quality visualization colors
    public enum SleepZones {
        public static let awake = Color(hex: 0xFEF3C7) // Light Yellow
        public static let lightSleep = Color(hex: 0xDDD6FE) // Light Purple
        public static let deepSleep = Color(hex: 0x5B21B6) // Deep Purple
        public static let remSleep = Color(hex: 0x1E40AF) // Blue
        public static let restless = Color(hex: 0xFCA5A5) // Light Red

        /// All sleep stages in order
        public static let allStages = [awake, lightSleep, deepSleep, remSleep, restless]

        /// Stage names for display
        public static let stageNames = ["Awake", "Light Sleep", "Deep Sleep", "REM Sleep", "Restless"]

        /// Get color for sleep stage
        public static func color(for stage: String) -> Color {
            switch stage.lowercased() {
            case "awake": self.awake
            case "light", "light sleep": self.lightSleep
            case "deep", "deep sleep": self.deepSleep
            case "rem", "rem sleep": self.remSleep
            case "restless": self.restless
            default: self.lightSleep
            }
        }
    }

    // MARK: - Mood & Stress Indicators

    /// Emotional state and stress level visualization colors
    public enum MoodZones {
        public static let excellent = Color(hex: 0x10B981) // Emerald
        public static let good = Color(hex: 0x84CC16) // Lime
        public static let neutral = Color(hex: 0xF59E0B) // Amber
        public static let poor = Color(hex: 0xF97316) // Orange
        public static let terrible = Color(hex: 0xEF4444) // Red

        // Stress levels
        public static let lowStress = Color(hex: 0x06B6D4) // Cyan
        public static let moderateStress = Color(hex: 0xF59E0B) // Amber
        public static let highStress = Color(hex: 0xEF4444) // Red

        /// Mood scale colors (1-5)
        public static let moodScale = [terrible, poor, neutral, good, excellent]

        /// Stress level colors
        public static let stressLevels = [lowStress, moderateStress, highStress]

        /// Get mood color for rating (1-5)
        public static func moodColor(for rating: Int) -> Color {
            guard rating >= 1 && rating <= 5 else {
                return self.neutral
            }
            return self.moodScale[rating - 1]
        }

        /// Get stress color for level (1-3)
        public static func stressColor(for level: Int) -> Color {
            guard level >= 1 && level <= 3 else {
                return self.lowStress
            }
            return self.stressLevels[level - 1]
        }
    }
}
