//
//  ClaudeAIEngine.swift
//  AiTest
//
//  Created by Joey's Mac mini on 6/25/26.
//
//  ── Claude AI Engine ──────────────────────────────────────────────────────────
//  전략 개요:
//  1. selectHandCard  : 기대 점수(Expected Value) 기반 + 상대방 저지 전략 카드 우선 선택
//  2. selectGoOrStop  : 현재 점수, 남은 패 수, 상대방 점수, 고 배율 리스크를 종합 판단
//  3. selectCard      : 테이블의 2장 중 자신에게 더 가치 있는 카드 선택
//  4. selectGukjin    : 국진(9월 열끗) - 현재 열끗 점수 상황에 따라 쌍피/열끗 선택
//  5. selectWave      : 흔들기 - 손패와 게임 상황을 보고 흔들기 여부 결정
//  ─────────────────────────────────────────────────────────────────────────────

import Foundation

final class ClaudeAIEngine: AIEngine {
    var gameData: GameData!

    func setGameData(_ gameData: GameData) {
        self.gameData = gameData
    }

    // MARK: - 1. 손패 카드 선택 (핵심 전략)
    /// AI가 낼 손패 카드를 선택한다.
    /// 우선순위: ① 폭발 가능(3장 같은 달) ② 매칭 있는 카드 중 EV 최대 ③ 매칭 없는 카드 중 버리기 최적
    func selectHandCard(aiPlayerIndex: Int, tableCards: [Card]) -> Card {
        let player = gameData.players[aiPlayerIndex]
        let hand = player.handCards.filter { $0.month != 100 } // 빈 카드 제외
        guard !hand.isEmpty else { return player.handCards[0] }

        let tableGroups = groupByMonth(tableCards)
        let opponents = opponents(of: aiPlayerIndex)

        // ① 폭탄 가능 여부 체크 (손에 3장 + 테이블 1장)
        for card in hand {
            let sameInHand = hand.filter { $0.month == card.month }
            let sameOnTable = tableGroups[card.month] ?? []
            if sameInHand.count >= 3 && sameOnTable.count == 1 {
                return card // 폭탄 → 바로 선택
            }
        }

        // ② 매칭 있는 카드 평가
        let matchingCandidates = hand.filter { card in
            let onTable = tableGroups[card.month] ?? []
            return !onTable.isEmpty
        }

        if !matchingCandidates.isEmpty {
            // 각 카드의 포획 가치 = 내가 가져올 카드 가치 - 상대방 차단 가치
            let best = matchingCandidates.max { a, b in
                captureValue(handCard: a, tableGroups: tableGroups, player: player, opponents: opponents)
                < captureValue(handCard: b, tableGroups: tableGroups, player: player, opponents: opponents)
            }!
            return best
        }

        // ③ 매칭 없는 카드: 상대에게 유리한 달을 피하고, 가치 낮은 카드 버리기
        let discardBest = hand.min { a, b in
            discardCost(card: a, player: player, opponents: opponents, tableGroups: tableGroups)
            < discardCost(card: b, player: player, opponents: opponents, tableGroups: tableGroups)
        }!
        return discardBest
    }

    // MARK: - 2. 고/스톱 결정
    /// 고를 할지 스톱을 할지 결정한다.
    func selectGoOrStop(aiPlayerIndex: Int, tableCards: [Card] = []) -> Bool {
        let player = gameData.players[aiPlayerIndex]
        let opponents = opponents(of: aiPlayerIndex)
        let currentScore = player.baseScore

        // 현재 점수가 7점 이상이면 거의 항상 스톱 (배율 리스크)
        if currentScore >= 7 { return false }

        // 이미 고를 2번 이상 했으면 배율이 x2 이상 → 리스크 큼
        if player.goCount >= 2 { return false }

        // 남은 손패가 없으면 스톱 (막장)
        if player.handCards.isEmpty { return false }

        // 상대방 점수가 1점 이하면 고를 해도 안전
        let maxOpponentScore = opponents.map { $0.baseScore }.max() ?? 0
        if maxOpponentScore <= 1 && currentScore <= 4 && player.handCards.count >= 3 {
            return true
        }

        // 남은 패 수가 많고, 점수가 낮으면 고 고려
        let remainingCards = player.handCards.count
        if remainingCards >= 4 && currentScore == 3 && maxOpponentScore < 3 {
            return true
        }

        // 고도리/청단/홍단/초단 완성이 1장 남은 경우 고 고려
        if isOneAwayFromBonus(player: player, tableCards: tableCards) && remainingCards >= 3 {
            return true
        }

        return false
    }

