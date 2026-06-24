//
//  GameScene.swift
//  AiGoStop Shared
//
//  Created by Joey's Mac mini on 4/29/26.
//

import SpriteKit
import SwiftUI
import Combine


class GameScene: SKScene, ObservableObject {
    
    @Binding var isPresentedCharacterSettingPopup: Bool
    var gameData: GameData
    var popupData: PopupData
    var isUserTouchCardEnabled = false
    
    private let emptyCardMonth: Int = 100 // 폭탄 후 빈 카드
    // zPosition > tableCard = 10 ~ 140  deckCard = 1000~카드쌓기, 움직이는카드 10000 > 정지 후 0
    private let deckZPosition: CGFloat = 1000
    private var tableCardGroups: [[Card]] = []
    private var deckCards: [Card] = []
    
    private var cardSize: CGSize = .zero
    private var playerImageSize: CGSize = .zero
    private var cardGap: CGFloat = 0
    private var cardLayeredGap: CGFloat = 0
    
    init(size: CGSize, gameData: GameData, popupData: PopupData, isPresentedCharacterSettingPopup: Binding<Bool>) {
        _isPresentedCharacterSettingPopup = isPresentedCharacterSettingPopup
        self.gameData = gameData
        self.popupData = popupData
        super.init(size: size)
        
        self.backgroundColor = .tableBG ?? .green
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        DispatchQueue.main.async {
            self.cardSize = CGSize(width: self.size.height / 14, height: self.size.height / 14 * 1.5)
            self.playerImageSize = CGSize(width: self.cardSize.height, height: self.cardSize.height)
            self.cardGap = self.cardSize.width / 10
            self.cardLayeredGap = self.cardSize.width / 5
        }
    }
    
    // 매 프레임마다 SwiftUI로부터 온 데이터를 감지하고 적용
    override func update(_ currentTime: TimeInterval) {
        switch self.gameData.gameStatus {
        case .start:
            self.startGame()
        case .updatePlayers:
            self.updatePlayers()
        default:
            break
        }
        self.gameData.gameStatus = .wait
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let loc = touches.first!.location(in: self)
        
        for n in nodes(at: loc) {
            if let cardNode = n as? CardNode, self.isUserTouchCardEnabled {
                if self.gameData.currentPlayerIndex == 0, let handCard = self.gameData.players[self.gameData.currentPlayerIndex].handCards.first(where: { $0.id == cardNode.card.id }) {
                    self.playWithSelectedHandCard(handCard: handCard)
                    self.isUserTouchCardEnabled = false
                }
            }
            else if let playerIconNode = n as? PlayerIconNode {
                if playerIconNode.name == PlayerIconNode.prefixName + "0" {
                    self.isPresentedCharacterSettingPopup = true
                }
            }
        }
    }
}


extension GameScene {
    private func startGame() {
        self.removeAllChildren()
        self.setBackgroundNodes()
        self.setDeckCards()
        self.tableCardGroups = [[], [], [], [], [], [], [], [], [], [], [], [], [], []]
        
        self.gameData.winnerIndex = UserDefaults.standard.lastWinnerIndex ?? 1
        self.gameData.currentPlayerIndex = self.gameData.winnerIndex
        self.gameData.goHistory = []
        
        for i in 0...2 {
            self.clearPlayerGameStatus(i)
            self.setPlayerNodes(player: self.gameData.players[i])
        }
        
        Task {
            // Test : player captured영역 확인을 위해 전체 카드 주기 */
//            for _ in 0..<self.deckCards.count - 1 {
//                await self.moveDeckCardToPlayerCaptured(playerIndex: 0)
//            }
//            self.showWinnerPopup(winnerIndex: 0, wasNagari: true)
//            return
            
            // Test 특정카드 사용자에게
//            for (i, card) in self.deckCards.enumerated().reversed() {
//                if card.type != .gwang && card.month == 1  {
//                    let element = self.deckCards.remove(at: i)
//                    self.deckCards.insert(element, at: self.deckCards.count - 4)
//                }
//            }
//            for (i, card) in self.deckCards.enumerated().reversed() {
//                if card.type == .yeol && card.month > 5 && card.piNum == 0 {
//                    let element = self.deckCards.remove(at: i)
//                    self.deckCards.insert(element, at: 26)
//                    break
//                }
//            }
            
            
            // 테이블에 첫번째 3장 나눠주기
            await self.moveDeckCardToTable(count: 3)
            
            // 각 플레이어에게 첫번째 4장 나눠주기
            for i in 0...2 {
                let nextPlayerIndex = (self.gameData.winnerIndex + 1 + i) % 3
                await self.moveDeckCardToPlayerHand(playerIndex: nextPlayerIndex, count: 4)
            }
            
            // 테이블에 두번째 3장 나눠주기
            await self.moveDeckCardToTable(count: 3)
            
            // 각 플레이어에게 두번째 3장 나눠주기
            for i in 0...2 {
                let nextPlayerIndex = (self.gameData.winnerIndex + 1 + i) % 3
                await self.moveDeckCardToPlayerHand(playerIndex: nextPlayerIndex, count: 3)
                self.sortPlayerHandCards(playerIndex: nextPlayerIndex)
            }

            // 보너스 카드 지급 후 덱카드 테이블에 지급 (재귀반복)
            await self.moveBonusTableCardToPlayerCapturedAndMoveDeckCardToTableAgain(playerIndex: self.gameData.winnerIndex)
            // 총통 검사 1 (10점)
            if !self.isChongTong() {
                // 테스트 한장씩 뺏어오기 테스트용
    //            for i in 0...8 {
    //                await self.moveDeckCardToPlayerCaptured(playerIndex: i % 3)
    //            }
                self.doPlay()
            }
        }
    }
    
    private func doPlay() {
        print("\(#function) playerIndex:\(self.gameData.currentPlayerIndex)")
        //  이전 플레이어도 정리해 줘야 함
        for i in 0...2 {
            self.sortPlayerHandCards(playerIndex: i)
            self.setStrokeWithBlinkToPlayerNode(playerIndex: i)
        }
        
        Task {
            do { try await Task.sleep(for: .seconds(1.0))
            } catch { print("error: \(error)")}
            
            switch self.gameData.currentPlayerIndex {
            case 0:
                self.isUserTouchCardEnabled = true
                // 보너스카드 뒤 뻑카드 처리 테스트용
                if self.deckCards.count > 2 {
                    print("???? next Deck Cards: \(self.deckCards[self.deckCards.count - 1].month) > \(self.deckCards[self.deckCards.count - 2].month)")
                }
            case 1, 2:
                self.aiTurn()
            default: break
            }
        }
    }
    
    func clearPlayerGameStatus(_ i: Int) {
        self.gameData.players[i].capturedCardTypeGroups = [[],[],[],[]]
        self.gameData.players[i].handCards = []
        self.gameData.players[i].goCount = 0
        self.gameData.players[i].lastGoScore = 0
        self.gameData.players[i].fuckCardMonths = []
        self.gameData.players[i].waveCount = 0
        
        // winner
        self.gameData.players[i].isChongTongWin = false
        self.gameData.players[i].is3FuckWin = false
        self.gameData.players[i].isGokbak = false
        self.gameData.players[i].wasNagari = false
        // looser
        self.gameData.players[i].isPiBak = false
        self.gameData.players[i].isGwangBak = false
        self.gameData.players[i].isGoBak = false // 독박과 동일
        self.gameData.players[i].finalScore = 0
    }
    
    private func checkScoreAndDoNextPlay() {
        let player = self.gameData.players[self.gameData.currentPlayerIndex]
        
        // 3점 이상이고 이전에 고한 점수 보다 높아야 함
        if player.baseScore > 2 && player.baseScore > player.lastGoScore {
            // 막장이었으면 고/스톱 선택없이 바로 결과 출력
            if player.handCards.isEmpty {
                UserDefaults.standard.lastWinnerIndex = player.index
                self.showWinnerPopup(winnerIndex: self.gameData.currentPlayerIndex, wasNagari: UserDefaults.standard.wasNagari ?? false)
                UserDefaults.standard.wasNagari = false
            }
            // User
            else if player.index == 0 {
                PopupManager.shared.showPopup(popupData: self.popupData, type: .selectGoOrStop, cards: [], players: [player]) { select in
                    self.afterSelectGoOrStop(isGo: select == 0, player: player)
                }
            }
            // Ai
            else {
                let isGo = self.selectGoOrStopWithAi()
                self.afterSelectGoOrStop(isGo: isGo, player: player)
            }
        }
        // 전체 사용자 막장이었으면 나가리>> 다음판 두배
        else if self.gameData.players[0].handCards.isEmpty && self.gameData.players[1].handCards.isEmpty && self.gameData.players[2].handCards.isEmpty {
            PopupManager.shared.showPopup(popupData: self.popupData, type: .nagari, cards: [], players: []) { _ in
                UserDefaults.standard.wasNagari = true
                self.startGame()
            }
        }
        else {
            self.gameData.currentPlayerIndex = (self.gameData.currentPlayerIndex + 1) % 3
            self.doPlay()
        }
    }
    
