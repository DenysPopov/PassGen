//
//  SettingsStore.swift
//  PassGen
//
//  Created by Denys Popov on 31.03.2026.
//

import Combine
import Foundation

// Thin protocol so tests can inject an in-memory store instead of UserDefaults.
protocol UserDefaultsProtocol {
    func object(forKey key: String) -> Any?
    func string(forKey key: String) -> String?
    func data(forKey key: String) -> Data?
    func set(_ value: Any?, forKey key: String)
}

extension UserDefaults: UserDefaultsProtocol {}

class SettingsStore: ObservableObject {
    private let defaults: UserDefaultsProtocol

    @Published var isUppercaseEnabled: Bool = true { didSet { save("isUppercaseEnabled", isUppercaseEnabled) } }
    @Published var isLowercaseEnabled: Bool = true { didSet { save("isLowercaseEnabled", isLowercaseEnabled) } }
    @Published var isNumbersEnabled:   Bool = true { didSet { save("isNumbersEnabled",   isNumbersEnabled)   } }
    @Published var isSymbolsEnabled:   Bool = true { didSet { save("isSymbolsEnabled",   isSymbolsEnabled)   } }
    @Published var passwordLength: Double   = 16   { didSet { save("passwordLength",     passwordLength)     } }

    @Published var customUppercase: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"       { didSet { save("customUppercase", customUppercase) } }
    @Published var customLowercase: String = "abcdefghijklmnopqrstuvwxyz"       { didSet { save("customLowercase", customLowercase) } }
    @Published var customNumbers:   String = "0123456789"                       { didSet { save("customNumbers",   customNumbers)   } }
    @Published var customSymbols:   String = "!@#$%^&*()-_=+[]{}|;:',.<>?/~"  { didSet { save("customSymbols",   customSymbols)   } }

    @Published var passwordHistory: [String] = [] {
        didSet {
            if let data = try? JSONEncoder().encode(passwordHistory) {
                defaults.set(data, forKey: "passwordHistory")
            }
        }
    }

    init(defaults: UserDefaultsProtocol = UserDefaults.standard) {
        self.defaults = defaults
        let d = defaults
        if let v = d.object(forKey: "isUppercaseEnabled") as? Bool   { isUppercaseEnabled = v }
        if let v = d.object(forKey: "isLowercaseEnabled") as? Bool   { isLowercaseEnabled = v }
        if let v = d.object(forKey: "isNumbersEnabled")   as? Bool   { isNumbersEnabled   = v }
        if let v = d.object(forKey: "isSymbolsEnabled")   as? Bool   { isSymbolsEnabled   = v }
        if let v = d.object(forKey: "passwordLength")     as? Double { passwordLength     = v }
        if let v = d.string(forKey: "customUppercase")               { customUppercase    = v }
        if let v = d.string(forKey: "customLowercase")               { customLowercase    = v }
        if let v = d.string(forKey: "customNumbers")                 { customNumbers      = v }
        if let v = d.string(forKey: "customSymbols")                 { customSymbols      = v }
        if let data = d.data(forKey: "passwordHistory"),
           let history = try? JSONDecoder().decode([String].self, from: data) {
            passwordHistory = history
        }
    }

    func addToHistory(_ password: String) {
        var h = passwordHistory
        h.removeAll { $0 == password }
        h.insert(password, at: 0)
        passwordHistory = Array(h.prefix(10))
    }

    func clearHistory() {
        passwordHistory = []
    }

    var characterPool: String {
        var pool = ""
        if isUppercaseEnabled { pool += customUppercase }
        if isLowercaseEnabled { pool += customLowercase }
        if isNumbersEnabled   { pool += customNumbers }
        if isSymbolsEnabled   { pool += customSymbols }
        return pool
    }

    private func save(_ key: String, _ value: some Any) {
        defaults.set(value, forKey: key)
    }
}
