import SwiftUI

// MARK: - GallerySection

public struct GallerySection<Item: Identifiable, Header: View, Cell: View>: View {
    // MARK: Lifecycle

    public init(
        items: [Item],
        maxVisible: Int = 4,
        @ViewBuilder header: @escaping () -> Header,
        @ViewBuilder cell: @escaping (Item) -> Cell
    ) {
        self.items = items
        self.maxVisible = maxVisible
        self.header = header
        self.cell = cell
    }

    // MARK: Public

    public var body: some View {
        VStack(alignment: .leading, spacing: self.theme.spacing.md) {
            // Section Header with Show All toggle
            HStack {
                self.header()

                Spacer()

                if self.items.count > self.maxVisible {
                    Button {
                        HapticManager.shared.trigger(.selection)
                        withAnimation {
                            self.showAll.toggle()
                        }
                    } label: {
                        Text(
                            self.showAll
                                ? String(
                                    localized: "gallery.showLess",
                                    defaultValue: "Show Less",
                                    bundle: .module,
                                    comment: "Gallery section collapse button"
                                )
                                : String(
                                    localized: "gallery.showAll",
                                    defaultValue: "Show All (\(self.items.count))",
                                    bundle: .module,
                                    comment: "Gallery section expand button with item count"
                                )
                        )
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(self.theme.colors.primary)
                    }
                }
            }
            .padding(.horizontal)

            // Grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: self.theme.spacing.md),
                GridItem(.flexible(), spacing: self.theme.spacing.md)
            ], spacing: self.theme.spacing.md) {
                ForEach(self.visibleItems) { item in
                    self.cell(item)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: Private

    @Environment(\.theme) private var theme
    @State private var showAll = false

    private let items: [Item]
    private let maxVisible: Int
    private let header: () -> Header
    private let cell: (Item) -> Cell

    private var visibleItems: [Item] {
        self.showAll ? self.items : Array(self.items.prefix(self.maxVisible))
    }
}
