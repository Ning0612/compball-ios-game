//
//  RankingView.swift
//  CompBall
//
//  Created by 王政甯 on 2025/5/21.
//

import SwiftUI

struct RankingView: View {
    
    // 兩邊資料
    private let normal  = ScoreManager.topNormal()        // [NormalEntry]
    private let cd      = ScoreManager.topCountdown()     // [CountdownEntry]
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("排行榜")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                
                // ------ 左右並排 ------
                HStack(alignment: .top, spacing: 100) {
                    
                    // ==== 一般模式 ====
                    VStack(alignment: .leading, spacing: 8) {
                        Text("一般模式")
                            .font(.system(size: 38))
                            .foregroundColor(.cyan)
                            .frame(maxWidth: .infinity, alignment: .center)
                        if normal.isEmpty {
                            Text("尚無紀錄")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(Array(normal.enumerated()), id:\.element.id) { idx,e in
                                RowNormal(rank: idx+1, entry: e)
                            }
                        }
                    }
                    .frame(width: 400, alignment: .leading)   // ★ 固定寬

                    // ==== 倒數模式 ====
                    VStack(alignment: .leading, spacing: 8) {
                        Text("倒數模式")
                            .font(.system(size: 38))
                            .foregroundColor(.orange)
                            .frame(maxWidth: .infinity, alignment: .center)
                        if cd.isEmpty {
                            Text("尚無紀錄")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(Array(cd.enumerated()), id:\.element.id) { idx,e in
                                RowCountdown(rank: idx+1, entry: e)
                            }
                        }
                    }
                    .frame(width: 500, alignment: .leading)   // ★ 固定寬
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .center)
                
                Spacer()
                
                Button("返回") { dismiss() }
                    .padding()
                    .frame(maxWidth: 160)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(10)
            }
            .padding()
        }
    }
}

// -------- Row views --------
private struct RowNormal: View {
    let rank: Int
    let entry: NormalEntry
    var body: some View {
        HStack {
            Text("#\(rank)")
                .frame(width: 60, alignment: .leading)
                .font(.system(size: 30))
            Text(entry.name)
            Spacer()
            Text("\(entry.score)")
        }
        .foregroundColor(.white)
        .font(.system(size: 30))
    }
}

private struct RowCountdown: View {
    let rank: Int
    let entry: CountdownEntry
    var body: some View {
        HStack {
            Text("#\(rank)")
                .frame(width: 60, alignment: .leading)
                .font(.system(size: 30))
            Text(entry.name)
            Spacer()
            Text("\(entry.score)")
            Text("(\(entry.seconds)s)")
                .font(.system(size: 18))
                .foregroundColor(.yellow)
        }
        .foregroundColor(.white)
        .font(.system(size: 30))
    }
}
