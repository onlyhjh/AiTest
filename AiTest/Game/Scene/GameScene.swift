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

    var gameData: GameData
    var popupData: PopupData
    
    static let playerNames = ["고니", "정마담", "고광렬", "짝귀", "평경장", "박무석", "아귀", "곽철용", "장동식", "함대길", "꼬장", "작은마담", "우사장", "송마담", "허미나", "영미", "도일출", "애꾸", "이상무", "물영감", "까치"]
    
    // zPosition > tableCard = 10 ~ 140  deckCard = 1000~카드쌓기, 움직이는카드 10000 > 정지 후 0
    private let deckZPosition: CGFloat = 1000
    
    private var winnerIndex = 0
    private var players: [Player] = []
    private var tableCardGroups: [[Card]] = []
    private var deckCards: [Card] = []
    
    private var currentPlayerIndex = 100 //100 대기
    private var cardSize: CGSize = .zero
    private var playerImageSize: CGSize = .zero
    private var cardGap: CGFloat = 0
    private var cardLayeredGap: CGFloat = 0
    
    private let cardDuration: Double = 0.2
    private let emptyCardMonth: Int = 100
    
    init(size: CGSize, gameData: GameData, popupData: PopupData) {
        self.gameData = gameData
        self.popupData = popupData
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        self.backgroundColor = .tableBG ?? .black
        
        // 화면 전환 이후 싸이즈 계산해야 함!
        DispatchQueue.main.async {
            self.cardSize = CGSize(width: self.size.height / 14, height: self.size.height / 14 * 1.5)
            self.playerImageSize = CGSize(width: self.cardSize.height, height: self.cardSize.height)
            self.cardGap = self.cardSize.width / 10
            self.cardLayeredGap = self.cardSize.width / 5
        }
    }
    
    // 매 프레임마다 SwiftUI로부터 온 데이터를 감지하고 적용
    override func update(_ currentTime: TimeInterval) {
        //print("\(#function) update gameStatus: \(gameData.gameStatus)")
        switch self.gameData.gameStatus {
        case .start:
            self.startGame()
            self.gameData.gameStatus = .wait
        default:
            break
        }
    }
    
    private func startGame() {
        self.removeAllChildren()
        self.deckCards = self.gameData.deckCards
        self.players = [Player(index: 0), Player(index: 1), Player(index: 2)]
        self.setPlayers()
        self.initDeckCardNode()
        self.tableCardGroups = [[], [], [], [], [], [], [], [], [], [], [], [], [], []]
        
        Task {
            // Test : player captured영역 확인을 위해 전체 카드 주기 */
//            for _ in 0..<self.deckCards.count - 1 {
//                await self.moveDeckCardToPlayerCaptured(playerIndex: 0)
//            }
//            return
            
//            // Test 특정카드 사용자에게
//            for (i, card) in self.deckCards.enumerated().reversed() {
//                if card.type == .gwang && card.month == 3 && card.piNum == 0 {
//                    let element = self.deckCards.remove(at: i)
//                    self.deckCards.insert(element, at: 25)
//                    break
//                }
//            }
            
            
            // 테이블에 첫번째 3장 나눠주기
            for _ in 0...2 {
                let _ = await self.moveDeckCardToTable()
            }
            
            // 플레이어에게 첫번째 4장 나눠주기
            for i in 0...2 {
                let nextPlayerIndex = (winnerIndex + 1 + i) % 3
                
                for cardIndex in 0...3 {
                    await self.moveDeckCardToPlayerHand(playerIndex: nextPlayerIndex, cardIndex: cardIndex)
                }
            }
            
            // 테이블에 두번째 3장 나눠주기
            for _ in 3...5 {
                let _ = await self.moveDeckCardToTable()
            }
            
            // 플레이어에게 두번째 3장 나눠주기
            for i in 0...2 {
                let nextPlayerIndex = (winnerIndex + 1 + i) % 3
                
                for cardIndex in 4...6 {
                    await self.moveDeckCardToPlayerHand(playerIndex: nextPlayerIndex, cardIndex: cardIndex)
                }
                
                self.sortPlayerHandCards(playerIndex: nextPlayerIndex)
            }

            self.currentPlayerIndex = 0 //(winnerIndex + 1) % 3
            
            // 보너스 카드 지급 후 덱카드 테이블에 지급 (재귀반복)
            let _ = await self.moveBonusTableCardToPlayerCapturedAndMoveDeckCardToTableAgain(playerIndex: self.currentPlayerIndex)
            // 총통 검사 1 (10점)
            self.checkChongTong()
            
            // 테스트 한장씩 뺏어오기 테스트용
            for i in 0...8 {
                await self.moveDeckCardToPlayerCaptured(playerIndex: i % 3)
            }
        }
    }
    
