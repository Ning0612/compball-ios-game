//
//  MainMenuView.swift
//  CompBall
//
//  Created by 王政甯 on 2025/5/21.
//

import SwiftUI
import SpriteKit

/// 遊戲主選單：深色背景 + 三顆按鈕，提供「一般模式」、「倒數模式」及「排行榜」選項。
struct MainMenuView: View {

    // MARK: - Menu Selection Enum
    /// Defines the possible selections from the main menu, conforming to `Identifiable`
    /// to be used with `.fullScreenCover(item:)`.
    enum MenuSelection: Identifiable {
        case none        // No selection
        case normal      // Normal game mode
        case countdown   // Countdown game mode
        case ranking     // Ranking view

        // Conformance to Identifiable for use with `fullScreenCover`
        var id: Int { hashValue }
    }

    // MARK: - State Properties
    @State private var selection: MenuSelection? = nil // Tracks the currently selected menu item

    // MARK: - Body
    var body: some View {
        ZStack {
            
            Image("main_background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            

            VStack(spacing: 30) {
                Spacer()
                    .frame(height: 340)
                // MARK: - Menu Buttons

                // Button for Normal Mode
                Button {
                    selection = .normal // Set selection to normal mode
                } label: {
                    menuButtonLabel("一般模式") // Uses a common style for all menu buttons
                }

                // Button for Countdown Mode
                Button {
                    selection = .countdown // Set selection to countdown mode
                } label: {
                    menuButtonLabel("倒數模式") // Uses a common style for all menu buttons
                }

                // Button for Ranking
                Button {
                    selection = .ranking // Set selection to ranking view
                } label: {
                    menuButtonLabel("排行榜") // Uses a common style for all menu buttons
                }
            }
        }
        // MARK: - Full Screen Cover Navigation
        // Presents different views based on the `selection` state.
        .fullScreenCover(item: $selection) { selectedCase in
            switch selectedCase {
            case .normal:
                GameView(mode: .normal) // Navigate to GameView in normal mode
            case .countdown:
                GameView(mode: .countdown) // Navigate to GameView in countdown mode
            case .ranking:
                RankingView() // Navigate to RankingView
            case .none:
                EmptyView() // No view shown if .none is selected
            }
        }
    }

    /// MARK: - Private Helper Views
    /// Provides a consistent visual style for all menu buttons, with customizable colors.
    /// - Parameters:
    ///   - text: The text to display on the button.
    ///   - foregroundColor: The text color.
    ///   - backgroundColor: The background color.
    /// - Returns: A `View` configured with the menu button styling.
    private func menuButtonLabel(
        _ text: String,
        foregroundColor: Color = .black,
        backgroundColor: Color = Color.white.opacity(0.6)
    ) -> some View {
        Text(text)
            .font(.system(size: 50))
            .frame(maxWidth: 600)
            .padding()
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.black.opacity(0.8), lineWidth: 2)
            )
    }
}
