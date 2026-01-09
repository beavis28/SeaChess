//
//  GameModel.swift
//  SimpleShogi Watch App
//
//  Created by satoshi goto on 9/1/26.
//

import Foundation
import SwiftUI

// 駒の種類
enum PieceType: String, CaseIterable {
    case lion = "🐋"      // ライオン（王）→ クジラ
    case giraffe = "🐙"   // キリン（角）→ タコ
    case elephant = "🦀"  // ゾウ（飛）→ カニ
    case chick = "🐟"     // ひよこ（歩）→ 小魚
    case hen = "🦈"       // にわとり（成ったひよこ）→ サメ
    
    var isPromoted: Bool {
        return self == .hen
    }
}

// プレイヤー
enum Player {
    case player
    case ai
    
    var opposite: Player {
        return self == .player ? .ai : .player
    }
}

// 駒
struct Piece: Identifiable {
    let id = UUID()
    let type: PieceType
    let owner: Player
    
    var displaySymbol: String {
        return type.rawValue
    }
    
    var displayColor: Color {
        return owner == .player ? .blue : .red
    }
}

// 位置
struct Position: Hashable {
    let row: Int
    let col: Int
    
    init(_ row: Int, _ col: Int) {
        self.row = row
        self.col = col
    }
}

// 盤面の状態
class GameState: ObservableObject {
    @Published var board: [[Piece?]]
    @Published var currentPlayer: Player
    @Published var selectedPosition: Position?
    @Published var selectedHandPiece: PieceType? // 選択中の持ち駒
    @Published var playerHand: [PieceType] = [] // プレイヤーの持ち駒
    @Published var aiHand: [PieceType] = [] // AIの持ち駒
    @Published var gameOver: Bool = false
    @Published var winner: Player?
    
    let rows = 4
    let cols = 4
    
    init() {
        // @Publishedプロパティを最初に初期化
        self.currentPlayer = .player
        self.board = Array(repeating: Array(repeating: nil, count: cols), count: rows)
        
        // 手前1列目（row 3）に4つのコマをランダムに配置
        var playerPositions: [Position] = []
        
        // 手前1列目（row 3）の全位置を取得
        for col in 0..<cols {
            playerPositions.append(Position(rows - 1, col))
        }
        
        // ランダムにシャッフル
        playerPositions.shuffle()
        
        // プレイヤー側の駒を配置（4個）
        board[playerPositions[0].row][playerPositions[0].col] = Piece(type: .giraffe, owner: .player)
        board[playerPositions[1].row][playerPositions[1].col] = Piece(type: .lion, owner: .player)
        board[playerPositions[2].row][playerPositions[2].col] = Piece(type: .elephant, owner: .player)
        board[playerPositions[3].row][playerPositions[3].col] = Piece(type: .chick, owner: .player)
        
        // AI側の駒を配置（4個）- 上1列目（row 0）にランダムに配置
        var aiPositions: [Position] = []
        for col in 0..<cols {
            aiPositions.append(Position(0, col))
        }
        aiPositions.shuffle()
        
        board[aiPositions[0].row][aiPositions[0].col] = Piece(type: .elephant, owner: .ai)
        board[aiPositions[1].row][aiPositions[1].col] = Piece(type: .lion, owner: .ai)
        board[aiPositions[2].row][aiPositions[2].col] = Piece(type: .giraffe, owner: .ai)
        board[aiPositions[3].row][aiPositions[3].col] = Piece(type: .chick, owner: .ai)
    }
    
    // コピーコンストラクタ
    init(from other: GameState) {
        // @Publishedプロパティを初期化
        self.board = other.board.map { $0.map { $0 } }
        self.currentPlayer = other.currentPlayer
        self.selectedPosition = other.selectedPosition
        self.selectedHandPiece = other.selectedHandPiece
        self.playerHand = other.playerHand
        self.aiHand = other.aiHand
        self.gameOver = other.gameOver
        self.winner = other.winner
    }
    
