# CustomMenuKit

A customizable, drop-in replacement for SwiftUI's `Menu`, designed to provide an identical visual style to SwiftUI's Menu and behavior while offering enhanced features like searchable content.

| Searchable Menu | Custom Styles |
| --- | --- |
| <img src="Media/searchable-menu-demo.gif" width="250"/> | <img src="Media/custom-menu-demo.gif" width="250"/> |

## Features

- **Visually Identical**: Looks and feels just like the native SwiftUI `Menu`.
- **Searchable Menus**: The `SelectionMenu` component includes a built-in search bar to filter long lists of options.
- **Expandable Folders**: Group menu items into collapsible folders with `MenuFolder`.
- **Generic Filter System**: Add key-value filtering to any `Hashable` type with the `Filterable` protocol.
- **Smart Search**: `FilterableSelectionMenu` searches both folder names and item names intelligently.
- **Highly Customizable**: Both the menu's label and its content can be customized with any SwiftUI `View`.
- **Single-Selection Support**: Built-in support for menus that manage a single selection from a list of options, complete with checkmarks.
- **Auto-Dismiss**: Menu items automatically dismiss the menu after their action is performed.
- **External Presentation Control (opt-in)**: Drive the menu's visibility with a `Binding<Bool>` if you need programmatic control.
- **Lifecycle Callbacks (opt-in)**: Be notified whenever a menu opens/closes via `onOpen` / `onClose` closures.

## Installation

You can add `CustomMenuKit` to your Xcode project as a package dependency.

1. In Xcode, open your project and navigate to **File > Add Packages...**
2. In the search bar, enter the URL for this repository: `https://github.com/tcollins590/CustomMenuKit.git`
3. Click **Add Package**.
4. Select the `CustomMenuKit` library and add it to your app's target.

## Usage

First, import the library into your SwiftUI file:

```swift
import CustomMenuKit
```

### Standard Menu

Use `CustomMenu` as a direct replacement for `Menu`. You can provide a custom view for the label.

```swift
@State private var selectedSize: String? = nil
let sizes = ["Small", "Medium", "Large"]

CustomMenu {
    // This is the label for the menu button
    HStack {
        Text(selectedSize ?? "Size")
        Image(systemName: "chevron.down.circle.fill")
    }
    .padding()
    .background(Color.purple.opacity(0.2))
    .clipShape(Capsule())
} content: {
    // This is the content of the menu
    ForEach(sizes, id: \.self) { size in
        MenuButton(action: {
            selectedSize = size
        }) {
            Text(size)
        }
    }
}
```

### Selection Menu

Use `SelectionMenu` for cases where you need the user to select a single option from a list. It automatically manages the selection state and displays a checkmark next to the selected item.

```swift
@State private var selectedFruit: String? = nil
let fruits = ["Apple", "Banana", "Orange", "Grape", "Strawberry", ...]

SelectionMenu(
    selection: $selectedFruit,
    options: fruits,
    label: { $0 ?? "Select a fruit" }
)
```

### Searchable Selection Menu

To make a `SelectionMenu` searchable, simply add the `searchable: true` parameter. A search bar will be added to the top of the menu, allowing users to filter the options.

```swift
SelectionMenu(
    selection: $selectedFruit,
    options: fruits,
    label: { $0 ?? "Select a fruit" },
    searchable: true
)
```

### Driving menu visibility yourself

If you need to open or close a menu from the outside (for example in response to some other piece of UI), pass a `Binding<Bool>` called `isPresented`:

```swift
@State private var showMenu = false

CustomMenu(isPresented: $showMenu) {
    Label("More", systemImage: "ellipsis.circle")
} content: {
    MenuButton { /* … */ } label: { Text("Option 1") }
    MenuButton { /* … */ } label: { Text("Option 2") }
}

// Somewhere else …
showMenu = true     // the menu appears
```

The parameter is optional; omit it and the menu behaves exactly like the standard `Menu`.

`SelectionMenu` exposes the same capability:

```swift
SelectionMenu(
    selection: $picked,
    options: fruits,
    label: { $0 ?? "Fruit" },
    isPresented: $showMenu          // opt-in binding
)
```

### Reacting to menu lifecycle events

Sometimes you just want to know when a menu appears or disappears without manually controlling it. Use the `onOpen` / `onClose` callback closures:

```swift
SelectionMenu(
    selection: $picked,
    options: fruits,
    label: { $0 ?? "Fruit" },
    onOpen:  { analytics.track("menu_open") },
    onClose: { analytics.track("menu_close") }
)
```

Both callbacks are optional and fire immediately after the presentation state changes.

### Customizing the Label

The label for both `CustomMenu` and `SelectionMenu` can be any SwiftUI `View`:

```swift
SelectionMenu(
    selection: $selectedColor,
    options: colors,
    label: { selection in
        HStack {
            Image(systemName: "paintpalette")
            Text(selection ?? "Choose Color")
            Spacer()
            Image(systemName: "chevron.down")
        }
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(10)
    },
    searchable: true
)
```

### Menu Folders

Use `MenuFolder` to group related menu items into expandable/collapsible sections:

```swift
CustomMenu {
    Text("Options")
} content: {
    MenuButton(action: { /* ... */ }) {
        Text("Top-level item")
    }

    MenuFolder("Settings", systemImage: "gear") {
        MenuButton(action: { /* ... */ }) {
            Text("General")
        }
        MenuButton(action: { /* ... */ }) {
            Text("Advanced")
        }
    }

    MenuFolder("Recent Files", systemImage: "clock") {
        MenuButton(action: { /* ... */ }) {
            Text("Document.pdf")
        }
        MenuButton(action: { /* ... */ }) {
            Text("Image.png")
        }
    }
}
```

### Filterable Selection Menu

For advanced use cases, `FilterableSelectionMenu` combines folders, search, and filtering. First, make your data type conform to `Filterable`:

```swift
struct Employee: Filterable {
    let id: UUID
    let name: String
    let department: String
    let location: String

    enum FilterKey: String, CaseIterable, CustomStringConvertible {
        case department
        case location
        var description: String { rawValue.capitalized }
    }

    func filterValue(for key: FilterKey) -> AnyHashable {
        switch key {
        case .department: return department
        case .location: return location
        }
    }

    static func allFilterValues(for key: FilterKey, in items: [Employee]) -> [AnyHashable] {
        Array(Set(items.map { $0.filterValue(for: key) })).sorted { "\($0)" < "\($1)" }
    }
}
```

Then use `FilterableSelectionMenu` with `MenuItemGroup` for folder organization:

```swift
@State private var selectedEmployee: Employee? = nil

let employeeGroups = [
    MenuItemGroup(name: "Engineering", systemImage: "hammer", items: engineers),
    MenuItemGroup(name: "Design", systemImage: "paintbrush", items: designers),
    MenuItemGroup(name: "Marketing", systemImage: "megaphone", items: marketers),
]

FilterableSelectionMenu(
    selection: $selectedEmployee,
    groups: employeeGroups,
    label: { $0?.name ?? "Select Employee" },
    optionLabel: { $0.name },
    searchable: true,
    filterable: true,
    filterValueLabel: { "\($0)" }
)
```

**Smart Search Behavior:**
- Search for a folder name (e.g., "Engineering") → shows the folder expanded with all its items
- Search for an item name (e.g., "Alice") → shows the item with its folder name as a subtitle

## Example Application

This repository includes a demo application inside the `CustomMenuKitDemo` folder. To run it, open the `CustomMenuKitDemo.xcodeproj` file and run the `CustomMenuKitDemo` scheme. 