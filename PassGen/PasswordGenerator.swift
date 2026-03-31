//
//  PasswordGenerator.swift
//  PassGen
//
//  Created by Denys Popov on 31.03.2026.
//

import Foundation
import Security

struct PasswordGenerator {

    /// Generates a cryptographically secure random password.
    /// Returns nil if the character pool is empty or length < 1.
    static func generate(length: Int, from pool: String) -> String? {
        guard length >= 1, !pool.isEmpty else { return nil }

        let poolChars = Array(pool)
        let poolSize = poolChars.count

        // Largest multiple of poolSize that fits in a UInt8 (0...255),
        // used to eliminate modulo bias.
        let maxUsable = (256 / poolSize) * poolSize

        var result = ""
        result.reserveCapacity(length)

        while result.count < length {
            var randomByte: UInt8 = 0
            guard SecRandomCopyBytes(kSecRandomDefault, 1, &randomByte) == errSecSuccess else {
                return nil
            }
            let value = Int(randomByte)
            if value < maxUsable {
                result.append(poolChars[value % poolSize])
            }
            // Reject bytes outside maxUsable range to avoid modulo bias
        }

        return result
    }

    /// Returns entropy in bits: length × log₂(poolSize).
    static func entropy(length: Int, poolSize: Int) -> Double {
        guard poolSize > 1, length > 0 else { return 0 }
        return Double(length) * log2(Double(poolSize))
    }
}
