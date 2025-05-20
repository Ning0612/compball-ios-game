//
//  ScoreManager.swift
//  CompBall
//
//  Created by 王政甯 on 2025/4/13.
//

import Foundation

struct ScoreEntry: Codable, Identifiable {
    let id: UUID
    let name: String
    let score: Int
    
    /// 自己用時的便利建構
    init(name: String, score: Int, id: UUID = UUID()) {
        self.id = id
        self.name = name
        self.score = score
    }
}


struct ScoreManager {
    private static let key = "CompBallTop5"
    
    /// 讀取前 5
    static func getTopScores() -> [ScoreEntry] {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let list = try? JSONDecoder().decode([ScoreEntry].self, from: data)
        else { return [] }
        return list
    }
    
    /// 新增一筆 (自動排序並截前 5)
    static func addScore(name: String, score: Int) {
        var list = getTopScores()
        list.append(ScoreEntry(name: name, score: score))
        list.sort { $0.score > $1.score }
        if list.count > 5 { list = Array(list.prefix(5)) }
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
