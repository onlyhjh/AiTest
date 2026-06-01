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
}

enum PopupStatus {
    case showSelectCardPopup
    case showSelectButtonPopup
    case showAutoCloseMessagePopup
    case showWinPopup
    case showSpecialWinPopup
    case showAlert
    case closePopup
}

class GameData: ObservableObject {
    @Published var gameStatus: GameStatus = .wait
    @Published var deckCards: [Card] = []
    
}

class PopupData: ObservableObject {
    @Published var status: PopupStatus = .closePopup
    var title: String? = nil
    var message: String? = nil
    var cards: [Card] = []
    var players: [Player] = []
    var buttonTexts: [String] = []
    var completion: (_ select: Int) -> Void = { select in }
}
