import Foundation

// -------- 資料結構 --------
struct NormalEntry: Codable, Identifiable {
    var id = UUID()
    let name: String
    let score: Int
}
struct CountdownEntry: Codable, Identifiable {
    var id = UUID()
    let name: String
    let score: Int
    let seconds: Int
}

// -------- 管理 --------
enum ScoreManager {
    private static let normalKey    = "CompBallTop10Normal"
    private static let countdownKey = "CompBallTop10Countdown"
    private static let maxCount = 10                       // ← 前 10

    // MARK: 一般
    static func topNormal() -> [NormalEntry] { load(key: normalKey) }
    static func addNormal(name: String, score: Int) {
        var list: [NormalEntry] = load(key: normalKey)
        list.append(NormalEntry(name: name, score: score))
        list.sort { $0.score > $1.score }
        if list.count > maxCount { list = Array(list.prefix(maxCount)) }
        save(list, key: normalKey)
    }

    // MARK: 倒數
    static func topCountdown() -> [CountdownEntry] { load(key: countdownKey) }
    static func addCountdown(name: String, score: Int, seconds: Int) {
        var list: [CountdownEntry] = load(key: countdownKey)
        list.append(CountdownEntry(name: name, score: score, seconds: seconds))
        list.sort {
            $0.score > $1.score || ($0.score == $1.score && $0.seconds < $1.seconds)
        }
        if list.count > maxCount { list = Array(list.prefix(maxCount)) }
        save(list, key: countdownKey)
    }

    // -------- 泛型 load / save --------
    private static func load<T: Codable>(key: String) -> [T] {
        guard let d = UserDefaults.standard.data(forKey: key),
              let l = try? JSONDecoder().decode([T].self, from: d) else { return [] }
        return l
    }
    private static func save<T: Codable>(_ list: [T], key: String) {
        if let d = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(d, forKey: key)
        }
    }
}
