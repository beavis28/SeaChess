//
//  AIPlayer.swift
//  SimpleShogi Watch App
//
//  Created by satoshi goto on 9/1/26.
//

import Foundation

class AIPlayer {
    let maxDepth: Int = 3
    
    // 最善手を計算
    func findBestMove(gameState: GameState) -> (from: Position?, to: Position, pieceType: PieceType?)? {
        let moves = gameState.getAllPossibleMoves(for: .ai)
        guard !moves.isEmpty else { return nil }
        
        var bestMove: (from: Position?, to: Position, pieceType: PieceType?)?
        var bestScore = Int.min
        
        for move in moves {
            let newState = GameState(from: gameState)
            newState.applyMove(from: move.from, to: move.to, pieceType: move.pieceType)
            
            let score = minimax(state: newState, depth: maxDepth - 1, isMaximizing: false, alpha: Int.min, beta: Int.max)
            
            if score > bestScore {
                bestScore = score
                bestMove = move
            }
        }
        
        return bestMove
    }
    
    // ミニマックス法（アルファベータ法）
    private func minimax(state: GameState, depth: Int, isMaximizing: Bool, alpha: Int, beta: Int) -> Int {
        // 終了条件
        if state.gameOver {
            if let winner = state.winner {
                return winner == .ai ? 1000 : -1000
            }
            return 0
        }
        
        if depth == 0 {
            return evaluateBoard(state: state)
        }
        
        let player: Player = isMaximizing ? .ai : .player
        let moves = state.getAllPossibleMoves(for: player)
        
        if moves.isEmpty {
            return evaluateBoard(state: state)
        }
        
        var alpha = alpha
        var beta = beta
        
        if isMaximizing {
            var maxScore = Int.min
            for move in moves {
                let newState = GameState(from: state)
                newState.applyMove(from: move.from, to: move.to, pieceType: move.pieceType)
                let score = minimax(state: newState, depth: depth - 1, isMaximizing: false, alpha: alpha, beta: beta)
                maxScore = max(maxScore, score)
                alpha = max(alpha, score)
                if beta <= alpha {
                    break // 枝刈り
                }
            }
            return maxScore
        } else {
            var minScore = Int.max
            for move in moves {
                let newState = GameState(from: state)
                newState.applyMove(from: move.from, to: move.to, pieceType: move.pieceType)
                let score = minimax(state: newState, depth: depth - 1, isMaximizing: true, alpha: alpha, beta: beta)
                minScore = min(minScore, score)
                beta = min(beta, score)
                if beta <= alpha {
                    break // 枝刈り
                }
            }
            return minScore
        }
    }
    
        // 盤面評価
    private func evaluateBoard(state: GameState) -> Int {
        var score = 0
        
        // 駒の価値
        let pieceValues: [PieceType: Int] = [
            .lion: 1000,
            .hen: 200,
            .chick: 100,
            .giraffe: 150,
            .elephant: 150
        ]
        
        for row in 0..<state.rows {
            for col in 0..<state.cols {
                if let piece = state.getPiece(at: Position(row, col)) {
                    let value = pieceValues[piece.type] ?? 0
                    if piece.owner == .ai {
                        score += value
                        // ライオンが前進しているとボーナス
                        if piece.type == .lion {
                            score += (state.rows - row) * 10
                        }
                    } else {
                        score -= value
                        // プレイヤーのライオンが前進しているとペナルティ
                        if piece.type == .lion {
                            score -= row * 10
                        }
                    }
                }
            }
        }
        
        // 持ち駒の価値も考慮
        for pieceType in state.aiHand {
            score += (pieceValues[pieceType] ?? 0) / 2
        }
        for pieceType in state.playerHand {
            score -= (pieceValues[pieceType] ?? 0) / 2
        }
        
        return score
    }
}

