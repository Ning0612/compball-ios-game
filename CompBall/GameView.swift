//
//  GameView.swift
//  CompBall
//
//  Created by 王政甯 on 2025/4/13.
//

import SwiftUI
import SpriteKit

enum GameMode { case normal, countdown }

struct GameView: View {
    
    // ★ 1) 把 GameScene 實體化一次後存在 @State
    @State private var gameScene: GameScene
    @Environment(\.dismiss) private var dismiss
    
    @State private var isMuted   = AudioManager.isMuted
    @State private var isPaused  = false
    @State private var showNameAlert = false
    @State private var tempScore = 0
    @State private var inputName = ""
    
    @State private var tempElapsed = 0            // ★ 新增

    
    // ★ 2) 自訂 init，接 mode 後建立 scene
    init(mode: GameMode) {
        _gameScene = State(initialValue:
            GameScene(size: CGSize(width: 1024, height: 768), mode: mode)
        )
    }
    
    var body: some View {
        ZStack {
            SpriteView(scene: gameScene)          // ← 使用同一個實例
                .ignoresSafeArea()
            
            // 左上：返回
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
            // 右上：靜音 / 暫停
            HStack(spacing: 20) {
                Button {
                    isMuted.toggle()
                    AudioManager.isMuted = isMuted
                } label: {
                    Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .foregroundColor(.white)
                        .imageScale(.large)
                        .padding(8)
                }
                
                Button {
                    isPaused.toggle()
                    gameScene.isPaused = isPaused
                    if isPaused { gameScene.sceneDidPause() } else { gameScene.sceneDidResume() }
                } label: {
                    Image(systemName: isPaused ? "play.circle.fill" : "pause.circle.fill")
                        .foregroundColor(.white)
                        .imageScale(.large)
                        .padding(8)
                }
            }
            .padding(.trailing, 16)
            .padding(.top, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
        // ---------- 破紀錄 Alert ----------
        .onReceive(NotificationCenter.default.publisher(for: .gameOverScore)) { note in
            // ① 重新開始會送空 userInfo ⇒ 關閉 Alert 後直接 return
            guard let info = note.userInfo, !info.isEmpty else {
                showNameAlert = false
                return
            }

            // ② 正常破紀錄流程
            if let sc = info["score"] as? Int {
                tempScore = sc
                tempElapsed = info["seconds"] as? Int ?? 0
                showNameAlert = true
            }
        }
        .alert("輸入名稱", isPresented: $showNameAlert, actions: {
            TextField("Name", text: $inputName)
            Button("確定") {
                let name = inputName.trimmingCharacters(in: .whitespaces)
                let finalName = name.isEmpty ? "Unknown" : name     // ← 空白給 unknown
                switch gameScene.mode {
                case .normal:
                    ScoreManager.addNormal(name: finalName, score: tempScore)
                case .countdown:
                    ScoreManager.addCountdown(name: finalName,
                                              score: tempScore,
                                              seconds: tempElapsed)
                }
                resumeScene()
            }
        }, message: { Text("恭喜打入前 10！") })

    }
    
    private func resumeScene() {
        inputName = ""
        tempScore = 0
        tempElapsed = 0
        showNameAlert = false
        gameScene.isPaused = false
        isPaused = false
    }

}
