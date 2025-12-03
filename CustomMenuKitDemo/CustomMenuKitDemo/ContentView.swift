//
//  ContentView.swift
//  CustomMenuKitDemo
//
//  Created by Tyler Collins on 6/11/25.
//

import SwiftUI
import CustomMenuKit

// MARK: - Sample Filterable Data Model
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
        let values = Set(items.map { $0.filterValue(for: key) })
        return Array(values).sorted { "\($0)" < "\($1)" }
    }
}

struct ContentView: View {
    @State private var selectedFruit: String? = nil
    @State private var selectedColor: String? = nil
    @State private var selectedSize: String? = nil
    @State private var selectedIconOption: Int? = nil
    @State private var selectedPremiumFeature: String? = nil
    @State private var selectedOutlineOption: String? = nil
    @State private var selectedColorTab = 0
    @State private var selectedEmployee: Employee? = nil

    let fruits = [
        "Apple", "Banana", "Orange", "Grape", "Strawberry",
        "Mango", "Pineapple", "Watermelon", "Peach", "Pear",
        "Cherry", "Blueberry", "Raspberry", "Kiwi", "Lemon",
        "Lime", "Coconut", "Papaya", "Pomegranate", "Apricot",
        "Plum", "Fig", "Date", "Guava", "Passion Fruit"
    ]

    let colors = ["Red", "Blue", "Green", "Yellow", "Purple", "Orange"]
    let sizes = ["Small", "Medium", "Large", "Extra Large"]

