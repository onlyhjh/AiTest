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
    case next
    case wait
    case updatePlayers
}



class GameData: ObservableObject {
    static let playerNames = ["고니", "정마담", "고광렬", "짝귀", "평경장", "박무석", "아귀", "곽철용", "장동식", "함대길", "꼬장", "작은마담", "우사장", "송마담", "허미나", "영미", "도일출", "애꾸", "이상무", "물영감", "까치"]
    
    @Published var gameStatus: GameStatus = .wait
    var deckCards: [Card] = [] // saving test
    var cardDuration: Double = 0.2
    var winnerIndex = 0
    var players: [Player] = [Player(index: 0), Player(index: 1), Player(index: 2)]
    var currentPlayerIndex = 0
}


