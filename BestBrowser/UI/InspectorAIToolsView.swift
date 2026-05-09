import SwiftUI

struct AIToolsSidebarView: View {
    @StateObject private var aiClient = AIClient.shared
    @State private var isProcessing = false
    @State private var aiResult: String?
    @State private var autoSummarize = false
    @State private var contentInspectorActive = true

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .foregroundColor(BestBrowserBrand.secondary)
                    .neonGlow(BestBrowserBrand.secondary, radius: 3)
                Text("AI ASSISTANT")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(BestBrowserBrand.border)
                Spacer()
                if isProcessing {
                    ProgressView()
                        .scaleEffect(0.6)
                        .tint(BestBrowserBrand.primary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)

            if !aiClient.isAvailable {
                VStack(alignment: .leading, spacing: 8) {
                    Text("APPLE INTELLIGENCE REQUIRED")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(BestBrowserBrand.warning)

                    Text(unavailableMessage)
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
                .background(BestBrowserBrand.darkCard)
                .border(BestBrowserBrand.warning, width: 0.5)
                .cornerRadius(6)
                .padding(.horizontal, 8)
            }

            VStack(spacing: 6) {
                AIToolButton(title: "Summarize Page", icon: "doc.text.magnifyingglass", isLoading: isProcessing) {
                    performAIAction(.summarize)
                }
                .disabled(!aiClient.isAvailable)
                AIToolButton(title: "Extract Key Points", icon: "list.bullet.indent", isLoading: isProcessing) {
                    performAIAction(.keyPoints)
                }
                .disabled(!aiClient.isAvailable)
                AIToolButton(title: "Translate Page", icon: "text.bubble", isLoading: isProcessing) {
                    performAIAction(.translate)
                }
                .disabled(!aiClient.isAvailable)
                AIToolButton(title: "Simplify Text", icon: "wand.magic", isLoading: isProcessing) {
                    performAIAction(.simplify)
                }
                .disabled(!aiClient.isAvailable)
            }
            .padding(.horizontal, 8)

            Divider().background(BestBrowserBrand.border)

            HStack(spacing: 6) {
                Image(systemName: "eye.slash.fill")
                    .foregroundColor(BestBrowserBrand.error)
                    .neonGlow(BestBrowserBrand.error, radius: 3)
                Text("CONTENT INSPECTOR")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(BestBrowserBrand.border)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)

            VStack(spacing: 6) {
                AIToolButton(title: "Remove Ads & Noise", icon: "xmark.shield.fill", isLoading: false) {
                    performAIAction(.cleanPage)
                }
                AIToolButton(title: "Block Trackers", icon: "hand.raised.fill", isLoading: false) {
                    performAIAction(.blockTrackers)
                }
                AIToolButton(title: "Strip Popups", icon: "rectangle.xmark", isLoading: false) {
                    performAIAction(.stripPopups)
                }
            }
            .padding(.horizontal, 8)

            Toggle("Auto Content Inspector", isOn: $contentInspectorActive)
                .font(.system(size: 11, design: .monospaced))
                .tint(BestBrowserBrand.success)
                .padding(.horizontal, 8)

            Toggle("Auto-Summarize Pages", isOn: $autoSummarize)
                .font(.system(size: 11, design: .monospaced))
                .tint(BestBrowserBrand.primary)
                .padding(.horizontal, 8)
                .disabled(!aiClient.isAvailable)

            if let result = aiResult {
                ScrollView {
                    Text(result)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(BestBrowserBrand.primary)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(BestBrowserBrand.cardBackground)
                        .border(BestBrowserBrand.border, width: 0.5)
                        .cornerRadius(6)
                }
                .padding(.horizontal, 8)
                .frame(maxHeight: 200)
            }

            Spacer()
        }
    }

    private enum AIAction {
        case summarize, keyPoints, translate, simplify, cleanPage, blockTrackers, stripPopups
    }

