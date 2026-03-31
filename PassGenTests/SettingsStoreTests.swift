//
//  SettingsStoreTests.swift
//  PassGenTests
//
//  Created by Denys Popov on 31.03.2026.
//

import Foundation
import Testing
@testable import PassGen

// In-memory UserDefaults substitute — completely isolated, no app domain fallthrough.
private final class MemoryDefaults: UserDefaultsProtocol {
    private var store: [String: Any] = [:]
    func object(forKey key: String) -> Any? { store[key] }
    func string(forKey key: String) -> String? { store[key] as? String }
    func data(forKey key: String) -> Data? { store[key] as? Data }
    func set(_ value: Any?, forKey key: String) {
        if let value { store[key] = value } else { store.removeValue(forKey: key) }
    }
}

private func makeStore() -> SettingsStore {
    SettingsStore(defaults: MemoryDefaults())
}

struct SettingsStoreTests {

    // MARK: - Defaults

    @Test func defaultValuesAreCorrect() {
        let store = makeStore()
        #expect(store.isUppercaseEnabled == true)
        #expect(store.isLowercaseEnabled == true)
        #expect(store.isNumbersEnabled   == true)
        #expect(store.isSymbolsEnabled   == true)
        #expect(store.passwordLength     == 16)
    }

    @Test func defaultCharacterSetsAreCorrect() {
        let store = makeStore()
        #expect(store.customUppercase == "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        #expect(store.customLowercase == "abcdefghijklmnopqrstuvwxyz")
        #expect(store.customNumbers   == "0123456789")
        #expect(store.customSymbols   == "!@#$%^&*()-_=+[]{}|;:',.<>?/~")
    }

    // MARK: - Character pool composition

    @Test func poolIncludesAllWhenAllEnabled() {
        let store = makeStore()
        let pool = store.characterPool
        #expect(pool.contains("A"))
        #expect(pool.contains("a"))
        #expect(pool.contains("0"))
        #expect(pool.contains("!"))
    }

    @Test func poolIsEmptyWhenAllDisabled() {
        let store = makeStore()
        store.isUppercaseEnabled = false
        store.isLowercaseEnabled = false
        store.isNumbersEnabled   = false
        store.isSymbolsEnabled   = false
        #expect(store.characterPool.isEmpty)
    }

    @Test func poolContainsOnlyUppercaseWhenOthersDisabled() {
        let store = makeStore()
        store.isLowercaseEnabled = false
        store.isNumbersEnabled   = false
        store.isSymbolsEnabled   = false
        #expect(store.characterPool == store.customUppercase)
    }

    @Test func poolReflectsCustomCharacters() {
        let store = makeStore()
        store.isLowercaseEnabled = false
        store.isNumbersEnabled   = false
        store.isSymbolsEnabled   = false
        store.customUppercase = "XYZ"
        #expect(store.characterPool == "XYZ")
    }

    @Test func poolExcludesDisabledCategory() {
        let store = makeStore()
        store.isSymbolsEnabled = false
        let pool = store.characterPool
        for char in store.customSymbols {
            #expect(!pool.contains(char) || store.customUppercase.contains(char)
                    || store.customLowercase.contains(char) || store.customNumbers.contains(char))
        }
    }

    // MARK: - History

    @Test func addToHistoryStoresPassword() {
        let store = makeStore()
        store.addToHistory("abc123")
        #expect(store.passwordHistory.first == "abc123")
    }

    @Test func historyCapIsTen() {
        let store = makeStore()
        for i in 1...15 { store.addToHistory("password\(i)") }
        #expect(store.passwordHistory.count == 10)
    }

    @Test func historyMostRecentIsFirst() {
        let store = makeStore()
        store.addToHistory("first")
        store.addToHistory("second")
        #expect(store.passwordHistory.first == "second")
    }

    @Test func historyDeduplicates() {
        let store = makeStore()
        store.addToHistory("duplicate")
        store.addToHistory("other")
        store.addToHistory("duplicate")
        #expect(store.passwordHistory.first == "duplicate")
        #expect(store.passwordHistory.count == 2)
    }

    @Test func clearHistoryRemovesAllEntries() {
        let store = makeStore()
        store.addToHistory("abc")
        store.addToHistory("xyz")
        store.clearHistory()
        #expect(store.passwordHistory.isEmpty)
    }
}
