import SwiftUI

// MARK: - Filterable Protocol
/// A protocol that enables types to be filtered by key-value criteria in FilterableSelectionMenu.
///
/// Implement this protocol on your data types to enable filtering capabilities.
///
/// Example:
/// ```swift
/// struct Employee: Filterable {
///     let name: String
///     let department: String
///     let location: String
///
///     enum FilterKey: String, CaseIterable, CustomStringConvertible {
///         case department
///         case location
///
///         var description: String { rawValue.capitalized }
///     }
///
///     func filterValue(for key: FilterKey) -> AnyHashable {
///         switch key {
///         case .department: return department
///         case .location: return location
///         }
///     }
///
///     static func allFilterValues(for key: FilterKey, in items: [Employee]) -> [AnyHashable] {
///         Array(Set(items.map { $0.filterValue(for: key) })).sorted { "\($0)" < "\($1)" }
///     }
/// }
/// ```
public protocol Filterable: Hashable {
    /// The type representing available filter keys (e.g., department, category, status).
    associatedtype FilterKey: Hashable & CaseIterable & CustomStringConvertible

    /// Returns the value for a given filter key.
    /// - Parameter key: The filter key to get the value for.
    /// - Returns: The value as `AnyHashable` for comparison.
    func filterValue(for key: FilterKey) -> AnyHashable

    /// Returns all possible values for a given filter key from a collection of items.
    /// Used to populate the filter UI with available options.
    /// - Parameters:
    ///   - key: The filter key to get values for.
    ///   - items: The collection of items to extract values from.
    /// - Returns: An array of unique values for the given key.
    static func allFilterValues(for key: FilterKey, in items: [Self]) -> [AnyHashable]
}

// MARK: - FilterState
/// Manages the state of active filters for a FilterableSelectionMenu.
public struct FilterState<Key: Hashable>: Equatable {
    /// Dictionary mapping filter keys to their selected values.
    public var activeFilters: [Key: Set<AnyHashable>]

    /// Creates an empty filter state with no active filters.
    public init() {
        self.activeFilters = [:]
    }

    /// Returns `true` if no filters are currently active.
    public var isEmpty: Bool {
        activeFilters.values.allSatisfy { $0.isEmpty }
    }

    /// Returns the total count of active filter values across all keys.
    public var activeFilterCount: Int {
        activeFilters.values.reduce(0) { $0 + $1.count }
    }

    /// Toggles a filter value for the given key.
    /// If the value is currently selected, it will be deselected, and vice versa.
    /// - Parameters:
    ///   - key: The filter key.
    ///   - value: The value to toggle.
    public mutating func toggle(key: Key, value: AnyHashable) {
        if activeFilters[key]?.contains(value) == true {
            activeFilters[key]?.remove(value)
            // Clean up empty sets
            if activeFilters[key]?.isEmpty == true {
                activeFilters.removeValue(forKey: key)
            }
        } else {
            if activeFilters[key] == nil {
                activeFilters[key] = []
            }
            activeFilters[key]?.insert(value)
        }
    }

    /// Checks if a specific value is selected for the given key.
    /// - Parameters:
    ///   - key: The filter key.
    ///   - value: The value to check.
    /// - Returns: `true` if the value is currently selected.
    public func isSelected(key: Key, value: AnyHashable) -> Bool {
        activeFilters[key]?.contains(value) == true
    }

    /// Clears all active filters.
    public mutating func clear() {
        activeFilters.removeAll()
    }

    /// Checks if an item matches the current filter criteria.
    /// An item matches if it satisfies ALL active filter keys (AND logic).
    /// Within each key, the item matches if its value is in the selected set (OR logic).
    /// - Parameter item: The item to check.
    /// - Returns: `true` if the item matches all active filters, or if no filters are active.
    public func matches<T: Filterable>(_ item: T) -> Bool where T.FilterKey == Key {
        for (key, values) in activeFilters where !values.isEmpty {
            let itemValue = item.filterValue(for: key)
            if !values.contains(itemValue) {
                return false
            }
        }
        return true
    }
}
