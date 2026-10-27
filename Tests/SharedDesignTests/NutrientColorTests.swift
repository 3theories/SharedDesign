@testable import SharedDesign
import SwiftUI
import Testing

struct NutrientColorTests {
    @Test func darkPaletteUsesDarkNutritionVariants() {
        let dark = DarkColorPalette()
        #expect(dark.nutrientProtein == Color(hex: 0x64D2FF))
        #expect(dark.nutrientCarbs == Color(hex: 0x30D158))
        #expect(dark.nutrientFat == Color(hex: 0xFF375F))
    }

    @Test func lightPaletteUsesNutritionCategories() {
        let light = LightColorPalette()
        #expect(light.nutrientProtein == Color(hex: 0x5AC8FA))
        #expect(light.nutrientCarbs == Color(hex: 0x34C759))
        #expect(light.nutrientFat == Color(hex: 0xFF2D55))
    }

    @Test func darkNutrientColorsAreNotStatusColors() {
        let dark = DarkColorPalette()
        #expect(dark.nutrientProtein != dark.error)
        #expect(dark.nutrientCarbs != dark.primary)
        #expect(dark.nutrientFat != dark.success)
    }
}
