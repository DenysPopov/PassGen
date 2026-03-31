//
//  HistoryView.swift
//  PassGen
//
//  Created by Denys Popov on 31.03.2026.
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss
    @State private var copiedIndex: Int? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Button {
                    dismiss()
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
                        HStack(spacing: 8) {
                            Text(entry)
                                .font(.system(.body, design: .monospaced))
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Button {
                                copyEntry(entry, index: index)
                            } label: {
                                Image(systemName: copiedIndex == index ? "checkmark" : "doc.on.doc")
                                    .foregroundStyle(copiedIndex == index ? .green : .secondary)
                                    .frame(width: 16, height: 16)
                            }
                            .buttonStyle(.plain)
                            .help("Copy")
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { copyEntry(entry, index: index) }
                    }
                }
            }
        }
        .frame(width: 420, height: 480)
    }

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
    HistoryView()
        .environmentObject(SettingsStore())
}
