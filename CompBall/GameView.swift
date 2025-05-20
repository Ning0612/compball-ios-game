//
//  GameView.swift
//  CompBall
//
//  Created by 王政甯 on 2025/4/13.
//

import SwiftUI
import SpriteKit

/// 遊戲模式
enum GameMode {
    case normal
    case countdown
}

struct GameView: View {
    let mode: GameMode   // ← 傳入模式
    @Environment(\.dismiss) private var dismiss
    
    @State private var showNameAlert = false
    @State private var tempScore: Int = 0
    @State private var inputName: String = ""


    /// 依模式建立對應的 GameScene
    var scene: SKScene {
        let scene = GameScene(size: CGSize(width: 1024, height: 768), mode: mode)
        scene.scaleMode = .aspectFit
        return scene
    }

    var body: some View {
        ZStack {
            SpriteView(scene: scene)
                .ignoresSafeArea()
                .overlay(alignment: .topLeading) {          // ← 返回鈕
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .padding()
                    }
                }
        }
        // ★ 接收「破紀錄」通知
        .onReceive(NotificationCenter.default.publisher(for: .gameOverScore)) { note in
            if let sc = note.userInfo?["score"] as? Int {
                tempScore = sc
                showNameAlert = true
            }
        }
        // ★ 彈出輸入名稱 Alert
        .alert("輸入名稱", isPresented: $showNameAlert, actions: {
            TextField("Name", text: $inputName)
            Button("確定") {
                let n = inputName.trimmingCharacters(in: .whitespaces)
                ScoreManager.addScore(name: n.isEmpty ? "Player" : n,
                                      score: tempScore)
                resumeScene()
            }
            Button("取消", role: .cancel) { resumeScene() }
        }, message: {
            Text("恭喜打入前 5！")
        })
    }

    private func resumeScene() {
        inputName = ""; tempScore = 0
        if let gs = scene as? GameScene { gs.isPaused = false }
    }



}
