import SwiftUI

// MARK: - MenuItemGroup
/// Represents a hierarchical menu structure with folders and items.
/// Used with `FilterableSelectionMenu` to enable smart search across folders.
public struct MenuItemGroup<T: Hashable>: Identifiable {
    public let id: UUID
    public let name: String
    public let systemImage: String?
    public let items: [T]

    /// Creates a folder/group containing items.
    /// - Parameters:
    ///   - name: The display name of the folder.
    ///   - systemImage: Optional SF Symbol for the folder icon.
    ///   - items: The items contained in this folder.
    public init(
        name: String,
        systemImage: String? = nil,
        items: [T]
    ) {
        self.id = UUID()
        self.name = name
        self.systemImage = systemImage
        self.items = items
    }

    /// Creates a folder/group containing items with a custom ID.
    public init(
        id: UUID,
        name: String,
        systemImage: String? = nil,
        items: [T]
    ) {
        self.id = id
        self.name = name
        self.systemImage = systemImage
        self.items = items
    }
}

// MARK: - SearchResult
/// Represents a search result item with its folder context.
struct MenuSearchResult<T: Hashable>: Identifiable {
    let id: UUID
    let item: T
    let folderName: String?
    let folderImage: String?

    init(item: T, folderName: String? = nil, folderImage: String? = nil) {
        self.id = UUID()
        self.item = item
        self.folderName = folderName
        self.folderImage = folderImage
    }
}

// MARK: - HierarchicalMenuContent
/// Internal structure for organizing menu content with folders and ungrouped items.
struct HierarchicalMenuContent<T: Hashable> {
    let groups: [MenuItemGroup<T>]
    let ungroupedItems: [T]

    /// All items flattened from groups and ungrouped items.
    var allItems: [T] {
        groups.flatMap { $0.items } + ungroupedItems
    }

    /// Returns search results based on the query.
    /// - When query matches a folder name: returns all items in that folder
    /// - When query matches item labels: returns those items with folder context
    func search(
        query: String,
        itemLabel: (T) -> String
    ) -> (matchedGroups: [MenuItemGroup<T>], matchedItems: [MenuSearchResult<T>]) {
        let lowercaseQuery = query.lowercased()

        // Find folders whose names match the query
        let matchedGroups = groups.filter { group in
            group.name.lowercased().contains(lowercaseQuery)
        }

        // Find individual items that match (excluding items in matched folders to avoid duplicates)
        let matchedGroupIDs = Set(matchedGroups.map { $0.id })

        var matchedItems: [MenuSearchResult<T>] = []

        // Search in non-matched groups
        for group in groups where !matchedGroupIDs.contains(group.id) {
            for item in group.items {
                if itemLabel(item).lowercased().contains(lowercaseQuery) {
                    matchedItems.append(MenuSearchResult(
                        item: item,
                        folderName: group.name,
                        folderImage: group.systemImage
                    ))
                }
            }
        }

        // Search in ungrouped items
        for item in ungroupedItems {
            if itemLabel(item).lowercased().contains(lowercaseQuery) {
                matchedItems.append(MenuSearchResult(item: item))
            }
        }

        return (matchedGroups, matchedItems)
    }
}
