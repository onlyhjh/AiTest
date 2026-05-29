//
//  PopupManager.swift
//  AiTest
//
//  Created by Joey's Mac mini on 5/29/26.
//

import SwiftUI

enum PopupType {
    case oneSecMessage
    case selectCard
    case selectWave
    case wave
    case winner
    case boom
}

class PopupManager {
    static var shared = PopupManager()
    
    func showPopup(gameData: GameData, type: PopupType, cards: [Card], players: [Player], completion: @escaping (Int) -> Void) {
        switch type {
        case .selectWave:
            break
        case .boom:
            gameData.popupTitle = "🫣 폭탄!!!"
            gameData.popupMessage = "한장씩 내놔~"
            gameData.popupCards = cards
            gameData.players = players
            gameData.completion = completion
            gameData.gameStatus = .showOneSecMessagePopup
        default:
            break
        }
    }
}
