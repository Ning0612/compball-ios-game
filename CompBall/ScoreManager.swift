//
//  ScoreManager.swift
//  CompBall
//
//  Created by 王政甯 on 2025/4/13.
//

import Foundation

struct ScoreManager {
    private static let scoresKey = "BallFusionScores"  // UserDefaults 存取用的鍵值
    
    /// 新增一筆遊戲得分到本機排行榜中，並自動排序和截取最高的若干筆分數
    static func addScore(_ score: Int) {
        let defaults = UserDefaults.standard
        // 讀取已存在的分數陣列，若沒有則使用空陣列
        var scores = defaults.array(forKey: scoresKey) as? [Int] ?? []
        // 加入新的得分
        scores.append(score)
        // 由高到低排序分數
        scores.sort(by: >)
        // （可選）保留前 N 筆最高分，例如保留前10名
        if scores.count > 10 {
            scores = Array(scores.prefix(10))
        }
        // 將更新後的分數列表保存回 UserDefaults
        defaults.set(scores, forKey: scoresKey)
        defaults.synchronize()
    }
    
    /// 從本機排行榜取得所有儲存的分數（已排序，由高到低）
    static func getTopScores() -> [Int] {
        let defaults = UserDefaults.standard
        let scores = defaults.array(forKey: scoresKey) as? [Int] ?? []
        // 確保以由大到小排序後返回
        return scores.sorted(by: >)
    }
    
    /// （可選）清除本機儲存的所有分數記錄
    static func clearScores() {
        UserDefaults.standard.removeObject(forKey: scoresKey)
    }
}
