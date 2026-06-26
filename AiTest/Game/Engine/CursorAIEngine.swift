//
//  CursorAIEngine.swift
//  AiTest
//
//  Created by Joey's Mac mini on 6/25/26.
//

import Foundation

/// 고스톱 AI — 점수·족보·상대 견제를 반영한 휴리스틱 엔진
final class CursorAIEngine: AIEngine {

    /// true = 고, false = 스톱
    func selectGoOrStop(gameData: GameData, playerIndex: Int) -> Bool {
        let player = gameData.players[playerIndex]
        let opponents = opponentPlayers(gameData: gameData, excluding: playerIndex)
        let myScore = player.baseScore
        let maxOpponentScore = opponents.map(\.baseScore).max() ?? 0
        let scoreGain = myScore - player.lastGoScore
        let deckRemaining = gameData.deckCards.count
        let upside = handUpside(gameData: gameData, for: player, tableCards: gameData.allTableCards)

        // 막장이면 무조건 스톱
        if player.handCards.isEmpty {
            return false
        }

        // 7점 이상이면서 앞서면 스톱
        if myScore >= 7 && myScore >= maxOpponentScore + 2 {
            return false
        }

        // 상대가 7점 이상이면 더 모아야 함
        if maxOpponentScore >= 7 && myScore <= maxOpponentScore {
            return shouldGoAggressively(player: player, scoreGain: scoreGain, deckRemaining: deckRemaining)
        }

        // 이미 고를 한 상태
        if player.goCount > 0 {
            // 점수가 오르지 않았으면 스톱
            if scoreGain <= 0 {
                return false
            }
            // 2고 이상인데 점수가 낮으면 무리한 고 방지
            if player.goCount >= 2 && myScore < 5 {
                return false
            }
            // 충분히 올랐고 앞서면 스톱
            if myScore >= 5 && myScore > maxOpponentScore && scoreGain >= 2 {
                return false
            }
            return scoreGain >= 1 && upside >= 8
        }

        // 첫 고 판단
        if myScore >= 5 && myScore > maxOpponentScore {
            return upside >= 12 && deckRemaining > 6
        }

        if myScore >= 3 {
            if maxOpponentScore >= myScore {
                return scoreGain >= 1 || upside >= 10
            }
            return upside >= 14 && deckRemaining > 8
        }

        return false
    }

    /// 매칭 테이블 카드 2장 중 가져갈 카드 선택
    func selectCard(gameData: GameData, playerIndex: Int, deckOrHandCard: Card, tableCards: [Card]) -> Card {
        guard tableCards.count >= 2 else {
            return tableCards.last ?? deckOrHandCard
        }

        let player = gameData.players[playerIndex]
        return tableCards.max { lhs, rhs in
            capturePairValue(gameData: gameData, handOrDeck: deckOrHandCard, table: lhs, player: player)
                < capturePairValue(gameData: gameData, handOrDeck: deckOrHandCard, table: rhs, player: player)
        } ?? tableCards[0]
    }

    /// true = 쌍피, false = 열끗
    func selectGukjin(gameData: GameData, playerIndex: Int) -> Bool {
        let player = gameData.players[playerIndex]

        // 고도리 2장 → 열끗
        if player.godoriCount == 2 {
            return false
        }

        // 열 4장 → 열끗으로 점수
        if player.yeolCount == 4 {
            return false
        }

        // 피 8장 이하 → 쌍피(2피)가 유리
        if player.piCount <= 7 {
            return true
        }

        // 피 9장 → 쌍피로 10피 완성
        if player.piCount == 9 {
            return true
        }

        // 피가 충분하고 열/고도리 쪽이 더 필요하면 열끗
        let yeolValue = marginalYeolValue(for: player)
        let piValue = marginalPiValue(for: player, asDouble: true)
        return piValue >= yeolValue
    }

    /// true = 흔들기
    func selectWave(gameData: GameData, playerIndex: Int, cards: [Card]) -> Bool {
        let player = gameData.players[playerIndex]
        guard cards.count == 3 else { return false }

        // 점수가 3점 미만이면 흔들기 배수 효과가 작음
        if player.baseScore < 3 {
            return false
        }

        // 이미 흔든 적 있으면 추가 흔들기는 신중히
        if player.waveCount > 0 && player.baseScore < 5 {
            return false
        }

        // 5점 이상이면 흔들기로 배수 올리기
        if player.baseScore >= 5 {
            return true
        }

        // 3~4점: 손패·덱에 같은 월이 더 있으면(총통·폭탄 기대) 흔들기
        let month = cards[0].month
        let sameMonthInHand = player.handCards.filter { $0.month == month }.count
        let sameMonthInDeck = gameData.deckCards.filter { $0.month == month }.count
        return sameMonthInHand + sameMonthInDeck >= 1
    }

