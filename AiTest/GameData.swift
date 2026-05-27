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
    case showSelectCardPopup
    case showOneSecMessagePopup
    case showAlert
    case next
    case wait
}

class GameData: ObservableObject {
    @Published var gameStatus: GameStatus = .wait
    @Published var deckCards: [Card] = []
    var popupMessage: String? = nil
    var popupCards: [Card] = []
    var completion: () -> Void = { }
}