    // Employees grouped by department for folder demo
    // Note: Using static UUIDs so employees remain stable across view updates
    let employeeGroups: [MenuItemGroup<Employee>] = [
        MenuItemGroup(
            name: "Engineering",
            systemImage: "hammer",
            items: [
                Employee(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, name: "Alice Johnson", department: "Engineering", location: "New York"),
                Employee(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, name: "Carol Williams", department: "Engineering", location: "San Francisco"),
                Employee(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!, name: "Eva Martinez", department: "Engineering", location: "New York"),
                Employee(id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!, name: "Henry Chen", department: "Engineering", location: "San Francisco"),
            ]
        ),
        MenuItemGroup(
            name: "Design",
            systemImage: "paintbrush",
            items: [
                Employee(id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!, name: "Bob Smith", department: "Design", location: "San Francisco"),
                Employee(id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!, name: "Frank Lee", department: "Design", location: "Chicago"),
                Employee(id: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!, name: "Ivy Taylor", department: "Design", location: "New York"),
            ]
        ),
        MenuItemGroup(
            name: "Marketing",
            systemImage: "megaphone",
            items: [
                Employee(id: UUID(uuidString: "00000000-0000-0000-0000-000000000008")!, name: "David Brown", department: "Marketing", location: "Chicago"),
                Employee(id: UUID(uuidString: "00000000-0000-0000-0000-000000000009")!, name: "Grace Kim", department: "Marketing", location: "New York"),
                Employee(id: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!, name: "Jack Wilson", department: "Marketing", location: "San Francisco"),
            ]
        ),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Text("CustomMenuKit Examples")
                    .font(.largeTitle)
                    .padding(.top)


                // Example 1: Default text button with searchable menu
                SelectionMenu(
                    selection: $selectedFruit,
                    options: fruits,
                    label: { $0 ?? "Select a fruit" },
                    searchable: true
                )

                // Example 2: Rounded rectangle button with SelectionMenu (searchable)
                SelectionMenu(
                    selection: $selectedColor,
                    options: colors,
                    label: { selection in
                        HStack {
                            Image(systemName: "paintpalette")
                            Text(selection ?? "Choose Color")
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    },
                    searchable: true,
                    header: {
                        VStack(spacing: 0) {
                            Picker("", selection: $selectedColorTab) {
                                Text("Primary").tag(0)
                                Text("Secondary").tag(1)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                            .padding(.top, 12)
                            .padding(.bottom, 8)

                            Divider()
                        }
                    }
                )

                // Example 3: Capsule style button with MenuFolder
                CustomMenu {
                    HStack {
                        Text(selectedSize ?? "Size")
                            .fontWeight(.medium)
                        Image(systemName: "chevron.down.circle.fill")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.purple.opacity(0.2))
                    .foregroundColor(.purple)
                    .clipShape(Capsule())
                } content: {
                    ForEach(sizes, id: \.self) { size in
                        MenuButton(action: {
                            selectedSize = size
                        }) {
                            HStack {
                                Text(size)
                                Spacer()
                                if selectedSize == size {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }

                    Divider().menuDividerStyle()

                    // MenuFolder example
                    MenuFolder("Size Guide", systemImage: "ruler") {
                        MenuButton(action: {}) {
                            Text("Small: 0-10 lbs")
                        }
                        MenuButton(action: {}) {
                            Text("Medium: 10-25 lbs")
                        }
                        MenuButton(action: {}) {
                            Text("Large: 25-50 lbs")
                        }
                        MenuButton(action: {}) {
                            Text("Extra Large: 50+ lbs")
                        }
                    }
                }

                // Example 4: Icon-only circular button with nested folders
                VStack {
                    CustomMenu {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.gray)
                    } content: {
                        ScrollView {
                            VStack(spacing: 0) {
                                MenuFolder("Recent Items", systemImage: "clock") {
                                    ForEach(1...3, id: \.self) { index in
                                        if index > 1 { Divider() }
                                        MenuButton(action: { selectedIconOption = index }) {
                                            Label("Recent \(index)", systemImage: "doc")
                                        }
                                    }
                                }

                                Divider()

                                MenuFolder("Favorites", systemImage: "star") {
                                    ForEach(4...6, id: \.self) { index in
                                        if index > 4 { Divider() }
                                        MenuButton(action: { selectedIconOption = index }) {
                                            Label("Favorite \(index - 3)", systemImage: "star.fill")
                                        }
                                    }
                                }

                                Divider()

                                ForEach(7...10, id: \.self) { index in
                                    if index > 7 {
                                        Divider()
                                    }
                                    MenuButton(action: { selectedIconOption = index }) {
                                        Label {
                                            Text("Option \(index)")
                                        } icon: {
                                            Image(systemName: "circle.fill")
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.primary, lineWidth: selectedIconOption == index ? 2 : 0)
                                                )
                                        }
                                    }
                                }

                                Divider()

                                MenuButton(role: .destructive, action: { selectedIconOption = nil }) {
                                    Label("Clear Selection", systemImage: "trash")
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .frame(maxHeight: 350)
                        .contentMargins(16, for: .scrollIndicators)
                        .padding(.trailing, 1)
                    }
                    if let selectedIconOption {
                        Text("Selected: Option \(selectedIconOption)")
                            .font(.caption)
                            .padding(.top, 4)
                    }
                }

                // Example 5: Custom gradient button
                VStack {
                    CustomMenu {
                        HStack {
                            Image(systemName: "star.fill")
                            Text("Premium Options")
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [.orange, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: .pink.opacity(0.3), radius: 5, x: 0, y: 3)
                    } content: {
                        MenuButton(action: { selectedPremiumFeature = "Premium Feature 1" }) {
                            HStack {
                                Label("Premium Feature 1", systemImage: "crown")
                                Spacer()
                                if selectedPremiumFeature == "Premium Feature 1" {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        MenuButton(action: { selectedPremiumFeature = "Premium Feature 2" }) {
                            HStack {
                                Label("Premium Feature 2", systemImage: "sparkles")
                                Spacer()
                                if selectedPremiumFeature == "Premium Feature 2" {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    if let selectedPremiumFeature {
                        Text("Selected: \(selectedPremiumFeature)")
                            .font(.caption)
                            .padding(.top, 4)
                    }
                }

                // Example 6: Outlined button
                VStack {
                    CustomMenu {
                        HStack {
                            Text(selectedOutlineOption ?? "Options")
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                    } content: {
                        MenuButton(action: { selectedOutlineOption = "Option 1" }) {
                            HStack {
                                Text("Option 1")
                                Spacer()
                                if selectedOutlineOption == "Option 1" {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        MenuButton(action: { selectedOutlineOption = "Option 2" }) {
                            HStack {
                                Text("Option 2")
                                Spacer()
                                if selectedOutlineOption == "Option 2" {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }

                // Example 7: FilterableSelectionMenu with folders and smart search
                VStack(alignment: .leading, spacing: 8) {
                    Text("Filterable Menu with Folders")
                        .font(.headline)

                    Text("Try searching 'Engineering' or 'Alice'")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    FilterableSelectionMenu(
                        selection: $selectedEmployee,
                        groups: employeeGroups,
                        label: { employee in
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.title2)
                                Text(employee?.name ?? "Select Employee")
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.green.opacity(0.15))
                            .foregroundColor(.green)
                            .cornerRadius(10)
                        },
                        optionLabel: { $0.name },
                        searchable: true,
                        filterable: true,
                        filterValueLabel: { "\($0)" }
                    )

                    if let employee = selectedEmployee {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Selected: \(employee.name)")
                                .font(.caption)
                            Text("Department: \(employee.department)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Location: \(employee.location)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)

                Spacer(minLength: 100)
            }
            .padding()
        }
    }

    func colorForName(_ name: String) -> Color {
        switch name {
        case "Red": return .red
        case "Blue": return .blue
        case "Green": return .green
        case "Yellow": return .yellow
        case "Purple": return .purple
        case "Orange": return .orange
        default: return .gray
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
