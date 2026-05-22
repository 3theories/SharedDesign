import SwiftUI

/// Data model for nutrition tracking visualization
public struct NutritionData: Sendable {
    // MARK: Lifecycle

    public init(
        calories: MacroValue,
        protein: MacroValue,
        carbs: MacroValue,
        fat: MacroValue
    ) {
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }

    // MARK: Public

    /// Macro value with consumed/target amounts
    public struct MacroValue: Sendable {
        // MARK: Lifecycle

        public init(consumed: Double, target: Double) {
            self.consumed = consumed
            self.target = target
        }

        // MARK: Public

        public let consumed: Double
        public let target: Double

        public var progress: Double {
            guard self.target > 0 else {
                return 0
            }
            return min(self.consumed / self.target, 1.0)
        }

        public var percentage: Int {
            Int(self.progress * 100)
        }

        public var remaining: Double {
            max(self.target - self.consumed, 0)
        }
    }

    public let calories: MacroValue
    public let protein: MacroValue
    public let carbs: MacroValue
    public let fat: MacroValue
}

// Note: MacroType is defined in SharedMacroCard.swift
