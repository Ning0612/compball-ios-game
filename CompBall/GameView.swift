//
//  GameView.swift
//  CompBall
//
//  Created by 王政甯 on 2025/4/13.
//

import SwiftUI
import SpriteKit

// MARK: - 遊戲模式
enum GameMode { case normal, countdown }

// MARK: - 遊戲畫面 ---------------------------------------------------------
struct GameView: View {

    // MARK: 狀態
    @State private var gameScene: GameScene
    @Environment(\.dismiss) private var dismiss

    @State private var isMuted        = AudioManager.isMuted
    @State private var isPaused       = false
    @State private var showNameAlert  = false
    @State private var tempScore      = 0
    @State private var tempElapsed    = 0
    @State private var inputName      = ""

    // MARK: - 初始化
    init(mode: GameMode) {
        _gameScene = State(initialValue:
            GameScene(size: CGSize(width: 1024, height: 768), mode: mode)
        )
    }

    // MARK: - 版面
    var body: some View {
        ZStack {

            // SpriteKit 場景 ------------------------------------------------
            SpriteView(scene: gameScene)
                .ignoresSafeArea()

            // 左上：返回
            leadingBackButton

            // 右上：靜音 / 暫停
            topRightControls
        }
        .onReceive(scorePublisher, perform: handleScore(_:))
        .alert("輸入名稱", isPresented: $showNameAlert, actions: alertActions,
               message: { Text("恭喜打入前 10！") })
    }

    // MARK: - UI 組件 ------------------------------------------------------
    private var leadingBackButton: some View {
        Button {
            AudioManager.stopBGM()   // ★ 先把背景音樂關掉
            dismiss()                // 再返回主選單
        } label: {
            Image(systemName: "chevron.left")
                .foregroundColor(.white)
                .padding()
        }
        .frame(maxWidth: .infinity,
               maxHeight: .infinity,
               alignment: .topLeading)
    }


    private var topRightControls: some View {
        HStack(spacing: 20) {
            // 靜音
            Button {
                isMuted.toggle()
                AudioManager.isMuted = isMuted
            } label: {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .foregroundColor(.white)
                    .imageScale(.large)
                    .padding(8)
            }

            // 暫停
            Button {
                isPaused.toggle()
                gameScene.isPaused = isPaused
                isPaused ? gameScene.sceneDidPause()
                         : gameScene.sceneDidResume()
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

    // MARK: - 通知處理 ------------------------------------------------------
    private var scorePublisher: NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: .gameOverScore)
    }

    private func handleScore(_ note: NotificationCenter.Publisher.Output) {
        // 重新開始會送空 userInfo
        guard let info = note.userInfo, !info.isEmpty else {
            showNameAlert = false
            return
        }
        tempScore   = info["score"]   as? Int ?? 0
        tempElapsed = info["seconds"] as? Int ?? 0
        showNameAlert = true
    }

    // MARK: - Alert --------------------------------------------------------
    @ViewBuilder
    private func alertActions() -> some View {
        TextField("Name", text: $inputName)
        Button("確定") {
            let raw   = inputName.trimmingCharacters(in: .whitespaces)
            // --------- 一般寫入 ---------
            let final = raw.isEmpty ? "Unknown" : raw
            switch gameScene.mode {
            case .normal:
                ScoreManager.addNormal(name: final, score: tempScore)
            case .countdown:
                ScoreManager.addCountdown(name: final,
                                          score: tempScore,
                                          seconds: tempElapsed)
            }
            
            // --------- Debug: clearRank ---------
            if raw.lowercased() == "clearrank" {
                ScoreManager.clearAll()        // 清空兩榜
                resumeScene()
                return
            }
            resumeScene()
        }
    }



    // MARK: - 私用 ----------------------------------------------------------
    private func resumeScene() {
        inputName   = ""
        tempScore   = 0
        tempElapsed = 0
        showNameAlert = false
        gameScene.isPaused = false
        isPaused = false
    }
}
