//
//  GameData.swift
//  AiTest
//
//  Created by Joey's Mac mini on 5/21/26.
//

import SwiftUI
import Combine

enum GameStatus {
    case start
    case restart
    case next
    case wait
    case updatePlayers
}

class GameData: ObservableObject {
    static let defaultCardDuration: Double = 0.3
    static let playerNames = ["고니", "정마담", "고광렬", "짝귀", "평경장", "박무석", "아귀", "곽철용", "장동식", "함대길", "꼬장", "작은마담", "우사장", "송마담", "허미나", "영미", "도일출", "애꾸", "이상무", "물영감", "까치"]
    
    @Published var gameStatus: GameStatus = .wait
    var origianalDeckCards: [Card] = []  // 최초 저장용
    var deckCards: [Card] = []
    var tableCardGroups: [[Card]] = []
    var cardDuration: Double = 0
    var winnerIndex = 0
    var players: [Player] = [Player(index: 0), Player(index: 1), Player(index: 2)]
    var currentPlayerIndex = 0
    var goHistory: [Int] = []
    var allTableCards: [Card] {
        tableCardGroups.flatMap { $0 }
    }
    
    init() {
        setCardDuration(gameSpeed: UserDefaults.standard.gameSpeed ?? 0.0)
    }
    
    func resetGameData(newDeckCards: [Card]) {
        self.tableCardGroups = [[], [], [], [], [], [], [], [], [], [], [], [], [], []]
        self.winnerIndex = UserDefaults.standard.winnerHistory?.last ?? 1
        self.currentPlayerIndex = self.winnerIndex
        self.goHistory = []
        self.origianalDeckCards = newDeckCards // (최초 사용전 저장용)
        self.deckCards = newDeckCards
    }
    
    func setCardDuration(gameSpeed: Double) {
        cardDuration = GameData.defaultCardDuration + (gameSpeed * -0.2)
    }
}
