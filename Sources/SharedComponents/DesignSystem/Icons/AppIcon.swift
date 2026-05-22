import SwiftUI

// MARK: - IconCategory

public enum IconCategory: String, CaseIterable {
    case navigation
    case nutrition
    case fitness
    case health
    case time
    case chartsAndProgress = "charts & progress"
    case achievements
    case arrowsAndChevrons = "arrows & chevrons"
    case uiActions = "ui actions"
    case misc
}

// MARK: - AppIcon

/// Type-safe catalog of all 93 custom icons in Icons.xcassets.
/// Use `.image(size:)` to render, or pass `.rawValue` to `AppIconView`.
public enum AppIcon: String, CaseIterable, Sendable {
    // MARK: - Navigation

    case home
    case activity

    // MARK: - Nutrition

    case bread
    case carbs
    case protein
    case fat
    case calorieIntake
    case calorieAlt
    case mealPrep
    case mealplan
    case fridge
    case diet
    case waterdrop
    case serving

    // MARK: - Fitness

    case dumbell
    case kettlebell
    case liftWeight
    case legRaise
    case playingFootball
    case tennis
    case tenn
    case soccer
    case basketball
    case baseball
    case golf
    case volleyball
    case dance
    case cycling
    case hiking
    case swimming
    case walking
    case yoga
    case stretch
    case stretch2
    case squat
    case kick

    // MARK: - Health

    case activityHeart
    case sleep
    case step
    case fire
    case zap

    // MARK: - Time & Calendar

    case fasting
    case duration
    case stopwatch
    case clockalert
    case calendertoday
    case dateweekdays
    case dateweekly
    case night
    case moonstar
    case sunrise
    case sunset
    case sun
    case pause

    // MARK: - Charts & Progress

    case graphLine
    case macroDistribution
    case progress25
    case progress50
    case progress75
    case progress100
    case rating
    case star
    case starLine

    // MARK: - Achievements

    case trophy
    case wreath
    case flag

    // MARK: - Arrows & Chevrons

    case arrowdownright
    case arrowupright
    case arrowtrianglebottom
    case arrowtriangletop
    case chevrondownsmall
    case chevrontopsmall
    case chevrondownmedium
    case chevrontopmedium
    case chevrontriangledownsmall
    case chevrontriangleupsmall

    // MARK: - UI Actions

    case plus
    case minus
    case pluscircle
    case cancel
    case check
    case delete
    case edit
    case edit2
    case editPencil
    case editHistory
    case favourite
    case lock
    case love
    case minimize

    // MARK: - Misc

    case tips
    case info
    case bubbles
    case aiSummary
    case cosmos
    case dollar
    case target
    case type92

    // MARK: Public

    /// Returns icons grouped by category, preserving category order.
    public static var groupedByCategory: [(category: IconCategory, icons: [AppIcon])] {
        let grouped = Dictionary(grouping: allCases) { $0.category }
        return IconCategory.allCases.compactMap { category in
            guard let icons = grouped[category], !icons.isEmpty else {
                return nil
            }
            return (category: category, icons: icons)
        }
    }

    public var category: IconCategory {
        switch self {
        case .home, .activity:
            .navigation
        case .bread, .carbs, .protein, .fat, .calorieIntake, .calorieAlt,
             .mealPrep, .mealplan, .fridge, .diet, .waterdrop, .serving:
            .nutrition
        case .dumbell, .kettlebell, .liftWeight, .legRaise, .playingFootball,
             .tennis, .tenn, .soccer, .basketball, .baseball, .golf,
             .volleyball, .dance, .cycling, .hiking, .swimming, .walking,
             .yoga, .stretch, .stretch2, .squat, .kick:
            .fitness
        case .activityHeart, .sleep, .step, .fire, .zap:
            .health
        case .fasting, .duration, .stopwatch, .clockalert, .calendertoday,
             .dateweekdays, .dateweekly, .night, .moonstar, .sunrise,
             .sunset, .sun, .pause:
            .time
        case .graphLine, .macroDistribution, .progress25, .progress50,
             .progress75, .progress100, .rating, .star, .starLine:
            .chartsAndProgress
        case .trophy, .wreath, .flag:
            .achievements
        case .arrowdownright, .arrowupright, .arrowtrianglebottom,
             .arrowtriangletop, .chevrondownsmall, .chevrontopsmall,
             .chevrondownmedium, .chevrontopmedium,
             .chevrontriangledownsmall, .chevrontriangleupsmall:
            .arrowsAndChevrons
        case .plus, .minus, .pluscircle, .cancel, .check, .delete,
             .edit, .edit2, .editPencil, .editHistory,
             .favourite, .lock, .love, .minimize:
            .uiActions
        case .tips, .info, .bubbles, .aiSummary, .cosmos, .dollar,
             .target, .type92:
            .misc
        }
    }

    // MARK: - View Helpers

    @ViewBuilder
    public func image(size: CGFloat? = nil) -> some View {
        let img = Image(rawValue)
            .resizable()
            .aspectRatio(contentMode: .fit)
        if let size {
            img.frame(width: size, height: size)
        } else {
            img
        }
    }
}
