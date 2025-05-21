//
//  AudioManager.swift
//  CompBall
//
//  Created by 王政甯 on 2025/5/21.
//

import AVFoundation
import SpriteKit   

/// 全域音效控制
enum AudioManager {
    static var isMuted: Bool = false {
        didSet { bgmPlayer?.volume = isMuted ? 0 : 0.5 }
    }
    
    
    
    private(set) static var bgmPlayer: AVAudioPlayer?
    
    /// 播放背景音樂（只呼叫一次）
    static func playBGM() {
        guard bgmPlayer == nil,                     // 已播放則略過
              let url = Bundle.main.url(forResource: "background", withExtension: "ogg"),
              let player = try? AVAudioPlayer(contentsOf: url) else { return }
        
        player.numberOfLoops = -1
        player.volume = isMuted ? 0 : 0.5
        player.prepareToPlay()
        player.play()
        bgmPlayer = player
    }
    
    /// 播放一次性音效（merge.wav）
    static func playEffect(named name: String, on node: SKNode) {
            guard !isMuted else { return }
            node.run(SKAction.playSoundFileNamed(name, waitForCompletion: false))
        }

}
