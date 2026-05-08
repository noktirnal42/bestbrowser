import SwiftUI

struct ReadingModeView: View {
    let title: String
    let content: String
    let url: String

    @StateObject private var aiClient = AIClient.shared
    @State private var fontSize: CGFloat = 16
    @State private var lineSpacing: CGFloat = 1.5
    @State private var colorScheme: ReadingColorScheme = .dark
    @State private var insightText = ""
    @State private var insightMode: InsightMode = .summary
    @State private var isGeneratingInsight = false
    @Environment(\.dismiss) var dismiss

    enum InsightMode: String, CaseIterable {
        case summary = "Summary"
        case keyPoints = "Key Points"
        case simplify = "Simplify"
        case translate = "Translate"

        var icon: String {
            switch self {
            case .summary: return "sparkles"
            case .keyPoints: return "list.bullet"
            case .simplify: return "wand.magic"
            case .translate: return "text.bubble"
            }
        }
    }

    enum ReadingColorScheme: String, CaseIterable {
        case light = "Light"
        case dark = "Dark"
        case sepia = "Sepia"

        var backgroundColor: Color {
            switch self {
            case .light: return Color(red: 0.95, green: 0.95, blue: 0.95)
            case .dark: return BestBrowserBrand.darkBg
            case .sepia: return Color(red: 0.95, green: 0.92, blue: 0.84)
            }
        }

        var textColor: Color {
            switch self {
            case .light: return Color(red: 0.1, green: 0.1, blue: 0.1)
            case .dark: return BestBrowserBrand.primary
            case .sepia: return Color(red: 0.4, green: 0.3, blue: 0.2)
            }
        }

        var icon: String {
            switch self {
            case .light: return "sun.max.fill"
            case .dark: return "moon.fill"
            case .sepia: return "book.fill"
            }
        }
    }

    var body: some View {
        ZStack {
            colorScheme.backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                            Text("Close")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(BestBrowserBrand.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(BestBrowserBrand.primary.opacity(0.1))
                        .border(BestBrowserBrand.primary, width: 1)
                        .cornerRadius(4)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    HStack(spacing: 6) {
                        Image(systemName: "book.fill")
                            .foregroundColor(BestBrowserBrand.secondary)
                            .font(.system(size: 11))
                        Text("READING MODE")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(BestBrowserBrand.border)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(title)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .lineLimit(1)
                            .foregroundColor(BestBrowserBrand.primary)
                        Text(url)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(BestBrowserBrand.border)
                            .lineLimit(1)
                    }
                }
                .padding(12)
                .background(BestBrowserBrand.cardBackground)
                .border(BestBrowserBrand.border, width: 1)

                ScrollView {
                    VStack(alignment: .leading, spacing: lineSpacing) {
                        Text(title)
                            .font(.system(size: fontSize + 8, weight: .bold, design: .monospaced))
                            .foregroundColor(colorScheme.textColor)
                            .padding(.bottom, 12)

                        if !insightText.isEmpty || isGeneratingInsight {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Label(insightMode.rawValue, systemImage: insightMode.icon)
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(BestBrowserBrand.primary)
                                    Spacer()
                                    if isGeneratingInsight {
                                        ProgressView()
                                            .scaleEffect(0.6)
                                    }
                                }

                                Text(insightText.isEmpty ? "Preparing on-device insight..." : insightText)
                                    .font(.system(size: max(12, fontSize - 1)))
                                    .foregroundColor(colorScheme.textColor)
                            }
                            .padding(14)
                            .background(BestBrowserBrand.cardBackground.opacity(0.85))
                            .cornerRadius(10)
                            .padding(.bottom, 12)
                        }

                        Text(content)
                            .font(.system(size: fontSize, design: .monospaced))
                            .lineSpacing(lineSpacing)
                            .foregroundColor(colorScheme.textColor)
                    }
                    .padding(20)
                }

