import SwiftUI

#if !os(watchOS)

    // MARK: - SaveRecipeCollectionItem

    /// Lightweight collection info used by the save recipe sheet.
    public struct SaveRecipeCollectionItem: Identifiable, Sendable {
        // MARK: Lifecycle

        public init(id: UUID, name: String, emoji: String?, color: String?, itemCount: Int) {
            self.id = id
            self.name = name
            self.emoji = emoji
            self.color = color
            self.itemCount = itemCount
        }

        // MARK: Public

        public let id: UUID
        public let name: String
        public let emoji: String?
        public let color: String?
        public let itemCount: Int
    }

    // MARK: - SaveRecipeSheet

    /// A sheet that allows the user to rename a parsed recipe, optionally pick
    /// or create a collection, then confirm or cancel.
    ///
    /// Used by both the Share Extension and the main app Open In Niora flow.
    @available(iOS 26.0, *)
    public struct SaveRecipeSheet: View {
        // MARK: Lifecycle

        public init(
            recipeName: String,
            collections: [SaveRecipeCollectionItem],
            isLoadingCollections: Bool,
            isSaving: Bool,
            onLoadCollections: @escaping () async throws -> Void,
            onCreateCollection: @escaping (String, String?, String?, String?) async throws -> UUID,
            onSave: @escaping (String, UUID?) async -> Void,
            onCancel: @escaping () -> Void
        ) {
            self._editedName = State(initialValue: recipeName)
            self.collections = collections
            self.isLoadingCollections = isLoadingCollections
            self.isSaving = isSaving
            self.onLoadCollections = onLoadCollections
            self.onCreateCollection = onCreateCollection
            self.onSave = onSave
            self.onCancel = onCancel
        }

        // MARK: Public

        public var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(spacing: self.theme.spacing.lg) {
                        self.nameSection
                        self.collectionSection
                    }
                    .padding(self.theme.spacing.lg)
                }
                .scrollDismissesKeyboard(.interactively)
                .background(self.theme.colors.background)
                .navigationTitle(String(localized: "save_recipe.title", bundle: SharedDesignBundle.bundle))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .cancel) {
                            self.onCancel()
                        }
                        .tint(self.theme.colors.primary)
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        // Wrap the loading spinner in a disabled Button so the
                        // toolbar gives it the same vertical metrics as the
                        // real `Button(role: .confirm)` — rendering `LoadingView`
                        // as a bare toolbar item gets it clipped top/bottom.
                        // Same pattern `ExerciseDetailView`'s play/loading
                        // toolbar button uses for its loading state.
                        if self.isSaving {
                            Button(action: { }, label: {
                                LoadingView(size: 16)
                            })
                            .disabled(true)
                            .tint(self.theme.colors.primary)
                        } else {
                            Button(role: .confirm) {
                                Task {
                                    let name = self.editedName.trimmingCharacters(in: .whitespacesAndNewlines)
                                    await self.onSave(name, self.selectedCollectionId)
                                }
                            }
                            .disabled(self.editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .tint(self.theme.colors.primary)
                        }
                    }
                }
                .task {
                    do {
                        try await self.onLoadCollections()
                    } catch {
                        self.errorToastMessage = String(
                            localized: "save_recipe.error.load_collections_failed",
                            bundle: SharedDesignBundle.bundle
                        )
                        self.showErrorToast = true
                    }
                }
                .sheet(isPresented: self.$showingCreateCollection) {
                    self.createCollectionSheet
                        .presentationDetents([.height(520)])
                        .presentationDragIndicator(.visible)
                }
                .toast(
                    isShowing: self.$showErrorToast,
                    message: self.errorToastMessage,
                    type: .error
                )
            }
        }

        // MARK: Private

        // MARK: - Create Collection Sheet

        private static let presetColors: [(hex: String, name: String)] = [
            ("#FF6B35", "Orange"),
            ("#E74C3C", "Red"),
            ("#9B59B6", "Purple"),
            ("#3498DB", "Blue"),
            ("#2ECC71", "Green"),
            ("#F39C12", "Yellow"),
            ("#1ABC9C", "Teal"),
            ("#E91E63", "Pink")
        ]

        private static let emojiOptions: [String] = [
            "\u{1F4C1}", "\u{1F355}", "\u{1F4AA}", "\u{1F957}", "\u{1F3CB}\u{FE0F}", "\u{1F525}", "\u{2764}\u{FE0F}",
            "\u{2B50}",
            "\u{1F3AF}", "\u{1F951}", "\u{1F373}", "\u{1F969}", "\u{1F41F}", "\u{1F32E}", "\u{1F35C}", "\u{1F382}",
            "\u{1F3C3}", "\u{1F9D8}", "\u{1F6B4}", "\u{26A1}", "\u{1F31F}", "\u{1F4CC}", "\u{1F3A8}", "\u{1F331}"
        ]

        @Environment(\.theme) private var theme

        @State private var editedName: String
        @State private var selectedCollectionId: UUID?
        @State private var showingCreateCollection = false
        @FocusState private var isNameFocused: Bool

        // Create collection form state
        @State private var newCollectionName = ""
        @State private var newCollectionDescription = ""
        @State private var newCollectionEmoji: String?
        @State private var newCollectionColor: String?
        @State private var isCreatingCollection = false
        @State private var showEmojiPicker = false
        @State private var showErrorToast = false
        @State private var errorToastMessage = ""
        @FocusState private var isCollectionNameFocused: Bool

        private let collections: [SaveRecipeCollectionItem]
        private let isLoadingCollections: Bool
        private let isSaving: Bool
        private let onLoadCollections: () async throws -> Void
        private let onCreateCollection: (String, String?, String?, String?) async throws -> UUID
        private let onSave: (String, UUID?) async -> Void
        private let onCancel: () -> Void

        private var canCreateCollection: Bool {
            !self.newCollectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !self
                .isCreatingCollection
        }

        // MARK: - Name Section

        private var nameSection: some View {
            VStack(alignment: .leading, spacing: self.theme.spacing.sm) {
                Text(String(localized: "save_recipe.name_label", bundle: SharedDesignBundle.bundle))
                    .font(self.theme.typography.footnote)
                    .foregroundStyle(self.theme.colors.textSecondary)

                TextField(
                    String(localized: "save_recipe.name_placeholder", bundle: SharedDesignBundle.bundle),
                    text: self.$editedName
                )
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(self.theme.colors.textPrimary)
                .focused(self.$isNameFocused)
                .submitLabel(.done)
                .padding(self.theme.spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.medium)
                        .fill(self.theme.colors.surface)
                )
            }
        }

        // MARK: - Collection Section

        private var collectionSection: some View {
            VStack(alignment: .leading, spacing: self.theme.spacing.sm) {
                Text(String(localized: "save_recipe.collection_label", bundle: SharedDesignBundle.bundle))
                    .font(self.theme.typography.footnote)
                    .foregroundStyle(self.theme.colors.textSecondary)

                if self.isLoadingCollections && self.collections.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding(self.theme.spacing.lg)
                } else {
                    VStack(spacing: 0) {
                        self.newCollectionRow

                        // "None" option
                        self.noneCollectionRow

                        ForEach(self.collections) { collection in
                            self.collectionRow(collection)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.medium)
                            .fill(self.theme.colors.surface)
                    )
                }
            }
        }

        private var newCollectionRow: some View {
            Button {
                self.showingCreateCollection = true
            } label: {
                HStack(spacing: self.theme.spacing.md) {
                    ZStack {
                        Circle()
                            .fill(self.theme.colors.primary.opacity(0.12))
                            .frame(width: 36, height: 36)
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(self.theme.colors.primary)
                    }

                    Text(String(localized: "save_recipe.new_collection", bundle: SharedDesignBundle.bundle))
                        .font(self.theme.typography.headline)
                        .foregroundStyle(self.theme.colors.primary)

                    Spacer()
                }
                .padding(.horizontal, self.theme.spacing.md)
                .padding(.vertical, self.theme.spacing.sm)
            }
        }

        private var noneCollectionRow: some View {
            Button {
                self.selectedCollectionId = nil
            } label: {
                HStack(spacing: self.theme.spacing.md) {
                    ZStack {
                        Circle()
                            .fill(self.theme.colors.textTertiary.opacity(0.12))
                            .frame(width: 36, height: 36)
                        Image(systemName: "tray")
                            .font(.system(size: 14))
                            .foregroundStyle(self.theme.colors.textSecondary)
                    }

                    Text(String(localized: "save_recipe.no_collection", bundle: SharedDesignBundle.bundle))
                        .font(self.theme.typography.body)
                        .foregroundStyle(self.theme.colors.textPrimary)

                    Spacer()

                    Image(systemName: self.selectedCollectionId == nil ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundStyle(
                            self.selectedCollectionId == nil
                                ? self.theme.colors.primary
                                : self.theme.colors.textTertiary
                        )
                        .contentTransition(.symbolEffect(.replace))
                }
                .padding(.horizontal, self.theme.spacing.md)
                .padding(.vertical, self.theme.spacing.sm)
            }
        }

        private var createCollectionSheet: some View {
            NavigationStack {
                ScrollView {
                    VStack(spacing: self.theme.spacing.lg) {
                        self.emojiButton
                            .padding(.top, self.theme.spacing.sm)

                        TextField(
                            String(localized: "save_recipe.create_collection.name_placeholder", bundle: SharedDesignBundle.bundle),
                            text: self.$newCollectionName
                        )
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(self.theme.colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .focused(self.$isCollectionNameFocused)
                        .submitLabel(.next)

                        TextField(
                            String(localized: "save_recipe.create_collection.description_placeholder", bundle: SharedDesignBundle.bundle),
                            text: self.$newCollectionDescription,
                            axis: .vertical
                        )
                        .font(self.theme.typography.body)
                        .foregroundStyle(self.theme.colors.textPrimary)
                        .lineLimit(2...3)
                        .padding(self.theme.spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.medium)
                                .fill(self.theme.colors.surface)
                        )

                        self.colorRow

                        Button {
                            self.submitCreateCollection()
                        } label: {
                            HStack {
                                if self.isCreatingCollection {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text(String(localized: "save_recipe.create_collection.button", bundle: SharedDesignBundle.bundle))
                                        .fontWeight(.semibold)
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, self.theme.spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.medium)
                                    .fill(
                                        self.canCreateCollection
                                            ? self.theme.colors.primary
                                            : self.theme.colors.textTertiary
                                    )
                            )
                        }
                        .disabled(!self.canCreateCollection)
                    }
                    .padding(self.theme.spacing.lg)
                }
                .scrollDismissesKeyboard(.interactively)
                .navigationTitle(String(localized: "save_recipe.create_collection.title", bundle: SharedDesignBundle.bundle))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            self.showingCreateCollection = false
                        } label: {
                            Text(String(localized: "save_recipe.cancel", bundle: SharedDesignBundle.bundle))
                        }
                        .tint(self.theme.colors.primary)
                    }
                }
                .onAppear {
                    self.isCollectionNameFocused = true
                }
            }
        }

        private var emojiButton: some View {
            VStack(spacing: self.theme.spacing.sm) {
                Button {
                    self.isCollectionNameFocused = false
                    self.showEmojiPicker.toggle()
                } label: {
                    ZStack {
                        Circle()
                            .fill(self.theme.colors.surface)
                            .frame(width: 64, height: 64)
                            .shadow(color: self.theme.colors.textPrimary.opacity(0.08), radius: 4, x: 0, y: 2)

                        if let emoji = self.newCollectionEmoji {
                            Text(emoji)
                                .font(.system(size: 32))
                        } else {
                            Image(systemName: "face.smiling")
                                .font(.system(size: 24))
                                .foregroundStyle(self.theme.colors.textTertiary)
                        }
                    }
                }

                if self.showEmojiPicker {
                    self.emojiGrid
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .animation(.easeOut(duration: 0.2), value: self.showEmojiPicker)
        }

        private var emojiGrid: some View {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: self.theme.spacing.xs), count: 8),
                spacing: self.theme.spacing.xs
            ) {
                Button {
                    self.newCollectionEmoji = nil
                    self.showEmojiPicker = false
                } label: {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(self.theme.colors.textTertiary)
                        .frame(width: 36, height: 36)
                }

                ForEach(Self.emojiOptions, id: \.self) { emoji in
                    Button {
                        self.newCollectionEmoji = emoji
                        self.showEmojiPicker = false
                    } label: {
                        Text(emoji)
                            .font(.system(size: 24))
                            .frame(width: 36, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.small)
                                    .fill(
                                        self.newCollectionEmoji == emoji
                                            ? self.theme.colors.primary.opacity(0.15)
                                            : Color.clear
                                    )
                            )
                    }
                }
            }
            .padding(self.theme.spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: self.theme.sizing.cornerRadius.medium)
                    .fill(self.theme.colors.surface)
            )
        }

        private var colorRow: some View {
            VStack(alignment: .leading, spacing: self.theme.spacing.sm) {
                Text(String(localized: "save_recipe.create_collection.color_label", bundle: SharedDesignBundle.bundle))
                    .font(self.theme.typography.footnote)
                    .foregroundStyle(self.theme.colors.textSecondary)

                HStack(spacing: self.theme.spacing.sm) {
                    Button {
                        self.newCollectionColor = nil
                    } label: {
                        ZStack {
                            Circle()
                                .stroke(self.theme.colors.textTertiary, lineWidth: 1.5)
                                .frame(width: 28, height: 28)

                            if self.newCollectionColor == nil {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(self.theme.colors.textSecondary)
                            }
                        }
                    }

                    ForEach(Self.presetColors, id: \.hex) { preset in
                        Button {
                            self.newCollectionColor = preset.hex
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: preset.hex))
                                    .frame(width: 28, height: 28)

                                if self.newCollectionColor == preset.hex {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                    }
                }
            }
        }

        private func collectionRow(_ collection: SaveRecipeCollectionItem) -> some View {
            let isSelected = self.selectedCollectionId == collection.id
            let cellColor: Color? = collection.color.map { Color(hex: $0) }

            return Button {
                if isSelected {
                    self.selectedCollectionId = nil
                } else {
                    self.selectedCollectionId = collection.id
                }
            } label: {
                HStack(spacing: self.theme.spacing.md) {
                    ZStack {
                        Circle()
                            .fill((cellColor ?? self.theme.colors.primary).opacity(0.12))
                            .frame(width: 36, height: 36)

                        if let emoji = collection.emoji {
                            Text(emoji)
                                .font(.system(size: 18))
                        } else {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(cellColor ?? self.theme.colors.primary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(collection.name)
                            .font(self.theme.typography.body)
                            .foregroundStyle(self.theme.colors.textPrimary)
                        Text(String(localized: "save_recipe.items_count \(collection.itemCount)", bundle: SharedDesignBundle.bundle))
                            .font(self.theme.typography.footnote)
                            .foregroundStyle(self.theme.colors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundStyle(isSelected ? self.theme.colors.primary : self.theme.colors.textTertiary)
                        .contentTransition(.symbolEffect(.replace))
                }
                .padding(.horizontal, self.theme.spacing.md)
                .padding(.vertical, self.theme.spacing.sm)
            }
        }

        private func submitCreateCollection() {
            self.isCreatingCollection = true
            let trimmedDescription = self.newCollectionDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            Task {
                do {
                    let newId = try await self.onCreateCollection(
                        self.newCollectionName.trimmingCharacters(in: .whitespacesAndNewlines),
                        trimmedDescription.isEmpty ? nil : trimmedDescription,
                        self.newCollectionEmoji,
                        self.newCollectionColor
                    )
                    self.selectedCollectionId = newId
                    self.isCreatingCollection = false
                    self.showingCreateCollection = false
                    // Reset form state
                    self.newCollectionName = ""
                    self.newCollectionDescription = ""
                    self.newCollectionEmoji = nil
                    self.newCollectionColor = nil
                } catch {
                    self.isCreatingCollection = false
                    self.showingCreateCollection = false
                    self.errorToastMessage = String(
                        localized: "save_recipe.error.create_collection_failed",
                        bundle: SharedDesignBundle.bundle
                    )
                    self.showErrorToast = true
                }
            }
        }
    }

#endif // !os(watchOS)
