//
//  PasswordGenerator.swift
//  PassGen
//
//  Created by Denys Popov on 31.03.2026.
//

import Foundation

struct PasswordGenerator {

    /// Generates a cryptographically secure random password.
    /// Returns nil if the character pool is empty or length < 1.
    static func generate(length: Int, from pool: String) -> String? {
        guard length >= 1, !pool.isEmpty else { return nil }
        let poolChars = Array(pool)
        let poolSize = UInt32(poolChars.count)
        // arc4random_uniform is cryptographically secure and eliminates modulo bias.
        return String((0..<length).map { _ in poolChars[Int(arc4random_uniform(poolSize))] })
    }

    /// Returns entropy in bits: length × log₂(poolSize).
    static func entropy(length: Int, poolSize: Int) -> Double {
        guard poolSize > 1, length > 0 else { return 0 }
        return Double(length) * log2(Double(poolSize))
    }
}