    private func aiTurn() {
        guard let card = self.gameData.players[self.gameData.currentPlayerIndex].handCards.first else { return }
        self.playWithSelectedHandCard(handCard: card)
    }
    
    private func selectGoOrStopWithAi() -> Bool {
        return false
    }
    
    private func selectCardWithAi(deckOrHandCard: Card, tableCards: [Card]) -> Card {
        return tableCards.last!
    }
    
    private func selectGukjinWithAi(card: Card) -> Bool {
        return true
    }
    
    private func selectWaveWithAi(cards: [Card]) -> Bool {
        return true
    }
    
    // 총통 검사 2 (10점)
    private func isChongTong() -> Bool  {
        for (i, player) in self.gameData.players.enumerated() {
            for handCard in player.handCards {
                let sameMonthCards = player.handCards.filter({$0.month == handCard.month})
                
                if player.handCards.count == 7 && sameMonthCards.count == 4 {
                    UserDefaults.standard.lastWinnerIndex = self.gameData.currentPlayerIndex
                    UserDefaults.standard.wasNagari = false
                    self.showChongTongWinPopup(winnerIndex: i, cards: sameMonthCards) {
                        self.collectMoney(winnerIndex: player.index, loserIndex: (player.index + 1) % 3, money: 10){
                            self.collectMoney(winnerIndex: player.index, loserIndex: (player.index + 2) % 3, money: 10){
                                self.removeAllChildren()
                            }
                        }
                    }
                    return true
                }
            }
        }
        return false
    }
    
