//
//  RankingView.swift
//  CompBall
//
//  Created by 王政甯 on 2025/5/21.
//

import SwiftUI

struct RankingView: View {
    private let top5: [ScoreEntry] = ScoreManager.getTopScores()   // ★ 明確型別
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color(.black).ignoresSafeArea()
            VStack(spacing: 24) {
                Text("排行榜")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                
                // ★ 拆成單獨 RowView，減少 type-check 負擔
                ForEach(Array(top5.enumerated()), id: \.offset) { idx, entry in
                    RowView(rank: idx + 1, entry: entry)
                }
                
                Button("返回") { dismiss() }
                    .padding()
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(10)
            }
            .padding()
        }
    }
}

/// 排行榜單列
private struct RowView: View {
    let rank: Int
    let entry: ScoreEntry
    
    var body: some View {
        HStack {
            Text("#\(rank)")
            Text(entry.name)
            Spacer()
            Text("\(entry.score)")
        }
        .foregroundColor(.white)
        .padding(.horizontal)
    }
}
