import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - CustomMenu
/// A drop-in replacement for SwiftUI's `Menu` with identical visual style and behavior.
public struct CustomMenu<Label: View, Content: View>: View {
    private let labelBuilder: () -> Label
    private let contentBuilder: () -> Content
    
    @State private var isPresented: Bool = false
    
    public init(@ViewBuilder label: @escaping () -> Label,
                @ViewBuilder content: @escaping () -> Content) {
        self.labelBuilder = label
        self.contentBuilder = content
    }
    
    /// Convenience initializer mirroring `Menu` that takes a `String` title.
    public init(_ title: String, @ViewBuilder content: @escaping () -> Content) where Label == Text {
        self.labelBuilder = { Text(title) }
        self.contentBuilder = content
    }
    
    /// Convenience initializer for picker-style menu with selection binding
    public init<T: Hashable>(
        selection: Binding<T?>,
        options: [T],
        label: @escaping (T?) -> String,
        optionLabel: @escaping (T) -> String,
        @ViewBuilder content: @escaping () -> Content
    ) where Label == Text {
        self.labelBuilder = { Text(label(selection.wrappedValue)) }
        self.contentBuilder = content
    }
    
    public var body: some View {
        Button(action: {
            isPresented = true
        }) {
            labelBuilder()
        }
        .popover(isPresented: $isPresented) {
            let menuContent = VStack(alignment: .leading, spacing: 0) {
                contentBuilder()
                    .environment(\.menuDismiss) {
                        isPresented = false
                    }
            }
            .frame(idealWidth: 280, maxHeight: 400)
            
            if #available(iOS 16.4, *) {
                menuContent
                    .presentationCompactAdaptation(.popover)
            } else {
                menuContent
            }
        }
    }
}

// MARK: - Environment for auto-dismiss
private struct MenuDismissActionKey: EnvironmentKey {
    static var defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var menuDismiss: () -> Void {
        get { self[MenuDismissActionKey.self] }
        set { self[MenuDismissActionKey.self] = newValue }
    }
}

// MARK: - MenuButton
/// A convenience button for use inside CustomMenu that auto-dismisses after action.
public struct MenuButton<Label: View>: View {
    let role: ButtonRole?
    let action: () -> Void
    let label: () -> Label
    
    @Environment(\.menuDismiss) private var dismiss
    @State private var isPressed: Bool = false
    @GestureState private var dragAmount = CGSize.zero
    
    public init(role: ButtonRole? = nil, action: @escaping () -> Void, @ViewBuilder label: @escaping () -> Label) {
        self.role = role
        self.action = action
        self.label = label
    }
    
    public var body: some View {
        HStack {
            label()
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .foregroundColor(role == .destructive ? .red : nil)
        .background(isPressed ? Color.gray.opacity(0.1) : Color.clear)
        .onTapGesture {
            action()
            dismiss()
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .updating($dragAmount) { value, state, _ in
                    state = value.translation
                }
                .onChanged { _ in
                    isPressed = false
                }
        )
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0)
                .onChanged { _ in
                    if dragAmount == .zero {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

// MARK: - Divider Extension
extension Divider {
    /// Custom divider that matches Menu styling
    public func menuDividerStyle() -> some View {
        self
            .padding(.vertical, 4)
    }
}

public extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, content: (Self) -> Content) -> some View {
        if condition {
            content(self)
        } else {
            self
        }
    }
} 