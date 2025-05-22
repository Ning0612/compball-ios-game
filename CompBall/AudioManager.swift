//
//  AudioManager.swift
//  CompBall
//
//  Created by 王政甯 on 2025/5/21.
//

import AVFoundation
import SpriteKit

/// 全域音效控制中心
/// - 只需 call `playBGM()` 一次即可開始背景音，之後透過 `isMuted` 控制靜音
enum AudioManager {

    // MARK: - 公用屬性
    /// 是否靜音；監聽 didSet 自動調整音量
    static var isMuted: Bool = false {
        didSet { bgmPlayer?.volume = isMuted ? 0 : 0.5 }
    }

    // MARK: - 私用屬性
    private(set) static var bgmPlayer: AVAudioPlayer?

    // MARK: - 公用方法
    /// 播放背景音樂（只會成功執行一次）
    static func playBGM() {
        guard
            bgmPlayer == nil,                      // 已播放過則略過
            let url = Bundle.main.url(forResource: "background", withExtension: "mp3"),
            let player = try? AVAudioPlayer(contentsOf: url)
        else { return }

        player.numberOfLoops = -1                 // 無限循環
        player.volume = isMuted ? 0 : 0.5
        player.prepareToPlay()
        player.play()
        bgmPlayer = player
    }
    
    static func stopBGM() {
        bgmPlayer?.stop()
        bgmPlayer = nil           // 釋放資源（下次再進遊戲會重新 playBGM）
    }

    /// 播放一次性音效（檔名含副檔名）
    /// - Parameters:
    ///   - name: 音效檔名
    ///   - node: 執行 `run` 的 SKNode
    static func playEffect(named name: String, on node: SKNode) {
        guard !isMuted else { return }
        node.run(SKAction.playSoundFileNamed(name, waitForCompletion: false))
    }
}
