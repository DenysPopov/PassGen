//
//  AdvancedSettingsView.swift
//  PassGen
//
//  Created by Denys Popov on 31.03.2026.
//

import ServiceManagement
import SwiftUI

struct AdvancedSettingsView: View {
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

    @State private var launchAtLogin: Bool = (SMAppService.mainApp.status == .enabled)

    private let defaults = (
        uppercase: "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
        lowercase: "abcdefghijklmnopqrstuvwxyz",
        numbers:   "0123456789",
        symbols:   "!@#$%^&*()-_=+[]{}|;:',.<>?/~"
    )

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("Advanced Settings")
                    .font(.headline)
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(16)

            Divider()

            ScrollView {
                VStack(spacing: 12) {
                    characterSetRow(
                        label: "Uppercase",
                        isEnabled: $settings.isUppercaseEnabled,
                        characters: $settings.customUppercase
                    )
                    Divider()
                    characterSetRow(
                        label: "Lowercase",
                        isEnabled: $settings.isLowercaseEnabled,
                        characters: $settings.customLowercase
                    )
                    Divider()
                    characterSetRow(
                        label: "Numbers",
                        isEnabled: $settings.isNumbersEnabled,
                        characters: $settings.customNumbers
                    )
                    Divider()
                    characterSetRow(
                        label: "Symbols",
                        isEnabled: $settings.isSymbolsEnabled,
                        characters: $settings.customSymbols
                    )
                }
                .padding(16)
            }

            Divider()

            // App settings
            HStack {
                Toggle(isOn: $launchAtLogin) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Launch at Login")
                            .font(.subheadline)
                        Text("Start PassGen automatically when you log in")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onChange(of: launchAtLogin) { _, enabled in
                    toggleLaunchAtLogin(enabled)
                }
                Spacer()
            }
            .padding(16)

            Divider()

            // Global shortcut
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Global Shortcut")
                        .font(.subheadline)
                    Text("Generate & copy a password from anywhere")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                ShortcutRecorderView(keyCode: $settings.hotKeyCode, modifiers: $settings.hotKeyModifiers)
                    .frame(width: 120, height: 28)
            }
            .padding(16)

            Divider()

            // Footer
            HStack {
                Button(role: .destructive) {
                    resetToDefaults()
                } label: {
                    Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                }
                Spacer()
            }
            .padding(16)
        }
        .frame(width: 420, height: 540)
    }

    // MARK: - Row

    @ViewBuilder
    private func characterSetRow(
        label: String,
        isEnabled: Binding<Bool>,
        characters: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(label, isOn: isEnabled)
                .font(.subheadline.weight(.medium))

            TextField("", text: characters)
                .font(.system(.body, design: .monospaced))
                .textFieldStyle(.roundedBorder)
                .disabled(!isEnabled.wrappedValue)
                .opacity(isEnabled.wrappedValue ? 1 : 0.4)

            HStack {
                let count = uniqueCount(characters.wrappedValue)
                Text("\(count) character\(count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if isEnabled.wrappedValue && characters.wrappedValue.isEmpty {
                    Spacer()
                    Label("Empty — won't be used", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    // MARK: - Helpers

    private func toggleLaunchAtLogin(_ enable: Bool) {
        do {
            if enable {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            launchAtLogin = !enable // revert on failure
        }
    }

    private func uniqueCount(_ s: String) -> Int {
        Set(s).count
    }

    private func resetToDefaults() {
        settings.customUppercase = defaults.uppercase
        settings.customLowercase = defaults.lowercase
        settings.customNumbers   = defaults.numbers
        settings.customSymbols   = defaults.symbols
    }
}

#Preview {
    AdvancedSettingsView()
        .environmentObject(SettingsStore())
}
