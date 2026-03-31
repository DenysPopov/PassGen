//
//  SettingsStore.swift
//  PassGen
//
//  Created by Denys Popov on 31.03.2026.
//

import Combine
import Foundation

class SettingsStore: ObservableObject {
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
                UserDefaults.standard.set(data, forKey: "passwordHistory")
            }
        }
    }

    init() {
        let d = UserDefaults.standard
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
        h.removeAll { $0 == password }   // avoid duplicates
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
        UserDefaults.standard.set(value, forKey: key)
    }
}
