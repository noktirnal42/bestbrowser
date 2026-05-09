import SwiftUI

struct EditTabGroupSheet: View {
    let group: TabGroup
    let onSave: (String, String) -> Void
    let onDelete: () -> Void
    let onCancel: () -> Void

    @State private var name: String
    @State private var colorKey: String

    init(
        group: TabGroup,
        onSave: @escaping (String, String) -> Void,
        onDelete: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.group = group
        self.onSave = onSave
        self.onDelete = onDelete
        self.onCancel = onCancel
        _name = State(initialValue: group.name)
        _colorKey = State(initialValue: group.colorKey)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Edit Tab Group")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(BestBrowserBrand.border)
                TextField("Group name", text: $name)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Color")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(BestBrowserBrand.border)

                HStack(spacing: 10) {
                    ForEach(TabGroup.availableColorKeys, id: \.self) { key in
                        Button(action: { colorKey = key }) {
                            Circle()
                                .fill(BrowserTabGroupPalette.color(for: key))
                                .frame(width: 22, height: 22)
                                .overlay(
                                    Circle()
                                        .stroke(colorKey == key ? Color.white : Color.clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack {
                Button("Delete Group", role: .destructive, action: onDelete)
                Spacer()
                Button("Cancel", action: onCancel)
                Button("Save") {
                    onSave(name, colorKey)
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(22)
        .frame(minWidth: 360)
        .background(BestBrowserBrand.darkBg)
    }
}
