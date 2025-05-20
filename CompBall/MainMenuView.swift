//
//  MainMenuView.swift
//  CompBall
//
//  Created by 王政甯 on 2025/5/21.
//

import SwiftUI
import SpriteKit

/// 遊戲主選單：深色背景 + 三顆按鈕
struct MainMenuView: View {
    @State private var selection: MenuSelection? = nil

    enum MenuSelection {
        case none
        case normal     // 一般模式
        case countdown  // 倒數模式
        case ranking    // 排行榜
    }
        
    var body: some View {
        ZStack {
            // 深色背景
            Color(.black)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Text("CompBall")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                
                // 一般模式
                Button {
                    selection = .normal
                } label: {
                    menuButtonLabel("一般模式")
                }
                
                // 倒數模式
                Button {
                    selection = .countdown
                } label: {
                    menuButtonLabel("倒數模式")
                }
                
                // 排行榜
                Button {
                    selection = .ranking
                } label: {
                    menuButtonLabel("排行榜")
                }
            }
        }
        // 依照 selection push 對應畫面
        .fullScreenCover(item: $selection) { sel in
            switch sel {
            case .normal:
                GameView(mode: .normal)      // 一般模式
            case .countdown:
                GameView(mode: .countdown)   // 倒數模式（下一步會實作）
            case .ranking:
                RankingView()                // 排行榜（下一步會實作）
            case .none:
                EmptyView()
            }
        }
    }
    
    /// 統一的按鈕樣式
    private func menuButtonLabel(_ text: String) -> some View {
        Text(text)
            .font(.title2.bold())
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white.opacity(0.12))
            .foregroundColor(.white)
            .cornerRadius(12)
    }
}

/// 讓 .fullScreenCover 的 item 符合 Identifiable
extension MainMenuView.MenuSelection: Identifiable {
    var id: Int { hashValue }
}
