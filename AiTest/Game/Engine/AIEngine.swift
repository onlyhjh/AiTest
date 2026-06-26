//
//  AIEngine.swift
//  AiTest
//
//  Created by Joey's Mac mini on 6/25/26.
//

protocol AIEngine {
    /// 매칭 테이블 카드 2장 중 가져갈 카드 선택
    func selectCard(gameData: GameData, playerIndex: Int, deckOrHandCard: Card, tableCards: [Card]) -> Card
    
    /// true = 쌍피, false = 열끗
    func selectGukjin(gameData: GameData, playerIndex: Int) -> Bool

    /// true = 흔들기
    func selectWave(gameData: GameData, playerIndex: Int, cards: [Card]) -> Bool

    /// AI가 낼 손패 카드 선택
    func selectHandCard(gameData: GameData, playerIndex: Int) -> Card
    
    /// true = 고, false = 스톱
    func selectGoOrStop(gameData: GameData, playerIndex: Int) -> Bool
}