    // 有効な移動先を取得
    func getValidMoves(from position: Position, for player: Player? = nil) -> [Position] {
        let targetPlayer = player ?? currentPlayer
        guard let piece = getPiece(at: position),
              piece.owner == targetPlayer else {
            return []
        }
        
        var moves: [Position] = []
        let directions = getMoveDirections(for: piece.type, at: position)
        
        for direction in directions {
            let newRow = position.row + direction.row
            let newCol = position.col + direction.col
            
            // 盤面の範囲内かチェック
            if newRow >= 0 && newRow < rows && newCol >= 0 && newCol < cols {
                let newPos = Position(newRow, newCol)
                let targetPiece = getPiece(at: newPos)
                
                // 自分の駒でない場合のみ移動可能
                if targetPiece?.owner != targetPlayer {
                    moves.append(newPos)
                }
            }
        }
        
        return moves
    }
    
    // 移動可能な方向を取得（キリンとゾウ用）
    func getMoveDirections(for position: Position) -> [(row: Int, col: Int)] {
        guard let piece = getPiece(at: position) else { return [] }
        return getMoveDirections(for: piece.type, at: position)
    }
    
    // 駒の移動方向を取得
    private func getMoveDirections(for type: PieceType, at position: Position) -> [(row: Int, col: Int)] {
        let isPlayer = getPiece(at: position)?.owner == .player
        let forward = isPlayer ? -1 : 1
        
        switch type {
        case .lion:
            // ライオン：全方向1マス
            return [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]
            
        case .giraffe:
            // キリン：縦横1マス
            return [(-1, 0), (1, 0), (0, -1), (0, 1)]
            
        case .elephant:
            // ゾウ：斜め1マス
            return [(-1, -1), (-1, 1), (1, -1), (1, 1)]
            
        case .chick:
            // ひよこ：前1マスのみ
            return [(forward, 0)]
            
        case .hen:
            // にわとり：前後左右と斜め前
            return [(forward, -1), (forward, 0), (forward, 1), (-forward, 0), (0, -1), (0, 1)]
        }
    }
    
    // 駒を取得
    func getPiece(at position: Position) -> Piece? {
        return board[position.row][position.col]
    }
    
    // 駒を移動
    func movePiece(from: Position, to: Position) {
        guard var piece = board[from.row][from.col] else { return }
        
        // 取った駒を処理
        if let capturedPiece = board[to.row][to.col] {
            addToHand(capturedPiece: capturedPiece)
        }
        
        // 移動
        board[to.row][to.col] = piece
        board[from.row][from.col] = nil
        
        // 成り判定（ひよこが相手の陣地の一番奥に到達）
        if piece.type == .chick {
            let promotionRow = piece.owner == .player ? 0 : rows - 1
            if to.row == promotionRow {
                piece = Piece(type: .hen, owner: piece.owner)
                board[to.row][to.col] = piece
            }
        }
        
        // 勝敗判定
        checkGameOver()
        
        // ターン交代
        if !gameOver {
            currentPlayer = currentPlayer.opposite
        }
        
        selectedPosition = nil
        selectedHandPiece = nil
    }
    
    // 取った駒を持ち駒に追加
    private func addToHand(capturedPiece: Piece) {
        // にわとりを取った場合はひよことして追加
        let pieceType: PieceType = capturedPiece.type == .hen ? .chick : capturedPiece.type
        
        if capturedPiece.owner == .player {
            aiHand.append(pieceType)
        } else {
            playerHand.append(pieceType)
        }
    }
    
    // 持ち駒を打つ
    func dropPiece(pieceType: PieceType, to position: Position) -> Bool {
        guard board[position.row][position.col] == nil else { return false }
        
        // ひよこは相手の陣地の一番奥には打てない
        if pieceType == .chick {
            let forbiddenRow = currentPlayer == .player ? 0 : rows - 1
            if position.row == forbiddenRow {
                return false
            }
        }
        
        // 持ち駒から削除
        if currentPlayer == .player {
            guard let index = playerHand.firstIndex(of: pieceType) else { return false }
            playerHand.remove(at: index)
        } else {
            guard let index = aiHand.firstIndex(of: pieceType) else { return false }
            aiHand.remove(at: index)
        }
        
        // 駒を配置
        board[position.row][position.col] = Piece(type: pieceType, owner: currentPlayer)
        
        // 勝敗判定
        checkGameOver()
        
        // ターン交代
        if !gameOver {
            currentPlayer = currentPlayer.opposite
        }
        
        selectedHandPiece = nil
        return true
    }
    
