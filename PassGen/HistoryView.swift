//
//  HistoryView.swift
//  PassGen
//
//  Created by Denys Popov on 31.03.2026.
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var settings: SettingsStore
    var onBack: () -> Void
    @State private var copiedIndex: Int? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Button {
                    onBack()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)

                Spacer()

                Text("Password History")
                    .font(.headline)

                Spacer()

                if !settings.passwordHistory.isEmpty {
                    Button("Clear") { settings.clearHistory() }
                        .foregroundStyle(.red)
                        .buttonStyle(.plain)
                }
            }
            .padding(16)

            Divider()

            if settings.passwordHistory.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock.badge.xmark")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text("No history yet")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(Array(settings.passwordHistory.enumerated()), id: \.offset) { index, entry in
                        HistoryRow(
                            entry: entry,
                            isCopied: copiedIndex == index,
                            onCopy: { copyEntry(entry, index: index) }
                        )
                    }
                }
            }
        }
    }

}

private struct HistoryRow: View {
    let entry: String
    let isCopied: Bool
    let onCopy: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            Text(entry)
                .font(.system(.body, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                .foregroundStyle(isCopied ? .green : (isHovered ? Color.primary : .secondary))
                .frame(width: 16, height: 16)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .background(isHovered ? Color(nsColor: .selectedContentBackgroundColor).opacity(0.15) : .clear)
        .onHover { isHovered = $0 }
        .onTapGesture { onCopy() }
        .help("Click to copy")
    }
}

extension HistoryView {
    private func copyEntry(_ entry: String, index: Int) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(entry, forType: .string)
        copiedIndex = index
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if copiedIndex == index { copiedIndex = nil }
        }
    }
}

#Preview {
    HistoryView(onBack: {})
        .environmentObject(SettingsStore())
}
