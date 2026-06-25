//
//  AIManager.swift
//  AiTest
//
//  Created by Joey's Mac mini on 6/25/26.
//

class AIEngineManager {
    private let cursorAI = CursorAIEngine()
    private let claudeAI = ClaudeAIEngine()
    
    func setGameData(_ gameData: GameData) {
        cursorAI.gameData = gameData
        claudeAI.gameData = gameData
    }
    
    func selectCard(aiPlayerIndex: Int, deckOrHandCard: Card, tableCards: [Card]) -> Card {
        if aiPlayerIndex == 1 {
            return cursorAI.selectHandCard(aiPlayerIndex: aiPlayerIndex, tableCards: tableCards)
        }
        else {
            return claudeAI.selectHandCard(aiPlayerIndex: aiPlayerIndex, tableCards: tableCards)
        }
    }
    
    func selectGukjin(aiPlayerIndex: Int, card: Card) -> Bool {
        if aiPlayerIndex == 1 {
            return cursorAI.selectGukjin(aiPlayerIndex: aiPlayerIndex, card: card)
        }
        else {
            return claudeAI.selectGukjin(aiPlayerIndex: aiPlayerIndex, card: card)
        }
    }
    
    func selectWave(aiPlayerIndex: Int, cards: [Card]) -> Bool {
        if aiPlayerIndex == 1 {
            return cursorAI.selectWave(aiPlayerIndex: aiPlayerIndex, cards: cards)
        }
        else {
            return claudeAI.selectWave(aiPlayerIndex: aiPlayerIndex, cards: cards)
        }
    }
    
    func selectHandCard(aiPlayerIndex: Int, tableCards: [Card]) -> Card {
        if aiPlayerIndex == 1 {
            return cursorAI.selectHandCard(aiPlayerIndex: aiPlayerIndex, tableCards: tableCards)
        }
        else {
            return claudeAI.selectHandCard(aiPlayerIndex: aiPlayerIndex, tableCards: tableCards)
        }
    }
    
    func selectGoOrStop(aiPlayerIndex: Int, tableCards: [Card]) -> Bool {
        if aiPlayerIndex == 1 {
            return cursorAI.selectGoOrStop(aiPlayerIndex: aiPlayerIndex, tableCards: tableCards)
        }
        else {
            return claudeAI.selectGoOrStop(aiPlayerIndex: aiPlayerIndex, tableCards: tableCards)
        }
    }
    
    
}
