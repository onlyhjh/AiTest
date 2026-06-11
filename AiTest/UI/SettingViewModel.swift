//
//  SettingViewModel.swift
//  AiTest
//
//  Created by Joey's Mac mini on 6/10/26.
//

import Combine
import SwiftUI

class SettingViewModel {
    
    var gameData: GameData
    var isFirstLaunch: Bool
    
    init(gameData: GameData, isFirstLaunch: Bool) {
        self.gameData = gameData
        self.isFirstLaunch = isFirstLaunch
        
        if isFirstLaunch {
            setPlayers()
        }
    }
    
    private func setPlayers() {
        let range = 0...20
        let randomThree = range.shuffled()
        
        for i in 0...2 {
            let randomIndex = randomThree[i]
            self.gameData.players[i].characterIndex = randomIndex
            self.gameData.players[i].name = GameData.playerNames[randomIndex]
            self.gameData.players[i].imageName = "player_" + String(format: "%02d", randomThree[i])
        }
    }
}