    // 持ち駒を打てる位置を取得
    func getValidDropPositions(for pieceType: PieceType, for player: Player? = nil) -> [Position] {
        let targetPlayer = player ?? currentPlayer
        var positions: [Position] = []
        
        for row in 0..<rows {
            for col in 0..<cols {
                let pos = Position(row, col)
                
                // 空いているマスかチェック
                guard board[row][col] == nil else { continue }
                
                // ひよこは相手の陣地の一番奥には打てない
                if pieceType == .chick {
                    let forbiddenRow = targetPlayer == .player ? 0 : rows - 1
                    if row == forbiddenRow {
                        continue
                    }
                }
                
                positions.append(pos)
            }
        }
        
        return positions
    }
    
    // 持ち駒を取得
    func getHand(for player: Player) -> [PieceType] {
        return player == .player ? playerHand : aiHand
    }
    
    // 勝敗判定
    private func checkGameOver() {
        // ライオンを取られたかチェック
        var playerLionExists = false
        var aiLionExists = false
        var playerLionInGoal = false
        
        for row in 0..<rows {
            for col in 0..<cols {
                if let piece = board[row][col] {
                    if piece.type == .lion {
                        if piece.owner == .player {
                            playerLionExists = true
                            // プレイヤーのライオンがAIの陣地（row 0）に到達
                            if row == 0 {
                                playerLionInGoal = true
                            }
                        } else {
                            aiLionExists = true
                        }
                    }
                }
            }
        }
        
        if !aiLionExists {
            gameOver = true
            winner = .player
        } else if !playerLionExists {
            gameOver = true
            winner = .ai
        } else if playerLionInGoal {
            gameOver = true
            winner = .player
        }
    }
    
    // すべての可能な手を取得（AI用）
    func getAllPossibleMoves(for player: Player) -> [(from: Position?, to: Position, pieceType: PieceType?)] {
        var moves: [(from: Position?, to: Position, pieceType: PieceType?)] = []
        
        // 盤上の駒の移動
        for row in 0..<rows {
            for col in 0..<cols {
                let pos = Position(row, col)
                if let piece = getPiece(at: pos), piece.owner == player {
                    let validMoves = getValidMoves(from: pos, for: player)
                    for move in validMoves {
                        moves.append((from: pos, to: move, pieceType: nil))
                    }
                }
            }
        }
        
        // 持ち駒を打つ手
        let hand = player == .player ? playerHand : aiHand
        for pieceType in hand {
            let validPositions = getValidDropPositions(for: pieceType, for: player)
            for pos in validPositions {
                moves.append((from: nil, to: pos, pieceType: pieceType))
            }
        }
        
        return moves
    }
    
    // 手を適用（AI用、ターン交代なし）
    func applyMove(from: Position?, to: Position, pieceType: PieceType?) {
        if let from = from {
            // 盤上の駒を移動
            guard var piece = board[from.row][from.col] else { return }
            
            // 取った駒を処理
            if let capturedPiece = board[to.row][to.col] {
                addToHand(capturedPiece: capturedPiece)
            }
            
            // 移動
            board[to.row][to.col] = piece
            board[from.row][from.col] = nil
            
            // 成り判定（ひよこが相手の陣地の一番奥に到達）
            if piece.type == .chick {
                let promotionRow = piece.owner == .player ? 0 : rows - 1
                if to.row == promotionRow {
                    piece = Piece(type: .hen, owner: piece.owner)
                    board[to.row][to.col] = piece
                }
            }
        } else if let pieceType = pieceType {
            // 持ち駒を打つ
            if currentPlayer == .ai {
                guard let index = aiHand.firstIndex(of: pieceType) else { return }
                aiHand.remove(at: index)
            } else {
                guard let index = playerHand.firstIndex(of: pieceType) else { return }
                playerHand.remove(at: index)
            }
            
            board[to.row][to.col] = Piece(type: pieceType, owner: currentPlayer)
        }
        
        // 勝敗判定（ターン交代はしない）
        checkGameOver()
    }
}

