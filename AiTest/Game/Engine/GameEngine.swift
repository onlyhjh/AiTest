//
//  GameEngine.swift
//  AiGoStop iOS
//
//  Created by Joey's Mac mini on 5/6/26.
//

import Foundation


class AIEngine {
    
    func selectAction(state: GameState) -> Action {
        let actions = RuleEngine().generateActions(state: state)
        return actions.randomElement()!
    }
}


final class GameEngine {
    
    private(set) var state: GameState
    private let aiEngine = AIEngine()
    private let ruleEngine = RuleEngine()
    
    var onStateChanged: ((GameState) -> Void)?
    
    init(initialState: GameState) {
        self.state = initialState
    }
    
    func startGame() {
        nextTurn()
    }
    
    private func nextTurn() {
        onStateChanged?(state)
        
        if state.currentPlayerIndex != 0 {
            DispatchQueue.global().async {
                let action = self.aiEngine.selectAction(state: self.state)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.apply(action: action)
                }
            }
        }
    }
    
    func apply(action: Action) {
        state = self.ruleEngine.simulate(state: state, action: action)
        state.currentPlayerIndex = (state.currentPlayerIndex + 1) % 3
        nextTurn()
    }
}


// 게임 상태




class GameState {
    let ruleEngine = RuleEngine()
    
    var players: [Player]
    var table: [Card]
    var deck: [Card]
    
    var currentPlayerIndex: Int
    
    init(players: [Player], table: [Card], deck: [Card], currentPlayerIndex: Int) {
        self.players = players
        self.table = table
        self.deck = deck
        self.currentPlayerIndex = currentPlayerIndex
    }
    
    var currentPlayer: Player {
        players[currentPlayerIndex]
    }
    
    func opponentPlayers() -> [Player] {
        players.enumerated()
            .filter { $0.offset != currentPlayerIndex }
            .map { $0.element }
    }
    
    // 액션 평가
    func evaluateAction(state: GameState, action: Action) -> Double {
        let nextState = RuleEngine().simulate(state: state, action: action)
        
        var score = evaluateState(state: nextState, playerIndex: currentPlayerIndex)
        
        // 특수 전략 가중치
        score += bonusForSpecialRules(state: nextState, playerIndex: currentPlayerIndex)
        
        return score
    }
    
    func bonusForSpecialRules(state: GameState, playerIndex: Int) -> Double {
        
        let me = state.players[playerIndex]
        let opponents = state.players.enumerated().filter { $0.offset != playerIndex }.map { $0.element }
        
        let myScore = calculateScore(player: me)
        
        var bonus: Double = 0.0
        
        // MARK: - 1. 광박 유도
        if me.gwangCount >= 3 {
            for op in opponents where op.gwangCount == 0 {
                bonus += 25.0
            }
        }
        
        // 광 2장 상태 → 3광 노리는 상황
        if me.gwangCount == 2 {
            let remaining = estimateRemainingCards(state: state)
            let remainingGwang = remaining.filter { meta(for: $0).isGwang }.count
            
            if remainingGwang > 0 {
                bonus += 15.0
            }
        }
        
        // MARK: - 2. 피박 유도
        for op in opponents {
            if op.piCount < 5 {
                bonus += 10.0
            }
        }
        
        // 피 9장 → 피 10 직전
        if me.piCount == 9 {
            bonus += 20.0
        }
        
        // MARK: - 3. 멍텅구리 방지
        if myScore.baseScore < 3 && me.goCount > 0 {
            bonus -= 30.0 // 무리한 고 방지
        }
        
        // MARK: - 4. 단 (청단 / 홍단 / 초단)
        // 완성
        if myScore.hongdan { bonus += 30.0 }
        if myScore.chungdan { bonus += 30.0 }
        if myScore.chodan { bonus += 30.0 }
        
        // 임박
        if me.hongDanCount == 2 { bonus += 15.0 }
        if me.chungDanCount == 2 { bonus += 15.0 }
        if me.choDanCount == 2 { bonus += 15.0 }
        
        // MARK: - 5. 고도리
        if me.godoriCount == 3 {
            bonus += 25.0
        } else if me.godoriCount == 2 {
            bonus += 10.0
        }
        
        // MARK: - 6. 상대 견제 (3인 핵심)
        for op in opponents {
            let opScore = calculateScore(player: op)
            
            // 상대 점수 높으면 강하게 견제
            if opScore.baseScore >= 7 {
                bonus -= 20.0
            }
            
            // 상대 광 위험
            if op.gwangCount >= 2 {
                bonus -= 15.0
            }
            
            // 상대 단 임박
            if op.hongDanCount == 2 {
                bonus -= 10.0
            }
        }
        
        // MARK: - 7. 고 전략 보정
        if me.goCount > 0 {
            bonus += Double(me.goCount * 10)
        }
        
        // MARK: - 8. 게임 후반 가중치
        if state.deck.count < 10 {
            bonus *= 1.2
        }
        
        return bonus
    }
    
