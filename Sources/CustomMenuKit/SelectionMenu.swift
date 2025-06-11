import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - SelectionMenu
/// A menu designed for single selection with checkmarks
public struct SelectionMenu<Label: View, T: Hashable>: View {
    @Binding var selection: T?
    let options: [T]
    let label: (T?) -> Label
    let optionLabel: (T) -> String
    let searchable: Bool
    
    @State private var searchText: String = ""
    @FocusState private var isSearchFocused: Bool
    
    public init(
        selection: Binding<T?>,
        options: [T],
        @ViewBuilder label: @escaping (T?) -> Label,
        optionLabel: @escaping (T) -> String = { "\($0)" },
        searchable: Bool = false
    ) {
        self._selection = selection
        self.options = options
        self.label = label
        self.optionLabel = optionLabel
        self.searchable = searchable
    }
    
    private var filteredOptions: [T] {
        if searchText.isEmpty {
            return options
        } else {
            return options.filter { option in
                optionLabel(option).localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    public var body: some View {
        CustomMenu {
            label(selection)
        } content: {
            VStack(spacing: 0) {
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
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    #if canImport(UIKit)
                    .background(Color(UIColor.systemGray6))
                    #else
                    .background(Color.gray.opacity(0.1))
                    #endif
                    
                    Divider()
                        .padding(.horizontal, 0)
                }
                
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(filteredOptions.enumerated()), id: \.offset) { index, option in
                            if index > 0 {
                                Divider()
                            }
                            
                            MenuButton(action: {
                                // Toggle selection
                                if selection == option {
                                    selection = nil
                                } else {
                                    selection = option
                                }
                                searchText = "" // Clear search after selection
                            }) {
                                HStack {
                                    Text(optionLabel(option))
                                    Spacer()
                                    if selection == option {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }
                        }
                        
                        if filteredOptions.isEmpty && !searchText.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 32, weight: .light))
                                    #if canImport(UIKit)
                                    .foregroundColor(Color(UIColor.systemGray3))
                                    #else
                                    .foregroundColor(Color.gray.opacity(0.5))
                                    #endif
                                
                                Text("No results found")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                Text("Try a different search term")
                                    .font(.system(size: 14))
                                    #if canImport(UIKit)
                                    .foregroundColor(Color(UIColor.systemGray3))
                                    #else
                                    .foregroundColor(Color.gray.opacity(0.5))
                                    #endif
                            }
                            .padding(.vertical, 40)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, searchable ? 0 : 8)
                }
                .frame(maxHeight: searchable ? 300 : nil)
            }
        }
        .onAppear {
            if searchable {
                // Focus search field when menu appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isSearchFocused = true
                }
            }
        }
    }
}

extension SelectionMenu where Label == Text {
    public init(
        selection: Binding<T?>,
        options: [T],
        label: @escaping (T?) -> String,
        optionLabel: @escaping (T) -> String = { "\($0)" },
        searchable: Bool = false
    ) {
        self.init(
            selection: selection,
            options: options,
            label: { Text(label($0)) },
            optionLabel: optionLabel,
            searchable: searchable
        )
    }
} 