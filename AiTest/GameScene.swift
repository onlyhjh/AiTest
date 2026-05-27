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
    
    private let cardDuration: Double = 0.3
    
    init(size: CGSize, gameData: GameData) {
        self.gameData = gameData
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
        /*
        guard let box = movingBox else { return }
        
        // 1. SwiftUI에서 변경한 속도(boxSpeed)를 실시간으로 적용해 박스를 움직임
        box.position.x += gameData.boxSpeed
        if box.position.x > frame.width { box.position.x = 0 }
        
        // 2. SwiftUI에서 변경한 색상(boxColor)을 실시간으로 노드에 반영
        // (UI적인 변환은 메인 스레드 안전을 위해 비동기 처리하는 것이 좋습니다)
        DispatchQueue.main.async {
            box.color = UIColor(self.gameData.boxColor)
        }
        */
        //print("update gameStatus: \(gameData.gameStatus)")
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
            
            // Test 특정카드 사용자에게
//            for (i, card) in self.deckCards.enumerated().reversed() {
//                if card.type == .pi && card.month == 7 && card.piNum == 0 {
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
        self.playWithSelectHandCard(handCard: card)
    }
    
    private func playWithSelectHandCard(handCard: Card) {
        let player = players[currentPlayerIndex]
        
        Task {
            // 선택카드가 bonus 카드인경우
            if handCard.month == 0 {
                await moveBonusPlayerHandBonusCardToPlayerChaptured(player: player, handCard: handCard)
                self.sortPlayerHandCards(playerIndex: currentPlayerIndex)
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
            print("handCard : \(handCard.month), \(handCard.type), nextDeckCardExceptBonus: \(nextDeckCardExceptBonus.month), \(nextDeckCardExceptBonus.type)")
            for card in matchingTableCards {
                print("... matchingTableCard: \(card.month), \(card.type)")
            }

            switch matchingTableCards.count {
            case 0: // 매칭카드 없는 경우
                //먼저 선택카드를 테이블에 내려놓기
                await self.movePlayerHandCardToTable(player: player, handCard: handCard)
                // 덱 보너스 카드 처리 후 카드 뒤집기
                await self.moveBonusDeckCardsToPlayerCapturedIfNeeded(playerIndex: self.currentPlayerIndex)
                await self.flipDeckCardAfterBonusCard()
                
                // 쪽이면 > 쪽카드 받아가기 (막장 제외)
                if nextDeckCardExceptBonus.month == handCard.month && player.handCards.count > 0 {
                    //TODO: 한장씩 받아오기
                    self.gameData.popupTitle = "😘 쪽!!!"
                    self.gameData.popupMessage = "한장씩 내놔~"
                    self.gameData.popupCards = [handCard, nextDeckCardExceptBonus]
                    self.gameData.gameStatus = .showOneSecMessagePopup
                    self.collectOnePiCardFromOtherPlayer()
                }
            case 1: // 매칭카드 1개
                //덱카드 뒤집을때 경우 뻑 처리(첫뻑, 첫뻑후 연속뻑, 연속뻑3회, 막장 제외)
                if nextDeckCardExceptBonus.month == handCard.month && player.handCards.count > 0 {
                    await self.movePlayerHandCardToTable(player: player, handCard: handCard)
                    let tableGroupIndex = self.getTableCardGroupIndex(cardMonth: handCard.month)
                    await self.moveBonusDeckCardsToTable(tableGroupIndex: tableGroupIndex)
                    // await self.flipDeckCardAfterBonusCard() 가져가면 안됨
                    await self.moveDeckCardToTable()
                    
                    // 첫뻑
                    if player.handCards.count == 6 {
                        self.gameData.popupTitle = "😂 첫뻑!!!"
                        self.gameData.popupMessage = "웃프다~ 일단 돈 받자~"
                        self.collectMoney()
                    }
                    //  2연뻑
                    else if player.handCards.count == 5 && player.fuckCardMonths.count == 1 {
                        self.gameData.popupTitle = "😂 첫뻑 후 2연속 뻑!!!"
                        self.gameData.popupMessage = "대단하다~ 일단 따블로 돈 받자~"
                        self.collectMoney()
                    }
                    else if player.fuckCardMonths.count == 2 {
                        self.gameData.popupTitle = "😂 뻑 3번 승!!!"
                        self.gameData.popupMessage = "뭐여 이건~"
                        self.gameData.completion = { self.showWinner() }
                        self.collectMoney()
                    }
                    else {
                        self.gameData.popupTitle = "🤯 뻑!!!"
                        self.gameData.popupMessage = "아놔~"
                    }
                    
                    self.gameData.popupCards = [handCard, nextDeckCardExceptBonus]
                    self.gameData.popupCards.append(contentsOf: matchingTableCards)
                    self.gameData.gameStatus = .showOneSecMessagePopup
                    player.fuckCardMonths.append(handCard.month)
                    
                    if player.fuckCardMonths.count == 3 {
                        self.removeAllChildren()
                    }
                }
                else {
                    await movePlayerHandCardMatchingTableCardToPlayerChaptured(player: player, handCard: handCard, matchingTableCards: matchingTableCards)
                    await self.moveBonusDeckCardsToPlayerCapturedIfNeeded(playerIndex: self.currentPlayerIndex)
                    await self.flipDeckCardAfterBonusCard()
                }
            case 2: // 매칭카드 2개
                //TODO: 덱카드 뒤집을때 따닥 처리, 카드 선택
                if nextDeckCardExceptBonus.month == handCard.month {
                    self.gameData.popupMessage = "🤩 따닥!!!"
                    self.gameData.popupMessage = "한장씩 내놔~"
                    self.gameData.popupCards = [handCard, nextDeckCardExceptBonus]
                    self.gameData.popupCards.append(contentsOf: matchingTableCards)
                    self.gameData.gameStatus = .showOneSecMessagePopup
                }
                //TODO: 카드선택
                else {
                    self.gameData.popupTitle = "🥸 카드 선택!!!"
                    self.gameData.popupMessage = "가져올 카드를 선택해 주세요"
                    self.gameData.popupCards = [handCard]
                    self.gameData.popupCards.append(contentsOf: matchingTableCards)
                    self.gameData.completion = {
                        Task {
                            await self.movePlayerHandCardMatchingTableCardToPlayerChaptured(player: player, handCard: self.gameData.popupCards[0], matchingTableCards: [self.gameData.popupCards[1]])
                            await self.moveBonusDeckCardsToPlayerCapturedIfNeeded(playerIndex: self.currentPlayerIndex)
                            await self.flipDeckCardAfterBonusCard()
                            self.gameData.popupCards = []
                        }
                    }
                    self.gameData.gameStatus = .showSelectCardPopup
                }
                //TODO: 덱카드 뒤집을때 따닥 처리, 카드 선택
            case 3: // 매칭카드 3개
                //TODO:  쓸~ 한장씩 뺏기
                self.gameData.popupTitle = "🥳 아싸 쓸!!!"
                self.gameData.popupMessage = "한장씩 내놔~"
                self.gameData.popupCards = [handCard]
                self.gameData.popupCards.append(contentsOf: matchingTableCards)
                self.gameData.gameStatus = .showOneSecMessagePopup
                await movePlayerHandCardMatchingTableCardToPlayerChaptured(player: player, handCard: handCard, matchingTableCards: matchingTableCards)
            default: break
            }
            
            self.sortPlayerHandCards(playerIndex: currentPlayerIndex)
            //self.currentPlayerIndex = (self.currentPlayerIndex + 1) % 3
        }
    }
    
    private func collectOnePiCardFromOtherPlayer() {
        
    }
    
    private func collectMoney() {
        
    }
    
    private func showWinner() {
        self.winnerIndex = self.currentPlayerIndex
        self.gameData.popupTitle = "🥳 아싸 승!!!"
        self.gameData.popupMessage = "광3점, 피2점, 띠1점, 고1점 >  총점 25점"
        let winner = self.players[winnerIndex]
        let player1 = self.players[(winnerIndex + 1) % 3]
        let player2 = self.players[(winnerIndex + 2) % 3]
        player1.scoreText = "피박, 광박 -12만원"
        player2.scoreText = "피박 -5만원"
        self.gameData.players = [winner, player1, player2]
        self.gameData.gameStatus = .showWinnerPopup
    }
    
    // 덱카드 뒤집기 (보너스카드 이후)
    private func flipDeckCardAfterBonusCard() async {
        let player = self.players[self.currentPlayerIndex]
        guard let deckCard = self.deckCards.last else { return }
        
        Task {
            // 매칭카드가 갯수에 따른 처리
            let matchingTableCards = self.getMatchingTableCards(cardMonth: deckCard.month)
            print("deckCard : \(deckCard.month), \(deckCard.type)")
            for card in matchingTableCards {
                print("... matchingTableCard: \(card.month), \(card.type)")
            }
            
            switch matchingTableCards.count {
            case 0: // 매칭카드 없는 경우
                await self.moveDeckCardToTable()
            case 1: // 매칭카드 1개
                await self.moveDeckCardMatchingTableCardToPlayerChaptured(player: player, matchingTableCards: matchingTableCards)
            case 2: // 매칭카드 2개
                self.gameData.popupTitle = "🥸 카드 선택!!!"
                self.gameData.popupMessage = "가져올 카드를 선택해 주세요"
                self.gameData.popupCards = [deckCard]
                self.gameData.popupCards.append(contentsOf: matchingTableCards)
                self.gameData.completion = {
                    Task {
                        await self.moveDeckCardMatchingTableCardToPlayerChaptured(player: player, matchingTableCards: [self.gameData.popupCards[1]])
                        self.gameData.popupCards = []
                    }
                }
                self.gameData.gameStatus = .showSelectCardPopup
            case 3: // 매칭카드 3개
                //TODO:  3개 인경우 한장씩 뺏기
                self.gameData.popupTitle = "🥳 아싸3장!!!"
                self.gameData.popupMessage = "한장씩 내놔~"
                self.gameData.popupCards = [deckCard]
                self.gameData.popupCards.append(contentsOf: matchingTableCards)
                self.gameData.gameStatus = .showOneSecMessagePopup
                await moveDeckCardMatchingTableCardToPlayerChaptured(player: player, matchingTableCards: matchingTableCards)
            default: break
            }
            
            self.sortPlayerHandCards(playerIndex: currentPlayerIndex)
            //self.currentPlayerIndex = (self.currentPlayerIndex + 1) % 3
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
    
    private func moveDeckCardMatchingTableCardToPlayerChaptured(player: Player, matchingTableCards: [Card]) async {
        let deckCard = deckCards.removeLast()
        let tableGroupIndex = self.getTableCardGroupIndex(cardMonth: matchingTableCards.last!.month)
        player.capture(card: deckCard)
        
        guard let deckCardNode = childNode(withName: deckCard.id.uuidString) as? CardNode else { return }
        guard let matchingTableCardNode = childNode(withName: matchingTableCards.last!.id.uuidString) as? CardNode else { return }
        var matchPosition = matchingTableCardNode.position
        matchPosition.x += 10
        matchPosition.y -= 10
        
        deckCardNode.moveAndTurnCard(movePosition: matchPosition, duration: cardDuration, isFront: true, zPosition: 0, afterCardNodeScale: .large)
        do { try await Task.sleep(for: .seconds(cardDuration))
        } catch { print("error: \(error)")}
        
        let cardIndexByType = player.getCapturedCardIndexByType(card: deckCard)
        let movePosition = self.getPlayerCapturedCardPosition(playerIndex: player.index, cardIndexByType: cardIndexByType, cardType: deckCard.type)
        deckCardNode.moveAndTurnCard(movePosition: movePosition, duration: cardDuration, isFront: true, zPosition: cardIndexByType, afterCardNodeScale: .normal)
        
        for matchingTableCard in matchingTableCards {
            self.removeTableCard(card: matchingTableCard)
            player.capture(card: matchingTableCard)

            let cardIndexByType = player.getCapturedCardIndexByType(card: matchingTableCard)
            let movePosition = self.getPlayerCapturedCardPosition(playerIndex: player.index, cardIndexByType: cardIndexByType, cardType: matchingTableCard.type)
            matchingTableCardNode.moveAndTurnCard(movePosition: movePosition, duration: cardDuration, isFront: true, zPosition: cardIndexByType, afterCardNodeScale: .normal)
        }
        // 테이블 바닥카드 가져갈때 위치값 비워줌
        self.sortTableCardGroup(tableGroupIndex: tableGroupIndex)
        do { try await Task.sleep(for: .seconds(cardDuration))
        } catch { print("error: \(error)")}
    }
    
    private func moveBonusPlayerHandBonusCardToPlayerChaptured(player: Player, handCard: Card) async {
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
    
    private func movePlayerHandCardMatchingTableCardToPlayerChaptured(player: Player, handCard: Card, matchingTableCards: [Card]) async {
        guard let handCardNode = childNode(withName: handCard.id.uuidString) as? CardNode else { return }
        guard let matchingTableCardNode = childNode(withName: matchingTableCards.last!.id.uuidString) as? CardNode else { return }
        player.handCards.removeAll { $0.id == handCard.id }
        player.capture(card: handCard)
   
        let tableCardGroupIndex = self.getTableCardGroupIndex(cardMonth: matchingTableCards.last!.month)
        
        var matchPosition = matchingTableCardNode.position
        matchPosition.x += 10
        matchPosition.y -= 10
        handCardNode.moveAndTurnCard(movePosition: matchPosition, duration: cardDuration, isFront: true, afterCardNodeScale: .normal)
        do { try await Task.sleep(for: .seconds(cardDuration))
        } catch { print("error: \(error)")}
        
        let cardIndexByType = player.getCapturedCardIndexByType(card: handCard)
        let movePosition = self.getPlayerCapturedCardPosition(playerIndex: player.index, cardIndexByType: cardIndexByType, cardType: handCard.type)
        handCardNode.moveAndTurnCard(movePosition: movePosition, duration: cardDuration, isFront: true, zPosition: cardIndexByType, afterCardNodeScale: .normal)
        
        for matchingTableCard in matchingTableCards {
            player.capture(card: matchingTableCard)
            self.removeTableCard(card: matchingTableCard)
            
            let cardIndexByType = player.getCapturedCardIndexByType(card: matchingTableCard)
            let movePosition = self.getPlayerCapturedCardPosition(playerIndex: player.index, cardIndexByType: cardIndexByType, cardType: matchingTableCard.type)
            matchingTableCardNode.moveAndTurnCard(movePosition: movePosition, duration: cardDuration, isFront: true, zPosition: cardIndexByType, afterCardNodeScale: .normal)
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
    
    private func movePlayerHandCardToTable(player: Player, handCard: Card) async {
        guard let handCardNode = childNode(withName: handCard.id.uuidString) as? CardNode else { return }
        player.handCards.removeAll { $0.id == handCard.id }
        let groupIndex = self.getTableCardGroupIndex(cardMonth: handCard.month)
        let cardIndexByGroup = self.tableCardGroups[groupIndex].count
        let zPosition = self.getTableCardZPosition(groupIndex: groupIndex, cardIndexByGroup: cardIndexByGroup)
        self.addTableCard(card: handCard)
        let movePosition = self.getTableCardPosition(groupIndex: groupIndex, cardIndexByGroup: cardIndexByGroup)

        handCardNode.moveAndTurnCard(movePosition: movePosition, duration: cardDuration, isFront: true, zPosition: zPosition, afterCardNodeScale: .large)
        
        do { try await Task.sleep(for: .seconds(cardDuration))
        } catch { print("error: \(error)")}
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
                //print("same positioin \(i)")
            }
            else {
                //print("different positioin \(i) current(\(handCardNode.position.x),\(handCardNode.position.y)),target(\(movePosition.x),\(movePosition.y))")
                handCardNode.moveAndTurnCard(movePosition: movePosition, duration: cardDuration, isFront: playerIndex == 0, movingUpScale: nil, afterCardNodeScale: playerIndex == 0 ? .large : .small)
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
        //print("getTableCardPosition: \(groupIndex), \(cardIndexByGroup)")
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
            print("empty childNode: playerLabelNode_\(playerIndex)")
            startPosition.x = (playerIndex == 2 ? 0.0 : self.size.width / 2) + self.cardGap
            startPosition.y = size.height + (cardSize.height / 2) - self.cardGap
        }

        var position: CGPoint = .zero
        position.x = startPosition.x + (self.cardSize.width / 2) + CGFloat(cardIndex) * cardWidthWithGap
        position.y = startPosition.y + (self.cardSize.height * CardNodeScale.large.rawValue / 2)
        return position
    }
    
    private func getPlayerCapturedCardPosition(playerIndex: Int, cardIndexByType: Int, cardType: CardType) -> CGPoint {
        print("cardIndexByType: \(cardIndexByType), cardType: \(cardType)")
        let cardHeightWithGap = self.cardSize.height + self.cardGap
        var startPosition: CGPoint = .zero // 좌측 하단이 시작점
        startPosition.x = (playerIndex == 1 ? self.size.width / 2 : 0.0) + self.playerImageSize.width + (self.cardGap * 2)
        startPosition.y = playerIndex == 0 ? self.cardGap : size.height - (cardSize.height / 2) - cardHeightWithGap * 3 - (self.cardGap * 2)
        var position: CGPoint = .zero
        position.x = startPosition.x  + (cardSize.width / 2) + (cardSize.width / 2.5) * CGFloat(cardIndexByType) + ( cardType == .dan ? self.size.width / 5 : 0)
        position.y = startPosition.y + (cardSize.height / 2) + cardHeightWithGap * (cardType == .gwang ? 2.0 : cardType == .pi ? 0.0 : 1.0)
        return position
    }
    
    private func setPlayer(playerIndex: Int) {
        let player = players[playerIndex]
        let cardHeightWithGap = self.cardSize.height + self.cardGap
        var startPosition: CGPoint = .zero // 좌측 하단이 시작점
        let playerAreaNode = SKShapeNode(circleOfRadius: playerIndex == 0 ? self.size.width : self.size.width / 2 )
        let playerLabelNode = SKLabelNode(fontNamed: "System")
        playerLabelNode.name = "playerLabelNode_\(playerIndex)"
        playerLabelNode.text = GameScene.playerNames[player.charactorIndex] + " (\(player.money)만원)"
        playerLabelNode.fontSize = 18
        
        switch playerIndex {
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
        playerImageNode.name = "playerImageNode_\(playerIndex)"
        playerImageNode.size = self.playerImageSize
        let playerImageMaskPath = UIBezierPath(roundedRect: playerImageNode.frame, cornerRadius: self.cardSize.width / 2)
        let playerImageMaskNode = SKShapeNode(path: playerImageMaskPath.cgPath)
        playerImageMaskNode.name = "playerImageMaskNode_\(playerIndex)"
        playerImageMaskNode.fillColor = .black
        playerImageMaskNode.strokeColor = .white
        playerImageMaskNode.lineWidth = 2
        let playerImageCropNode = SKCropNode()
        playerImageCropNode.name = "playerCropNode_\(playerIndex)"
        playerImageCropNode.maskNode = playerImageMaskNode
        playerImageCropNode.addChild(playerImageNode)
        playerImageCropNode.position.x = startPosition.x + self.playerImageSize.height / 2
        playerImageCropNode.position.y = startPosition.y + self.playerImageSize.height / 2
        addChild(playerImageCropNode)
    
        playerLabelNode.position.x = startPosition.x + self.playerImageSize.width + playerLabelNode.bounds.width / 2
        playerLabelNode.position.y = startPosition.y + (playerIndex == 0 ? 0.0 : self.playerImageSize.height / 2)
        self.addChild(playerLabelNode)
    }
    
    private func setPlayers() {
        let range = 0...20
        let randomThree = range.shuffled()
        
        for i in 0...2 {
            self.players[i].charactorIndex = randomThree[i]
            self.players[i].imageName = "player_" + String(format: "%02d", randomThree[i])
            self.setPlayer(playerIndex: i)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard currentPlayerIndex == 0 else { return }
        
        let loc = touches.first!.location(in: self)
        
        for n in nodes(at: loc) {
            if let cardNode = n as? CardNode {
                
                if currentPlayerIndex == 0, let handCard = self.players[currentPlayerIndex].handCards.first(where: { $0.id == cardNode.card.id }) {
                    self.playWithSelectHandCard(handCard: handCard)
                }
                else {
                    print("not your turn nor your card")
                }
            }
        }
    }
}
