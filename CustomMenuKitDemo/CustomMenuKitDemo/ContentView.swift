//
//  ContentView.swift
//  CustomMenuKitDemo
//
//  Created by Tyler Collins on 6/11/25.
//

import SwiftUI
import CustomMenuKit

struct ContentView: View {
    @State private var selectedFruit: String? = nil
    @State private var selectedColor: String? = nil
    @State private var selectedSize: String? = nil
    
    let fruits = [
        "Apple", "Banana", "Orange", "Grape", "Strawberry",
        "Mango", "Pineapple", "Watermelon", "Peach", "Pear",
        "Cherry", "Blueberry", "Raspberry", "Kiwi", "Lemon",
        "Lime", "Coconut", "Papaya", "Pomegranate", "Apricot",
        "Plum", "Fig", "Date", "Guava", "Passion Fruit"
    ]
    
    let colors = ["Red", "Blue", "Green", "Yellow", "Purple", "Orange"]
    let sizes = ["Small", "Medium", "Large", "Extra Large"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Text("Custom Menu Button Examples")
                    .font(.largeTitle)
                    .padding(.top)
                
                Text("SelectionMenu examples are searchable and auto-scroll")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
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
                    searchable: true
                )
                
                // Example 3: Capsule style button
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
                            Text(size)
                        }
                    }
                }
                
                // Example 4: Icon-only circular button (with many items to show scrolling)
                CustomMenu {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.gray)
                } content: {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(1...20, id: \.self) { index in
                                if index > 1 {
                                    Divider()
                                }
                                MenuButton(action: {}) {
                                    Label("Option \(index)", systemImage: "circle.fill")
                                }
                            }
                            Divider()
                            MenuButton(role: .destructive, action: {}) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .frame(maxHeight: 300)
                }
                
                // Example 5: Custom gradient button
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
                    MenuButton(action: {}) {
                        Label("Premium Feature 1", systemImage: "crown")
                    }
                    MenuButton(action: {}) {
                        Label("Premium Feature 2", systemImage: "sparkles")
                    }
                }
                
                // Example 6: Outlined button
                CustomMenu {
                    HStack {
                        Text("Options")
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
                    MenuButton(action: {}) {
                        Text("Option 1")
                    }
                    MenuButton(action: {}) {
                        Text("Option 2")
                    }
                }
                
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