                VStack(spacing: 12) {
                    Divider().background(BestBrowserBrand.border)

                    HStack {
                        Image(systemName: "textformat.size.smaller")
                            .foregroundColor(BestBrowserBrand.border)
                            .font(.system(size: 10))
                            .onTapGesture { fontSize = max(12, fontSize - 1) }

                        Slider(value: $fontSize, in: 12...24, step: 1)
                            .tint(BestBrowserBrand.primary)

                        Image(systemName: "textformat.size.larger")
                            .foregroundColor(BestBrowserBrand.border)
                            .font(.system(size: 10))
                            .onTapGesture { fontSize = min(24, fontSize + 1) }

                        Text("\(Int(fontSize))")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(BestBrowserBrand.primary)
                            .frame(width: 30)
                    }

                    HStack {
                        Text("SPACING")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(BestBrowserBrand.border)

                        Slider(value: $lineSpacing, in: 1...2.5, step: 0.1)
                            .tint(BestBrowserBrand.secondary)

                        Text(String(format: "%.1f", lineSpacing))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(BestBrowserBrand.primary)
                            .frame(width: 30)
                    }

                    HStack {
                        Text("AI")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(BestBrowserBrand.border)

                        Spacer()

                        ForEach(InsightMode.allCases, id: \.self) { mode in
                            Button(action: {
                                insightMode = mode
                                Task { await generateInsight(force: true) }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: mode.icon)
                                        .font(.system(size: 10))
                                    Text(mode.rawValue)
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                }
                                .foregroundColor(insightMode == mode ? BestBrowserBrand.primary : BestBrowserBrand.border)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(insightMode == mode ? BestBrowserBrand.primary.opacity(0.1) : Color.clear)
                                .border(insightMode == mode ? BestBrowserBrand.primary : BestBrowserBrand.border, width: 1)
                                .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                            .disabled(!aiClient.isAvailable || isGeneratingInsight)
                        }
                    }

                    HStack {
                        Text("THEME")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(BestBrowserBrand.border)

                        Spacer()

                        ForEach(ReadingColorScheme.allCases, id: \.self) { scheme in
                            Button(action: { colorScheme = scheme }) {
                                HStack(spacing: 4) {
                                    Image(systemName: scheme.icon)
                                        .font(.system(size: 10))
                                    Text(scheme.rawValue)
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                }
                                .foregroundColor(colorScheme == scheme ? BestBrowserBrand.primary : BestBrowserBrand.border)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(colorScheme == scheme ? BestBrowserBrand.primary.opacity(0.1) : Color.clear)
                                .border(colorScheme == scheme ? BestBrowserBrand.primary : BestBrowserBrand.border, width: 1)
                                .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(12)
                .background(BestBrowserBrand.cardBackground)
                .border(BestBrowserBrand.border, width: 1)
            }
        }
        .task {
            await generateInsight()
        }
    }

    private func generateInsight(force: Bool = false) async {
        guard aiClient.isAvailable else { return }
        if !force && !insightText.isEmpty { return }

        isGeneratingInsight = true
        defer { isGeneratingInsight = false }

        let trimmedContent = String(content.prefix(5000))

        switch insightMode {
        case .summary:
            if let generated = try? await AIClient.shared.summarize(trimmedContent) {
                insightText = generated
            }
        case .keyPoints:
            if let generated = try? await ContentSummarizer.shared.extractKeyPoints(trimmedContent) {
                insightText = generated.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
            }
        case .simplify:
            let prompt = "Simplify the following text for a general audience. Use plain language and shorter sentences:\n\n\(trimmedContent)"
            if let generated = try? await AIClient.shared.chat([["role": "user", "content": prompt]], maxTokens: 900) {
                insightText = generated
            }
        case .translate:
            let prompt = "Translate this text to English if it is in another language, or to Spanish if it is already English. Provide only the translated text:\n\n\(trimmedContent)"
            if let generated = try? await AIClient.shared.chat([["role": "user", "content": prompt]], maxTokens: 900) {
                insightText = generated
            }
        }
    }
}

#Preview {
    ReadingModeView(
        title: "The Art of Programming",
        content: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
        url: "https://example.com/article"
    )
}
