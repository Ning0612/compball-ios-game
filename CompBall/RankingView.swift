//
//  RankingView.swift
//  CompBall
//
//  Created by 王政甯 on 2025/5/21.
//

import SwiftUI

// MARK: - RankingView
struct RankingView: View {

    // MARK: - Properties
    // Fetches ranking data from ScoreManager for both game modes
    private let normal = ScoreManager.topNormal()       // [NormalEntry]
    private let cd     = ScoreManager.topCountdown()    // [CountdownEntry]

    // Environment variable to dismiss the view
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body
    var body: some View {
        ZStack {
            // Sets the background color to black and ignores safe area insets
            Image("rank_background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 12) {
                // Title of the ranking view
                Spacer().frame(height: 12)
                
                Text("排行榜")
                    .font(.system(size: 60).bold())
                    .foregroundColor(.white)

                // Horizontal stack to display rankings for both modes side-by-side
                HStack(alignment: .top, spacing: 100) {

                    // MARK: - Normal Mode Ranking
                    VStack(alignment: .leading, spacing: 8) {
                        Text("一般模式")
                            .font(.system(size: 38))
                            .foregroundColor(.cyan)
                            .frame(maxWidth: .infinity, alignment: .center) // Centers the title

                        // Displays "尚無紀錄" if no entries, otherwise lists them
                        if normal.isEmpty {
                            Text("尚無紀錄")
                                .foregroundColor(.gray)
                                .font(.system(size: 24))
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            ForEach(Array(normal.enumerated()), id: \.element.id) { idx, entry in
                                RowNormal(rank: idx + 1, entry: entry)
                            }
                        }
                    }
                    .padding(20)
                    .frame(width: 500, height: 580 ,alignment: .top) // Fixed width for consistent layout
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(16)

                    // MARK: - Countdown Mode Ranking
                    VStack(alignment: .leading, spacing: 8) {
                        Text("倒數模式")
                            .font(.system(size: 38))
                            .foregroundColor(.orange)
                            .frame(maxWidth: .infinity, alignment: .center) // Centers the title

                        // Displays "尚無紀錄" if no entries, otherwise lists them
                        if cd.isEmpty {
                            Text("尚無紀錄")
                                .foregroundColor(.gray)
                                .font(.system(size: 24))
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            ForEach(Array(cd.enumerated()), id: \.element.id) { idx, entry in
                                RowCountdown(rank: idx + 1, entry: entry)
                            }
                        }
                    }
                    .padding(20)
                    .frame(width: 500, height: 580 ,alignment: .top) // Fixed width for consistent layout
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(16)
                }
                .padding(.horizontal) // Adds horizontal padding to the HStack
                .frame(maxWidth: .infinity, alignment: .center) // Centers the HStack within its parent

                Spacer() // Pushes content to the top, and the button to the bottom

                // MARK: - Return Button
                Button("返回") {
                    dismiss() // Dismisses the current view
                }
                .font(.system(size: 24))
                .padding()
                .frame(maxWidth: 160)
                .background(Color.white.opacity(0.5)) // Semi-transparent background
                .cornerRadius(10) // Rounded corners for the button
            }
            .padding() // Adds overall padding to the VStack
        }
    }
}

// ---

// MARK: - Row Views
// Private struct for displaying a single normal mode ranking entry
private struct RowNormal: View {
    let rank: Int        // The rank number (e.g., #1, #2)
    let entry: NormalEntry // The data for the ranking entry

    var body: some View {
        HStack {
            Text("#\(rank)")
                .frame(width: 60, alignment: .leading) // Fixed width for rank alignment
                .font(.system(size: 34))
            Text(entry.name) // Player's name
            Spacer()        // Pushes score to the right
            Text("\(entry.score)") // Player's score
        }
        .foregroundColor(.black)
        .font(.system(size: 34))
    }
}

// Private struct for displaying a single countdown mode ranking entry
private struct RowCountdown: View {
    let rank: Int           // The rank number
    let entry: CountdownEntry // The data for the ranking entry

    var body: some View {
        HStack {
            Text("#\(rank)")
                .frame(width: 60, alignment: .leading) // Fixed width for rank alignment
                .font(.system(size: 34))
            Text(entry.name) // Player's name
            Spacer()         // Pushes scores to the right
            Text("\(entry.score)") // Player's score
            Text("(\(entry.seconds)s)") // Time taken for countdown mode
                .font(.system(size: 24))
                .foregroundColor(.blue) // Different color for time for distinction
        }
        .foregroundColor(.black)
        .font(.system(size: 34))
    }
}
