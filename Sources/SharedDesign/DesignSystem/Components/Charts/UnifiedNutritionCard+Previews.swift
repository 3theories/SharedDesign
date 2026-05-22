import SwiftUI

// MARK: - Comprehensive Previews

#if !os(watchOS)
    #Preview("Light Mode - Low Progress") {
        UnifiedNutritionCard(
            data: NutritionData(
                calories: .init(consumed: 750, target: 2500),
                protein: .init(consumed: 45, target: 150),
                carbs: .init(consumed: 80, target: 280),
                fat: .init(consumed: 25, target: 70)
            )
        )
        .padding()
        .background(Color(.systemGroupedBackground))
        .preferredColorScheme(.light)
    }

    #Preview("Dark Mode - Low Progress") {
        UnifiedNutritionCard(
            data: NutritionData(
                calories: .init(consumed: 750, target: 2500),
                protein: .init(consumed: 45, target: 150),
                carbs: .init(consumed: 80, target: 280),
                fat: .init(consumed: 25, target: 70)
            )
        )
        .padding()
        .background(Color(.systemGroupedBackground))
        .preferredColorScheme(.dark)
    }

    #Preview("Light Mode - Medium Progress") {
        UnifiedNutritionCard(
            data: NutritionData(
                calories: .init(consumed: 1400, target: 2500),
                protein: .init(consumed: 90, target: 150),
                carbs: .init(consumed: 160, target: 280),
                fat: .init(consumed: 48, target: 70)
            )
        )
        .padding()
        .background(Color(.systemGroupedBackground))
        .preferredColorScheme(.light)
    }

    #Preview("Dark Mode - Medium Progress") {
        UnifiedNutritionCard(
            data: NutritionData(
                calories: .init(consumed: 1400, target: 2500),
                protein: .init(consumed: 90, target: 150),
                carbs: .init(consumed: 160, target: 280),
                fat: .init(consumed: 48, target: 70)
            )
        )
        .padding()
        .background(Color(.systemGroupedBackground))
        .preferredColorScheme(.dark)
    }

    #Preview("Light Mode - Near Complete") {
        UnifiedNutritionCard(
            data: NutritionData(
                calories: .init(consumed: 2400, target: 2500),
                protein: .init(consumed: 145, target: 150),
                carbs: .init(consumed: 270, target: 280),
                fat: .init(consumed: 68, target: 70)
            )
        )
        .padding()
        .background(Color(.systemGroupedBackground))
        .preferredColorScheme(.light)
    }

    #Preview("Dark Mode - Near Complete") {
        UnifiedNutritionCard(
            data: NutritionData(
                calories: .init(consumed: 2400, target: 2500),
                protein: .init(consumed: 145, target: 150),
                carbs: .init(consumed: 270, target: 280),
                fat: .init(consumed: 68, target: 70)
            )
        )
        .padding()
        .background(Color(.systemGroupedBackground))
        .preferredColorScheme(.dark)
    }

    #Preview("In Card - Light") {
        Card(showShadow: true) {
            VStack(spacing: 16) {
                HStack {
                    Text("Nutrition Intake")
                        .font(.headline)
                    Spacer()
                }

                UnifiedNutritionCard(
                    data: NutritionData(
                        calories: .init(consumed: 1739, target: 2925),
                        protein: .init(consumed: 120, target: 150),
                        carbs: .init(consumed: 190, target: 300),
                        fat: .init(consumed: 70, target: 80)
                    )
                )
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .preferredColorScheme(.light)
    }

    #Preview("In Card - Dark") {
        Card(showShadow: true) {
            VStack(spacing: 16) {
                HStack {
                    Text("Nutrition Intake")
                        .font(.headline)
                    Spacer()
                }

                UnifiedNutritionCard(
                    data: NutritionData(
                        calories: .init(consumed: 1739, target: 2925),
                        protein: .init(consumed: 120, target: 150),
                        carbs: .init(consumed: 190, target: 300),
                        fat: .init(consumed: 70, target: 80)
                    )
                )
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .preferredColorScheme(.dark)
    }
#endif