    // 상태 평가 함수
    func evaluateState(state: GameState, playerIndex: Int) -> Double {
        let player = state.players[playerIndex]
        let opponents = state.players.enumerated().filter { $0.offset != playerIndex }
        
        var score = 0.0
        
        // 기본 점수
        score += Double(player.piCount) * 1.0
        score += Double(player.ttiCount) * 2.5
        score += Double(player.yeolCount) * 3.0
        score += Double(player.gwangCount) * 10.0
        
        // 광 보너스
        if player.gwangCount >= 3 { score += 20 }
        
        // 단 보너스 (간단화)
        if player.ttiCount >= 5 { score += 10 }
        
        // 상대 견제
        for (_, op) in opponents {
            if op.gwangCount >= 2 { score -= 15 }
            if op.piCount < 5 { score += 5 } // 피박 유도
        }
        
        return score
    }
    // 몬테카를로 시뮬레이션
    func monteCarlo(state: GameState, action: Action, iterations: Int = 30) -> Double {
        var total = 0.0
        
        for _ in 0..<iterations {
            var simState = self.ruleEngine.simulate(state: state, action: action)
            
            // 랜덤 플레이
            for _ in 0..<5 {
                let actions = self.ruleEngine.generateActions(state: simState)
                guard let randomAction = actions.randomElement() else { break }
                simState = self.ruleEngine.simulate(state: simState, action: randomAction)
            }
            
            total += evaluateState(state: simState, playerIndex: state.currentPlayerIndex)
        }
        
        return total / Double(iterations)
    }
    
    // 최종 선택
    func selectBestAction(state: GameState) -> Action? {
        let actions = self.ruleEngine.generateActions(state: state)
        guard !actions.isEmpty else { return nil }
        
        let scored = actions.map { action in
            (action, evaluateAction(state: state, action: action))
        }
        
        // 상위 3개만
        let topActions = scored.sorted { $0.1 > $1.1 }.prefix(3)
        
        let final = topActions.map { (action, _) in
            (action, monteCarlo(state: state, action: action))
        }
        
        return final.max { $0.1 < $1.1 }?.0
    }
    
    // 카드 메타 정의 (족보 판별용)
    struct ScoreBreakdown {
        var baseScore: Int = 0
        var gwangScore: Int = 0
        var ttiScore: Int = 0
        var yeolScore: Int = 0
        var piScore: Int = 0
        
        var hongdan = false
        var chungdan = false
        var chodan = false
        var godori = false
    }
    
    enum DanColor {
        case hong, chung, cho
    }

    struct CardMeta {
        let isGwang: Bool
        let isanimal: Bool
        let isDan: Bool
        let isPi: Bool
        let danColor: DanColor?
        let isGodori: Bool
    }

    // 실제 구현 시 48장 전체 매핑 필요
    func meta(for card: Card) -> CardMeta {
        switch (card.month, card.type) {
        case (1, .gwang): return CardMeta(isGwang: true, isanimal: false, isDan: false, isPi: false, danColor: nil, isGodori: false)
            
        case (3, .yeol), (8, .yeol), (11, .yeol):
            return CardMeta(isGwang: false, isanimal: true, isDan: false, isPi: false, danColor: nil, isGodori: true)
            
        case (_, .tti):
            let color: DanColor = {
                if [1,2,3].contains(card.month) { return .hong }
                if [4,5,6].contains(card.month) { return .chung }
                return .cho
            }()
            return CardMeta(isGwang: false, isanimal: false, isDan: true, isPi: false, danColor: color, isGodori: false)
            
        case (_, .pi):
            return CardMeta(isGwang: false, isanimal: false, isDan: false, isPi: true, danColor: nil, isGodori: false)
            
        default:
            return CardMeta(isGwang: false, isanimal: false, isDan: false, isPi: false, danColor: nil, isGodori: false)
        }
    }
    