    private func playWithSelectedHandCard(handCard: Card) {
        let player = self.gameData.players[self.gameData.currentPlayerIndex]
        let sameMonthPlayerHandCards = player.handCards.filter({$0.month == handCard.month}) //폭탄, 흔들기
        
        Task {
            // 선택카드가 bonus 카드인경우
            if handCard.month == 0 {
                PopupManager.shared.showPopup(popupData: self.popupData, type: .handBonus, cards: [handCard], players: [player], completion: {_ in
                    Task {
                        await self.moveBonusPlayerHandBonusCardToPlayerCaptured(playerIndex: player.index, handCard: handCard)
                        self.sortPlayerHandCards(playerIndex: player.index)
                        // 총통 검사 2 (10점)
                        if !self.isChongTong() {
                            self.doPlay() // 다시
                        }
                    }
                })
                return
            }
            
            // 다음 덱카드를 미리 확인하여 연속된 보너스 카드 갯수 가져오기
            var nextBonusDeckCardCount = 0
            var nextDeckCardExceptBonus: Card = self.deckCards.last!
            for card in (self.deckCards).reversed() {
                if card.month == 0 {
                    nextBonusDeckCardCount += 1
                }
                else {
                    nextDeckCardExceptBonus = card
                    break
                }
            }
            
            // 매칭카드가 갯수에 따른 처리
            let matchingTableCards = self.getMatchingTableCards(cardMonth: handCard.month)
            print("\(#function) handCard: \(handCard.month), \(handCard.type), nextDeckCardExceptBonus: \(nextDeckCardExceptBonus.month), \(nextDeckCardExceptBonus.type)")
            for card in matchingTableCards {
                print("... matchingTableCard: \(card.month), \(card.type)")
            }

            switch matchingTableCards.count {
            case 0: // 매칭카드 없는 경우
                // 흔들기
                if sameMonthPlayerHandCards.count == 3 {
                    // user
                    if self.gameData.currentPlayerIndex == 0 {
                        PopupManager.shared.showPopup(popupData: self.popupData, type: .selectWave, cards: sameMonthPlayerHandCards, players: [player]) { select in
                            self.afterWave(isWave: select == 0, player: player, handCard: handCard, sameMonthPlayerHandCards: sameMonthPlayerHandCards, nextDeckCardExceptBonus: nextDeckCardExceptBonus)
                        }
                    }
                    // ai
                    else {
                        let isWave = self.selectWaveWithAi(cards: sameMonthPlayerHandCards)
                        self.afterWave(isWave: isWave, player: player, handCard: handCard, sameMonthPlayerHandCards: sameMonthPlayerHandCards, nextDeckCardExceptBonus: nextDeckCardExceptBonus)
                    }
                }
                else {
                    await self.playWithNoMatchingCard(playerIndex: player.index, handCard: handCard, nextDeckCardExceptBonus: nextDeckCardExceptBonus)
                }
            case 1: // 매칭카드 1개
                // 폭탄
                if sameMonthPlayerHandCards.count == 3 {
                    await self.movePlayerHandCardsToMatchingTableCards(handCards: sameMonthPlayerHandCards, tableCards: matchingTableCards)
                    PopupManager.shared.showPopup(popupData: self.popupData, type: .bomb, cards: sameMonthPlayerHandCards, players: [player], completion: {_ in
                        Task{
                            await self.moveMatchingCardsToPlayerCaptured(playerIndex: player.index, deckOrHandCards: sameMonthPlayerHandCards, tableCards: matchingTableCards) {
                                Task{
                                    await self.collectPiCardsFromOthers(toPlayerIndex: player.index, piCount: 2) {
                                        Task{
                                            await self.moveBonusDeckCardsToPlayerCapturedIfNeeded(playerIndex: player.index){
                                                Task {
                                                    await self.flipDeckCardAfterBonusCard()
                                                    await self.setEmptyPlayerHandCards(playerIndex: player.index, count: 2)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    })
                }
                //덱카드 뻑 처리(첫뻑, 첫뻑후 연속뻑, 연속뻑3회, 막장 제외)
                else if nextDeckCardExceptBonus.month == handCard.month && player.handCards.count > 1 {
                    await self.movePlayerHandCardsToTable(playerIndex: player.index, handCards: [handCard])
                    let tableCardGroupIndex = self.getTableCardGroupIndex(cardMonth: handCard.month) ?? self.getEmptyTableCardGroupIndex(cardMonth: handCard.month)
                    let fuckCards = [handCard, nextDeckCardExceptBonus] + matchingTableCards
                    await self.moveBonusDeckCardsToTable(tableCardGroupIndex: tableCardGroupIndex)
                    // await self.flipDeckCardAfterBonusCard() 가져가면 안됨
                    await self.moveDeckCardToTable()
                    
                    // 시작 첫뻑
                    if player.handCards.count > 5 {
                        PopupManager.shared.showPopup(popupData: self.popupData, type: .firstFuck, cards: fuckCards, players: [player]) {_ in
                            self.collectMoney(winnerIndex: player.index, loserIndex: (player.index + 1) % 3 ,money: 5) {
                                self.collectMoney(winnerIndex: player.index, loserIndex: (player.index + 2) % 3 ,money: 5) {
                                    self.checkScoreAndDoNextPlay()
                                }
                            }
                        }
                    }
                    //  2연뻑
                    else if player.handCards.count == 5 && player.fuckCardMonths.count == 1 {
                        PopupManager.shared.showPopup(popupData: self.popupData, type: .secondFuck, cards: fuckCards, players: [player]) {_ in
                            self.collectMoney(winnerIndex: player.index, loserIndex: (player.index + 1) % 3, money: 10) {
                                self.collectMoney(winnerIndex: player.index, loserIndex: (player.index + 2) % 3, money: 10) {
                                    self.checkScoreAndDoNextPlay()
                                }
                            }
                        }
                    }
                    // 3번뻑 > 게임끝
                    else if player.fuckCardMonths.count == 2 {
                        PopupManager.shared.showPopup(popupData: self.popupData, type: .thirdFuckWin, cards: fuckCards, players: [player]) {_ in
                            // 독박체크
                            let goBakPlayerIndex = self.getGoBakPlayerIndex(winnerIndex: player.index)
                            if let goBakPlayerIndex {
                                self.gameData.players[goBakPlayerIndex].isGokbak = true
                                self.collectMoney(winnerIndex: player.index, loserIndex: goBakPlayerIndex, money: 6) {
                                    self.gameData.winnerIndex = player.index
                                    UserDefaults.standard.lastWinnerIndex = player.index
                                    UserDefaults.standard.wasNagari = false
                                    self.startGame()
                                }
                            }
                            else {
                                self.collectMoney(winnerIndex: player.index, loserIndex: (player.index + 1) % 3 ,money: 3) {
                                    self.collectMoney(winnerIndex: player.index, loserIndex: (player.index + 2) % 3 ,money: 3) {
                                        self.gameData.winnerIndex = player.index
                                        UserDefaults.standard.lastWinnerIndex = player.index
                                        UserDefaults.standard.wasNagari = false
                                        self.startGame()
                                    }
                                }
                            }
                        }
                        return
                    }
                    else {
                        PopupManager.shared.showPopup(popupData: self.popupData, type: .fuck, cards: fuckCards, players: [player], completion: {_ in
                            self.checkScoreAndDoNextPlay()
                        })
                    }
                    
                    self.gameData.players[self.gameData.currentPlayerIndex].fuckCardMonths.append(handCard.month)
                }
                else {
                    await self.movePlayerHandCardsToMatchingTableCards(handCards: [handCard], tableCards: matchingTableCards)
                    await self.moveMatchingCardsToPlayerCaptured(playerIndex: player.index, deckOrHandCards: [handCard], tableCards: matchingTableCards) {
                        Task {
                            await self.moveBonusDeckCardsToPlayerCapturedIfNeeded(playerIndex: player.index) {
                                Task {
                                    await self.flipDeckCardAfterBonusCard()
                                }
                            }
                        }
                    }
                }
            case 2: // 매칭카드 2개
                // 따닥
                if nextDeckCardExceptBonus.month == handCard.month {
                    await self.movePlayerHandCardsToMatchingTableCards(handCards: [handCard], tableCards: matchingTableCards)
                    
                    PopupManager.shared.showPopup(popupData: self.popupData, type: player.handCards.count > 5 ? .firstTadak : .tadak, cards: [handCard, nextDeckCardExceptBonus] + matchingTableCards, players: [player], completion: { _ in
                        Task {
                            await self.moveMatchingCardsToPlayerCaptured(playerIndex: player.index, deckOrHandCards: [handCard], tableCards: [matchingTableCards[0]]) {
                                Task {
                                    await self.moveBonusDeckCardsToPlayerCapturedIfNeeded(playerIndex: player.index){
                                        Task {
                                            await self.flipDeckCardAfterBonusCard()
                                            await self.collectPiCardsFromOthers(toPlayerIndex: player.index, piCount: 1, completion: {
                                                // 첫따닥 5만냥
                                                if player.handCards.count > 5 {
                                                    self.collectMoney(winnerIndex: player.index, loserIndex: (player.index + 1) % 3,money: 5){
                                                        self.collectMoney(winnerIndex: player.index, loserIndex: (player.index + 2) % 3,money: 5){}
                                                    }
                                                }
                                            })
                                        }
                                    }
                                }
                            }
                        }
                    })
                }
                // 매칭카드가 같은 종류이면 아무거나 가져가기
                else if matchingTableCards[0].type == matchingTableCards[1].type && matchingTableCards[0].isDoublePi == matchingTableCards[1].isDoublePi {
                    await self.movePlayerHandCardsToMatchingTableCards(handCards: [handCard], tableCards: matchingTableCards)
                    await self.moveMatchingCardsToPlayerCaptured(playerIndex: player.index, deckOrHandCards: [handCard], tableCards: [matchingTableCards[0]]){
                        Task {
                            await self.moveBonusDeckCardsToPlayerCapturedIfNeeded(playerIndex: player.index){
                                Task {
                                    await self.flipDeckCardAfterBonusCard()
                                }
                            }
                        }
                    }
                }
                // 카드선택
                else {
                    await self.movePlayerHandCardsToMatchingTableCards(handCards: [handCard], tableCards: matchingTableCards)
                    // user
                    if self.gameData.currentPlayerIndex == 0 {
                        PopupManager.shared.showPopup(popupData: self.popupData, type: .selectCard, cards: [handCard] + matchingTableCards, players: [player]) { select in
                            self.afterSelectCard(player: player, deckOrHandCard: handCard, tableCard: self.popupData.cards[1])
                        }
                    }
                    // ai
                    else {
                        let tableCard = self.selectCardWithAi(deckOrHandCard: handCard, tableCards: matchingTableCards)
                        self.afterSelectCard(player: player, deckOrHandCard: handCard, tableCard: tableCard)
                    }
                }
            default:  // 매칭카드 3개 이상 (뻑하고 보너스가 함께 있을수 있음)
                // 3장 가져오기 ~ 한장씩 뺏기
                let isPlayerFuckCard = player.fuckCardMonths.first(where: { $0 == handCard.month }) != nil
                await self.movePlayerHandCardsToMatchingTableCards(handCards: [handCard], tableCards: matchingTableCards)
                PopupManager.shared.showPopup(popupData: self.popupData, type: isPlayerFuckCard ? .threeTableCardsWithPlayerFuck : .threeTableCards, cards: [handCard] + matchingTableCards, players: [player], completion: { _ in
                    Task {
                        await self.moveMatchingCardsToPlayerCaptured(playerIndex: player.index, deckOrHandCards: [handCard], tableCards: matchingTableCards) {
                            Task {
                                await self.collectPiCardsFromOthers(toPlayerIndex: player.index, piCount: isPlayerFuckCard ? 2 : 1) {
                                    Task{
                                        await self.moveBonusDeckCardsToPlayerCapturedIfNeeded(playerIndex: player.index){
                                            Task {
                                                await self.flipDeckCardAfterBonusCard()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                })
            }
        }
    }
    
    // Winner가 고 한 경우가 이닌 마지막 사용자 index반환
    private func getGoBakPlayerIndex(winnerIndex: Int) -> Int? {
        return gameData.goHistory.last{ $0 != winnerIndex }
    }
    
    // 덱카드 뒤집기 (보너스카드 이후)
    private func flipDeckCardAfterBonusCard(kissHandCard: Card? = nil) async {
        let player = self.gameData.players[self.gameData.currentPlayerIndex]
        guard let deckCard = self.deckCards.last else { return }
        
        Task {
            // 매칭카드가 갯수에 따른 처리
            let matchingTableCards = self.getMatchingTableCards(cardMonth: deckCard.month)
            print("\(#function) deckCard: \(deckCard.month), \(deckCard.type)")
            for card in matchingTableCards {
                print("... matchingTableCard: \(card.month), \(card.type)")
            }
            
            switch matchingTableCards.count {
            case 0: // 매칭카드 없는 경우
                await self.moveDeckCardToTable()
                self.checkScoreAndDoNextPlay()
            case 1: // 매칭카드 1개 (
                await self.moveDeckCardToMatchingTableCards(deckCard: deckCard, tableCards: matchingTableCards)
                // 쪽인경우
                if let kissHandCard {
                    PopupManager.shared.showPopup(popupData: popupData, type: .kiss, cards: [kissHandCard, deckCard], players: [player]) { select in
                        Task {
                            await self.moveMatchingCardsToPlayerCaptured(playerIndex: player.index, deckOrHandCards: [deckCard], tableCards: matchingTableCards){
                                // 쓸인경우
                                if !player.handCards.isEmpty && self.isEmptyTable() {
                                    PopupManager.shared.showPopup(popupData: self.popupData, type: .emptyTable, cards: [], players: [player]) { select in
                                        Task {
                                            await self.collectPiCardsFromOthers(toPlayerIndex: player.index, piCount: 2) {
                                                self.checkScoreAndDoNextPlay()
                                            }
                                        }
                                    }
                                }
                                else {
                                    Task {
                                        await self.collectPiCardsFromOthers(toPlayerIndex: player.index, piCount: 1) {
                                            self.checkScoreAndDoNextPlay()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                else {
                    await self.moveMatchingCardsToPlayerCaptured(playerIndex: player.index, deckOrHandCards: [deckCard], tableCards: matchingTableCards){
                        
                        // 쓸인경우
                        if !player.handCards.isEmpty && self.isEmptyTable() {
                            PopupManager.shared.showPopup(popupData: self.popupData, type: .emptyTable, cards: [], players: [player]) { select in
                                Task {
                                    await self.collectPiCardsFromOthers(toPlayerIndex: player.index, piCount: 1) {
                                        self.checkScoreAndDoNextPlay()
                                    }
                                }
                            }
                        }
                        else {
                            self.checkScoreAndDoNextPlay()
                        }
                    }
                    
                }
            case 2: // 매칭카드 2개
                // 매칭카드가 같은 종류이면 아무거나 가져가기
                if matchingTableCards[0].type == matchingTableCards[1].type && matchingTableCards[0].isDoublePi == matchingTableCards[1].isDoublePi {
                    await self.moveDeckCardToMatchingTableCards(deckCard: deckCard, tableCards: matchingTableCards)
                    await self.moveMatchingCardsToPlayerCaptured(playerIndex: player.index, deckOrHandCards: [deckCard], tableCards: [matchingTableCards[0]]){
                        self.checkScoreAndDoNextPlay()
                    }
                }
                // 카드 선택
                else {
                    await self.moveDeckCardToMatchingTableCards(deckCard: deckCard, tableCards: matchingTableCards)
                    if self.gameData.currentPlayerIndex == 0 {
                        PopupManager.shared.showPopup(popupData: self.popupData, type: .selectCard, cards: [deckCard] + matchingTableCards, players: [player], completion: { select in
                            Task {
                                await self.moveMatchingCardsToPlayerCaptured(playerIndex: player.index, deckOrHandCards: [deckCard], tableCards: [self.popupData.cards[1]]){
                                    self.checkScoreAndDoNextPlay()
                                }
                            }
                        })
                    }
                    else {
                        let selectCard = self.selectCardWithAi(deckOrHandCard: deckCard, tableCards: matchingTableCards)
                        Task {
                            await self.moveMatchingCardsToPlayerCaptured(playerIndex: player.index, deckOrHandCards: [deckCard], tableCards: [selectCard]){
                                self.checkScoreAndDoNextPlay()
                            }
                        }
                    }
                }
            default:  // 매칭카드 3개 이상 (뻑하고 보너스가 함께 있을수 있음)
                let isPlayerFuckCard = player.fuckCardMonths.first(where: { $0 == deckCard.month }) != nil
                await self.moveDeckCardToMatchingTableCards(deckCard: deckCard, tableCards: matchingTableCards)
                PopupManager.shared.showPopup(popupData: self.popupData, type: isPlayerFuckCard ? .threeTableCardsWithPlayerFuck : .threeTableCards, cards: [deckCard] + matchingTableCards, players: [player], completion: { _ in
                    Task {
                        await self.moveMatchingCardsToPlayerCaptured(playerIndex: player.index, deckOrHandCards: [deckCard], tableCards: matchingTableCards) {
                            // 쓸인경우
                            if !player.handCards.isEmpty && self.isEmptyTable() {
                                PopupManager.shared.showPopup(popupData: self.popupData, type: .emptyTable, cards: [], players: [player]) { select in
                                    Task {
                                        await self.collectPiCardsFromOthers(toPlayerIndex: player.index, piCount: isPlayerFuckCard ? 3 : 2) {
                                            self.checkScoreAndDoNextPlay()
                                        }
                                    }
                                }
                            }
                            else {
                                Task {
                                    await self.collectPiCardsFromOthers(toPlayerIndex: player.index, piCount: isPlayerFuckCard ? 2 : 1) {
                                        self.checkScoreAndDoNextPlay()
                                    }
                                }
                            }
                        }
                    }
                })
            }
        }
    }
    
    private func afterSelectGoOrStop(isGo: Bool, player: Player) {
        if isGo {
            PopupManager.shared.showPopup(popupData: self.popupData, type: .go, cards: [], players: [player], message: "\(player.goCount + 1) 고!") { _ in
                self.gameData.currentPlayerIndex = (self.gameData.currentPlayerIndex + 1) % 3
                self.doPlay()
            }
            self.gameData.players[player.index].goCount += 1
            self.gameData.players[player.index].lastGoScore = player.baseScore
            self.gameData.goHistory.append(player.index)
        }
        else {
            PopupManager.shared.showPopup(popupData: self.popupData, type: .stop, cards: [], players: [player]) { _ in
                UserDefaults.standard.lastWinnerIndex = player.index
                self.showWinnerPopup(winnerIndex: self.gameData.currentPlayerIndex, wasNagari: UserDefaults.standard.wasNagari ?? false)
                UserDefaults.standard.wasNagari = false
            }
        }
    }
    
    private func afterWave(isWave: Bool, player: Player, handCard: Card, sameMonthPlayerHandCards: [Card], nextDeckCardExceptBonus: Card) {
        //  흔들기 선택
        if isWave {
            self.gameData.players[player.index].waveCount += 1
            //  흔들기 확인 팝업 다시 보이기
            PopupManager.shared.showPopup(popupData: self.popupData, type: .wave, cards: sameMonthPlayerHandCards, players: [player]) { select in
                Task{
                    await self.playWithNoMatchingCard(playerIndex: player.index, handCard: handCard, nextDeckCardExceptBonus: nextDeckCardExceptBonus)
                }
            }
        }
        else {
            Task{
                await self.playWithNoMatchingCard(playerIndex: player.index, handCard: handCard, nextDeckCardExceptBonus: nextDeckCardExceptBonus)
            }
        }
    }
    
    private func afterSelectCard(player: Player, deckOrHandCard: Card, tableCard: Card) {
        Task {
            await self.moveMatchingCardsToPlayerCaptured(playerIndex: player.index, deckOrHandCards: [deckOrHandCard], tableCards: [tableCard]) {
                Task {
                    await self.moveBonusDeckCardsToPlayerCapturedIfNeeded(playerIndex: player.index){
                        Task {
                            await self.flipDeckCardAfterBonusCard()
                        }
                    }
                }
            }
        }
    }
    
    func afterSelectGukjin(isDoublePi: Bool, playerIndex: Int, card: Card, tableCardGroupIndex: Int, completion: () -> Void) {
        //  쌍피 선택
        if isDoublePi {
            self.moveCardToPlayerCaptured(playerIndex: playerIndex, card: card, forcedType: .pi)
        }
        // 열끗 선택
        else {
            self.moveCardToPlayerCaptured(playerIndex: playerIndex, card: card)
        }
        self.sortTableCardGroup(tableCardGroupIndex: tableCardGroupIndex)
        completion()
    }
    
    private func setEmptyPlayerHandCards(playerIndex: Int, count: Int) async {
        let scaleRate = playerIndex == 0 ? CardNodeScale.normal.rawValue : CardNodeScale.small.rawValue
        let cardSize = CGSize(width: self.cardSize.width * scaleRate, height: self.cardSize.height * scaleRate)

        for i in 0..<count {
            let card = Card(month: self.emptyCardMonth, type: .gwang, imageName: Card.emptyImageName)
            self.gameData.players[self.gameData.currentPlayerIndex].handCards.append(card)
            let node = CardNode(name: card.id.uuidString, card: card, cardSize: cardSize, isFront: true)
            node.position = self.getPlayerHandCardPosition(playerIndex: playerIndex, cardIndex: self.gameData.players[playerIndex].handCards.count)
            node.zPosition = self.deckZPosition + CGFloat(i)
            self.addChild(node)
        }
    }
    
    private func playWithNoMatchingCard(playerIndex: Int, handCard: Card, nextDeckCardExceptBonus: Card) async {
        let player = self.gameData.players[self.gameData.currentPlayerIndex]
        Task {
            // 폭탄빈카드는 그냥 제거하고 덱카드 뒤집기
            if handCard.month == self.emptyCardMonth {
                self.removePlayerHandCards(playerIndex: player.index, handCards: [handCard])
            }
            // 먼저 선택카드를 테이블에 내려놓기
            else {
                await self.movePlayerHandCardsToTable(playerIndex: player.index, handCards: [handCard])
            }
            
            // 쪽이면 > 쪽카드 받아가기 (막장 제외)
            if nextDeckCardExceptBonus.month == handCard.month && !player.handCards.isEmpty {
                await self.moveBonusDeckCardsToPlayerCapturedIfNeeded(playerIndex: playerIndex) {
                    Task {
                        await self.flipDeckCardAfterBonusCard(kissHandCard: handCard)
                    }
                }
            }
            else {
                // 덱 보너스 카드 처리 후 카드 뒤집기
                await self.moveBonusDeckCardsToPlayerCapturedIfNeeded(playerIndex: playerIndex) {
                    Task {
                        await self.flipDeckCardAfterBonusCard()
                    }
                }
            }
        }
    }
    
    private func collectPiCardsFromOthers(toPlayerIndex: Int, piCount: Int, completion: @escaping () -> Void) async {
        print("\(#function) 가져올 피 \(piCount)장")
        Task{
            await self.moveOtherPlayersCapturedCardsToPlayerCaptured(toPlayerIndex: toPlayerIndex, piCount: piCount)
            completion()
        }
    }
    
    private func collectMoney(winnerIndex: Int, loserIndex: Int, money: Int, completion: @escaping () -> Void) {
        guard let winnerIconNode = self.childNode(withName: PlayerIconNode.prefixName + "\(winnerIndex)") else { return }
        guard let loserNode = self.childNode(withName: PlayerIconNode.prefixName + "\(loserIndex)") else { return }
        
        self.gameData.players[loserIndex].money -= money
        self.gameData.players[winnerIndex].money += money
        
        let moneyNode = MoneyNode(position: loserNode.position)
        self.addChild(moneyNode)
        moneyNode.moveToWinner(movePosition: winnerIconNode.position, duration: self.gameData.cardDuration) {
            completion()
        }
    }
    
    private func showWinnerPopup(winnerIndex: Int, wasNagari: Bool) {
        self.gameData.winnerIndex = winnerIndex
        
        var winner = self.gameData.players[winnerIndex]
        var player1 = self.gameData.players[(winnerIndex + 1) % 3]
        var player2 = self.gameData.players[(winnerIndex + 2) % 3]
        
        winner.wasNagari = wasNagari
        
        if winner.gwangScore > 0 {
            player1.isGwangBak = player1.gwangCount == 0
            player2.isGwangBak = player2.gwangCount == 0
        }
        
        if winner.piScore > 0 {
            player1.isPiBak = player1.piCount > 0 && player1.piCount < 6
            player2.isPiBak = player2.piCount > 0 && player2.piCount < 6
        }
        
        // 독박 확인
        player1.finalScore = winner.subtotalScore * (player1.isGwangBak ? 2 :1) * (player1.isPiBak ? 2 : 1) * (player1.isGoBak ? 2 : 1)
        player2.finalScore = winner.subtotalScore * (player2.isGwangBak ? 2 :1) * (player2.isPiBak ? 2 : 1) * (player2.isGoBak ? 2 : 1)
        
        let goBakPlayerIndex = self.getGoBakPlayerIndex(winnerIndex: winnerIndex)
        if let goBakPlayerIndex {
            if goBakPlayerIndex == player1.index {
                player1.isGoBak = true
                player1.finalScore += player2.finalScore
                player2.finalScore = 0
            }
            else if goBakPlayerIndex == player2.index {
                player2.isGoBak = true
                player2.finalScore += player1.finalScore
                player1.finalScore = 0
            }
        }
        winner.finalScore = player1.finalScore + player2.finalScore
        
        PopupManager.shared.showPopup(popupData: self.popupData, type: .winner, cards: [], players: [winner, player1, player2], completion: { select in
            if let goBakPlayerIndex {
                self.collectMoney(winnerIndex: winnerIndex, loserIndex: goBakPlayerIndex, money: winner.finalScore){
                    self.startGame()
                }
            }
            else {
                self.collectMoney(winnerIndex: winnerIndex, loserIndex: player1.index, money: player1.finalScore){
                    self.collectMoney(winnerIndex: winnerIndex, loserIndex: player2.index, money: player2.finalScore){
                        self.startGame()
                    }
                }
            }
        })
    }
    
    private func showChongTongWinPopup(winnerIndex: Int, cards: [Card], competion: @escaping () -> Void) {
        self.gameData.winnerIndex = winnerIndex
        
        let winner = self.gameData.players[winnerIndex]
        var loser1 = self.gameData.players[(winnerIndex + 1) % 3]
        var loser2 = self.gameData.players[(winnerIndex + 2) % 3]
        
        PopupManager.shared.showPopup(popupData: self.popupData, type: .chongtongWin, cards: cards, players: [winner, loser1, loser2], completion: { _ in
            competion()
        })
    }
    
    private func isEmptyTable() -> Bool {
        for tableCardGroup in self.tableCardGroups {
            if tableCardGroup.count > 0 { return false }
        }
        return true
    }
    
    // Test : 한사람에게 카드 몰빵
    private func moveDeckCardToPlayerCaptured(playerIndex: Int) async {
        let deckCard = self.deckCards.removeLast()
        self.moveCardToPlayerCaptured(playerIndex: playerIndex, card: deckCard)
        
        do { try await Task.sleep(for: .seconds(self.gameData.cardDuration))
        } catch { print("error: \(error)")}
    }
    
    private func moveCardToPlayerCaptured(playerIndex: Int, card: Card, forcedType: CardType? = nil) {
        print("\(#function) card: \(card.month), \(card.type)")
        guard let cardNode = self.childNode(withName: card.id.uuidString) as? CardNode else { return }
        cardNode.removeStroke()
        
        // 국진일 경우 type 강제 할당
        let cardIndexByType = self.gameData.players[playerIndex].capturedCardTypeGroups[forcedType?.rawValue ?? card.type.rawValue].count
        self.gameData.players[playerIndex].capturedCardTypeGroups[forcedType?.rawValue ?? card.type.rawValue].append(card)
        
        let movePosition = self.getPlayerCapturedCardPosition(playerIndex: playerIndex, cardIndexByType: cardIndexByType, cardType: forcedType ?? card.type)
        cardNode.moveAndTurnCard(movePosition: movePosition, duration: self.gameData.cardDuration, isFront: true, zPosition: cardIndexByType, afterCardNodeScale: .normal, completion: {
            self.setPlayerScoreNodes(playerIndex: playerIndex)
        })
    }
    
    private func moveCardToTable(card: Card, tableCardGroupIndex: Int) {
        print("\(#function) card: \(card.month), \(card.type)")
        guard let cardNode = childNode(withName: card.id.uuidString) as? CardNode else { return }
        cardNode.removeStroke()
        let groupIndex = tableCardGroupIndex ?? self.getTableCardGroupIndex(cardMonth: cardNode.card.month) ?? self.getEmptyTableCardGroupIndex(cardMonth: cardNode.card.month)
        let cardIndexByGroup = self.tableCardGroups[groupIndex].count
        let zPosition = self.getTableCardZPosition(groupIndex: groupIndex, cardIndexByGroup: cardIndexByGroup)
        let movePosition = self.getTableCardPosition(groupIndex: groupIndex, cardIndexByGroup: cardIndexByGroup)
        self.tableCardGroups[tableCardGroupIndex].append(card)
        cardNode.moveAndTurnCard(movePosition: movePosition, duration: self.gameData.cardDuration, isFront: true, zPosition: Int(zPosition),afterCardNodeScale: .large)
    }
    
    private func moveDeckCardToTable(count: Int = 1) async {
        for _ in 0..<count {
            if self.deckCards.count == 0 { return }
            let deckCard = self.deckCards.removeLast()
            print("\(#function) deckCard: \(deckCard.month), \(deckCard.type)")
            let tableCardGroupIndex = self.getTableCardGroupIndex(cardMonth: deckCard.month) ?? self.getEmptyTableCardGroupIndex(cardMonth: deckCard.month)
            self.moveCardToTable(card: deckCard, tableCardGroupIndex: tableCardGroupIndex)
        }
        
        do { try await Task.sleep(for: .seconds(self.gameData.cardDuration))
        } catch { print("error: \(error)")}
    }
    
    private func isGukjinCard(card: Card) -> Bool {
        return card.month == 9 && card.type == .yeol
    }
    
    private func moveBonusPlayerHandBonusCardToPlayerCaptured(playerIndex: Int, handCard: Card) async {
        // 가지고 있는 카드를 수집카드로// 손에서 비움
        self.gameData.players[playerIndex].handCards.removeAll { $0.id == handCard.id }
        self.moveCardToPlayerCaptured(playerIndex: playerIndex, card: handCard)
        
        do { try await Task.sleep(for: .seconds(self.gameData.cardDuration))
        } catch { print("error: \(error)")}
        
        // 덱에서 카드 한장 새로 받기
        await self.moveDeckCardToPlayerHand(playerIndex: playerIndex)
        do { try await Task.sleep(for: .seconds(self.gameData.cardDuration))
        } catch { print("error: \(error)")}
    }

    func getTableCardZPosition(groupIndex: Int, cardIndexByGroup: Int) -> Int {
        // 왼쪽 테이블 카드가 zPiosition이 높아야 함
        // 14개 기준
        if groupIndex % 2 == 0 {
            return (groupIndex + 1) * 10 + cardIndexByGroup
        }
        else {
            return (20 - groupIndex) * 10 + cardIndexByGroup
        }
    }
    
    private func moveDeckCardToMatchingTableCards(deckCard: Card, tableCards: [Card]) async {
        guard let deckCardNode = childNode(withName: deckCard.id.uuidString) as? CardNode else { return }
        guard let matchingTableCardNode = childNode(withName: tableCards.last!.id.uuidString) as? CardNode else { return }
        
        let groupIndex = self.getTableCardGroupIndex(cardMonth: deckCard.month) ?? self.getEmptyTableCardGroupIndex(cardMonth: deckCard.month)
        let cardIndexByGroup = self.tableCardGroups[groupIndex].count
        let zPosition = self.getTableCardZPosition(groupIndex: groupIndex, cardIndexByGroup: cardIndexByGroup)
        
        print("tablecarscount:\(tableCards.count), groupIndex = \(groupIndex), cardIndexByGroup = \(cardIndexByGroup), zposition =\(zPosition)")
        var matchPosition = matchingTableCardNode.position
        matchPosition.x += 10
        matchPosition.y -= 10
        
        deckCardNode.moveAndTurnCard(movePosition: matchPosition, duration: self.gameData.cardDuration, isFront: true, zPosition: zPosition, afterCardNodeScale: .large)
        do { try await Task.sleep(for: .seconds(self.gameData.cardDuration))
        } catch { print("error: \(error)")}
    }
    
    private func movePlayerHandCardsToMatchingTableCards(handCards: [Card], tableCards: [Card]) async {
        for (i, handCard) in handCards.enumerated() {
            guard let handCardNode = childNode(withName: handCard.id.uuidString) as? CardNode else { return }
            guard let matchingTableCardNode = childNode(withName: tableCards.last!.id.uuidString) as? CardNode else { return }
            
            let groupIndex = self.getTableCardGroupIndex(cardMonth: handCard.month) ?? self.getEmptyTableCardGroupIndex(cardMonth: handCard.month)
            let cardIndexByGroup = self.tableCardGroups[groupIndex].count + (i + 1)
            let zPosition = self.getTableCardZPosition(groupIndex: groupIndex, cardIndexByGroup: cardIndexByGroup)
            
            var matchPosition = matchingTableCardNode.position
            matchPosition.x += CGFloat(10 * (i + 1))
            matchPosition.y -= CGFloat(10 * (i + 1))
            
            handCardNode.removeStroke()
            handCardNode.moveAndTurnCard(movePosition: matchPosition, duration: self.gameData.cardDuration, isFront: true, zPosition: zPosition, afterCardNodeScale: .large)
        }
        
        do { try await Task.sleep(for: .seconds(self.gameData.cardDuration))
        } catch { print("error: \(error)")}
    }
    
    private func moveMatchingDeckOrHandCardToPlayerCaptured(playerIndex: Int, deckOrHandCards: [Card] = [], tableCards: [Card], completion: @escaping () -> Void) {
        let tableCardGroupIndex = self.getTableCardGroupIndex(cardMonth: tableCards.last!.month) ?? self.getEmptyTableCardGroupIndex(cardMonth: tableCards.last!.month)
        var gukjinCard: Card? = nil
        
        for deckOrHandCard in deckOrHandCards {
            self.gameData.players[playerIndex].handCards.removeAll { $0.id == deckOrHandCard.id }
            self.deckCards.removeAll { $0.id == deckOrHandCard.id }
            
            // 국진 위치
            if self.isGukjinCard(card: deckOrHandCard) {
                gukjinCard = deckOrHandCard
            }
            else {
                self.moveCardToPlayerCaptured(playerIndex: playerIndex, card: deckOrHandCard)
            }
        }
        
        if let gukjinCard {
            // user
            if self.gameData.currentPlayerIndex == 0 {
                PopupManager.shared.showPopup(popupData: self.popupData, type: .selectGukjin, cards: [gukjinCard], players: [self.gameData.players[playerIndex]]) { select in
                    self.afterSelectGukjin(isDoublePi: select == 0, playerIndex: playerIndex, card: gukjinCard, tableCardGroupIndex: tableCardGroupIndex, completion: completion)
                }
            }
            // ai
            else {
                //  쌍피 선택
                let isDoublePi = self.selectGukjinWithAi(card: gukjinCard)
                self.afterSelectGukjin(isDoublePi: isDoublePi, playerIndex: playerIndex, card: gukjinCard, tableCardGroupIndex: tableCardGroupIndex, completion: completion)
            }
        }
        else {
            self.sortTableCardGroup(tableCardGroupIndex: tableCardGroupIndex)
            completion()
        }
    }
    
    private func moveMatchingTableCardsToPlayerCaptured(playerIndex: Int, tableCards: [Card], completion: @escaping () -> Void) {
        let tableCardGroupIndex = self.getTableCardGroupIndex(cardMonth: tableCards.last!.month) ?? self.getEmptyTableCardGroupIndex(cardMonth: tableCards.last!.month)
        var gukjinCard: Card? = nil
        
        for tableCard in tableCards {
            self.removeTableCard(card: tableCard)
            
            
            // 국진 위치
            if self.isGukjinCard(card: tableCard) {
                gukjinCard = tableCard
            }
            else {
                self.moveCardToPlayerCaptured(playerIndex: playerIndex, card: tableCard)
            }
        }
        
        if let gukjinCard {
            // user
            if playerIndex == 0 {
                PopupManager.shared.showPopup(popupData: self.popupData, type: .selectGukjin, cards: [gukjinCard], players: [self.gameData.players[playerIndex]]) { select in
                    //  쌍피 선택
                    if select == 0 {
                        self.moveCardToPlayerCaptured(playerIndex: playerIndex, card: gukjinCard, forcedType: .pi)
                        self.sortTableCardGroup(tableCardGroupIndex: tableCardGroupIndex)
                    }
                    // 열끗 선택
                    else {
                        self.moveCardToPlayerCaptured(playerIndex: playerIndex, card: gukjinCard)
                        self.sortTableCardGroup(tableCardGroupIndex: tableCardGroupIndex)
                    }
                    self.sortTableCardGroup(tableCardGroupIndex: tableCardGroupIndex)
                    completion()
                }
            }
            // ai
            else {
                //  쌍피 선택
                if self.selectGukjinWithAi(card: gukjinCard) {
                    self.moveCardToPlayerCaptured(playerIndex: playerIndex, card: gukjinCard, forcedType: .pi)
                    self.sortTableCardGroup(tableCardGroupIndex: tableCardGroupIndex)
                }
                // 열끗 선택
                else {
                    self.moveCardToPlayerCaptured(playerIndex: playerIndex, card: gukjinCard)
                    self.sortTableCardGroup(tableCardGroupIndex: tableCardGroupIndex)
                }
                self.sortTableCardGroup(tableCardGroupIndex: tableCardGroupIndex)
                completion()
            }
            
        }
        else {
            self.sortTableCardGroup(tableCardGroupIndex: tableCardGroupIndex)
            completion()
        }
    }
    
    private func moveMatchingCardsToPlayerCaptured(playerIndex: Int, deckOrHandCards: [Card] = [], tableCards: [Card], completion: @escaping () -> Void) async {
        print("\(#function) playerIndex: \(playerIndex), deckOrHandCards: \(deckOrHandCards.count), tableCards: \(tableCards.count)")
        self.moveMatchingDeckOrHandCardToPlayerCaptured(playerIndex: playerIndex, deckOrHandCards: deckOrHandCards, tableCards: tableCards) {
            self.moveMatchingTableCardsToPlayerCaptured(playerIndex: playerIndex, tableCards: tableCards) {
                Task{
                    do { try await Task.sleep(for: .seconds(self.self.gameData.cardDuration))
                    } catch { print("error: \(error)")}
                    completion()
                }
            }
        }
    }
    
    // 테이블 바닥카드 가져갈때 해당 그룹 정렬
    private func sortTableCardGroup(tableCardGroupIndex: Int) {
        for (i, card) in tableCardGroups[tableCardGroupIndex].enumerated() {
            guard let cardNode = childNode(withName: card.id.uuidString) as? CardNode else { continue }
            let zPosition = self.getTableCardZPosition(groupIndex: tableCardGroupIndex, cardIndexByGroup: i)
            let movePosition = self.getTableCardPosition(groupIndex: tableCardGroupIndex, cardIndexByGroup: i)
            cardNode.moveAndTurnCard(movePosition: movePosition, isFront: true, zPosition: zPosition, movingUpScale: nil, afterCardNodeScale: .large)
        }
    }
    
    private func moveDeckCardToPlayerHand(playerIndex: Int, count: Int = 1) async {
        for _ in 0..<count {
            guard let deckCardNode = childNode(withName: deckCards.last?.id.uuidString ?? "") as? CardNode else { return }
            let lastDeckCard = self.deckCards.removeLast()
            self.gameData.players[playerIndex].handCards.append(lastDeckCard)
            let cardIndex = self.gameData.players[playerIndex].handCards.count
            let movePosition = self.getPlayerHandCardPosition(playerIndex: playerIndex, cardIndex: cardIndex)
            deckCardNode.moveAndTurnCard(movePosition: movePosition, duration: self.gameData.cardDuration, isFront: playerIndex == 0, afterCardNodeScale: playerIndex == 0 ? .xLarge : .small)
        }
        
        do { try await Task.sleep(for: .seconds(self.gameData.cardDuration))
        } catch { print("error: \(error)")}
    }
    
    private func movePlayerHandCardsToTable(playerIndex: Int, handCards: [Card]) async {
        for handCard in handCards {
            self.gameData.players[playerIndex].handCards.removeAll { $0.id == handCard.id }
            let tableCardGroupIndex = self.getTableCardGroupIndex(cardMonth: handCard.month) ?? self.getEmptyTableCardGroupIndex(cardMonth: handCard.month)
            self.moveCardToTable(card: handCard, tableCardGroupIndex: tableCardGroupIndex)
        }
        
        do { try await Task.sleep(for: .seconds(self.gameData.cardDuration))
        } catch { print("error: \(error)")}
    }
    
    private func removePlayerHandCards(playerIndex: Int, handCards: [Card]) {
        var handCardNodes: [SKNode] = []
        for handCard in handCards {
            guard let handCardNode = childNode(withName: handCard.id.uuidString) as? CardNode else { return }
            handCardNodes.append(handCardNode)
            self.gameData.players[playerIndex].handCards.removeAll { $0.id == handCard.id }
        }
        self.removeChildren(in: handCardNodes)
    }
    
    private func sortPlayerHandCards(playerIndex: Int) {
        self.gameData.players[playerIndex].handCards.sort { (card1, card2) -> Bool in
            if card1.month < card2.month { return true }
            else if card1.month > card2.month { return false }
            else { return card1.type.rawValue > card2.type.rawValue }
        }
        for (i, handCard) in self.gameData.players[playerIndex].handCards.enumerated() {
            guard let handCardNode = childNode(withName: handCard.id.uuidString) as? CardNode else { return }
            
            // 사용자 카드가 테이블에 있으면 깜빡이게 표시하기 or 보너스카드
            if self.gameData.currentPlayerIndex == 0 && playerIndex == 0 && (handCard.month == 100 || handCard.month == 0 || self.getTableCardGroupIndex(cardMonth: handCard.month) != nil) {
                handCardNode.addStrokeWithBlink(size: self.cardSize)
            }
            else {
                handCardNode.removeStroke()
            }
            
            let movePosition = self.getPlayerHandCardPosition(playerIndex: playerIndex, cardIndex: i)
            // 동일위치 다시 그리기 방지 (위치값 소숫점 미세하게 변경 무시)
            if Int(movePosition.x) == Int(handCardNode.position.x) && Int(movePosition.y) == Int(handCardNode.position.y) {
                //print("\(#function) same positioin \(i)")
            }
            else {
                //print("\(#function) different positioin \(i) current(\(handCardNode.position.x),\(handCardNode.position.y)),target(\(movePosition.x),\(movePosition.y))")
                handCardNode.moveAndTurnCard(movePosition: movePosition, duration: self.gameData.cardDuration, isFront: playerIndex == 0, movingUpScale: nil, afterCardNodeScale: playerIndex == 0 ? .xLarge : .small)
            }
        }
    }
    
    private func sortPlayerCapturedPiCards(playerIndex: Int) {
        for capturedCard in self.gameData.players[playerIndex].capturedCardTypeGroups[CardType.pi.rawValue] {
            guard let capturedCardNode = childNode(withName: capturedCard.id.uuidString) as? CardNode else { return }
            let cardIndexByType = self.gameData.players[playerIndex].capturedCardTypeGroups[capturedCard.type.rawValue].firstIndex{ c in c.id == capturedCard.id } ?? 0
            // 6쌍피가 있어 강제 pi로만 위치 가져오기
            let movePosition = self.getPlayerCapturedCardPosition(playerIndex: playerIndex, cardIndexByType: cardIndexByType, cardType: .pi)
            // 동일위치 다시 그리기 방지 (위치값 소숫점 미세하게 변경 무시)
            if Int(movePosition.x) == Int(capturedCardNode.position.x) && Int(movePosition.y) == Int(capturedCardNode.position.y) {
                //print("\(#function) same positioin \(i)")
            }
            else {
                //print("\(#function) different positioin \(i) current(\(handCardNode.position.x),\(handCardNode.position.y)),target(\(movePosition.x),\(movePosition.y))")
                capturedCardNode.moveAndTurnCard(movePosition: movePosition, duration: self.gameData.cardDuration, isFront: true, zPosition: cardIndexByType, movingUpScale: nil, afterCardNodeScale: .normal)
            }
        }
    }
    
    // 테이블 카드가 보너스 카드인 경우(복수가능) > 덱카드 다시받기 > 다시받은 카드가 보너스카드인경우 재귀반복
    private func moveBonusTableCardToPlayerCapturedAndMoveDeckCardToTableAgain(playerIndex: Int) async  {
        var bounsCardCount = 0
        
        for i in (0..<self.tableCardGroups.count).reversed() {
            for j in (0..<self.tableCardGroups[i].count).reversed() {
                let tableCard = self.tableCardGroups[i][j]
                if tableCard.month == 0 {
                    // table에서 제거하고 winner에게 지급
                    let tableCardGroupIndex = self.getTableCardGroupIndex(cardMonth: tableCard.month) ?? self.getEmptyTableCardGroupIndex(cardMonth: tableCard.month)
                    self.removeTableCard(card: tableCard)
                    self.moveCardToPlayerCaptured(playerIndex: playerIndex, card: tableCard)
                    self.sortTableCardGroup(tableCardGroupIndex: tableCardGroupIndex)
                    
                    do { try await Task.sleep(for: .seconds(self.gameData.cardDuration))
                    } catch { print("error: \(error)")}
                    
                    bounsCardCount += 1
                }
            }
        }
        
        // 재귀함수 호출
        if bounsCardCount > 0 {
            for _ in 0..<bounsCardCount {
                await self.moveDeckCardToTable()
                await moveBonusTableCardToPlayerCapturedAndMoveDeckCardToTableAgain(playerIndex: playerIndex)
            }
        }
    }

    // 보너스 카드가 연속인 경우 처리, 보너스 카드가 아닌경우
    private func moveBonusDeckCardsToPlayerCapturedIfNeeded(playerIndex: Int, completion: @escaping () -> Void) async  {
        guard let deckCard = self.deckCards.last else { return }
        if deckCard.month == 0 {
            PopupManager.shared.showPopup(popupData: self.popupData, type: .deckBonus, cards: [deckCard], players: [self.gameData.players[playerIndex]]) { _ in
                Task {
                    // table에서 제거하고 winner에게 지급
                    self.deckCards.removeLast()
                    self.moveCardToPlayerCaptured(playerIndex: playerIndex, card: deckCard)
                    
                    do { try await Task.sleep(for: .seconds(self.self.gameData.cardDuration))
                    } catch { print("error: \(error)")}
                    
                    // 다시 시도
                    await self.moveBonusDeckCardsToPlayerCapturedIfNeeded(playerIndex: playerIndex, completion: completion)
                }
            }
        }
        else {
            completion()
        }
    }

    private func moveOtherPlayersCapturedCardsToPlayerCaptured(toPlayerIndex: Int, piCount: Int) async  {
        for anotherPlayer in self.gameData.players {
            if anotherPlayer.index == toPlayerIndex { continue }
            
            let doublePi: Card? = anotherPlayer.capturedCardTypeGroups[CardType.pi.rawValue].last{ $0.isDoublePi == true }
            let onePis: [Card] = anotherPlayer.capturedCardTypeGroups[CardType.pi.rawValue].filter{ $0.isDoublePi == false }.suffix(2) // 뒤에 쌍피가 아닌 일반피 두개 가져오기
            
            var movingCards: [Card] = []
            
            switch piCount {
            case 1: // 피가 한개있으면 가져오고 없으면 쌍피가져오기
                if let onePi = onePis.last {
                    movingCards.append(onePi)
                }
                else if let pi2 = doublePi {
                    movingCards.append(pi2)
                }
            case 2: // 쌍피 있으면 가져오고 없으면 피 두개 가져오기
                if let pi2 = doublePi {
                    movingCards.append(pi2)
                }
                else {
                    movingCards = onePis
                }
            default :
                break
            }
            
            for movingCard in movingCards {
                self.gameData.players[anotherPlayer.index].capturedCardTypeGroups[CardType.pi.rawValue].removeAll { $0.id == movingCard.id }
                self.moveCardToPlayerCaptured(playerIndex: toPlayerIndex, card: movingCard)
            }
            
            self.sortPlayerCapturedPiCards(playerIndex: anotherPlayer.index)
            self.setPlayerScoreNodes(playerIndex: anotherPlayer.index)
        }
        
        do { try await Task.sleep(for: .seconds(self.gameData.cardDuration))
        } catch { print("error: \(error)")}
    }
    
    private func moveBonusDeckCardsToTable(tableCardGroupIndex: Int) async  {
        if self.deckCards.last?.month == 0 {
            // table에서 제거하고 winner에게 지급
            let deckCard = self.deckCards.removeLast()
            self.moveCardToTable(card: deckCard, tableCardGroupIndex: tableCardGroupIndex)
            
            do { try await Task.sleep(for: .seconds(self.gameData.cardDuration))
            } catch { print("error: \(error)")}
            // 반복
            Task {
                await self.moveBonusDeckCardsToTable(tableCardGroupIndex: tableCardGroupIndex)
            }
        }
        else {
            return
        }
    }
    
    // 존재하는 테이블 그룹 찾기 (없으면 nil)
    private func getTableCardGroupIndex(cardMonth: Int) -> Int? {
        for (i, tableCardGroup) in tableCardGroups.enumerated() {
            if let card  = tableCardGroup.first {
                if card.month == cardMonth {
                    return i
                }
            }
        }
        return nil
    }
    
    // 비어있는 테이블 그룹 반환 (getTableCardGroupIndex이 없으면 )
    private func getEmptyTableCardGroupIndex(cardMonth: Int) -> Int {
        for (i, tableCardGroup) in tableCardGroups.enumerated() {
            if tableCardGroup.isEmpty {
                return i
            }
        }
        return 0
    }
    
    private func getMatchingTableCards(cardMonth: Int) -> [Card] {
        var cards: [Card] = []
        for tableCardGroup in tableCardGroups {
            // 첫번째 카드로만 같은 그룹인지 확인 후 보너스카드까지 가져가야 함
            if tableCardGroup.first?.month == cardMonth {
                for card in tableCardGroup {
                    cards.append(card)
                }
            }
        }
        return cards
    }
    
    private func removeTableCard(card: Card) {
        for i in 0..<self.tableCardGroups.count {
            self.tableCardGroups[i].removeAll { $0.id == card.id }
        }
    }

    private func setDeckCards() {
        let startX = round(size.width / 2)
        let startY = round(size.height / 2) - cardGap * 5
        
        self.deckCards = self.gameData.deckCards
        
        for i in 0 ..< deckCards.count {
            let node = CardNode(name: deckCards[i].id.uuidString, card: deckCards[i], cardSize: cardSize, isFront: false)
            node.position = CGPoint(x: startX + CGFloat(i), y: startY - CGFloat(i))
            node.zPosition = self.deckZPosition + CGFloat(i)
            self.addChild(node)
            
            let scaleAction = SKAction.scale(to: CardNodeScale.large.rawValue, duration: 0)
            node.run(scaleAction)
        }
    }
    
    private func getTableCardPosition(groupIndex: Int, cardIndexByGroup: Int) -> CGPoint {
        print("\(#function): \(groupIndex), \(cardIndexByGroup)")
        let startX = round(size.width / 2)
        let startY = round(size.height / 2) - cardGap * 5
        
        let cardWidthWithGap = self.cardSize.width * CardNodeScale.large.rawValue + self.cardGap
        let sp = CGFloat(cardIndexByGroup) * self.cardLayeredGap * CardNodeScale.large.rawValue
        if groupIndex % 2 == 0 {
            return CGPoint(x:startX - cardWidthWithGap / 2 - cardWidthWithGap * CGFloat(groupIndex / 2 + 1) + sp, y: startY - sp)
        }
        else {
            return CGPoint(x:startX + cardWidthWithGap / 2 + cardWidthWithGap * round(CGFloat(groupIndex / 2 + 1)) + sp, y: startY - sp)
        }
    }
    
    private func getPlayerHandCardPosition(playerIndex: Int, cardIndex: Int) -> CGPoint {
        let cardNodeScale = playerIndex == 0 ? CardNodeScale.xLarge.rawValue : CardNodeScale.small.rawValue
        let cardWidthWithGap = self.cardSize.width * cardNodeScale + self.cardGap
        var startPosition: CGPoint = .zero // 좌측 하단이 시작점

        if playerIndex == 0 {
            startPosition.x = self.size.width / 2 + self.cardGap
            startPosition.y = 15
        }
        else if let playerNameNode = self.childNode(withName: CapsuledLabelNode.prefixPlayerName + "\(playerIndex)") as? SKLabelNode {
            startPosition.x = playerNameNode.position.x + (playerNameNode.bounds.size.width / 2) + self.cardGap
            startPosition.y = playerNameNode.position.y - (self.cardSize.height * cardNodeScale) - self.cardGap
        }
        else {
            print("\(#function) empty childNode: \(CapsuledLabelNode.prefixPlayerName)\(playerIndex)")
            startPosition.x = (playerIndex == 2 ? 0.0 : self.size.width / 2) + self.cardGap
            startPosition.y = size.height + (cardSize.height / 2) - self.cardGap
        }

        var position: CGPoint = .zero
        position.x = startPosition.x + (self.cardSize.width / 2) + CGFloat(cardIndex) * cardWidthWithGap
        position.y = startPosition.y + (self.cardSize.height * CardNodeScale.large.rawValue / 2)
        return position
    }
    
    private func getPlayerCapturedCardPosition(playerIndex: Int, cardIndexByType: Int, cardType: CardType) -> CGPoint {
        print("\(#function) cardIndexByType: \(cardIndexByType), cardType: \(cardType)")
        let cardHeightWithGap = self.cardSize.height + self.cardGap
        var startPosition: CGPoint = .zero // 좌측 하단이 시작점
        startPosition.x = (playerIndex == 1 ? self.size.width / 2 : 0.0) + self.playerImageSize.width + (self.cardGap * 2)
        startPosition.y = playerIndex == 0 ? self.cardGap : size.height - (cardSize.height / 2) - cardHeightWithGap * 3 - (self.cardGap * 2)
        var position: CGPoint = .zero
        position.x = startPosition.x  + (cardSize.width / 2) + (cardSize.width / 2.5) * CGFloat(cardIndexByType) + ( cardType == .tti ? self.size.width / 5 : 0)
        position.y = startPosition.y + (cardSize.height / 2) + cardHeightWithGap * (cardType == .gwang ? 2.0 : cardType == .pi ? 0.0 : 1.0)
        return position
    }
    
    private func setBackgroundNodes() {
        let startY = round(size.height / 2) - cardGap * 5
        
        let deckAreaNode = SKShapeNode(rect: CGRect(x: 0, y: startY - cardSize.height , width: self.size.width, height: cardSize.height * 2))
        deckAreaNode.fillColor = .black.withAlphaComponent(0.7)
        deckAreaNode.strokeColor = .clear
        self.addChild(deckAreaNode)
        
        for playerIndex in 0...2 {
            let playerAreaNode = SKShapeNode(circleOfRadius: playerIndex == 0 ? self.size.width : self.size.width / 2 )
            
            switch playerIndex {
            case 1:
                playerAreaNode.position.x = 0
                playerAreaNode.position.y = self.size.height * 4 / 3
            case 2:
                playerAreaNode.position.x = self.size.width
                playerAreaNode.position.y = self.size.height * 4 / 3
            default: // user
                playerAreaNode.position.x = self.size.width / 2
                playerAreaNode.position.y = -self.size.height * 1.5
            }
            
            playerAreaNode.fillColor = .white.withAlphaComponent(0.2)
            playerAreaNode.strokeColor = .clear
            playerAreaNode.zPosition = -100
            addChild(playerAreaNode)
        }
    }
    
    private func setStrokeWithBlinkToPlayerNode(playerIndex: Int) {
        guard let playerIconNode = self.childNode(withName: PlayerIconNode.prefixName + "\(playerIndex)") else { return }
        print("playerIndex \(playerIndex) == currentPlayerIndex: \(self.gameData.currentPlayerIndex)")
        if playerIndex == self.gameData.currentPlayerIndex {
            let borderNode = SKShapeNode(rectOf: self.playerImageSize, cornerRadius: self.playerImageSize.width / 2)
            borderNode.name = PlayerIconNode.blinkBorderName
            borderNode.strokeColor = .yellow.withAlphaComponent(0.5)
            borderNode.lineWidth = 10.0
            borderNode.fillColor = .clear
            borderNode.zPosition = 100
            playerIconNode.addChild(borderNode)
            
            // 깜빡이는 액션
            let fadeOut = SKAction.fadeAlpha(to: 0.2, duration: 0.3)
            let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.3)
            let blink = SKAction.repeatForever(
                SKAction.sequence([fadeOut, fadeIn])
            )
            borderNode.run(blink)
        }
        else {
            if let borderNode = playerIconNode.childNode(withName: PlayerIconNode.blinkBorderName) {
                borderNode.removeFromParent()
            }
            else {
                print("not found blinkBorderName")
                for node in playerIconNode.children {
                    print("... \(node.name)")
                }
            }
        }
    }
    
    private func updatePlayers() { 
        for i in 0...2 {
            guard let playerNameNode = self.childNode(withName: CapsuledLabelNode.prefixPlayerName + "\(i)") else { return }
            guard let playerIconNode = self.childNode(withName: PlayerIconNode.prefixName + "\(i)") else { return }
            self.removeChildren(in: [playerNameNode, playerIconNode])
            self.setPlayerNodes(player: self.gameData.players[i])
            self.setStrokeWithBlinkToPlayerNode(playerIndex: i)
        }
    }
    
    private func setPlayerNodes(player: Player) {
        let cardHeightWithGap = self.cardSize.height + self.cardGap
        var startPosition: CGPoint = .zero // 좌측 하단이 시작점
        let playerNameNode = CapsuledLabelNode(player: player)
        
        switch player.index {
        case 1:
            startPosition.x = (self.size.width / 2) + self.cardGap
            startPosition.y = self.size.height - self.cardSize.height - self.cardGap
        case 2:
            startPosition.x = self.cardGap
            startPosition.y = self.size.height - self.cardSize.height - self.cardGap
        default: // user
            startPosition.x = (self.size.width - self.playerImageSize.width - playerNameNode.frame.width) / 2
            startPosition.y = cardHeightWithGap * 2 /*+ (self.playerImageSize.height / 2) - self.cardGap * 5*/
        }

        let playerIconNode = PlayerIconNode(player: player, position: startPosition, size: self.playerImageSize)
        self.addChild(playerIconNode)
    
        playerNameNode.position.x = startPosition.x + self.playerImageSize.width + playerNameNode.bounds.width / 2 + 10
        playerNameNode.position.y = startPosition.y + (player.index == 0 ? self.playerImageSize.height / 4 : self.playerImageSize.height / 2)
        self.addChild(playerNameNode)
    }
    
    private func setPlayerScoreNodes(playerIndex: Int) {
        let player = self.gameData.players[playerIndex]
        
        for i in 0..<player.capturedCardTypeGroups.count {
            if let node = self.childNode(withName: CapsuledLabelNode.prefixPlayerCapturedGroup + "\(player.index)_\(i)") {
                self.removeChildren(in: [node])
            }
            
            let cardIndexByType = player.capturedCardTypeGroups[i].count
            if cardIndexByType == 0 { continue }
            var position = self.getPlayerCapturedCardPosition(playerIndex: player.index, cardIndexByType: cardIndexByType, cardType: CardType(rawValue: i) ?? .gwang)
            var score = 0
            switch i {
            case 0: score = player.gwangCount
            case 1: score = player.yeolCount
            case 2: score = player.ttiCount
            case 3: score = player.piCount
            default: break
            }
            let capturedCountNode = CapsuledLabelNode(player: player, groupIndex: i, score: score)
            position.x += capturedCountNode.frame.width
            position.y -= capturedCountNode.frame.height + 3
            capturedCountNode.position = position
            self.addChild(capturedCountNode)
        }
    }
}
