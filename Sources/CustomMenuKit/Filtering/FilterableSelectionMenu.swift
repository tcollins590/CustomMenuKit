import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - MenuSelectionStyle
/// How the selected row is indicated in a ``FilterableSelectionMenu``.
public enum MenuSelectionStyle {
    /// A trailing checkmark on the selected row. This is the default and the
    /// original behavior.
    case checkmark
    /// The selected row's label is rendered accent-tinted and semibold, with no
    /// checkmark. Useful when a `trailingAction` occupies the checkmark slot —
    /// a checkmark beside it would otherwise read as part of that control.
    case tintedLabel
}

// MARK: - FilterableSelectionMenu
/// A menu designed for single selection with checkmarks, search, and filtering capabilities.
/// Use this when your data type conforms to `Filterable` and you need advanced filtering.
public struct FilterableSelectionMenu<Label: View, T: Filterable, OptionIcon: View, TrailingAction: View>: View {
    @Binding var selection: T?
    let options: [T]
    let groups: [MenuItemGroup<T>]
    let label: (T?) -> Label
    let optionLabel: (T) -> String
    let optionIcon: ((T) -> OptionIcon)?
    let trailingAction: ((T) -> TrailingAction)?
    /// How the selected row is indicated. Defaults to `.checkmark`.
    let selectionStyle: MenuSelectionStyle
    let searchable: Bool
    let filterable: Bool
    let filterValueLabel: (AnyHashable) -> String

    @State private var searchText: String = ""
    @State private var filterState: FilterState<T.FilterKey> = FilterState()
    @State private var expandedGroups: Set<UUID> = []
    @FocusState private var isSearchFocused: Bool

    // Optional presentation control forwarded to CustomMenu
    private let isPresentedExternal: Binding<Bool>?
    private let onOpen: (() -> Void)?
    private let onClose: (() -> Void)?

    // Computed hierarchical content
    private var hierarchicalContent: HierarchicalMenuContent<T> {
        HierarchicalMenuContent(groups: groups, ungroupedItems: options)
    }

    /// Creates a filterable selection menu with optional folder groupings, custom icons, and trailing actions.
    /// - Parameters:
    ///   - selection: Binding to the currently selected item.
    ///   - options: Array of ungrouped options to display.
    ///   - groups: Array of folder groups containing items.
    ///   - label: ViewBuilder for the menu's trigger label.
    ///   - optionLabel: Closure to get display text for each option.
    ///   - optionIcon: Optional ViewBuilder closure to render an icon for each option.
    ///   - trailingAction: Optional ViewBuilder closure to render a trailing action button for each option.
    ///     The trailing action does NOT dismiss the menu, allowing multiple interactions.
    ///   - selectionStyle: How the selected row is indicated. Defaults to
    ///     `.checkmark`. Use `.tintedLabel` when a `trailingAction` occupies the
    ///     checkmark slot.
    ///   - searchable: Whether to show a search bar. Defaults to `true`.
    ///   - filterable: Whether to show the filter button. Defaults to `true`.
    ///   - filterValueLabel: Closure to convert filter values to display strings.
    ///   - isPresented: Optional binding for external presentation control.
    ///   - onOpen: Optional callback when the menu opens.
    ///   - onClose: Optional callback when the menu closes.
    public init(
        selection: Binding<T?>,
        options: [T] = [],
        groups: [MenuItemGroup<T>] = [],
        @ViewBuilder label: @escaping (T?) -> Label,
        optionLabel: @escaping (T) -> String = { "\($0)" },
        @ViewBuilder optionIcon: @escaping (T) -> OptionIcon,
        @ViewBuilder trailingAction: @escaping (T) -> TrailingAction,
        selectionStyle: MenuSelectionStyle = .checkmark,
        searchable: Bool = true,
        filterable: Bool = true,
        filterValueLabel: @escaping (AnyHashable) -> String = { "\($0)" },
        isPresented: Binding<Bool>? = nil,
        onOpen: (() -> Void)? = nil,
        onClose: (() -> Void)? = nil
    ) {
        self._selection = selection
        self.options = options
        self.groups = groups
        self.label = label
        self.optionLabel = optionLabel
        self.optionIcon = optionIcon
        self.trailingAction = trailingAction
        self.selectionStyle = selectionStyle
        self.searchable = searchable
        self.filterable = filterable
        self.filterValueLabel = filterValueLabel
        self.isPresentedExternal = isPresented
        self.onOpen = onOpen
        self.onClose = onClose
    }

