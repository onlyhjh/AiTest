//
//  PlayerFactory.swift
//  AiTest
//
//  Created by Joey's Mac mini on 6/15/26.
//

import Foundation

class PlayerFactory {
    func loadPlayer(playerIndex: Int) -> Player? {
        var playerData: Data?
        switch playerIndex {
        case 1: playerData = UserDefaults.standard.player1
        case 2: playerData = UserDefaults.standard.player2
        default : playerData = UserDefaults.standard.user
        }
        
        if let playerData, let player = try? JSONDecoder().decode(Player.self, from: playerData) {
            return player
        }
        
        return nil
    }
    
    func getRandomPlayers() -> [Player] {
        let random = (0...20).shuffled()
        var players: [Player] = []
        
        for i in 0...2 {
            var player = Player(index: i)
            player.characterIndex = random[i]
            player.name = GameData.playerNames[random[i]]
            player.imageName = Player.imageNamePrefix + String(format: "%02d", random[i])
            players.append(player)
        }
        return players
    }
    
    func getRandomPlayer(playerIndex: Int, without: [Int]) -> Player {
        let withoutNumbers = (Set(without) as Set).symmetricDifference(1...20)
        let random = (withoutNumbers).shuffled()

        var player = Player(index: playerIndex)
        player.characterIndex = random[0]
        player.name = GameData.playerNames[random[0]]
        player.imageName = Player.imageNamePrefix + String(format: "%02d", random[0])
        
        return player
    }
}