    // 점수 계산
    func calculateScore(player: Player) -> ScoreBreakdown {
        var result = ScoreBreakdown()
        
        // 광
        if player.gwangCount == 3 { result.gwangScore = 3 }
        if player.gwangCount == 4 { result.gwangScore = 4 }
        if player.gwangCount == 5 { result.gwangScore = 15 }
        
        // 띠
        if player.ttiCount >= 5 { result.ttiScore = player.ttiCount - 4 }
        
        // 열끗
        if player.yeolCount >= 5 { result.yeolScore = player.yeolCount - 4 }
        
        // 피
        if player.piCount >= 10 { result.piScore = player.piCount - 9 }
        
        // 단
        if player.hongDanCount >= 3 { result.hongdan = true; result.ttiScore += 3 }
        if player.chungDanCount >= 3 { result.chungdan = true; result.ttiScore += 3 }
        if player.choDanCount >= 3 { result.chodan = true; result.ttiScore += 3 }
        
        // 고도리
        if player.godoriCount  == 3 {
            result.godori = true
            result.yeolScore += 5
        }
        
        result.baseScore = result.gwangScore + result.ttiScore + result.yeolScore + result.piScore
        
        return result
    }
    
    // 배수 규칙 (핵심)
    func applyMultipliers(score: Int, player: Player, opponents: [Player]) -> Int {
        var final = score
        
        // 고
        if player.goCount > 0 {
            final *= (player.goCount + 1)
        }
        
        // 피박
        for op in opponents {
            if op.piCount < 5 {
                final *= 2
            }
        }
        
        // 광박
        if player.gwangCount >= 3 {
            for op in opponents where op.gwangCount == 0 {
                final *= 2
            }
        }
        
        return final
    }
    
    // 남은 카드 기반 추론
    func estimateRemainingCards(state: GameState) -> [Card] {
        var used: [Card] = []
        
        for p in state.players {
            used += p.handCards
            used += p.capturedCardTypeGroup[CardType.gwang.rawValue] + p.capturedCardTypeGroup[CardType.yeol.rawValue] + p.capturedCardTypeGroup[CardType.tti.rawValue] + p.capturedCardTypeGroup[CardType.pi.rawValue]
        }
        
        used += state.table
        
        let fullDeck = DeckFactory().generateFullDeck()
        
        return fullDeck.filter { !used.contains($0) }
    }
    
    // 특정 카드 나올 확률
    func probability(of month: Int, state: GameState) -> Double {
        let remaining = estimateRemainingCards(state: state)
        
        let count = remaining.filter { $0.month == month }.count
        
        return Double(count) / Double(remaining.count)
    }
    // 가장 위험한 1명 집중 견제
    func mostDangerousPlayer(state: GameState) -> Int {
        var maxScore = -1
        var index = 0
        
        for (i, p) in state.players.enumerated() {
            let score = calculateScore(player: p).baseScore
            if score > maxScore {
                maxScore = score
                index = i
            }
        }
        
        return index
    }
    // 견제 로직
    func defensivePenalty(state: GameState, action: Action) -> Double {
        let dangerIndex = mostDangerousPlayer(state: state)
        
        let nextState = self.ruleEngine.simulate(state: state, action: action)
        let danger = nextState.players[dangerIndex]
        
        let before = calculateScore(player: state.players[dangerIndex]).baseScore
        let after = calculateScore(player: danger).baseScore
        
        if after > before {
            return -20.0 // 점수 올려주면 강하게 패널티
        }
        
        return 0
    }
    
    
    func evaluateActionAdvanced(state: GameState, action: Action) -> Double {
        let nextState = self.ruleEngine.simulate(state: state, action: action)
        
        let myIndex = state.currentPlayerIndex
        let me = nextState.players[myIndex]
        let opponents = nextState.opponentPlayers()
        
        let myScore = calculateScore(player: me)
        let finalScore = applyMultipliers(score: myScore.baseScore, player: me, opponents: opponents)
        
        var value = Double(finalScore)
        
        // 미래 확률
        let prob = probability(of: action.handCard.month, state: state)
        value += prob * 5
        
        // 견제
        value += defensivePenalty(state: state, action: action)
        
        // 단 완성 보너스
        if myScore.hongdan || myScore.chungdan || myScore.chodan {
            value += 20
        }
        
        return value
    }
    
    func shouldGoAdvanced(state: GameState) -> Bool {
        let me = state.currentPlayer
        let score = calculateScore(player: me).baseScore
        
        let opponents = state.opponentPlayers()
        
        // 위험 감지
        let danger = opponents.contains {
            calculateScore(player: $0).baseScore >= score
        }
        
        if score >= 7 && !danger {
            return true
        }
        
        if score >= 10 {
            return true
        }
        
        return false
    }
    
    func selectBestActionFinal(state: GameState) -> Action? {
        let actions = self.ruleEngine.generateActions(state: state)
        guard !actions.isEmpty else { return nil }
        
        let scored = actions.map {
            ($0, evaluateActionAdvanced(state: state, action: $0))
        }
        
        let top = scored.sorted { $0.1 > $1.1 }.prefix(4)
        
        let final = top.map { (action, _) in
            (action, monteCarlo(state: state, action: action, iterations: 50))
        }
        
        return final.max { $0.1 < $1.1 }?.0
    }
}
