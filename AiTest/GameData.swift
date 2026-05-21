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
    case guckginSelectPopup
}

class GameData: ObservableObject {
    @Published var gameStatus: GameStatus = .wait
    @Published var deckCards: [Card] = []
}
