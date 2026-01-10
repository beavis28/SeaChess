//
//  ContentView.swift
//  SimpleShogi Watch App
//
//  Created by satoshi goto on 9/1/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var gameState = GameState()
    @State private var aiPlayer = AIPlayer()
    @State private var isAIThinking = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 3) {
                // Status display
                if gameState.gameOver {
                    Text(gameState.winner == .player ? "You Win!" : "AI Wins")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text(gameState.currentPlayer == .player ? "Your Turn" : "AI's Turn")
                        .font(.caption)
                        .foregroundColor(gameState.currentPlayer == .player ? .blue : .orange)
                }
                
                // Hand pieces display (Player)
                if !gameState.playerHand.isEmpty {
                    HStack(spacing: 2) {
                        Text("Hand:")
                            .font(.caption2)
                        ForEach(Array(gameState.playerHand.enumerated()), id: \.offset) { index, pieceType in
                            Button(action: {
                                handleHandPieceTap(pieceType: pieceType)
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(gameState.selectedHandPiece == pieceType ? Color.blue.opacity(0.5) : Color.gray.opacity(0.2))
                                        .frame(width: 30, height: 30)
                                    ZStack {
                                        if pieceType == .lion {
                                            // 鯨（どっしりとした表現）
                                            Text(pieceType.rawValue)
                                                .font(.system(size: 20, weight: .bold))
                                            
                                            // 王冠を被せる
                                            Text("👑")
                                                .font(.system(size: 9))
                                                .offset(y: -7)
                                        } else {
                                            Text(pieceType.rawValue)
                                                .font(.system(size: 18))
                                        }
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // 盤面
                VStack(spacing: 2) {
                    ForEach(0..<gameState.rows, id: \.self) { row in
                        HStack(spacing: 2) {
                            ForEach(0..<gameState.cols, id: \.self) { col in
                                BoardCellView(
                                    position: Position(row, col),
                                    gameState: gameState,
                                    isValidMove: isValidMovePosition(Position(row, col)),
                                    onTap: { handleCellTap(at: Position(row, col)) }
                                )
                            }
                        }
                    }
                }
                .padding(3)
                
                // Reset button
                if gameState.gameOver {
                    Button("Play Again") {
                        resetGame()
                    }
                    .font(.caption2)
                }
                
                // Rules section
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rules")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.top, 4)
                    
                    // Whale (King)
                    RuleRowView(
                        icon: "🐋",
                        name: "Whale (King)",
                        description: "Moves 1 square in all directions",
                        hasCrown: true
                    )
                    
                    // Octopus (Bishop)
                    RuleRowView(
                        icon: "🐙",
                        name: "Octopus (Bishop)",
                        description: "Moves 1 square horizontally or vertically"
                    )
                    
                    // Crab (Rook)
                    RuleRowView(
                        icon: "🦀",
                        name: "Crab (Rook)",
                        description: "Moves 1 square diagonally"
                    )
                    
                    // Fish (Pawn)
                    RuleRowView(
                        icon: "🐟",
                        name: "Fish (Pawn)",
                        description: "Moves 1 square forward"
                    )
                    
                    // Shark (Promoted Fish)
                    RuleRowView(
                        icon: "🦈",
                        name: "Shark (Promoted Fish)",
                        description: "Moves forward, backward, sideways, and diagonally forward"
                    )
                    
                    Text("Win Condition: Capture the opponent's whale")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
                .padding(.horizontal, 4)
                .padding(.top, 4)
            }
            .padding(4)
        }
        .onChange(of: gameState.currentPlayer) { oldValue, newValue in
            if newValue == .ai && !gameState.gameOver && !isAIThinking {
                makeAIMove()
            }
        }
    }
    
    private func isValidMovePosition(_ position: Position) -> Bool {
        if let selected = gameState.selectedPosition {
            return gameState.getValidMoves(from: selected).contains(position)
        } else if let selectedPieceType = gameState.selectedHandPiece {
            return gameState.getValidDropPositions(for: selectedPieceType).contains(position)
        }
        return false
    }
    
    
    private func handleHandPieceTap(pieceType: PieceType) {
        guard gameState.currentPlayer == .player && !gameState.gameOver else { return }
        
        if gameState.selectedHandPiece == pieceType {
            gameState.selectedHandPiece = nil
        } else {
            gameState.selectedHandPiece = pieceType
            gameState.selectedPosition = nil
        }
    }
    
    private func handleCellTap(at position: Position) {
        guard gameState.currentPlayer == .player && !gameState.gameOver else { return }
        
        // 持ち駒が選択されている場合
        if let selectedPieceType = gameState.selectedHandPiece {
            if gameState.getValidDropPositions(for: selectedPieceType).contains(position) {
                _ = gameState.dropPiece(pieceType: selectedPieceType, to: position)
            } else {
                gameState.selectedHandPiece = nil
            }
            return
        }
        
        // 盤上の駒の処理
        if let selected = gameState.selectedPosition {
            // 移動先が選択されている
            let validMoves = gameState.getValidMoves(from: selected)
            if validMoves.contains(position) {
                gameState.movePiece(from: selected, to: position)
            } else {
                // 別の駒を選択
                if let piece = gameState.getPiece(at: position), piece.owner == .player {
                    gameState.selectedPosition = position
                } else {
                    gameState.selectedPosition = nil
                }
            }
        } else {
            // 駒を選択
            if let piece = gameState.getPiece(at: position), piece.owner == .player {
                gameState.selectedPosition = position
            }
        }
    }
    
    private func makeAIMove() {
        isAIThinking = true
        
        // AIの思考時間をシミュレート（少し遅延）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let bestMove = aiPlayer.findBestMove(gameState: gameState) {
                if let from = bestMove.from {
                    gameState.movePiece(from: from, to: bestMove.to)
                } else if let pieceType = bestMove.pieceType {
                    _ = gameState.dropPiece(pieceType: pieceType, to: bestMove.to)
                }
            }
            isAIThinking = false
        }
    }
    
    private func resetGame() {
        gameState.selectedPosition = nil
        gameState.selectedHandPiece = nil
        let newState = GameState()
        gameState.board = newState.board
        gameState.currentPlayer = newState.currentPlayer
        gameState.playerHand = newState.playerHand
        gameState.aiHand = newState.aiHand
        gameState.gameOver = newState.gameOver
        gameState.winner = newState.winner
    }
}

// 盤面のセルView
struct BoardCellView: View {
    let position: Position
    @ObservedObject var gameState: GameState
    let isValidMove: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // 背景
                RoundedRectangle(cornerRadius: 4)
                    .fill(backgroundColor)
                    .frame(width: 35, height: 35)
                
                // 駒
                if let piece = gameState.getPiece(at: position) {
                    ZStack {
                        if piece.type == .lion {
                            // 鯨（どっしりとした表現）
                            Text(piece.displaySymbol)
                                .font(.system(size: 28, weight: .bold))
                                .rotationEffect(.degrees(piece.owner == .ai ? 180 : 0))
                            
                            // 王冠を被せる
                            Text("👑")
                                .font(.system(size: 14))
                                .rotationEffect(.degrees(piece.owner == .ai ? 180 : 0))
                                .offset(y: piece.owner == .ai ? 8 : -8)
                        } else {
                            Text(piece.displaySymbol)
                                .font(.system(size: 24))
                                .rotationEffect(.degrees(piece.owner == .ai ? 180 : 0))
                        }
                    }
                } else if isValidMove {
                    // 動ける位置を示す緑点（駒がない場合）
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var backgroundColor: Color {
        let isSelected = gameState.selectedPosition == position
        if isSelected {
            return .blue.opacity(0.5)
        } else if isValidMove {
            return .green.opacity(0.6)
        } else {
            // チェッカーパターン（青と水色）
            return (position.row + position.col) % 2 == 0 ? Color.blue.opacity(0.3) : Color.cyan.opacity(0.3)
        }
    }
    
}

// ルール説明の行View
struct RuleRowView: View {
    let icon: String
    let name: String
    let description: String
    var hasCrown: Bool = false
    
    var body: some View {
        HStack(spacing: 4) {
            ZStack {
                if hasCrown {
                    Text(icon)
                        .font(.system(size: 16, weight: .bold))
                    Text("👑")
                        .font(.system(size: 8))
                        .offset(y: -6)
                } else {
                    Text(icon)
                        .font(.system(size: 16))
                }
            }
            .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.caption2)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    ContentView()
}
