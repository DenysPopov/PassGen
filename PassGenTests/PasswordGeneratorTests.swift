//
//  PasswordGeneratorTests.swift
//  PassGenTests
//
//  Created by Denys Popov on 31.03.2026.
//

import Testing
@testable import PassGen

struct PasswordGeneratorTests {

    // MARK: - Length

    @Test func generatedPasswordMatchesRequestedLength() {
        let pool = "abcdefghijklmnopqrstuvwxyz"
        for length in [1, 8, 16, 64, 128] {
            let result = PasswordGenerator.generate(length: length, from: pool)
            #expect(result?.count == length, "Expected length \(length)")
        }
    }

    @Test func lengthZeroReturnsNil() {
        let result = PasswordGenerator.generate(length: 0, from: "abc")
        #expect(result == nil)
    }

    @Test func negativeLengthReturnsNil() {
        let result = PasswordGenerator.generate(length: -1, from: "abc")
        #expect(result == nil)
    }

    // MARK: - Character pool

    @Test func passwordOnlyContainsCharactersFromPool() {
        let pool = "abc123!@#"
        let poolSet = Set(pool)
        for _ in 0..<50 {
            let result = PasswordGenerator.generate(length: 32, from: pool)!
            for char in result {
                #expect(poolSet.contains(char), "Unexpected character: \(char)")
            }
        }
    }

    @Test func emptyPoolReturnsNil() {
        let result = PasswordGenerator.generate(length: 16, from: "")
        #expect(result == nil)
    }

    @Test func singleCharPoolProducesRepeatedCharacter() {
        let result = PasswordGenerator.generate(length: 8, from: "x")
        #expect(result == "xxxxxxxx")
    }

    // MARK: - Entropy

    @Test func entropyIsZeroForEmptyPool() {
        #expect(PasswordGenerator.entropy(length: 16, poolSize: 0) == 0)
    }

    @Test func entropyIsZeroForLengthZero() {
        #expect(PasswordGenerator.entropy(length: 0, poolSize: 62) == 0)
    }

    @Test func entropyCalculationIsCorrect() {
        // 16 chars from pool of 64: 16 * log2(64) = 16 * 6 = 96
        let result = PasswordGenerator.entropy(length: 16, poolSize: 64)
        #expect(abs(result - 96.0) < 0.0001)
    }

    @Test func entropyIncreasesWithLength() {
        let short = PasswordGenerator.entropy(length: 8,  poolSize: 62)
        let long  = PasswordGenerator.entropy(length: 16, poolSize: 62)
        #expect(long > short)
    }

    @Test func entropyIncreasesWithPoolSize() {
        let small = PasswordGenerator.entropy(length: 16, poolSize: 26)
        let large = PasswordGenerator.entropy(length: 16, poolSize: 94)
        #expect(large > small)
    }

    // MARK: - Distribution (modulo bias)

    @Test func characterDistributionIsReasonablyUniform() {
        // Generate many passwords from a small pool and check each character
        // appears roughly equally — a biased generator would skew results.
        let pool = "ABCD"
        let poolChars = Array(pool)
        var counts = [Character: Int]()
        poolChars.forEach { counts[$0] = 0 }

        let iterations = 10_000
        for _ in 0..<iterations {
            let pw = PasswordGenerator.generate(length: 1, from: pool)!
            counts[pw.first!]! += 1
        }

        let expected = Double(iterations) / Double(pool.count)
        let tolerance = expected * 0.10 // allow ±10%

        for char in poolChars {
            let count = Double(counts[char]!)
            #expect(abs(count - expected) < tolerance,
                    "Character '\(char)' appeared \(counts[char]!) times, expected ~\(Int(expected))")
        }
    }
}
