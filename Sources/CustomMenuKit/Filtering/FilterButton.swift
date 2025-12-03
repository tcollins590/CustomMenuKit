import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - FilterButton
/// A circular "liquid glass" button that opens a filter popover.
/// Displays a badge with the active filter count when filters are applied.
public struct FilterButton<Key: Hashable & CaseIterable & CustomStringConvertible>: View {
    @Binding var filterState: FilterState<Key>
    let availableValues: (Key) -> [AnyHashable]
    let valueLabel: (AnyHashable) -> String

    @State private var isPopoverPresented: Bool = false

    /// Creates a filter button.
    /// - Parameters:
    ///   - filterState: Binding to the filter state.
    ///   - availableValues: Closure that returns available values for each filter key.
    ///   - valueLabel: Closure that converts a filter value to a display string.
    public init(
        filterState: Binding<FilterState<Key>>,
        availableValues: @escaping (Key) -> [AnyHashable],
        valueLabel: @escaping (AnyHashable) -> String
    ) {
        self._filterState = filterState
        self.availableValues = availableValues
        self.valueLabel = valueLabel
    }

    public var body: some View {
        Button(action: { isPopoverPresented = true }) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(filterState.isEmpty ? .secondary : .accentColor)
                    .frame(width: 32, height: 32)
                    .background(glassBackground)
                    .clipShape(Circle())

                // Badge for active filter count
                if filterState.activeFilterCount > 0 {
                    Text("\(filterState.activeFilterCount)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 14, height: 14)
                        .background(Color.accentColor, in: Circle())
                        .offset(x: 2, y: -2)
                }
            }
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isPopoverPresented) {
            FilterCreatorPopover(
                filterState: $filterState,
                availableValues: availableValues,
                valueLabel: valueLabel
            )
        }
    }

    @ViewBuilder
    private var glassBackground: some View {
        if #available(iOS 15.0, macOS 12.0, *) {
            Circle()
                .fill(.ultraThinMaterial)
        } else {
            #if canImport(UIKit)
            Circle()
                .fill(Color(UIColor.systemGray5))
            #else
            Circle()
                .fill(Color.gray.opacity(0.2))
            #endif
        }
    }
}

// MARK: - FilterCreatorPopover
/// The popover content displaying filter options organized by filter key.
struct FilterCreatorPopover<Key: Hashable & CaseIterable & CustomStringConvertible>: View {
    @Binding var filterState: FilterState<Key>
    let availableValues: (Key) -> [AnyHashable]
    let valueLabel: (AnyHashable) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Filters")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                if !filterState.isEmpty {
                    Button(action: { filterState.clear() }) {
                        Text("Clear All")
                            .font(.system(size: 14))
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(Key.allCases), id: \.self) { key in
                        FilterKeySection(
                            key: key,
                            filterState: $filterState,
                            values: availableValues(key),
                            valueLabel: valueLabel
                        )
                    }
                }
            }
            .frame(maxHeight: 300)
        }
        .frame(width: 260)
        .applyPresentationCompactAdaptation()
    }
}

// MARK: - FilterKeySection
/// A section within the filter popover for a single filter key.
private struct FilterKeySection<Key: Hashable & CustomStringConvertible>: View {
    let key: Key
    @Binding var filterState: FilterState<Key>
    let values: [AnyHashable]
    let valueLabel: (AnyHashable) -> String

    @State private var isExpanded: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(key.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Values
            if isExpanded {
                ForEach(values, id: \.self) { value in
                    FilterValueRow(
                        value: value,
                        isSelected: filterState.isSelected(key: key, value: value),
                        label: valueLabel(value),
                        onToggle: {
                            filterState.toggle(key: key, value: value)
                        }
                    )
                }
            }

            Divider()
                .padding(.top, 4)
        }
    }
}

// MARK: - FilterValueRow
/// A single selectable value row within a filter section.
private struct FilterValueRow: View {
    let value: AnyHashable
    let isSelected: Bool
    let label: String
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                Text(label)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(FilterRowButtonStyle())
    }
}

// MARK: - FilterRowButtonStyle
/// Button style for filter rows with press highlight.
private struct FilterRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.gray.opacity(0.1) : Color.clear)
    }
}

// MARK: - View Extension for iOS 16.4+ Presentation
private extension View {
    @ViewBuilder
    func applyPresentationCompactAdaptation() -> some View {
        if #available(iOS 16.4, macOS 13.3, *) {
            self.presentationCompactAdaptation(.popover)
        } else {
            self
        }
    }
}