    // MARK: - 3. 테이블 카드 2장 중 선택
    /// 매칭 카드가 2장일 때 가져갈 카드를 선택한다.
    func selectCard(aiPlayerIndex: Int, deckOrHandCard: Card, tableCards: [Card]) -> Card {
        guard tableCards.count >= 2 else { return tableCards.last! }

        let player = gameData.players[aiPlayerIndex]
        let opponents = opponents(of: aiPlayerIndex)

        let scores = tableCards.map { card in
            (card: card, value: singleCardValue(card: card, player: player, opponents: opponents))
        }
        return scores.max { $0.value < $1.value }!.card
    }

    // MARK: - 4. 국진 선택 (쌍피 vs 열끗)
    /// 9월 열끗(국진)을 쌍피로 가져갈지, 열끗으로 가져갈지 결정한다.
    /// true = 쌍피, false = 열끗
    func selectGukjin(aiPlayerIndex: Int, card: Card) -> Bool {
        let player = gameData.players[aiPlayerIndex]

        // 열끗이 4개 이상이면 열끗으로 가져가는 게 더 유리 (5개부터 1점)
        if player.yeolCount >= 4 {
            return false // 열끗 선택
        }

        // 피가 8개 이상이면 쌍피 선택 (10개부터 점수)
        if player.piCount >= 8 {
            return true // 쌍피 선택
        }

        // 열끗 점수가 이미 나고 있으면 열끗 유지
        if player.yeolScore > 0 {
            return false
        }

        // 고도리 완성이 가능하면 열끗 선택 (국진은 고도리 카드가 아니지만 열끗 수 증가)
        if player.godoriCount >= 2 && player.yeolCount < 5 {
            return false
        }

        // 기본은 쌍피 (피는 안정적인 점수원)
        return true
    }

    // MARK: - 5. 흔들기 선택
    /// 손에 같은 달 3장이 있을 때 흔들기를 할지 결정한다.
    /// true = 흔들기
    func selectWave(aiPlayerIndex: Int, cards: [Card]) -> Bool {
        let player = gameData.players[aiPlayerIndex]
        let opponents = opponents(of: aiPlayerIndex)

        // 이미 흔들기를 한 적 있으면 다시 하면 배율 x4 → 리스크 큼
        if player.waveCount >= 1 { return false }

        // 상대방 중 점수가 2점 이상인 사람이 있으면 흔들기 고려
        let maxOpponentScore = opponents.map { $0.baseScore }.max() ?? 0

        // 현재 점수가 낮고 상대방 점수도 낮으면 흔들기
        if player.baseScore <= 2 && maxOpponentScore <= 2 {
            return true
        }

        // 내 점수가 이미 3점 이상이면 흔들기 없이 스톱 유도
        if player.baseScore >= 3 { return false }

        return true
    }
}

// MARK: - Private Helpers
private extension ClaudeAIEngine {

    // 상대방 플레이어 배열
    func opponents(of playerIndex: Int) -> [Player] {
        gameData.players.filter { $0.index != playerIndex }
    }

    // 카드 배열을 월별로 그룹핑
    func groupByMonth(_ cards: [Card]) -> [Int: [Card]] {
        Dictionary(grouping: cards, by: { $0.month })
    }

    // MARK: 카드 개별 가치 점수
    /// 카드 한 장의 절대 가치를 반환한다.
    /// 광 > 고도리/단 완성 기여 > 열끗 > 띠 > 쌍피 > 피
    func singleCardValue(card: Card, player: Player, opponents: [Player]) -> Double {
        var value: Double = 0

        switch card.type {
        case .gwang:
            value = 100
            // 이미 광이 2개 있으면 3광 완성 가치 폭발
            if player.gwangCount == 2 { value = 200 }
            if player.gwangCount >= 3 { value = 50 } // 이미 3광이면 추가 가치 낮음

        case .yeol:
            value = 30
            // 고도리 완성 기여
            if card.isGodori {
                value += Double(player.godoriCount) * 40  // 고도리 2개째가 되면 매우 중요
            }
            // 열끗 수에 따라 가치 증가
            value += Double(player.yeolCount) * 5

        case .tti:
            value = 20
            // 청단 완성 기여
            if card.isChungDan {
                value += Double(player.chungdanCount) * 30
            }
            // 홍단 완성 기여
            if card.isHongDan {
                value += Double(player.hongdanCount) * 30
            }
            // 초단 완성 기여
            if card.isChoDan {
                value += Double(player.chodanCount) * 30
            }

        case .pi:
            value = card.isDoublePi ? 14 : 7
            // 피가 9개 이상이면 추가 피의 가치 급상승 (10개부터 1점)
            if player.piCount >= 9 { value += 20 }
        }

        // 상대방이 가져가면 안 되는 카드에 추가 가중치 (차단 가치)
        value += blockingValue(card: card, opponents: opponents)

        return value
    }