    /// AI가 낼 손패 카드 선택
    func selectHandCard(gameData: GameData, playerIndex: Int) -> Card {
        let player = gameData.players[playerIndex]
        let handCards = player.handCards
        guard !handCards.isEmpty else {
            return Card(month: 0, type: .pi)
        }

        let tableByMonth = tableCardsByMonth(gameData.allTableCards)
        let nextDeckMonth = nextNonBonusDeckMonth(gameData: gameData)

        return handCards.max { lhs, rhs in
            handCardPlayValue(
                gameData: gameData,
                card: lhs,
                player: player,
                tableByMonth: tableByMonth,
                nextDeckMonth: nextDeckMonth
            ) < handCardPlayValue(
                gameData: gameData,
                card: rhs,
                player: player,
                tableByMonth: tableByMonth,
                nextDeckMonth: nextDeckMonth
            )
        } ?? handCards[0]
    }

    // MARK: - Hand card evaluation

    private func handCardPlayValue(
        gameData: GameData,
        card: Card,
        player: Player,
        tableByMonth: [Int: [Card]],
        nextDeckMonth: Int?
    ) -> Double {
        if card.month == 0 {
            return projectedCaptureValue(gameData: gameData, cards: [card], for: player) + 5
        }

        let sameInHand = player.handCards.filter { $0.month == card.month }.count
        let tableMatches = tableByMonth[card.month] ?? []
        var value = 0.0

        switch tableMatches.count {
        case 0:
            // 흔들기·쌓기
            if sameInHand == 3 {
                value += selectWave(gameData: gameData, playerIndex: player.index, cards: player.handCards.filter { $0.month == card.month })
                    ? 18 : 6
            } else {
                value -= 2
            }
            if let nextDeckMonth, nextDeckMonth == card.month, sameInHand < 3, player.handCards.count > 1 {
                value -= 12
            }
        case 1:
            if sameInHand == 3 {
                value += 35
            } else {
                let captured = tableMatches + [card]
                value += captured.reduce(0.0) { $0 + cardIntrinsicValue($1, for: player) }
                value += setCompletionBonus(gameData: gameData, adding: captured, to: player)
            }
            if let nextDeckMonth, nextDeckMonth == card.month, sameInHand < 3, player.handCards.count > 1 {
                value -= 8
            }
        case 2:
            let bestTable = selectCard(gameData: gameData,
                playerIndex: player.index,
                deckOrHandCard: card,
                tableCards: tableMatches
            )
            value += capturePairValue(gameData: gameData, handOrDeck: card, table: bestTable, player: player)
        default:
            value += 25
            if player.fuckCardMonths.contains(card.month) {
                value += 10
            }
        }

        return value
    }

    // MARK: - Scoring helpers

    private func capturePairValue(gameData: GameData, handOrDeck: Card, table: Card, player: Player) -> Double {
        let cards = [handOrDeck, table]
        var value = cards.reduce(0.0) { $0 + cardIntrinsicValue($1, for: player) }
        value += setCompletionBonus(gameData: gameData, adding: cards, to: player)

        if isGukjin(table) {
            value += max(marginalPiValue(for: player, asDouble: true), marginalYeolValue(for: player))
        }
        if isGukjin(handOrDeck) {
            value += max(marginalPiValue(for: player, asDouble: true), marginalYeolValue(for: player))
        }

        return value
    }

    private func cardIntrinsicValue(_ card: Card, for player: Player) -> Double {
        switch card.type {
        case .gwang:
            var value = 12.0
            if player.gwangCount == 2 { value += 18 }
            if player.gwangCount >= 3 { value += 8 }
            if player.gwangCount == 4 { value += 25 }
            return value
        case .yeol:
            var value = 4.0
            if card.isGodori {
                value += 6
                if player.godoriCount == 2 { value += 20 }
            }
            if player.yeolCount == 4 { value += 5 }
            return value
        case .tti:
            var value = 3.0
            if card.isChoDan {
                value += danProgressBonus(current: player.chodanCount)
            }
            if card.isHongDan {
                value += danProgressBonus(current: player.hongdanCount)
            }
            if card.isChungDan {
                value += danProgressBonus(current: player.chungdanCount)
            }
            if player.ttiCount == 4 { value += 4 }
            return value
        case .pi:
            var value = 1.0
            if card.isDoublePi { value = 2.5 }
            if player.piCount == 9 { value += 15 }
            if player.piCount >= 7 { value += 3 }
            return value
        }
    }

