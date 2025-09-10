import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - CustomMenu
/// A drop-in replacement for SwiftUI's `Menu` with identical visual style and behavior.
public struct CustomMenu<Label: View, Content: View>: View {
    private let labelBuilder: () -> Label
    private let contentBuilder: () -> Content
    // Optional external presentation binding supplied by the caller (opt-in)
    private let externalIsPresented: Binding<Bool>?
    // Optional lifecycle callbacks
    private let onOpen: (() -> Void)?
    private let onClose: (() -> Void)?
    
    // Internal fallback state when the caller did not provide a binding
    @State private var internalIsPresented: Bool = false
    
    // Unified binding (either external or our own @State)
    private var isPresentedBinding: Binding<Bool> {
        externalIsPresented ?? $internalIsPresented
    }
    
    // MARK: - Initialisers
    /// Primary initialiser. Extra parameters are fully optional so existing call-sites remain valid.
    public init(
        isPresented: Binding<Bool>? = nil,
        onOpen: (() -> Void)? = nil,
        onClose: (() -> Void)? = nil,
        @ViewBuilder label: @escaping () -> Label,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.externalIsPresented = isPresented
        self.onOpen = onOpen
        self.onClose = onClose
        self.labelBuilder = label
        self.contentBuilder = content
    }
    
    /// Convenience initializer mirroring `Menu` that takes a `String` title.
    public init(
        _ title: String,
        isPresented: Binding<Bool>? = nil,
        onOpen: (() -> Void)? = nil,
        onClose: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) where Label == Text {
        self.externalIsPresented = isPresented
        self.onOpen = onOpen
        self.onClose = onClose
        self.labelBuilder = { Text(title) }
        self.contentBuilder = content
    }
    
    /// Convenience initializer for picker-style menu with selection binding
    public init<T: Hashable>(
        selection: Binding<T?>,
        options: [T],
        label: @escaping (T?) -> String,
        optionLabel: @escaping (T) -> String,
        isPresented: Binding<Bool>? = nil,
        onOpen: (() -> Void)? = nil,
        onClose: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) where Label == Text {
        self.externalIsPresented = isPresented
        self.onOpen = onOpen
        self.onClose = onClose
        self.labelBuilder = { Text(label(selection.wrappedValue)) }
        self.contentBuilder = content
    }
    
    public var body: some View {
        Button(action: {
            isPresentedBinding.wrappedValue = true
        }) {
            labelBuilder()
        }
        .popover(isPresented: isPresentedBinding) {
            if #available(iOS 16.4, macOS 13.3, *) {
                VStack(alignment: .leading, spacing: 0) {
                    contentBuilder()
                        .environment(\.menuDismiss) {
                            isPresentedBinding.wrappedValue = false
                        }
                }
                .frame(idealWidth: 280, maxHeight: 400)
                .presentationCompactAdaptation(.popover)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    contentBuilder()
                        .environment(\.menuDismiss) {
                            isPresentedBinding.wrappedValue = false
                        }
                }
                .frame(idealWidth: 280, maxHeight: 400)
            }
        }
        // Lifecycle callbacks
        .onChange(of: isPresentedBinding.wrappedValue) { newValue in
            if newValue {
                onOpen?()
            } else {
                onClose?()
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
    
    public init(role: ButtonRole? = nil, action: @escaping () -> Void, @ViewBuilder label: @escaping () -> Label) {
        self.role = role
        self.action = action
        self.label = label
    }
    
    public var body: some View {
        Button(role: role) {
            action()
            dismiss()
        } label: {
            HStack {
                label()
                Spacer()
            }
            .contentShape(Rectangle())
            .foregroundColor(role == .destructive ? .red : nil)
        }
        .buttonStyle(MenuRowButtonStyle())
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

// MARK: - Button Style
/// A button style that provides the pressed highlight behavior used by menu rows
public struct MenuRowButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(configuration.isPressed ? Color.gray.opacity(0.1) : Color.clear)
    }
}