    private func performAIAction(_ action: AIAction) {
        isProcessing = true
        aiResult = nil

        Task {
            let summarizer = ContentSummarizer.shared
            let privacyShield = PrivacyShield.shared

            if [.summarize, .keyPoints, .translate, .simplify].contains(action),
               !aiClient.isAvailable {
                aiResult = unavailableMessage
                isProcessing = false
                return
            }

            switch action {
            case .summarize:
                if let content = await BrowserViewModel.shared.currentPageContent() {
                    do {
                        let summary = try await summarizer.summarize(content, style: .concise)
                        aiResult = summary
                    } catch {
                        aiResult = "Error: \(error.localizedDescription)"
                    }
                } else {
                    aiResult = "Navigate to a page first to summarize its content."
                }

            case .keyPoints:
                if let content = await BrowserViewModel.shared.currentPageContent() {
                    do {
                        let points = try await summarizer.extractKeyPoints(content)
                        aiResult = points.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
                    } catch {
                        aiResult = "Error: \(error.localizedDescription)"
                    }
                } else {
                    aiResult = "Navigate to a page first."
                }

            case .translate:
                if let content = await BrowserViewModel.shared.currentPageContent() {
                    do {
                        let prompt = "Translate the following text to English if it's in another language, or to Spanish if it's in English. Provide only the translation:\n\n\(String(content.prefix(5000)))"
                        let messages: [[String: String]] = [["role": "user", "content": prompt]]
                        let result = try await AIClient.shared.chat(messages, maxTokens: 800)
                        aiResult = result
                    } catch {
                        aiResult = "Error: \(error.localizedDescription)"
                    }
                } else {
                    aiResult = "Navigate to a page first."
                }

            case .simplify:
                if let content = await BrowserViewModel.shared.currentPageContent() {
                    do {
                        let prompt = "Simplify the following text to be easy to understand for a general audience. Use simple words and short sentences:\n\n\(String(content.prefix(5000)))"
                        let messages: [[String: String]] = [["role": "user", "content": prompt]]
                        let result = try await AIClient.shared.chat(messages, maxTokens: 800)
                        aiResult = result
                    } catch {
                        aiResult = "Error: \(error.localizedDescription)"
                    }
                } else {
                    aiResult = "Navigate to a page first."
                }

            case .cleanPage:
                NotificationCenter.default.post(name: .cleanPageContent, object: nil)
                aiResult = "Content cleaning activated — ads, banners, and noise elements will be removed from the current page."

            case .blockTrackers:
                if !privacyShield.trackerBlockingEnabled {
                    privacyShield.toggleTrackerBlocking()
                }
                NotificationCenter.default.post(name: .blockTrackersNow, object: nil)
                aiResult = "Tracker blocking enhanced. \(privacyShield.stats.trackersBlocked) trackers blocked this session."

            case .stripPopups:
                NotificationCenter.default.post(name: .stripPopupsNow, object: nil)
                aiResult = "Popup stripping activated — cookie banners, overlays, and modals will be removed."
            }

            isProcessing = false
        }
    }

    private var unavailableMessage: String {
        switch aiClient.availability {
        case .available:
            return "Apple Intelligence is available."
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                return "This Mac is not eligible for Apple Intelligence, so on-device page AI is unavailable."
            case .appleIntelligenceNotEnabled:
                return "Turn on Apple Intelligence in macOS settings to enable summaries, translation, and simplification."
            case .modelNotReady:
                return "Apple Intelligence is still preparing the on-device model. Try again in a moment."
            @unknown default:
                return "Apple Intelligence is currently unavailable on this Mac."
            }
        }
    }
}

struct AIToolButton: View {
    let title: String
    let icon: String
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 16, height: 16)
                } else {
                    Image(systemName: icon)
                        .foregroundColor(BestBrowserBrand.secondary)
                        .neonGlow(BestBrowserBrand.secondary, radius: 2)
                }
                Text(title)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 9))
                    .foregroundColor(BestBrowserBrand.border)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(BestBrowserBrand.cardBackground)
            .foregroundColor(BestBrowserBrand.primary)
            .cornerRadius(6)
            .border(BestBrowserBrand.border, width: 0.5)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .help(title)
    }
}
