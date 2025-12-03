import SwiftUI

// MARK: - MenuFolder
/// An expandable folder component for grouping menu items within CustomMenu or SelectionMenu.
/// Supports single-level nesting only (folders cannot contain other folders).
public struct MenuFolder<Label: View, Content: View>: View {
    private let labelBuilder: () -> Label
    private let contentBuilder: () -> Content
    @State private var isExpanded: Bool

    /// Creates an expandable menu folder.
    /// - Parameters:
    ///   - isExpanded: Initial expansion state. Defaults to `false` (collapsed).
    ///   - label: A ViewBuilder that creates the folder's header label.
    ///   - content: A ViewBuilder that creates the folder's child items (typically MenuButtons).
    public init(
        isExpanded: Bool = false,
        @ViewBuilder label: @escaping () -> Label,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._isExpanded = State(initialValue: isExpanded)
        self.labelBuilder = label
        self.contentBuilder = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Folder header row
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    labelBuilder()
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(MenuRowButtonStyle())

            // Expandable content with smooth height animation
            VStack(alignment: .leading, spacing: 0) {
                Divider()
                contentBuilder()
            }
            .padding(.leading, 16)
            .frame(maxHeight: isExpanded ? nil : 0, alignment: .top)
            .clipped()
            .opacity(isExpanded ? 1 : 0)
        }
    }
}

// MARK: - Convenience Initializers
extension MenuFolder where Label == Text {
    /// Creates an expandable menu folder with a text label.
    /// - Parameters:
    ///   - title: The text to display as the folder's header.
    ///   - isExpanded: Initial expansion state. Defaults to `false` (collapsed).
    ///   - content: A ViewBuilder that creates the folder's child items.
    public init(
        _ title: String,
        isExpanded: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            isExpanded: isExpanded,
            label: { Text(title) },
            content: content
        )
    }
}

extension MenuFolder where Label == SwiftUI.Label<Text, Image> {
    /// Creates an expandable menu folder with a system image and text label.
    /// - Parameters:
    ///   - title: The text to display as the folder's header.
    ///   - systemImage: The SF Symbol name for the icon.
    ///   - isExpanded: Initial expansion state. Defaults to `false` (collapsed).
    ///   - content: A ViewBuilder that creates the folder's child items.
    public init(
        _ title: String,
        systemImage: String,
        isExpanded: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            isExpanded: isExpanded,
            label: { SwiftUI.Label(title, systemImage: systemImage) },
            content: content
        )
    }
}