    private func danProgressBonus(current count: Int) -> Double {
        switch count {
        case 0: return 2
        case 1: return 8
        case 2: return 18
        default: return 0
        }
    }

    private func setCompletionBonus(gameData: GameData, adding cards: [Card], to player: Player) -> Double {
        projectedCaptureValue(gameData: gameData, cards: cards, for: player) - Double(player.baseScore)
    }

    private func projectedCaptureValue(gameData: GameData, cards: [Card], for player: Player) -> Double {
        Double(projectedBaseScore(gameData: gameData, for: player, adding: cards))
    }

    private func projectedBaseScore(gameData: GameData, for player: Player, adding cards: [Card]) -> Int {
        var captured = player.capturedCardTypeGroups
        for card in cards {
            if isGukjin(card) {
                if selectGukjin(gameData: gameData, playerIndex: player.index) {
                    captured[CardType.pi.rawValue].append(
                        Card(month: card.month, type: .pi, isDoublePi: true)
                    )
                } else {
                    captured[CardType.yeol.rawValue].append(card)
                }
            } else {
                captured[card.type.rawValue].append(card)
            }
        }
        return baseScore(from: captured, goCount: player.goCount)
    }

    private func baseScore(from groups: [[Card]], goCount: Int) -> Int {
        let gwangs = groups[CardType.gwang.rawValue]
        let yeols = groups[CardType.yeol.rawValue]
        let ttis = groups[CardType.tti.rawValue]
        let pis = groups[CardType.pi.rawValue]

        let gwangCount = gwangs.count == 5 ? 15
            : gwangs.count == 3 && gwangs.contains(where: { $0.month == 12 }) ? 2
            : gwangs.count
        let gwangScore = gwangCount > 4 ? 15 : gwangCount > 2 ? gwangCount - 2 : 0

        let yeolCount = yeols.count
        let yeolScore = yeolCount > 4 ? yeolCount - 4 : 0

        let ttiCount = ttis.count
        let ttiScore = ttiCount > 4 ? ttiCount - 4 : 0

        let piCount = pis.count + pis.count(where: { $0.isDoublePi })
        let piScore = piCount > 9 ? piCount - 9 : 0

        let chodanScore = ttis.count(where: { $0.isChoDan }) > 2 ? 3 : 0
        let hongdanScore = ttis.count(where: { $0.isHongDan }) > 2 ? 3 : 0
        let chungdanScore = ttis.count(where: { $0.isChungDan }) > 2 ? 3 : 0
        let godoriScore = yeols.count(where: { $0.isGodori }) > 2 ? 5 : 0

        return gwangScore + yeolScore + ttiScore + piScore
            + chodanScore + hongdanScore + chungdanScore + godoriScore + goCount
    }

    private func marginalPiValue(for player: Player, asDouble: Bool) -> Double {
        let added = asDouble ? 2 : 1
        let newCount = player.piCount + added
        if player.piCount <= 9 && newCount > 9 {
            return 20
        }
        if player.piCount == 8 && newCount >= 9 {
            return 12
        }
        return Double(added)
    }

    private func marginalYeolValue(for player: Player) -> Double {
        if player.godoriCount == 2 { return 22 }
        if player.yeolCount == 4 { return 8 }
        return 4
    }

    private func handUpside(gameData: GameData, for player: Player, tableCards: [Card]) -> Double {
        let tableByMonth = tableCardsByMonth(tableCards)
        let nextDeckMonth = nextNonBonusDeckMonth(gameData: gameData)
        return player.handCards.reduce(0.0) { partial, card in
            partial + handCardPlayValue(gameData: gameData,
                card: card,
                player: player,
                tableByMonth: tableByMonth,
                nextDeckMonth: nextDeckMonth
            )
        }
    }

    private func shouldGoAggressively(player: Player, scoreGain: Int, deckRemaining: Int) -> Bool {
        if scoreGain >= 2 { return true }
        if deckRemaining <= 4 { return player.baseScore >= 5 }
        return player.baseScore >= 3 && player.handCards.count >= 2
    }

    // MARK: - Utilities

    private func opponentPlayers(gameData: GameData, excluding index: Int) -> [Player] {
        gameData.players.enumerated()
            .filter { $0.offset != index }
            .map(\.element)
    }

    private func tableCardsByMonth(_ tableCards: [Card]) -> [Int: [Card]] {
        Dictionary(grouping: tableCards.filter { $0.month != 100 }, by: \.month)
    }

    private func nextNonBonusDeckMonth(gameData: GameData) -> Int? {
        for card in gameData.deckCards.reversed() where card.month != 0 {
            return card.month
        }
        return nil
    }

    private func isGukjin(_ card: Card) -> Bool {
        card.month == 9 && card.type == .yeol
    }
}