    /// All items for filter value extraction
    private var allItems: [T] {
        hierarchicalContent.allItems
    }

    /// Filtered items (applies filter state to all items)
    private var filteredAllItems: Set<T> {
        if filterState.isEmpty {
            return Set(allItems)
        }
        return Set(allItems.filter { filterState.matches($0) })
    }

    /// Check if an item passes the current filter
    private func passesFilter(_ item: T) -> Bool {
        filteredAllItems.contains(item)
    }

    /// Find the group ID that contains the given item
    private func groupContaining(_ item: T?) -> UUID? {
        guard let item = item else { return nil }
        return groups.first { $0.items.contains(item) }?.id
    }

    /// Expand the folder containing the current selection
    private func expandSelectionFolder() {
        if let groupID = groupContaining(selection) {
            expandedGroups.insert(groupID)
        }
    }

    /// Handle menu open - expand selection folder and call user's onOpen
    private func handleMenuOpen() {
        expandSelectionFolder()
        onOpen?()
    }

    public var body: some View {
        CustomMenu(isPresented: isPresentedExternal, onOpen: handleMenuOpen, onClose: onClose) {
            label(selection)
        } content: {
            VStack(spacing: 0) {
                // Search and filter bar
                if searchable || filterable {
                    searchAndFilterBar
                    Divider()
                }

                // Content
                ScrollView {
                    VStack(spacing: 0) {
                        if searchText.isEmpty {
                            // Normal browsing mode - show folders collapsed
                            normalBrowsingView
                        } else {
                            // Search mode - smart search results
                            searchResultsView
                        }
                    }
                    .padding(.vertical, (searchable || filterable) ? 0 : 8)
                }
                .frame(maxHeight: (searchable || filterable) ? 300 : nil)
            }
        }
        .onAppear {
            expandSelectionFolder()
            if searchable {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isSearchFocused = true
                }
            }
        }
    }

    // MARK: - Normal Browsing View
    @ViewBuilder
    private var normalBrowsingView: some View {
        var isFirst = true

        // Render groups (folders)
        ForEach(groups) { group in
            let filteredItems = group.items.filter { passesFilter($0) }
            if !filteredItems.isEmpty {
                if !isFirst {
                    Divider()
                }
                let _ = (isFirst = false)

                FolderRow(
                    group: group,
                    filteredItems: filteredItems,
                    isExpanded: expandedGroups.contains(group.id),
                    selection: $selection,
                    optionLabel: optionLabel,
                    optionIcon: optionIcon,
                    trailingAction: trailingAction,
                    selectionStyle: selectionStyle,
                    onToggleExpand: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            if expandedGroups.contains(group.id) {
                                expandedGroups.remove(group.id)
                            } else {
                                expandedGroups.insert(group.id)
                            }
                        }
                    },
                    onSelect: { item in
                        selectItem(item)
                    }
                )
            }
        }

        // Render ungrouped items
        ForEach(Array(options.filter { passesFilter($0) }.enumerated()), id: \.offset) { index, option in
            if !isFirst || index > 0 {
                Divider()
            }
            let _ = (isFirst = false)

            itemRow(option, folderContext: nil)
        }

        // Empty state for filters
        if filteredAllItems.isEmpty && !filterState.isEmpty {
            filterEmptyStateView
        }
    }

    // MARK: - Search Results View
    @ViewBuilder
    private var searchResultsView: some View {
        let searchResults = hierarchicalContent.search(query: searchText, itemLabel: optionLabel)
        let matchedGroups = searchResults.matchedGroups.filter { group in
            group.items.contains { passesFilter($0) }
        }
        let matchedItems = searchResults.matchedItems.filter { passesFilter($0.item) }

        let hasResults = !matchedGroups.isEmpty || !matchedItems.isEmpty

        if hasResults {
            var isFirst = true

            // Show matched folders expanded
            ForEach(matchedGroups) { group in
                let filteredItems = group.items.filter { passesFilter($0) }
                if !filteredItems.isEmpty {
                    if !isFirst {
                        Divider()
                    }
                    let _ = (isFirst = false)

                    FolderRow(
                        group: group,
                        filteredItems: filteredItems,
                        isExpanded: true, // Always expanded in search
                        selection: $selection,
                        optionLabel: optionLabel,
                        optionIcon: optionIcon,
                        trailingAction: trailingAction,
                        selectionStyle: selectionStyle,
                        onToggleExpand: {}, // No-op in search mode
                        onSelect: { item in
                            selectItem(item)
                        }
                    )
                }
            }

            // Show matched individual items with folder context
            ForEach(matchedItems) { result in
                if !isFirst {
                    Divider()
                }
                let _ = (isFirst = false)

                itemRow(result.item, folderContext: result.folderName)
            }
        } else {
            searchEmptyStateView
        }
    }

    // MARK: - Item Row
    @ViewBuilder
    private func itemRow(_ item: T, folderContext: String?) -> some View {
        MenuButton(action: {
            selectItem(item)
        }) {
            HStack(spacing: 8) {
                // Optional icon
                if let iconBuilder = optionIcon {
                    iconBuilder(item)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(optionLabel(item))
                        .fontWeight(selection == item && selectionStyle == .tintedLabel ? .semibold : .regular)
                        .foregroundColor(selection == item && selectionStyle == .tintedLabel ? .accentColor : .primary)
                    if let folder = folderContext {
                        Text(folder)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                // Trailing action (does not dismiss menu)
                if let actionBuilder = trailingAction {
                    actionBuilder(item)
                        .onTapGesture {} // Absorb tap so MenuButton doesn't fire
                }
                if selectionStyle == .checkmark && selection == item {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
            }
        }
    }

    private func selectItem(_ item: T) {
        if selection == item {
            selection = nil
        } else {
            selection = item
        }
        searchText = ""
    }

    // MARK: - Search and Filter Bar
    @ViewBuilder
    private var searchAndFilterBar: some View {
        HStack(spacing: 8) {
            // Filter button
            if filterable {
                FilterButton(
                    filterState: $filterState,
                    availableValues: { key in T.allFilterValues(for: key, in: allItems) },
                    valueLabel: filterValueLabel
                )
            }

            // Search field
            if searchable {
                HStack {
                    Image(systemName: "magnifyingglass")
                        #if canImport(UIKit)
                        .foregroundColor(Color(UIColor.systemGray2))
                        #else
                        .foregroundColor(Color.gray)
                        #endif
                        .font(.system(size: 15, weight: .medium))

                    TextField("Search", text: $searchText)
                        .textFieldStyle(.plain)
                        .focused($isSearchFocused)
                        .font(.system(size: 16))

                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                #if canImport(UIKit)
                                .foregroundColor(Color(UIColor.systemGray3))
                                #else
                                .foregroundColor(Color.gray.opacity(0.5))
                                #endif
                                .font(.system(size: 18))
                        }
                        .buttonStyle(.plain)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        #if canImport(UIKit)
        .background(Color(UIColor.systemGray6))
        #else
        .background(Color.gray.opacity(0.1))
        #endif
    }

    // MARK: - Empty States
    @ViewBuilder
    private var filterEmptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(.secondary)

            Text("No matching items")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)

            Text("Try adjusting your filters")
                .font(.system(size: 14))
                .foregroundColor(.secondary.opacity(0.8))

            Button(action: { filterState.clear() }) {
                Text("Clear Filters")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var searchEmptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(.secondary)

            Text("No results found")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)

            Text("Try a different search term")
                .font(.system(size: 14))
                .foregroundColor(.secondary.opacity(0.8))
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - No Trailing Action Convenience
extension FilterableSelectionMenu where TrailingAction == EmptyView {
    /// Creates a filterable selection menu with icons but no trailing actions.
    public init(
        selection: Binding<T?>,
        options: [T] = [],
        groups: [MenuItemGroup<T>] = [],
        @ViewBuilder label: @escaping (T?) -> Label,
        optionLabel: @escaping (T) -> String = { "\($0)" },
        @ViewBuilder optionIcon: @escaping (T) -> OptionIcon,
        selectionStyle: MenuSelectionStyle = .checkmark,
        searchable: Bool = true,
        filterable: Bool = true,
        filterValueLabel: @escaping (AnyHashable) -> String = { "\($0)" },
        isPresented: Binding<Bool>? = nil,
        onOpen: (() -> Void)? = nil,
        onClose: (() -> Void)? = nil
    ) {
        self._selection = selection
        self.options = options
        self.groups = groups
        self.label = label
        self.optionLabel = optionLabel
        self.optionIcon = optionIcon
        self.trailingAction = nil
        self.selectionStyle = selectionStyle
        self.searchable = searchable
        self.filterable = filterable
        self.filterValueLabel = filterValueLabel
        self.isPresentedExternal = isPresented
        self.onOpen = onOpen
        self.onClose = onClose
    }
}

// MARK: - No Icon Convenience
extension FilterableSelectionMenu where OptionIcon == EmptyView, TrailingAction == EmptyView {
    /// Creates a filterable selection menu without custom icons.
    public init(
        selection: Binding<T?>,
        options: [T] = [],
        groups: [MenuItemGroup<T>] = [],
        @ViewBuilder label: @escaping (T?) -> Label,
        optionLabel: @escaping (T) -> String = { "\($0)" },
        selectionStyle: MenuSelectionStyle = .checkmark,
        searchable: Bool = true,
        filterable: Bool = true,
        filterValueLabel: @escaping (AnyHashable) -> String = { "\($0)" },
        isPresented: Binding<Bool>? = nil,
        onOpen: (() -> Void)? = nil,
        onClose: (() -> Void)? = nil
    ) {
        self._selection = selection
        self.options = options
        self.groups = groups
        self.label = label
        self.optionLabel = optionLabel
        self.optionIcon = nil
        self.trailingAction = nil
        self.selectionStyle = selectionStyle
        self.searchable = searchable
        self.filterable = filterable
        self.filterValueLabel = filterValueLabel
        self.isPresentedExternal = isPresented
        self.onOpen = onOpen
        self.onClose = onClose
    }
}

// MARK: - Text Label Convenience
extension FilterableSelectionMenu where Label == Text, OptionIcon == EmptyView, TrailingAction == EmptyView {
    /// Creates a filterable selection menu with a text label and no icons.
    public init(
        selection: Binding<T?>,
        options: [T] = [],
        groups: [MenuItemGroup<T>] = [],
        label: @escaping (T?) -> String,
        optionLabel: @escaping (T) -> String = { "\($0)" },
        selectionStyle: MenuSelectionStyle = .checkmark,
        searchable: Bool = true,
        filterable: Bool = true,
        filterValueLabel: @escaping (AnyHashable) -> String = { "\($0)" },
        isPresented: Binding<Bool>? = nil,
        onOpen: (() -> Void)? = nil,
        onClose: (() -> Void)? = nil
    ) {
        self._selection = selection
        self.options = options
        self.groups = groups
        self.label = { Text(label($0)) }
        self.optionLabel = optionLabel
        self.optionIcon = nil
        self.trailingAction = nil
        self.selectionStyle = selectionStyle
        self.searchable = searchable
        self.filterable = filterable
        self.filterValueLabel = filterValueLabel
        self.isPresentedExternal = isPresented
        self.onOpen = onOpen
        self.onClose = onClose
    }
}

// MARK: - FolderRow
/// Internal view for rendering a folder with expandable content.
private struct FolderRow<T: Hashable, OptionIcon: View, TrailingAction: View>: View {
    let group: MenuItemGroup<T>
    let filteredItems: [T]
    let isExpanded: Bool
    @Binding var selection: T?
    let optionLabel: (T) -> String
    let optionIcon: ((T) -> OptionIcon)?
    let trailingAction: ((T) -> TrailingAction)?
    let selectionStyle: MenuSelectionStyle
    let onToggleExpand: () -> Void
    let onSelect: (T) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Folder header
            Button(action: onToggleExpand) {
                HStack {
                    if let systemImage = group.systemImage {
                        Image(systemName: systemImage)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    Text(group.name)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(filteredItems.count)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.15), in: Capsule())
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(MenuRowButtonStyle())

            // Expanded content
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(filteredItems.enumerated()), id: \.offset) { index, item in
                    if index > 0 {
                        Divider()
                    }
                    MenuButton(action: { onSelect(item) }) {
                        HStack(spacing: 8) {
                            // Optional icon
                            if let iconBuilder = optionIcon {
                                iconBuilder(item)
                            }

                            Text(optionLabel(item))
                                .fontWeight(selection == item && selectionStyle == .tintedLabel ? .semibold : .regular)
                                .foregroundColor(selection == item && selectionStyle == .tintedLabel ? .accentColor : .primary)
                            Spacer()
                            // Trailing action (does not dismiss menu)
                            if let actionBuilder = trailingAction {
                                actionBuilder(item)
                                    .onTapGesture {} // Absorb tap so MenuButton doesn't fire
                            }
                            if selectionStyle == .checkmark && selection == item {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }
            .padding(.leading, 16)
            .frame(maxHeight: isExpanded ? nil : 0, alignment: .top)
            .clipped()
            .opacity(isExpanded ? 1 : 0)
        }
    }
}