//    private func nextTurn() {
//        if checkEnd() { return }
//        
//        if self.currentPlayerIndex == 0 {
//            busy = false
//        } else {
//            busy = true
//            DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {
//                self.aiTurn()
//            }
//        }
//    }
    
    private func aiTurn() {
        guard let card = players[currentPlayerIndex].handCards.randomElement() else { return }
        self.playWithSelectedHandCard(handCard: card)
    }
    
    // 총통 검사 2 (10점)
    private func checkChongTong()  {
        for (i, player) in self.players.enumerated() {
            for handCard in player.handCards {
                let sameMonthCards = player.handCards.filter({$0.month == handCard.month})
                
                if player.handCards.count == 7 && sameMonthCards.count == 4 {
                    self.showChongTongWinPopup(winnerIndex: i, cards: sameMonthCards)
                    self.collectMoney(nyang: 10)
                    return
                }
            }
        }
    }
    
    private func playWithSelectedHandCard(handCard: Card) {
        let player = players[currentPlayerIndex]
        let sameMonthPlayerHandCards = player.handCards.filter({$0.month == handCard.month}) //폭탄, 흔들기
        
        Task {
            // 선택카드가 bonus 카드인경우
            if handCard.month == 0 {
                await moveBonusPlayerHandBonusCardToPlayerCaptured(player: player, handCard: handCard)
                self.sortPlayerHandCards(playerIndex: currentPlayerIndex)
                // 총통 검사 2 (10점)
                self.checkChongTong()
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
                    PopupManager.shared.showPopup(popupData: self.popupData, type: .selectWave, cards: sameMonthPlayerHandCards, players: [player]) { select in
                        //  흔들기 선택
                        if select == 0 {
                            player.waveCount += 1
                            //  흔들기 확인 팝업 다시 보이기
                            PopupManager.shared.showPopup(popupData: self.popupData, type: .wave, cards: sameMonthPlayerHandCards, players: [player]) { select in
                                Task{
                                    await self.playWithNoMatchingCard(player: player, handCard: handCard, nextDeckCardExceptBonus: nextDeckCardExceptBonus)
                                }
                            }
                        }
                        else {
                            Task{
                                await self.playWithNoMatchingCard(player: player, handCard: handCard, nextDeckCardExceptBonus: nextDeckCardExceptBonus)
                            }
                        }
                    }
                }
                else {
                    await self.playWithNoMatchingCard(player: player, handCard: handCard, nextDeckCardExceptBonus: nextDeckCardExceptBonus)
                }
            case 1: // 매칭카드 1개
                // 폭탄
                if sameMonthPlayerHandCards.count == 3 {
                    PopupManager.shared.showPopup(popupData: self.popupData, type: .boom, cards: sameMonthPlayerHandCards, players: [player], completion: {_ in
                        Task{
                            await self.movePlayerHandCardsMatchingTableCardsToPlayerCaptured(player: player, handCards: sameMonthPlayerHandCards, matchingTableCards: matchingTableCards)
                            await self.collectPiCardsFromOthers(toPlayer: player, piCount: 2) {
                                Task{
                                    await self.moveBonusDeckCardsToPlayerCapturedIfNeeded(playerIndex: self.currentPlayerIndex)
                                    await self.flipDeckCardAfterBonusCard()
                                    await self.setEmptyPlayerHandCards(player: player, count: 2)
                                }
                            }
                        }
                    })
                }

                //덱카드 뻑 처리(첫뻑, 첫뻑후 연속뻑, 연속뻑3회, 막장 제외)
                else if nextDeckCardExceptBonus.month == handCard.month && player.handCards.count > 0 {
                    await self.movePlayerHandCardsToTable(player: player, handCards: [handCard])
                    let tableGroupIndex = self.getTableCardGroupIndex(cardMonth: handCard.month)
                    let fuckCards = [handCard, nextDeckCardExceptBonus] + matchingTableCards
                    await self.moveBonusDeckCardsToTable(tableGroupIndex: tableGroupIndex)
                    // await self.flipDeckCardAfterBonusCard() 가져가면 안됨
                    await self.moveDeckCardToTable()
                    
                    // 첫뻑
                    if player.handCards.count == 6 {
                        PopupManager.shared.showPopup(popupData: self.popupData, type: .firstFuck, cards: fuckCards, players: [player], completion: {_ in })
                        self.collectMoney(nyang: 5)
                    }
                    //  2연뻑
                    else if player.handCards.count == 5 && player.fuckCardMonths.count == 1 {
                        PopupManager.shared.showPopup(popupData: self.popupData, type: .secondFuck, cards: fuckCards, players: [player], completion: {_ in })
                        self.collectMoney(nyang: 10)
                    }
                    // 3번뻑 > 게임끝
                    else if player.fuckCardMonths.count == 2 {
                        self.showThirdFuckWinPopup(winnerIndex: self.currentPlayerIndex, cards: fuckCards)
                        self.collectMoney(nyang: 3)
                        return
                    }
                    else {
                        PopupManager.shared.showPopup(popupData: self.popupData, type: .fuck, cards: fuckCards, players: [player], completion: {_ in })
                    }
                    
                    player.fuckCardMonths.append(handCard.month)
                }
                else {
                    await movePlayerHandCardsMatchingTableCardsToPlayerCaptured(player: player, handCards: [handCard], matchingTableCards: matchingTableCards)
                    await self.moveBonusDeckCardsToPlayerCapturedIfNeeded(playerIndex: self.currentPlayerIndex)
                    await self.flipDeckCardAfterBonusCard()
                }
            case 2: // 매칭카드 2개
                // 따닥
                if nextDeckCardExceptBonus.month == handCard.month {
                    PopupManager.shared.showPopup(popupData: self.popupData, type: .ddadak, cards: [handCard, nextDeckCardExceptBonus] + matchingTableCards, players: [player], completion: { select in
                        Task {
                            await self.movePlayerHandCardsMatchingTableCardsToPlayerCaptured(player: player, handCards: [handCard], matchingTableCards: [matchingTableCards[0]])
                            await self.moveBonusDeckCardsToPlayerCapturedIfNeeded(playerIndex: self.currentPlayerIndex)
                            await self.flipDeckCardAfterBonusCard()
                            await self.collectPiCardsFromOthers(toPlayer: player, piCount: 1, completion: {})
                        }
                    })
                }
                // 카드선택
                else {
                    PopupManager.shared.showPopup(popupData: self.popupData, type: .selectCard, cards: [handCard] + matchingTableCards, players: [player], completion: { select in
                        Task {
                            await self.movePlayerHandCardsMatchingTableCardsToPlayerCaptured(player: player, handCards: [self.popupData.cards[0]], matchingTableCards: [self.popupData.cards[1]])
                            await self.moveBonusDeckCardsToPlayerCapturedIfNeeded(playerIndex: self.currentPlayerIndex)
                            await self.flipDeckCardAfterBonusCard()
                        }
                    })
                }
            case 3: // 매칭카드 3개
                // 3장 가져오기 ~ 한장씩 뺏기
                let isPlayerFuckCard = player.fuckCardMonths.first(where: { $0 == handCard.month }) != nil
                PopupManager.shared.showPopup(popupData: self.popupData, type: isPlayerFuckCard ? .threeTableCardsWithPlayerFuck : .threeTableCards, cards: [handCard] + matchingTableCards, players: [player], completion: { _ in
                    Task {
                        await self.movePlayerHandCardsMatchingTableCardsToPlayerCaptured(player: player, handCards: [handCard], matchingTableCards: matchingTableCards)
                        await self.collectPiCardsFromOthers(toPlayer: player, piCount: isPlayerFuckCard ? 2 : 1) {
                            Task{
                                await self.moveBonusDeckCardsToPlayerCapturedIfNeeded(playerIndex: self.currentPlayerIndex)
                                await self.flipDeckCardAfterBonusCard()
                            }
                        }
                    }
                })
            default: break
            }
            
            self.sortPlayerHandCards(playerIndex: currentPlayerIndex)
            //self.currentPlayerIndex = (self.currentPlayerIndex + 1) % 3
        }
    }
    
    private func setEmptyPlayerHandCards(player: Player, count: Int) async {
        let scaleRate = player.index == 0 ? CardNodeScale.normal.rawValue : CardNodeScale.small.rawValue
        let cardSize = CGSize(width: self.cardSize.width * scaleRate, height: self.cardSize.height * scaleRate)

        for i in 0..<count {
            let card = Card(month: self.emptyCardMonth, type: .gwang, imageName: "hwatu_empty")
            player.handCards.append(card)
            let node = CardNode(name: card.id.uuidString, card: card, cardSize: cardSize, isFront: true)
            node.position = self.getPlayerHandCardPosition(playerIndex: player.index, cardIndex: player.handCards.count)
            node.zPosition = self.deckZPosition + CGFloat(i)
            self.addChild(node)
        }
    }
    
    private func playWithNoMatchingCard(player: Player, handCard: Card, nextDeckCardExceptBonus: Card) async {
        let player = players[currentPlayerIndex]
        Task {
            // 폭탄빈카드는 그냥 제거하고 덱카드 뒤집기
            if handCard.month == self.emptyCardMonth {
                self.removePlayerHandCards(player: player, handCards: [handCard])
            }
            // 먼저 선택카드를 테이블에 내려놓기
            else {
                await self.movePlayerHandCardsToTable(player: player, handCards: [handCard])
            }
            
            // 덱 보너스 카드 처리 후 카드 뒤집기
            await self.moveBonusDeckCardsToPlayerCapturedIfNeeded(playerIndex: self.currentPlayerIndex)
            await self.flipDeckCardAfterBonusCard()
            
            // 쪽이면 > 쪽카드 받아가기 (막장 제외)
            if nextDeckCardExceptBonus.month == handCard.month && player.handCards.count > 0 {
                PopupManager.shared.showPopup(popupData: popupData, type: .kiss, cards: [handCard, nextDeckCardExceptBonus], players: [player]) { select in
                    Task {
                        await self.collectPiCardsFromOthers(toPlayer: player, piCount: 1) { }
                    }
                }
            }
        }
    }
    
    private func playWithOneMatchingCard(player: Player, handCard: Card, nextDeckCardExceptBonus: Card) async {
    }
    
    private func playWithTwoMatchingCard(player: Player, handCard: Card, nextDeckCardExceptBonus: Card) async {
    }
    
    private func playWithThreeMatchingCard(player: Player, handCard: Card, nextDeckCardExceptBonus: Card) async {
    }
    
    private func collectPiCardsFromOthers(toPlayer: Player, piCount: Int, completion: @escaping () -> Void) async {
        print("\(#function) 가져올 피 \(piCount)장")
        Task{
            await self.moveOtherPlayersCapturedCardsToPlayerCaptured(toPlayer: toPlayer, piCount: piCount)
            completion()
        }
    }
    
    private func collectMoney(nyang: Int) {
        print("\(#function) 가져올 돈 \(nyang)만냥")
    }
    
    private func showWinPopup(winnerIndex: Int) {
        self.winnerIndex = winnerIndex
        
        let winner = self.players[winnerIndex]
        let player1 = self.players[(winnerIndex + 1) % 3]
        let player2 = self.players[(winnerIndex + 2) % 3]
        player1.scoreText = "피박, 광박 -12만냥"
        player2.scoreText = "피박 -5만냥"
        
        PopupManager.shared.showPopup(popupData: self.popupData, type: .win, cards: [], players: [winner, player1, player2], message: "광3점, 피2점, 띠1점, 고1점 >  총점 25점" ,completion: { select in
            self.removeAllChildren()
        })
    }
    
    private func showChongTongWinPopup(winnerIndex: Int, cards: [Card]) {
        self.winnerIndex = winnerIndex
        
        let winner = self.players[winnerIndex]
        let player1 = self.players[(winnerIndex + 1) % 3]
        let player2 = self.players[(winnerIndex + 2) % 3]
        player1.scoreText = "-10만냥"
        player2.scoreText = "-10만냥"
        
        PopupManager.shared.showPopup(popupData: self.popupData, type: .chongtongWin, cards: cards, players: [winner, player1, player2], completion: { _ in
            self.removeAllChildren()
        })
    }
    
    private func showThirdFuckWinPopup(winnerIndex: Int, cards: [Card]) {
        self.winnerIndex = winnerIndex
        
        let winner = self.players[winnerIndex]
        let player1 = self.players[(winnerIndex + 1) % 3]
        let player2 = self.players[(winnerIndex + 2) % 3]
        player1.scoreText = "-3만냥"
        player2.scoreText = "-3만냥"
        
        PopupManager.shared.showPopup(popupData: self.popupData, type: .thirdFuckWin, cards: cards, players: [winner, player1, player2], completion: { _ in
            self.removeAllChildren()
        })
    }
    
    // 덱카드 뒤집기 (보너스카드 이후)
    private func flipDeckCardAfterBonusCard() async {
        let player = self.players[self.currentPlayerIndex]
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
            case 1: // 매칭카드 1개
                await self.moveDeckCardMatchingTableCardsToPlayerCaptured(player: player, matchingTableCards: matchingTableCards)
            case 2: // 매칭카드 2개
                PopupManager.shared.showPopup(popupData: self.popupData, type: .selectCard, cards: [deckCard] + matchingTableCards, players: [player], completion: { select in
                    Task {
                        await self.moveDeckCardMatchingTableCardsToPlayerCaptured(player: player, matchingTableCards: [self.popupData.cards[1]])
                        self.popupData.cards = []
                    }
                })
            case 3: // 매칭카드 3개
                //TODO:  3개 인경우 한장씩 뺏기
                let isPlayerFuckCard = player.fuckCardMonths.first(where: { $0 == deckCard.month }) != nil
                PopupManager.shared.showPopup(popupData: self.popupData, type: isPlayerFuckCard ? .threeTableCardsWithPlayerFuck : .threeTableCards, cards: [deckCard] + matchingTableCards, players: [player], completion: { _ in
                    Task {
                        await self.moveDeckCardMatchingTableCardsToPlayerCaptured(player: player, matchingTableCards: matchingTableCards)
                        await self.collectPiCardsFromOthers(toPlayer: player, piCount: isPlayerFuckCard ? 2 : 1) {
                            
                        }
                    }
                })
            default: break
            }
            
            self.sortPlayerHandCards(playerIndex: currentPlayerIndex)
        }
    }
    
    // Test : 한사람에게 카드 몰빵
    private func moveDeckCardToPlayerCaptured(playerIndex: Int) async {
        let deckCard = self.deckCards.removeLast()
        players[playerIndex].capture(card: deckCard)
        guard let deckCardNode = childNode(withName: deckCard.id.uuidString) as? CardNode else { return }
        let cardIndexByType = players[playerIndex].getCapturedCardIndexByType(card: deckCard)
        let movePosition = self.getPlayerCapturedCardPosition(playerIndex: playerIndex, cardIndexByType: cardIndexByType, cardType: deckCard.type)
        deckCardNode.moveAndTurnCard(movePosition: movePosition, duration: cardDuration, isFront: true, zPosition: cardIndexByType, afterCardNodeScale: .normal)
        
        do { try await Task.sleep(for: .seconds(cardDuration))
        } catch { print("error: \(error)")}
    }
    
    private func moveDeckCardMatchingTableCardsToPlayerCaptured(player: Player, matchingTableCards: [Card]) async {
        let deckCard = deckCards.removeLast()
        let tableGroupIndex = self.getTableCardGroupIndex(cardMonth: matchingTableCards.last!.month)
        
        guard let deckCardNode = childNode(withName: deckCard.id.uuidString) as? CardNode else { return }
        guard let matchingTableCardNode = childNode(withName: matchingTableCards.last!.id.uuidString) as? CardNode else { return }
        var matchPosition = matchingTableCardNode.position
        matchPosition.x += 10
        matchPosition.y -= 10
        
        deckCardNode.moveAndTurnCard(movePosition: matchPosition, duration: cardDuration, isFront: true, zPosition: 0, afterCardNodeScale: .large)
        do { try await Task.sleep(for: .seconds(cardDuration))
        } catch { print("error: \(error)")}
        
        // 국진 위치
        if self.isGukjinCard(card: deckCard) {
            PopupManager.shared.showPopup(popupData: self.popupData, type: .selectGukjin, cards: [deckCard], players: [player]) { select in
                //  쌍피 선택
                if select == 0 {
                    self.moveEveryCardToPlayerCaptured(player: player, card: deckCard, forcedType: .pi)
                    self.sortTableCardGroup(tableGroupIndex: tableGroupIndex)
                }
                // 열끗 선택
                else {
                    self.moveEveryCardToPlayerCaptured(player: player, card: deckCard)
                    self.sortTableCardGroup(tableGroupIndex: tableGroupIndex)
                }
            }
        }
        else {
            self.moveEveryCardToPlayerCaptured(player: player, card: deckCard)
        }
        
        for matchingTableCard in matchingTableCards {
            self.removeTableCard(card: matchingTableCard)
            // 국진 위치
            if self.isGukjinCard(card: deckCard) {
                PopupManager.shared.showPopup(popupData: self.popupData, type: .selectGukjin, cards: [deckCard], players: [player]) { select in
                    guard let matchingTableCardNode = self.childNode(withName: matchingTableCard.id.uuidString) as? CardNode else { return }
                    //  쌍피 선택
                    if select == 0 {
                        self.moveEveryCardToPlayerCaptured(player: player, card: matchingTableCard, forcedType: .pi)
                        self.sortTableCardGroup(tableGroupIndex: tableGroupIndex)
                    }
                    // 열끗 선택
                    else {
                        self.moveEveryCardToPlayerCaptured(player: player, card: matchingTableCard)
                        self.sortTableCardGroup(tableGroupIndex: tableGroupIndex)
                    }
                }
            }
            else {
                self.moveEveryCardToPlayerCaptured(player: player, card: matchingTableCard)
            }
        }
        // 테이블 바닥카드 가져갈때 위치값 비워줌
        self.sortTableCardGroup(tableGroupIndex: tableGroupIndex)
        do { try await Task.sleep(for: .seconds(cardDuration))
        } catch { print("error: \(error)")}
    }
    
    private func moveEveryCardToPlayerCaptured(player: Player, card: Card, forcedType: CardType? = nil) {
        guard let cardNode = self.childNode(withName: card.id.uuidString) as? CardNode else { return }
        player.capture(card: card, forcedType: forcedType)
        let cardIndexByType = player.getCapturedCardIndexByType(card: card, forcedType: forcedType)
        let movePosition = self.getPlayerCapturedCardPosition(playerIndex: player.index, cardIndexByType: cardIndexByType, cardType: forcedType ?? card.type)
        cardNode.moveAndTurnCard(movePosition: movePosition, duration: cardDuration, isFront: true, zPosition: cardIndexByType, afterCardNodeScale: .normal)
    }
    
    private func isGukjinCard(card: Card) -> Bool {
        return card.month == 9 && card.type == .animal
    }
    
    private func moveBonusPlayerHandBonusCardToPlayerCaptured(player: Player, handCard: Card) async {
        guard let handCardNode = childNode(withName: handCard.id.uuidString) as? CardNode else { return }
        // 가지고 있는 카드를 수집카드로// 손에서 비움
        player.handCards.removeAll { $0.id == handCard.id }
        player.capture(card: handCard)
        
        // captured로 이동
        let cardIndexByType = player.getCapturedCardIndexByType(card: handCard)
        let movePosition = self.getPlayerCapturedCardPosition(playerIndex: player.index, cardIndexByType: cardIndexByType, cardType: handCard.type)
        handCardNode.moveAndTurnCard(movePosition: movePosition, duration: cardDuration, isFront: true, zPosition: cardIndexByType, afterCardNodeScale: .normal)
        do { try await Task.sleep(for: .seconds(cardDuration))
        } catch { print("error: \(error)")}
        
        // 덱에서 카드 한장 새로 받기
        await self.moveDeckCardToPlayerHand(playerIndex: player.index, cardIndex: player.handCards.count)
        do { try await Task.sleep(for: .seconds(cardDuration))
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
    
    private func moveDeckCardToTable() async {
        guard let deckCardNode = childNode(withName: deckCards.last?.id.uuidString ?? "") as? CardNode else { return }
        let groupIndex = self.getTableCardGroupIndex(cardMonth: deckCardNode.card.month)
        let cardIndexByGroup = self.tableCardGroups[groupIndex].count
        let zPosition = self.getTableCardZPosition(groupIndex: groupIndex, cardIndexByGroup: cardIndexByGroup)
        let lastDeckCard = self.deckCards.removeLast()
        self.addTableCard(card: lastDeckCard)
        let movePosition = self.getTableCardPosition(groupIndex: groupIndex, cardIndexByGroup: cardIndexByGroup)
        deckCardNode.moveAndTurnCard(movePosition: movePosition, duration: cardDuration, isFront: true, zPosition: Int(zPosition),afterCardNodeScale: .large)
        do { try await Task.sleep(for: .seconds(cardDuration))
        } catch { print("error: \(error)")}
    }
    
    private func movePlayerHandCardsMatchingTableCardsToPlayerCaptured(player: Player, handCards: [Card], matchingTableCards: [Card]) async {
        let tableCardGroupIndex = self.getTableCardGroupIndex(cardMonth: matchingTableCards.last!.month)
        
        for (i, handCard) in handCards.enumerated() {
            guard let handCardNode = childNode(withName: handCard.id.uuidString) as? CardNode else { return }
            guard let matchingTableCardNode = childNode(withName: matchingTableCards.last!.id.uuidString) as? CardNode else { return }

            var matchPosition = matchingTableCardNode.position
            matchPosition.x += CGFloat(10 * i)
            matchPosition.y -= CGFloat(10 * i)
            handCardNode.moveAndTurnCard(movePosition: matchPosition, duration: cardDuration, isFront: true, afterCardNodeScale: .normal)
        }
        
        do { try await Task.sleep(for: .seconds(cardDuration))
        } catch { print("error: \(error)")}
        
        let cardIndexByType = player.getCapturedCardIndexByType(card: handCards[0])
        
        for handCard in handCards {
            player.handCards.removeAll { $0.id == handCard.id }
            
            // 국진 위치
            if self.isGukjinCard(card: handCard) {
                PopupManager.shared.showPopup(popupData: self.popupData, type: .selectGukjin, cards: [handCard], players: [player]) { select in
                    //  쌍피 선택
                    if select == 0 {
                        self.moveEveryCardToPlayerCaptured(player: player, card: handCard, forcedType: .pi)
                        self.sortTableCardGroup(tableGroupIndex: tableCardGroupIndex)
                    }
                    // 열끗 선택
                    else {
                        self.moveEveryCardToPlayerCaptured(player: player, card: handCard)
                        self.sortTableCardGroup(tableGroupIndex: tableCardGroupIndex)
                    }
                }
            }
            else {
                self.moveEveryCardToPlayerCaptured(player: player, card: handCard)
            }
        }
        
        for matchingTableCard in matchingTableCards {
            self.removeTableCard(card: matchingTableCard)
            
            // 국진 위치
            if self.isGukjinCard(card: matchingTableCard) {
                PopupManager.shared.showPopup(popupData: self.popupData, type: .selectGukjin, cards: [matchingTableCard], players: [player]) { select in
                    //  쌍피 선택
                    if select == 0 {
                        self.moveEveryCardToPlayerCaptured(player: player, card: matchingTableCard, forcedType: .pi)
                        self.sortTableCardGroup(tableGroupIndex: tableCardGroupIndex)
                    }
                    // 열끗 선택
                    else {
                        self.moveEveryCardToPlayerCaptured(player: player, card: matchingTableCard)
                        self.sortTableCardGroup(tableGroupIndex: tableCardGroupIndex)
                    }
                }
            }
            else {
                self.moveEveryCardToPlayerCaptured(player: player, card: matchingTableCard)
            }
        }
        
        self.sortTableCardGroup(tableGroupIndex: tableCardGroupIndex)
        
        do { try await Task.sleep(for: .seconds(cardDuration))
        } catch { print("error: \(error)")}
    }
    
    // 테이블 바닥카드 가져갈때 해당 그룹 정렬
    private func sortTableCardGroup(tableGroupIndex: Int) {
        for (i, card) in tableCardGroups[tableGroupIndex].enumerated() {
            guard let cardNode = childNode(withName: card.id.uuidString) as? CardNode else { continue }
            let zPosition = self.getTableCardZPosition(groupIndex: tableGroupIndex, cardIndexByGroup: i)
            let movePosition = self.getTableCardPosition(groupIndex: tableGroupIndex, cardIndexByGroup: i)
            cardNode.moveAndTurnCard(movePosition: movePosition, isFront: true, zPosition: zPosition, movingUpScale: nil, afterCardNodeScale: .large)
        }
    }
    
    private func moveDeckCardToPlayerHand(playerIndex: Int, cardIndex: Int) async {
        guard let deckCardNode = childNode(withName: deckCards.last?.id.uuidString ?? "") as? CardNode else { return }
        let lastDeckCard = self.deckCards.removeLast()
        self.players[playerIndex].handCards.append(lastDeckCard)
        let movePosition = self.getPlayerHandCardPosition(playerIndex: playerIndex, cardIndex: cardIndex)
        deckCardNode.moveAndTurnCard(movePosition: movePosition, duration: cardDuration, isFront: playerIndex == 0, afterCardNodeScale: playerIndex == 0 ? .large : .small)
        do { try await Task.sleep(for: .seconds(cardDuration))
        } catch { print("error: \(error)")}
    }
    
    private func movePlayerHandCardsToTable(player: Player, handCards: [Card]) async {
        let groupIndex = self.getTableCardGroupIndex(cardMonth: handCards[0].month)
        let cardIndexByGroup = self.tableCardGroups[groupIndex].count
        
        for (i, handCard) in handCards.enumerated() {
            guard let handCardNode = childNode(withName: handCard.id.uuidString) as? CardNode else { return }
            player.handCards.removeAll { $0.id == handCard.id }
            
            let zPosition = self.getTableCardZPosition(groupIndex: groupIndex, cardIndexByGroup: cardIndexByGroup + i)
            self.addTableCard(card: handCard)
            let movePosition = self.getTableCardPosition(groupIndex: groupIndex, cardIndexByGroup: cardIndexByGroup + i)

            handCardNode.moveAndTurnCard(movePosition: movePosition, duration: cardDuration, isFront: true, zPosition: zPosition, afterCardNodeScale: .large)
        }
        
        do { try await Task.sleep(for: .seconds(cardDuration))
        } catch { print("error: \(error)")}
    }
    
    private func removePlayerHandCards(player: Player, handCards: [Card]) {
        var handCardNodes: [SKNode] = []
        for handCard in handCards {
            guard let handCardNode = childNode(withName: handCard.id.uuidString) as? CardNode else { return }
            handCardNodes.append(handCardNode)
            player.handCards.removeAll { $0.id == handCard.id }
        }
        self.removeChildren(in: handCardNodes)
    }
    
    private func sortPlayerHandCards(playerIndex: Int) {
        players[playerIndex].handCards.sort { (card1, card2) -> Bool in
            if card1.month < card2.month { return true }
            else if card1.month > card2.month { return false }
            else { return card1.type.rawValue > card2.type.rawValue }
        }
        for (i, handCard) in players[playerIndex].handCards.enumerated() {
            guard let handCardNode = childNode(withName: handCard.id.uuidString) as? CardNode else { return }
            let movePosition = self.getPlayerHandCardPosition(playerIndex: playerIndex, cardIndex: i)
            // 동일위치 다시 그리기 방지 (위치값 소숫점 미세하게 변경 무시)
            if Int(movePosition.x) == Int(handCardNode.position.x) && Int(movePosition.y) == Int(handCardNode.position.y) {
                //print("\(#function) same positioin \(i)")
            }
            else {
                //print("\(#function) different positioin \(i) current(\(handCardNode.position.x),\(handCardNode.position.y)),target(\(movePosition.x),\(movePosition.y))")
                handCardNode.moveAndTurnCard(movePosition: movePosition, duration: cardDuration, isFront: playerIndex == 0, movingUpScale: nil, afterCardNodeScale: playerIndex == 0 ? .large : .small)
            }
        }
    }
    
    private func sortPlayerCapturedPiCards(player: Player) {
        for capturedCard in player.capturedCardTypeGroup[3] {
            guard let capturedCardNode = childNode(withName: capturedCard.id.uuidString) as? CardNode else { return }
            let cardIndexByType = player.getCapturedCardIndexByType(card: capturedCard)
            let movePosition = self.getPlayerCapturedCardPosition(playerIndex: player.index, cardIndexByType: cardIndexByType, cardType: capturedCard.type)
            // 동일위치 다시 그리기 방지 (위치값 소숫점 미세하게 변경 무시)
            if Int(movePosition.x) == Int(capturedCardNode.position.x) && Int(movePosition.y) == Int(capturedCardNode.position.y) {
                //print("\(#function) same positioin \(i)")
            }
            else {
                //print("\(#function) different positioin \(i) current(\(handCardNode.position.x),\(handCardNode.position.y)),target(\(movePosition.x),\(movePosition.y))")
                capturedCardNode.moveAndTurnCard(movePosition: movePosition, duration: cardDuration, isFront: true, movingUpScale: nil, afterCardNodeScale: .normal)
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
                    guard let tableCardNode = childNode(withName: tableCard.id.uuidString) as? CardNode else { return  }
                    let tableGroupIndex = self.getTableCardGroupIndex(cardMonth: tableCard.month)
                    self.removeTableCard(card: tableCard)
                    self.players[winnerIndex].capture(card: tableCard)
                    
                    let cardIndexByType = players[playerIndex].getCapturedCardIndexByType(card: tableCard)
                    let movePosition = self.getPlayerCapturedCardPosition(playerIndex: playerIndex, cardIndexByType: cardIndexByType, cardType: tableCard.type)
                    tableCardNode.moveAndTurnCard(movePosition: movePosition, duration: cardDuration, isFront: true, zPosition: cardIndexByType, afterCardNodeScale: .normal)
                    self.sortTableCardGroup(tableGroupIndex: tableGroupIndex)
                    
                    do { try await Task.sleep(for: .seconds(cardDuration))
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
    private func moveBonusDeckCardsToPlayerCapturedIfNeeded(playerIndex: Int) async  {
        for i in (0..<self.deckCards.count).reversed() {
            let deckCard = self.deckCards[i]
            if deckCard.month == 0 {
                // table에서 제거하고 winner에게 지급
                guard let deckCardNode = childNode(withName: deckCard.id.uuidString) as? CardNode else { return  }
                self.deckCards.remove(at: i)
                self.players[playerIndex].capture(card: deckCard)
                
                let cardIndexByType = players[self.currentPlayerIndex].getCapturedCardIndexByType(card: deckCard)
                let movePosition = self.getPlayerCapturedCardPosition(playerIndex: playerIndex, cardIndexByType: cardIndexByType, cardType: deckCard.type)
                deckCardNode.moveAndTurnCard(movePosition: movePosition, duration: cardDuration, isFront: true, zPosition: cardIndexByType, afterCardNodeScale: .normal)
                
                do { try await Task.sleep(for: .seconds(cardDuration))
                } catch { print("error: \(error)")}
            }
            else {
                return
            }
        }
    }

    private func moveOtherPlayersCapturedCardsToPlayerCaptured(toPlayer: Player, piCount: Int) async  {
        for (i, anotherPlayer) in self.players.enumerated() {
            if anotherPlayer.index == toPlayer.index { continue }
            
            let doublePi: Card? = anotherPlayer.capturedCardTypeGroup[3].last{ $0.isDoublePi == true }
            let onePis: [Card] = anotherPlayer.capturedCardTypeGroup[3].filter{ $0.isDoublePi == false }.suffix(2) // 뒤에 쌍피가 아닌 일반피 두개 가져오기
            
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
                anotherPlayer.capturedCardTypeGroup[3].removeAll { $0.id == movingCard.id }
                toPlayer.capture(card: movingCard)
                
                guard let deckCardNode = childNode(withName: movingCard.id.uuidString) as? CardNode else { return  }
                let cardIndexByType = toPlayer.getCapturedCardIndexByType(card: movingCard)
                let movePosition = self.getPlayerCapturedCardPosition(playerIndex: toPlayer.index, cardIndexByType: cardIndexByType, cardType: movingCard.type)
                deckCardNode.moveAndTurnCard(movePosition: movePosition, duration: cardDuration, isFront: true, zPosition: cardIndexByType, afterCardNodeScale: .normal)
            }
            
            self.sortPlayerCapturedPiCards(player: anotherPlayer)
        }
        
        do { try await Task.sleep(for: .seconds(cardDuration))
        } catch { print("error: \(error)")}
    }
    
    private func moveBonusDeckCardsToTable(tableGroupIndex: Int) async  {
        for i in (0..<self.deckCards.count).reversed() {
            let deckCard = self.deckCards[i]
            if deckCard.month == 0 {
                // table에서 제거하고 winner에게 지급
                guard let deckCardNode = childNode(withName: deckCard.id.uuidString) as? CardNode else { return  }
                let cardIndexByGroup = self.tableCardGroups[tableGroupIndex].count
                let zPosition = self.getTableCardZPosition(groupIndex: tableGroupIndex, cardIndexByGroup: cardIndexByGroup)
                self.deckCards.removeLast()
                //self.addTableCard(card: lastDeckCard) > 보너스카드는 직접 넣어줌
                self.tableCardGroups[tableGroupIndex].append(deckCard)
                
                let movePosition = self.getTableCardPosition(groupIndex: tableGroupIndex, cardIndexByGroup: self.tableCardGroups[tableGroupIndex].count - 1)
                deckCardNode.moveAndTurnCard(movePosition: movePosition, duration: cardDuration, isFront: true, zPosition: cardIndexByGroup, afterCardNodeScale: .normal)
                
                do { try await Task.sleep(for: .seconds(cardDuration))
                } catch { print("error: \(error)")}
            }
            else {
                return
            }
        }
    }
    
    
    private func getTableCardGroupIndex(cardMonth: Int) -> Int {
        for (i, tableCardGroup) in tableCardGroups.enumerated() {
            
            if let card  = tableCardGroup.first {
                if card.month == cardMonth {
                    return i
                }
            }
        }
        // 없으면 첫뻔째 빈그룹을 줘야 함
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
            for card in tableCardGroup {
                if card.month == cardMonth {
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
    
    private func addTableCard(card: Card) {
        let index = self.getTableCardGroupIndex(cardMonth: card.month)
        self.tableCardGroups[index].append(card)
    }
    
    private func score(_ p: Player) -> Int {
        var s = 0
        if p.piCount >= 10 { s += p.piCount - 9 }
        if p.danCount >= 5 { s += p.danCount - 4 }
        if p.animalCount >= 5 { s += p.animalCount - 4 }
        if p.gwangCount == 3 { s += 3 }
        if p.gwangCount == 4 { s += 4 }
        if p.gwangCount == 5 { s += 15 }
        return s
    }
    
    private func initDeckCardNode() {
        let startX = round(size.width / 2)
        let startY = round(size.height / 2)
        
        for i in 0 ..< deckCards.count {
            let node = CardNode(name: deckCards[i].id.uuidString, card: deckCards[i], cardSize: cardSize, isFront: true)
            node.position = CGPoint(x: startX + CGFloat(i), y: startY - CGFloat(i))
            node.zPosition = self.deckZPosition + CGFloat(i)
            self.addChild(node)
            
            let scaleAction = SKAction.scale(to: CardNodeScale.large.rawValue, duration: 0)
            node.run(scaleAction)
        }
    }
    
    private func getTableCardPosition(groupIndex: Int, cardIndexByGroup: Int) -> CGPoint {
        //print("\(#function): \(groupIndex), \(cardIndexByGroup)")
        let centerX = size.width / 2
        let cardWidthWithGap = self.cardSize.width * CardNodeScale.large.rawValue + self.cardGap
        let sp = CGFloat(cardIndexByGroup) * self.cardLayeredGap * CardNodeScale.large.rawValue
        if groupIndex % 2 == 0 {
            return CGPoint(x:centerX - cardWidthWithGap / 2 - cardWidthWithGap * CGFloat(groupIndex / 2 + 1) + sp, y: self.size.height / 2 - sp)
        }
        else {
            return CGPoint(x:centerX + cardWidthWithGap / 2 + cardWidthWithGap * round(CGFloat(groupIndex / 2 + 1)) + sp, y: self.size.height / 2 - sp)
        }
    }
    
    private func getPlayerHandCardPosition(playerIndex: Int, cardIndex: Int) -> CGPoint {
        let cardNodeScale = playerIndex == 0 ? CardNodeScale.large.rawValue : CardNodeScale.small.rawValue
        let cardWidthWithGap = self.cardSize.width * cardNodeScale + self.cardGap
        var startPosition: CGPoint = .zero // 좌측 하단이 시작점

        if playerIndex == 0 {
            startPosition.x = self.size.width / 2 + self.cardGap
            startPosition.y = self.cardGap
        }
        else if let playerLabelNode = self.childNode(withName: "playerLabelNode_\(playerIndex)") as? SKLabelNode {
            startPosition.x = playerLabelNode.position.x + (playerLabelNode.bounds.size.width / 2) + self.cardGap
            startPosition.y = playerLabelNode.position.y - (self.cardSize.height * cardNodeScale) - self.cardGap
        }
        else {
            print("\(#function) empty childNode: playerLabelNode_\(playerIndex)")
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
        position.x = startPosition.x  + (cardSize.width / 2) + (cardSize.width / 2.5) * CGFloat(cardIndexByType) + ( cardType == .dan ? self.size.width / 5 : 0)
        position.y = startPosition.y + (cardSize.height / 2) + cardHeightWithGap * (cardType == .gwang ? 2.0 : cardType == .pi ? 0.0 : 1.0)
        return position
    }
    
    private func setPlayer(player: Player) {
        let cardHeightWithGap = self.cardSize.height + self.cardGap
        var startPosition: CGPoint = .zero // 좌측 하단이 시작점
        let playerAreaNode = SKShapeNode(circleOfRadius: player.index == 0 ? self.size.width : self.size.width / 2 )
        let playerLabelNode = SKLabelNode(fontNamed: "System")
        playerLabelNode.name = "playerLabelNode_\(player.index)"
        playerLabelNode.text = player.name + " (\(player.money)만냥)"
        playerLabelNode.fontSize = 18
        
        switch player.index {
        case 1:
            startPosition.x = (self.size.width / 2) + self.cardGap
            startPosition.y = self.size.height - self.cardSize.height - self.cardGap
            playerAreaNode.position.x = 0
            playerAreaNode.position.y = self.size.height * 4 / 3
        case 2:
            startPosition.x = self.cardGap
            startPosition.y = self.size.height - self.cardSize.height - self.cardGap
            playerAreaNode.position.x = self.size.width
            playerAreaNode.position.y = self.size.height * 4 / 3
        default: // user
            startPosition.x = (self.size.width - self.playerImageSize.width - playerLabelNode.frame.width) / 2
            startPosition.y = cardHeightWithGap * 2 + (self.playerImageSize.height / 2) + self.cardGap
            playerAreaNode.position.x = self.size.width / 2
            playerAreaNode.position.y = -self.size.height * 1.5
        }
        
        playerAreaNode.fillColor = .white.withAlphaComponent(0.1)
        playerAreaNode.strokeColor = .clear
        playerAreaNode.zPosition = -100
        addChild(playerAreaNode)

        let playerImageNode = SKSpriteNode(imageNamed: player.imageName ?? "player_unkown")
        playerImageNode.name = "playerImageNode_\(player.index)"
        playerImageNode.size = self.playerImageSize
        let playerImageMaskPath = UIBezierPath(roundedRect: playerImageNode.frame, cornerRadius: self.cardSize.width / 2)
        let playerImageMaskNode = SKShapeNode(path: playerImageMaskPath.cgPath)
        playerImageMaskNode.name = "playerImageMaskNode_\(player.index)"
        playerImageMaskNode.fillColor = .black
        playerImageMaskNode.strokeColor = .white
        playerImageMaskNode.lineWidth = 2
        let playerImageCropNode = SKCropNode()
        playerImageCropNode.name = "playerCropNode_\(player.index)"
        playerImageCropNode.maskNode = playerImageMaskNode
        playerImageCropNode.addChild(playerImageNode)
        playerImageCropNode.position.x = startPosition.x + self.playerImageSize.height / 2
        playerImageCropNode.position.y = startPosition.y + self.playerImageSize.height / 2
        addChild(playerImageCropNode)
    
        playerLabelNode.position.x = startPosition.x + self.playerImageSize.width + playerLabelNode.bounds.width / 2
        playerLabelNode.position.y = startPosition.y + (player.index == 0 ? 0.0 : self.playerImageSize.height / 2)
        self.addChild(playerLabelNode)
    }
    
    private func setPlayers() {
        let range = 0...20
        let randomThree = range.shuffled()
        
        for i in 0...2 {
            let randomIndex = randomThree[i]
            self.players[i].charactorIndex = randomIndex
            self.players[i].name = GameScene.playerNames[randomIndex]
            self.players[i].imageName = "player_" + String(format: "%02d", randomThree[i])
            self.setPlayer(player: players[i])
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard currentPlayerIndex == 0 else { return }
        
        let loc = touches.first!.location(in: self)
        
        for n in nodes(at: loc) {
            if let cardNode = n as? CardNode {
                
                if currentPlayerIndex == 0, let handCard = self.players[currentPlayerIndex].handCards.first(where: { $0.id == cardNode.card.id }) {
                    self.playWithSelectedHandCard(handCard: handCard)
                }
                else {
                    print("\(#function) not your turn nor your card")
                }
            }
        }
    }
}
