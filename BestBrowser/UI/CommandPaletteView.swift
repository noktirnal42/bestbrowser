import SwiftUI

struct CommandPaletteView: View {
    @Binding var query: String
    var aiAvailable: Bool = true
    var extensionCommands: [(String, String)] = []
    var onClose: () -> Void
    var onExecute: (String) -> Void

    let commands: [(String, String, String, Bool)] = [
        ("New Tab", "plus", "Cmd+T", false),
        ("Close Tab", "xmark", "Cmd+W", false),
        ("Reopen Closed Tab", "arrow.uturn.backward", "Cmd+Shift+T", false),
        ("Split View", "rectangle.split.2x1", "V3", false),
        ("Toggle Vertical Tabs", "sidebar.left", "Cmd+Shift+V", false),
        ("Group Current Tab", "square.stack.3d.up.fill", "Group", false),
        ("Brief Session", "rectangle.and.text.magnifyingglass", "V2", true),
        ("Compare Tabs", "square.split.2x1", "V2", true),
        ("Watch Current Page", "dot.radiowaves.left.and.right", "V2", false),
        ("Summarize", "sparkles", "AI", true),
        ("Reading Mode", "book.fill", "Reader", false),
        ("Repair Video Layout", "rectangle.compress.vertical", "YouTube", false),
        ("Downloads", "arrow.down.circle.fill", "Files", false),
        ("Clean Page", "xmark.shield.fill", "AI", false),
        ("History", "clock", "Sidebar", false),
        ("Settings", "gear", "Cmd+,", false),
        ("Focus Mode", "eye", "Cmd+Shift+F", false)
    ]

    var filteredCommands: [(String, String, String, Bool)] {
        let combined = commands + extensionCommands.map { ($0.0, $0.1, "Extension", false) }
        if query.isEmpty { return combined }
        return combined.filter { $0.0.lowercased().contains(query.lowercased()) }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(BestBrowserBrand.primary)
                        .neonGlow(BestBrowserBrand.primary, radius: 4)
                    TextField("Search commands...", text: $query)
                        .textFieldStyle(.plain)
                        .font(.system(size: 18, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                    if !query.isEmpty {
                        Button(action: { query = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(BestBrowserBrand.border)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                .background(BestBrowserBrand.darkCard)
                .border(BestBrowserBrand.primary, width: 1)
                .cornerRadius(12, corners: [.topLeft, .topRight])
                .neonGlow(BestBrowserBrand.primary, radius: 12)

                Divider().background(BestBrowserBrand.border)

                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(filteredCommands, id: \.0) { command in
                            let disabled = command.3 && !aiAvailable
                            Button(action: { onExecute(command.0) }) {
                                HStack(spacing: 10) {
                                    Image(systemName: command.1)
                                        .foregroundColor(disabled ? BestBrowserBrand.border : BestBrowserBrand.secondary)
                                        .neonGlow(BestBrowserBrand.secondary, radius: 2)
                                        .frame(width: 20)
                                    Text(command.0)
                                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                                        .foregroundColor(disabled ? BestBrowserBrand.border : .white)
                                    Spacer()
                                    Text(disabled ? "Unavailable" : command.2)
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(BestBrowserBrand.border)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(BestBrowserBrand.primary.opacity(0.1))
                                        .border(BestBrowserBrand.border, width: 0.5)
                                        .cornerRadius(3)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .disabled(disabled)
                            .background(Color.white.opacity(0.03))
                            .cornerRadius(6)
                            .padding(.horizontal, 4)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxHeight: 300)
            }
            .frame(width: 560)
            .background(BestBrowserBrand.darkBg)
            .cornerRadius(12)
            .border(BestBrowserBrand.border, width: 1)
            .shadow(color: BestBrowserBrand.primary.opacity(0.15), radius: 30)
        }
        .ignoresSafeArea()
    }
}

struct RectCorner: OptionSet, Sendable {
    let rawValue: Int
    static let topLeft = RectCorner(rawValue: 1 << 0)
    static let topRight = RectCorner(rawValue: 1 << 1)
    static let bottomRight = RectCorner(rawValue: 1 << 2)
    static let bottomLeft = RectCorner(rawValue: 1 << 3)
    static let allCorners: RectCorner = [.topLeft, .topRight, .bottomRight, .bottomLeft]
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: RectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}

struct RoundedCornerShape: Shape {
    let radius: CGFloat
    let corners: RectCorner

    func path(in rect: CGRect) -> Path {
        var path = Path()

        if corners.contains(.topLeft) {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addQuadCurve(to: CGPoint(x: rect.minX + radius, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        } else {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        }

        if corners.contains(.topRight) {
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + radius), control: CGPoint(x: rect.maxX, y: rect.minY))
        } else {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }

        if corners.contains(.bottomRight) {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
            path.addQuadCurve(to: CGPoint(x: rect.maxX - radius, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
        } else {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        }

        if corners.contains(.bottomLeft) {
            path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
            path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - radius), control: CGPoint(x: rect.minX, y: rect.maxY))
        } else {
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        }

        path.closeSubpath()
        return path
    }
}

#Preview {
    CommandPaletteView(query: .constant(""), onClose: {}, onExecute: { _ in })
}
