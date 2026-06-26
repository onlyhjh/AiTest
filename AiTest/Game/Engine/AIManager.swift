//
//  AIManager.swift
//  AiTest
//
//  Created by Joey's Mac mini on 6/25/26.
//

class AIEngineManager: AIEngine {
    private let cursorAI = CursorAIEngine()
    private let claudeAI = ClaudeAIEngine()
    
    func selectCard(gameData: GameData, playerIndex: Int, deckOrHandCard: Card, tableCards: [Card]) -> Card {
        if playerIndex == 1 {
            return cursorAI.selectCard(gameData: gameData, playerIndex: playerIndex, deckOrHandCard: deckOrHandCard, tableCards: tableCards)
        }
        else {
            return claudeAI.selectCard(gameData: gameData, playerIndex: playerIndex, deckOrHandCard: deckOrHandCard, tableCards: tableCards)
        }
    }
    
    func selectGukjin(gameData: GameData, playerIndex: Int) -> Bool {
        if playerIndex == 1 {
            return cursorAI.selectGukjin(gameData: gameData, playerIndex: playerIndex)
        }
        else {
            return claudeAI.selectGukjin(gameData: gameData, playerIndex: playerIndex)
        }
    }
    
    func selectWave(gameData: GameData, playerIndex: Int, cards: [Card]) -> Bool {
        if playerIndex == 1 {
            return cursorAI.selectWave(gameData: gameData, playerIndex: playerIndex, cards: cards)
        }
        else {
            return claudeAI.selectWave(gameData: gameData, playerIndex: playerIndex, cards: cards)
        }
    }
    
    func selectHandCard(gameData: GameData, playerIndex: Int) -> Card {
        if playerIndex == 1 {
            return cursorAI.selectHandCard(gameData: gameData,  playerIndex: playerIndex)
        }
        else {
            return claudeAI.selectHandCard(gameData: gameData, playerIndex: playerIndex)
        }
    }
    
    func selectGoOrStop(gameData: GameData, playerIndex: Int) -> Bool {
        if playerIndex == 1 {
            return cursorAI.selectGoOrStop(gameData: gameData, playerIndex: playerIndex)
        }
        else {
            return claudeAI.selectGoOrStop(gameData: gameData, playerIndex: playerIndex)
        }
    }
}
