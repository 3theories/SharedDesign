import SwiftUI

// MARK: - SearchResultsHeader

public struct SearchResultsHeader: View {
    // MARK: Lifecycle

    public init(count: Int, itemName: String) {
        self.count = count
        self.itemName = itemName
    }

    // MARK: Public

    public var body: some View {
        HStack {
            Text(String(
                localized: "search.results.count",
                defaultValue: "\(self.count) \(self.itemName)\(self.count == 1 ? "" : "s") found",
                bundle: .module,
                comment: "Search results count header with number and item name"
            ))
            .font(.headline)
            .foregroundStyle(self.theme.colors.textSecondary)
            Spacer()
        }
        .padding(.horizontal)
    }

    // MARK: Private

    @Environment(\.theme) private var theme

    private let count: Int
    private let itemName: String
}
