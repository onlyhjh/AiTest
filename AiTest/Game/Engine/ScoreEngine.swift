//
//  ScoreEngine.swift
//  AiTest
//
//  Created by Joey's Mac mini on 6/25/26.
//
import Foundation

class ScoreEngine {
    func getPlayersFinalScore(winnerIndex: Int, gameData: GameData, wasNagari: Bool, goBakPlayerIndex: Int?) -> [Player] {
        var winner = gameData.players[winnerIndex]
        var loser1 = gameData.players[(winnerIndex + 1) % 3]
        var loser2 = gameData.players[(winnerIndex + 2) % 3]
        
        winner.wasNagari = wasNagari
        
        if winner.gwangScore > 0 {
            loser1.isGwangBak = loser1.gwangCount == 0
            loser2.isGwangBak = loser2.gwangCount == 0
        }
        
        if winner.piScore > 0 {
            loser1.isPiBak = loser1.piCount > 0 && loser1.piCount < 6
            loser2.isPiBak = loser2.piCount > 0 && loser2.piCount < 6
        }
        
        // 독박 확인
        loser1.finalScore = winner.subtotalScore * (loser1.isGwangBak ? 2 :1) * (loser1.isPiBak ? 2 : 1)
        loser2.finalScore = winner.subtotalScore * (loser2.isGwangBak ? 2 :1) * (loser2.isPiBak ? 2 : 1)
        
        if let goBakPlayerIndex {
            if goBakPlayerIndex == loser1.index {
                loser1.isGoBak = true
                loser1.finalScore += loser2.finalScore
                loser2.finalScore = 0
            }
            else if goBakPlayerIndex == loser2.index {
                loser2.isGoBak = true
                loser2.finalScore += loser1.finalScore
                loser1.finalScore = 0
            }
        }
        winner.finalScore = loser1.finalScore + loser2.finalScore
        
        return[winner, loser1, loser2]
    }
}
