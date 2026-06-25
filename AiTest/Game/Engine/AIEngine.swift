//
//  AIEngine.swift
//  AiTest
//
//  Created by Joey's Mac mini on 6/25/26.
//

protocol AIEngine {
    func setGameData(_ gameData: GameData) -> Void
    
    /// 매칭 테이블 카드 2장 중 가져갈 카드 선택
    func selectCard(aiPlayerIndex: Int, deckOrHandCard: Card, tableCards: [Card]) -> Card
    /// true = 쌍피, false = 열끗
    func selectGukjin(aiPlayerIndex: Int, card: Card) -> Bool

    /// true = 흔들기
    func selectWave(aiPlayerIndex: Int, cards: [Card]) -> Bool

    /// AI가 낼 손패 카드 선택
    func selectHandCard(aiPlayerIndex: Int, tableCards: [Card]) -> Card
    
    /// true = 고, false = 스톱
    func selectGoOrStop(aiPlayerIndex: Int, tableCards: [Card]) -> Bool
}
