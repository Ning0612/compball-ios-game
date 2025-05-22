//
//  ScoreManager.swift
//  CompBall
//
//  Created by 王政甯 on 2025/5/21.
//

import Foundation

// MARK: - Data Structures

/// Represents a single entry in the normal mode ranking.
struct NormalEntry: Codable, Identifiable {
    let id: UUID // Unique identifier for each entry
    let name: String // Player's name
    let score: Int // Player's score

    // Initializes with a new UUID by default
    init(id: UUID = UUID(), name: String, score: Int) {
        self.id = id
        self.name = name
        self.score = score
    }
}

/// Represents a single entry in the countdown mode ranking.
struct CountdownEntry: Codable, Identifiable {
    let id: UUID // Unique identifier for each entry
    let name: String // Player's name
    let score: Int // Player's score
    let seconds: Int // Time taken in seconds (lower is better for ties)

    // Initializes with a new UUID by default
    init(id: UUID = UUID(), name: String, score: Int, seconds: Int) {
        self.id = id
        self.name = name
        self.score = score
        self.seconds = seconds
    }
}

// MARK: - Score Management

/// `ScoreManager` handles the loading, saving, and managing of high scores
/// for both normal and countdown game modes using `UserDefaults`.
enum ScoreManager {

    // MARK: - Private Constants

    private static let normalKey = "CompBallTop10Normal"     // Key for normal mode scores in UserDefaults
    private static let countdownKey = "CompBallTop10Countdown" // Key for countdown mode scores in UserDefaults
    private static let maxCount = 10                         // Maximum number of entries to store in the rankings (Top 10)

    // MARK: - Public Methods - Normal Mode

    /// Retrieves the top scores for the normal game mode.
    /// - Returns: An array of `NormalEntry` sorted by score in descending order.
    static func topNormal() -> [NormalEntry] {
        load(key: normalKey)
    }

    /// Adds a new score entry to the normal mode ranking.
    /// The list is kept sorted by score (highest first) and trimmed to `maxCount`.
    /// - Parameters:
    ///   - name: The name of the player.
    ///   - score: The score achieved by the player.
    static func addNormal(name: String, score: Int) {
        var list: [NormalEntry] = load(key: normalKey)
        list.append(NormalEntry(name: name, score: score))
        // Sort by score in descending order (highest score first)
        list.sort { $0.score > $1.score }
        // Keep only the top `maxCount` entries
        if list.count > maxCount {
            list = Array(list.prefix(maxCount))
        }
        save(list, key: normalKey)
    }

    // MARK: - Public Methods - Countdown Mode

    /// Retrieves the top scores for the countdown game mode.
    /// - Returns: An array of `CountdownEntry` sorted by score and then by time.
    static func topCountdown() -> [CountdownEntry] {
        load(key: countdownKey)
    }

    /// Adds a new score entry to the countdown mode ranking.
    /// The list is sorted first by score (highest first), then by time (lowest seconds first) for ties.
    /// It's then trimmed to `maxCount`.
    /// - Parameters:
    ///   - name: The name of the player.
    ///   - score: The score achieved by the player.
    ///   - seconds: The time taken by the player to complete the game.
    static func addCountdown(name: String, score: Int, seconds: Int) {
        var list: [CountdownEntry] = load(key: countdownKey)
        list.append(CountdownEntry(name: name, score: score, seconds: seconds))
        // Sort: primary by score (descending), secondary by seconds (ascending for ties)
        list.sort {
            $0.score > $1.score || ($0.score == $1.score && $0.seconds < $1.seconds)
        }
        // Keep only the top `maxCount` entries
        if list.count > maxCount {
            list = Array(list.prefix(maxCount))
        }
        save(list, key: countdownKey)
    }

    // MARK: - Generic Load/Save Operations

    /// Generic helper method to load a list of `Codable` objects from `UserDefaults`.
    /// - Parameter key: The `UserDefaults` key to retrieve data from.
    /// - Returns: An array of type `T`, or an empty array if data cannot be loaded/decoded.
    private static func load<T: Codable>(key: String) -> [T] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let list = try? JSONDecoder().decode([T].self, from: data) else {
            return [] // Return empty array if no data or decoding fails
        }
        return list
    }

    /// Generic helper method to save a list of `Codable` objects to `UserDefaults`.
    /// - Parameters:
    ///   - list: The array of `Codable` objects to save.
    ///   - key: The `UserDefaults` key to save data to.
    private static func save<T: Codable>(_ list: [T], key: String) {
        if let encodedData = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(encodedData, forKey: key)
        }
    }
    
    // MARK: Debug – 清除兩榜
    static func clearAll() {
        UserDefaults.standard.removeObject(forKey: normalKey)
        UserDefaults.standard.removeObject(forKey: countdownKey)
    }

}
