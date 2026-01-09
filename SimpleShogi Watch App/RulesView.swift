//
//  RulesView.swift
//  SeaChess Watch App
//
//  Created by satoshi goto on 9/1/26.
//

import SwiftUI

struct RulesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("SeaChess Rules")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                Group {
                    Text("Board")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Text("• 4x4 grid")
                    Text("• Your pieces start on the bottom row (randomly placed)")
                    Text("• AI pieces start on the top row (randomly placed)")
                }
                .padding(.bottom, 4)
                
                Group {
                    Text("Pieces")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Text("🐋 Whale (King): Moves 1 square in any direction")
                    Text("🐙 Octopus (Rook): Moves 1 square horizontally or vertically")
                    Text("🦀 Crab (Bishop): Moves 1 square diagonally")
                    Text("🐟 Small Fish (Pawn): Moves 1 square forward only")
                    Text("🦈 Shark (Promoted): Moves forward, backward, sideways, and diagonally forward")
                }
                .padding(.bottom, 4)
                
                Group {
                    Text("Promotion")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Text("• When a Small Fish reaches the opponent's back row, it automatically promotes to a Shark")
                }
                .padding(.bottom, 4)
                
                Group {
                    Text("Capturing")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Text("• When you capture an opponent's piece, it goes to your hand")
                    Text("• You can drop captured pieces on any empty square on your turn")
                    Text("• Small Fish cannot be dropped on the opponent's back row")
                    Text("• If you capture a Shark, it becomes a Small Fish in your hand")
                }
                .padding(.bottom, 4)
                
                Group {
                    Text("Winning")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Text("• Capture the opponent's Whale, OR")
                    Text("• Move your Whale to the opponent's back row")
                }
                .padding(.bottom, 4)
                
                Group {
                    Text("How to Play")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Text("• Tap a piece to select it")
                    Text("• Green squares show valid moves")
                    Text("• Tap a green square to move")
                    Text("• Tap a piece in your hand, then tap an empty square to drop it")
                    Text("• Opponent pieces are shown upside down")
                }
            }
            .padding()
            .font(.caption)
        }
    }
}

#Preview {
    RulesView()
}

