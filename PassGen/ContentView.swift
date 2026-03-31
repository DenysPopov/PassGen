//
//  ContentView.swift
//  PassGen
//
//  Created by Denys Popov on 31.03.2026.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settings: SettingsStore

    @State private var password: String = ""
    @State private var isCopied: Bool = false
    @State private var showAdvanced: Bool = false
    @State private var showHistory: Bool = false
    @State private var clearClipboardTask: DispatchWorkItem?


    // MARK: - Derived

    private var pool: String { settings.characterPool }
    private var length: Int { Int(settings.passwordLength) }

    private var entropy: Double {
        PasswordGenerator.entropy(length: length, poolSize: pool.count)
    }

    private var strengthLabel: String {
        switch entropy {
        case ..<40:  return "Weak"
        case 40..<60: return "Fair"
        case 60..<80: return "Strong"
        default:      return "Very Strong"
        }
    }

    private var strengthColor: Color {
        switch entropy {
        case ..<40:  return .red
        case 40..<60: return .orange
        case 60..<80: return .yellow
        default:      return .green
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("PassGen")
                    .font(.headline)
                Spacer()
                Button { showHistory = true } label: {
                    Image(systemName: "clock")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Password History")

                Button { showAdvanced = true } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(",", modifiers: .command)
                .help("Settings")
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    // Password field
                    passwordField

                    // Strength indicator
                    if !pool.isEmpty {
                        strengthIndicator
                    }

                    // Warning
                    if pool.isEmpty {
                        warningBanner
                    }

                    Divider()

                    // Toggles 2×2
                    toggleGrid

                    // Slider
                    lengthSlider

                    Divider()

                    // Buttons
                    actionButtons


                }
                .padding(16)
            }
        }
        .frame(width: 320)
        .onAppear { generate() }
        .onChange(of: settings.characterPool)    { _, _ in generate() }
        .onChange(of: settings.passwordLength)   { _, _ in generate() }
        .sheet(isPresented: $showAdvanced) {
            AdvancedSettingsView()
                .environmentObject(settings)
        }
        .sheet(isPresented: $showHistory) {
            HistoryView()
                .environmentObject(settings)
        }
    }

    // MARK: - Subviews

    private var passwordField: some View {
        Text(pool.isEmpty ? "—" : password)
            .font(.system(.body, design: .monospaced))
            .multilineTextAlignment(.center)
            .lineLimit(4)
            .frame(maxWidth: .infinity, minHeight: 56)
            .padding(10)
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isCopied ? Color.accentColor : Color(nsColor: .separatorColor))
            )
            .contentShape(Rectangle())
            .onTapGesture { if !pool.isEmpty { copyPassword() } }
            .help("Click to copy")
    }

    private var strengthIndicator: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(nsColor: .separatorColor))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(strengthColor)
                        .frame(width: geo.size.width * strengthFraction)
                }
            }
            .frame(height: 4)

            HStack {
                Text(strengthLabel)
                    .font(.caption)
                    .foregroundStyle(strengthColor)
                Spacer()
                Text(String(format: "%.0f bits", entropy))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var strengthFraction: Double {
        min(entropy / 120.0, 1.0)
    }

    private var warningBanner: some View {
        Label("Enable at least one character type", systemImage: "exclamationmark.triangle.fill")
            .font(.caption)
            .foregroundStyle(.orange)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var toggleGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 0) {
                Toggle("Uppercase", isOn: $settings.isUppercaseEnabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Toggle("Lowercase", isOn: $settings.isLowercaseEnabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: 0) {
                Toggle("Numbers", isOn: $settings.isNumbersEnabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Toggle("Symbols", isOn: $settings.isSymbolsEnabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .toggleStyle(.checkbox)
    }

    private var lengthSlider: some View {
        VStack(spacing: 2) {
            HStack {
                Text("Length")
                    .foregroundStyle(.secondary)
                TickSlider(value: $settings.passwordLength, range: 8...128)
                Text("\(length)")
                    .monospacedDigit()
                    .frame(minWidth: 28, alignment: .trailing)
            }
            HStack(spacing: 0) {
                // Offset to align with slider track (compensate for "Length" label and value label)
                Text("").frame(width: 52)
                ForEach(Array(tickLabels.enumerated()), id: \.offset) { i, label in
                    if i > 0 { Spacer() }
                    Text(label)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
                Text("").frame(width: 40)
            }
        }
    }

    private var tickLabels: [String] {
        let count = 7
        let min = 8.0, max = 128.0
        return (0..<count).map { i in
            let v = min + (max - min) * Double(i) / Double(count - 1)
            return "\(Int(v.rounded()))"
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button {
                generate()
            } label: {
                Text("Generate")
                    .frame(maxWidth: .infinity)
            }
            .keyboardShortcut("g", modifiers: .command)
            .disabled(pool.isEmpty)

            Button {
                copyPassword()
            } label: {
                Label(isCopied ? "Copied!" : "Copy", systemImage: isCopied ? "checkmark" : "doc.on.doc")
                    .frame(maxWidth: .infinity)
            }
            .keyboardShortcut("c", modifiers: .command)
            .disabled(password.isEmpty || pool.isEmpty)
        }
        .controlSize(.large)
    }

    // MARK: - Actions

    private func generate() {
        guard !pool.isEmpty else { password = ""; return }
        password = PasswordGenerator.generate(length: length, from: pool) ?? ""
    }

    private func copyPassword() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(password, forType: .string)
        settings.addToHistory(password)
        withAnimation { isCopied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { isCopied = false }
        }

        // Auto-clear clipboard after 45 seconds
        clearClipboardTask?.cancel()
        let task = DispatchWorkItem {
            // Only clear if we're still the ones who put content there
            if NSPasteboard.general.string(forType: .string) == password {
                NSPasteboard.general.clearContents()
            }
        }
        clearClipboardTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 45, execute: task)
    }
}

#Preview {
    ContentView()
        .environmentObject(SettingsStore())
}
