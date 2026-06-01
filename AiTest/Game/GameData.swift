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
    case showAutoCloseMessagePopup
    case showWinnerPopup
    case showChongTongWinnerPopup
    case showAlert
    case showSelectWavePopup
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
    var completion: (_ select: Int) -> Void = { select in }
}
