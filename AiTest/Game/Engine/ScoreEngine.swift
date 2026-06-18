//
//  ScoreEngine.swift
//  AiTest
//
//  Created by Joey's Mac mini on 6/17/26.
//

import Foundation

struct ScoreResult {
    var score: Int
    var winnerScoreText: String
    var losser1ScoreText: String
    var losser2ScoreText: String
}

class ScoreEngine {
    let gameData: GameData
    
    init(gameData: GameData) {
        self.gameData = gameData
    }
    
    func getScoreResult(playerIndex: Int) -> ScoreResult {
        let player = self.gameData.players[playerIndex]
        var score = 0
        var scoreText = ""
        
        let gwangScore = player.gwangCount - 2
        if gwangScore > 0 {
            score += gwangScore
            scoreText = "\n... 광 \(gwangScore)점"
        }
        let yeolScore = player.yeolCount - 4
        if yeolScore > 0 {
            score += yeolScore
            scoreText = "\n... 열끗 \(gwangScore)점"
        }
        let ttiScore = player.ttiCount - 4
        if ttiScore > 0 {
            score += ttiScore
            scoreText = "\n... 띠 \(ttiScore)점"
        }
        let piScore = player.piCount
        if piScore > 0 {
            score += piScore
            scoreText = "\n... 피 \(piScore)점"
        }
        if player.chodanCount > 2 {
            score += 3
            scoreText = "\n... 초단 3점"
        }
        if player.hongdanCount > 2 {
            score += 3
            scoreText = "\n... 홍단 3점"
        }
        if player.chungdanCount > 2 {
            score += 3
            scoreText = "\n... 청단 3점"
        }
        if player.godoriCount > 2 {
            score += 5
            scoreText = "\n... 고도리 5점"
        }
        if player.goCount > 0 {
            score += player.goCount
            scoreText = "\n... 고 \(player.goCount)점"
        }
        if player.goCount > 2 {
            score *= 2^(3 - player.goCount)
            scoreText = "\n... \(player.goCount)고 \(2^(3 - player.goCount))배"
        }
        if player.waveCount > 0 {
            score *= 2
            scoreText = "\n... 흔들기 \(player.waveCount)회 \(2^(3 - player.waveCount))배"
        }
        if player.ttiCount > 6 {
            score *= 2
            scoreText = "\n... 멍텅구리 \(2^(3 - player.waveCount))배"
        }
        if let wasNagari = UserDefaults.standard.wasNagari, wasNagari {
            score *= 2
            scoreText = "\n... 이전판 나가리 2배"
        }
        
        scoreText = "총 \(score)점" + scoreText
        return ScoreResult(score: score, winnerScoreText: scoreText, losser1ScoreText: "", losser2ScoreText: "")
    }
}
