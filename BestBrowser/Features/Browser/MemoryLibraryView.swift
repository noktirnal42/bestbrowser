import SwiftUI

struct MemoryLibraryView: View {
    @ObservedObject var memoryService: PageMemoryService
    @State private var draftNotes: [Int64: String] = [:]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MEMORY LIBRARY")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(BestBrowserBrand.secondary)
                    Text("Recent on-device page takeaways, notes, and pinned research breadcrumbs.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(BestBrowserBrand.fog.opacity(0.82))
                }

                Spacer()

                Button("Refresh") {
                    Task { await memoryService.refreshRecent() }
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(BestBrowserBrand.primary)
            }
            .padding(16)
            .background(BestBrowserBrand.chrome)
            .overlay(Rectangle().fill(BestBrowserBrand.border.opacity(0.45)).frame(height: 1), alignment: .bottom)

            ScrollView {
                VStack(spacing: 10) {
                    if memoryService.recentMemories.isEmpty {
                        Text("As you browse, BestBrowser will collect local page memories here so you can revisit what mattered instead of only where you went.")
                            .font(.system(size: 12))
                            .foregroundColor(BestBrowserBrand.fog.opacity(0.75))
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(BestBrowserBrand.cardBackground)
                            .cornerRadius(12)
                    } else {
                        ForEach(memoryService.recentMemories) { memory in
                            memoryCard(memory)
                        }
                    }
                }
                .padding(16)
            }
            .background(BestBrowserBrand.darkBg)
        }
        .task {
            await memoryService.refreshRecent()
        }
    }

    @ViewBuilder
    private func memoryCard(_ memory: PageMemory) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(memory.title ?? memory.url)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)

                    Text(memory.url)
                        .font(.system(size: 11))
                        .foregroundColor(BestBrowserBrand.border)
                        .lineLimit(1)
                }

                Spacer()

                Button(action: {
                    Task { await memoryService.togglePinned(memory) }
                }) {
                    Image(systemName: memory.isPinned ? "pin.fill" : "pin")
                        .foregroundColor(memory.isPinned ? BestBrowserBrand.secondary : BestBrowserBrand.border)
                }
                .buttonStyle(.plain)
            }

            Text(memory.summary ?? "No summary captured yet.")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(BestBrowserBrand.fog.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)

            if let takeaway = memory.takeaway, !takeaway.isEmpty {
                Text(takeaway)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)
            }

            TextField(
                "Add a note",
                text: Binding(
                    get: { draftNotes[memory.id ?? -1] ?? memory.note ?? "" },
                    set: { draftNotes[memory.id ?? -1] = $0 }
                ),
                onCommit: {
                    let key = memory.id ?? -1
                    let note = draftNotes[key] ?? memory.note ?? ""
                    Task { await memoryService.updateNote(for: memory, note: note) }
                }
            )
            .textFieldStyle(.roundedBorder)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BestBrowserBrand.raisedCard)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(BestBrowserBrand.border.opacity(0.75), lineWidth: 1)
        )
        .cornerRadius(14)
    }
}