    // MARK: 포획 가치 (손패 → 테이블 카드 가져오기)
    /// 손패 카드를 낼 때 테이블에서 가져올 카드들의 총 가치
    func captureValue(handCard: Card, tableGroups: [Int: [Card]], player: Player, opponents: [Player]) -> Double {
        let matchingTableCards = tableGroups[handCard.month] ?? []
        guard !matchingTableCards.isEmpty else { return -999 }

        // 가져올 카드들의 가치 합산
        let tableGain = matchingTableCards.map {
            singleCardValue(card: $0, player: player, opponents: opponents)
        }.max() ?? 0  // 2장 매칭이면 더 좋은 것만 가져옴

        // 손패 카드 자체의 가치 (광/고도리 카드면 더 가치 있음)
        let handCardValue = singleCardValue(card: handCard, player: player, opponents: opponents)

        // 쪽 가능성 보너스: 다음 덱 카드가 같은 달이면 쪽이 될 수 있음
        // (덱 정보는 없으므로 테이블에 같은 달이 있으면 약간의 보너스)
        let kissBonus: Double = matchingTableCards.count == 1 ? 5 : 0

        return tableGain + handCardValue * 0.3 + kissBonus
    }

    // MARK: 버리기 비용 (매칭 없을 때)
    /// 매칭 없이 버릴 카드를 고를 때 비용이 낮은(= 손해가 적은) 카드를 선택
    func discardCost(card: Card, player: Player, opponents: [Player], tableGroups: [Int: [Card]]) -> Double {
        var cost: Double = 0

        // 광/고도리는 절대 버리지 않기
        if card.type == .gwang { cost += 1000 }
        if card.isGodori && player.godoriCount >= 1 { cost += 500 }

        // 완성 1장 남은 단/고도리는 버리지 않기
        if (card.isChungDan && player.chungdanCount == 2) ||
           (card.isHongDan && player.hongdanCount == 2) ||
           (card.isChoDan && player.chodanCount == 2) {
            cost += 300
        }

        // 열끗은 점수에 기여하므로 웬만하면 버리지 않기
        if card.type == .yeol { cost += 50 }

        // 상대방이 갖고 있는 달의 카드는 버리면 위험 (상대에게 유리)
        cost += blockingValue(card: card, opponents: opponents) * 2

        // 띠는 중간 비용
        if card.type == .tti { cost += 20 }

        // 피는 낮은 비용 (버려도 됨)
        if card.type == .pi { cost += card.isDoublePi ? 10 : 5 }

        return cost
    }

    // MARK: 차단 가치 (상대방이 가져가면 손해인 정도)
    /// 이 카드를 상대방이 가져갔을 때의 위협 수준
    func blockingValue(card: Card, opponents: [Player]) -> Double {
        var value: Double = 0

        for opp in opponents {
            switch card.type {
            case .gwang:
                // 상대방이 광 2개 이상 가지면 위협
                if opp.gwangCount >= 2 { value += 80 }

            case .yeol:
                // 상대방 고도리 완성 차단
                if card.isGodori && opp.godoriCount >= 2 { value += 150 }
                if opp.yeolCount >= 4 { value += 30 }

            case .tti:
                // 상대방 단 완성 차단
                if card.isChungDan && opp.chungdanCount >= 2 { value += 100 }
                if card.isHongDan && opp.hongdanCount >= 2 { value += 100 }
                if card.isChoDan && opp.chodanCount >= 2 { value += 100 }

            case .pi:
                // 피는 상대방 차단 가치 낮음
                if opp.piCount >= 9 { value += 15 }
            }
        }
        return value
    }

    // MARK: 보너스 1장 남은 체크
    /// 고도리/청단/홍단/초단 중 1장만 더 있으면 완성되는 상황인지 확인
    func isOneAwayFromBonus(player: Player, tableCards: [Card]) -> Bool {
        // 고도리: 2개 보유 중
        if player.godoriCount == 2 { return true }
        // 청단: 2개 보유 중
        if player.chungdanCount == 2 { return true }
        // 홍단: 2개 보유 중
        if player.hongdanCount == 2 { return true }
        // 초단: 2개 보유 중
        if player.chodanCount == 2 { return true }
        // 3광: 2개 보유 중
        if player.gwangCount == 2 { return true }
        return false
    }
}
