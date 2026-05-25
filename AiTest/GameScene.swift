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
    
    private let cardDuration: Double = 0.1
    
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
        if self.gameData.gameStatus == .start {
            self.startGame()
            self.gameData.gameStatus = .wait
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
        
        guard let handCardNode = childNode(withName: handCard.id.uuidString) as? CardNode else {
            return
        }
        
        Task {
            // 손에서 비움
            player.handCards.removeAll { $0.id == handCard.id }
            
            // bonus 카드인경우
            if handCard.month == 0 {
                await moveBonusPlayerHandBonusCardToPlayerChaptured(player: player, handCard: handCard, handCardNode: handCardNode)
                self.sortPlayerHandCards(playerIndex: currentPlayerIndex)
                return
            }
            
            // 다음 덱카드를 미리 확인하여 연속된 보너스 카드 갯수 가져오기
            var nextBonusDeckCardCount = 0
            var nextDeckCardExceptBonus: Card = self.deckCards.last!
            for i in (0..<self.deckCards.count - 1).reversed() {
                if self.deckCards[i].month == 0 {
                    nextBonusDeckCardCount += 1
                }
                else {
                    nextDeckCardExceptBonus = self.deckCards[i]
                    break
                }
            }
            
            // 매칭카드가 갯수에 따른 처리
            let matchingTableCards = self.getMatchingTableCards(cardMonth: handCard.month)
            print("matchingTableCards : \(matchingTableCards.count)")
            switch matchingTableCards.count {
            case 0: // 매칭카드 없는 경우
                await self.movePlayerHandCardToTable(handCard: handCard, handCardNode: handCardNode)
                await self.moveBonusDeckCardsToPlayerCapturedIfNeeded(playerIndex: self.currentPlayerIndex)
                
                // 쪽이면 > 쪽카드 받아가기,
                if nextDeckCardExceptBonus.month == handCard.month {
                    await moveDeckCardMatchingTableCardToPlayerChaptured(player: player, matchingTableCard: handCard)
                    //TODO: 한장씩 받아오기
                    self.gameData.popupMessage = "쪽!!!"
                    print("쪽!!!")
                }
                else {
                    await self.moveDeckCardToTable()
                }
            case 1: // 매칭카드 1개
                //TODO: 덱카드 뒤집을때 경우 뻑 처리(첫뻑, 첫뻑후 연속뻑, 연속뻑3회)
                if nextDeckCardExceptBonus.month == handCard.month {
                    await self.movePlayerHandCardToTable(handCard: handCard, handCardNode: handCardNode)
                    let tableGroupIndex = self.getTableCardGroupIndex(cardMonth: handCard.month)
                    await self.moveBonusDeckCardsToTable(tableGroupIndex: tableGroupIndex)
                    await self.moveDeckCardToTable()
                    self.gameData.popupMessage = "뻑!!!"
                    print("뻑!!!")
                }
                else {
                    let selectedMatchingTableCard = matchingTableCards[0]
                    await moveHandCardMatchingTableCardToPlayerChaptured(player: player, handCard: handCard, matchingTableCard: selectedMatchingTableCard, handCardNode: handCardNode)
                    await self.moveBonusDeckCardsToPlayerCapturedIfNeeded(playerIndex: self.currentPlayerIndex)
                    await self.moveDeckCardToTable()
                }
            case 2: // 매칭카드 2개
                //TODO: 덱카드 뒤집을때 따닥 처리, 카드 선택
                let selectedMatchingTableCard = matchingTableCards[0]
                await moveHandCardMatchingTableCardToPlayerChaptured(player: player, handCard: handCard, matchingTableCard: selectedMatchingTableCard, handCardNode: handCardNode)
                
                self.gameData.popupMessage = "따닥!!!"
                print("따닥!!!")
            case 3: // 매칭카드 3개
                //TODO:  3개 인경우 한장씩 뺏기
                self.gameData.popupMessage = "아싸3장!!!"
                print("아싸3장!!!")
                for i in 0..<matchingTableCards.count {
                    let selectedMatchingTableCard = matchingTableCards[i]
                    await moveHandCardMatchingTableCardToPlayerChaptured(player: player, handCard: handCard, matchingTableCard: selectedMatchingTableCard, handCardNode: handCardNode)
                }
            default: break
            }
            
            self.sortPlayerHandCards(playerIndex: currentPlayerIndex)
            //self.currentPlayerIndex = (self.currentPlayerIndex + 1) % 3
        }
    }
    
    //
    private func flipDeckCardProcess() {
        
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
    
    private func moveDeckCardMatchingTableCardToPlayerChaptured(player: Player, matchingTableCard: Card) async {
        let deckCard = deckCards.removeLast()
        let tableGroupIndex = self.getTableCardGroupIndex(cardMonth: matchingTableCard.month)
        self.removeTableCard(card: matchingTableCard)
        
        player.capture(card: deckCard)
        player.capture(card: matchingTableCard)
        
        guard let deckCardNode = childNode(withName: deckCard.id.uuidString) as? CardNode else { return }
        guard let matchingTableCardNode = childNode(withName: matchingTableCard.id.uuidString) as? CardNode else { return }
        var matchPosition = matchingTableCardNode.position
        matchPosition.x += 10
        matchPosition.y -= 10
        deckCardNode.moveAndTurnCard(movePosition: matchPosition, duration: cardDuration, isFront: true, afterCardNodeScale: .large)
        do { try await Task.sleep(for: .seconds(cardDuration))
        } catch { print("error: \(error)")}

        let cardIndexByType1 = player.getCapturedCardIndexByType(card: deckCard)
        let cardIndexByType2 = player.getCapturedCardIndexByType(card: matchingTableCard)
        let movePosition1 = self.getPlayerCapturedCardPosition(playerIndex: player.index, cardIndexByType: cardIndexByType1, cardType: deckCard.type)
        let movePosition2 = self.getPlayerCapturedCardPosition(playerIndex: player.index, cardIndexByType: cardIndexByType2, cardType: matchingTableCard.type)
        deckCardNode.moveAndTurnCard(movePosition: movePosition1, duration: cardDuration, isFront: true, zPosition: cardIndexByType1, afterCardNodeScale: .normal)
        matchingTableCardNode.moveAndTurnCard(movePosition: movePosition2, duration: cardDuration, isFront: true, zPosition: cardIndexByType2, afterCardNodeScale: .normal)
        
        // 테이블 바닥카드 가져갈때 위치값 비워줌
        self.sortTableCardGroup(tableGroupIndex: tableGroupIndex)
    }
    
    private func moveBonusPlayerHandBonusCardToPlayerChaptured(player: Player, handCard: Card, handCardNode: CardNode) async {
        // 가지고 있는 카드를 수집카드로
        player.capture(card: handCard)
        
        // captured로 이동
        let cardIndexByType = player.getCapturedCardIndexByType(card: handCard)
        let movePosition = self.getPlayerCapturedCardPosition(playerIndex: player.index, cardIndexByType: cardIndexByType, cardType: handCard.type)
        handCardNode.moveAndTurnCard(movePosition: movePosition, duration: cardDuration, isFront: true, zPosition: cardIndexByType, afterCardNodeScale: .normal)
        do { try await Task.sleep(for: .seconds(cardDuration))
        } catch { print("error: \(error)")}
        
        // 덱에서 카드 한장 새로 받기
        await self.moveDeckCardToPlayerHand(playerIndex: player.index, cardIndex: player.handCards.count)
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
    
    private func moveHandCardMatchingTableCardToPlayerChaptured(player: Player, handCard: Card, matchingTableCard: Card, handCardNode: CardNode) async {
        player.capture(card: handCard)
        player.capture(card: matchingTableCard)
        let tableCardGroupIndex = self.getTableCardGroupIndex(cardMonth: matchingTableCard.month)
        self.removeTableCard(card: matchingTableCard)
        guard let matchingTableCardNode = childNode(withName: matchingTableCard.id.uuidString) as? CardNode else { return }
        var matchPosition = matchingTableCardNode.position
        matchPosition.x += 10
        matchPosition.y -= 10
        handCardNode.moveAndTurnCard(movePosition: matchPosition, duration: cardDuration, isFront: true, afterCardNodeScale: .normal)
        do { try await Task.sleep(for: .seconds(cardDuration))
        } catch { print("error: \(error)")}
        
        let cardIndexByType1 = player.getCapturedCardIndexByType(card: handCard)
        let cardIndexByType2 = player.getCapturedCardIndexByType(card: matchingTableCard)
        let movePosition1 = self.getPlayerCapturedCardPosition(playerIndex: player.index, cardIndexByType: cardIndexByType1, cardType: handCard.type)
        let movePosition2 = self.getPlayerCapturedCardPosition(playerIndex: player.index, cardIndexByType: cardIndexByType2, cardType: matchingTableCard.type)
        handCardNode.moveAndTurnCard(movePosition: movePosition1, duration: cardDuration, isFront: true, zPosition: cardIndexByType1, afterCardNodeScale: .normal)
        matchingTableCardNode.moveAndTurnCard(movePosition: movePosition2, duration: cardDuration, isFront: true, zPosition: cardIndexByType2, afterCardNodeScale: .normal)
        self.sortTableCardGroup(tableGroupIndex: tableCardGroupIndex)
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
    
    private func movePlayerHandCardToTable(handCard: Card, handCardNode: CardNode) async {
        let groupIndex = self.getTableCardGroupIndex(cardMonth: handCard.month)
        let cardIndexByGroup = self.tableCardGroups[groupIndex].count
        self.addTableCard(card: handCard)
        let movePosition = self.getTableCardPosition(groupIndex: groupIndex, cardIndexByGroup: cardIndexByGroup)
        handCardNode.moveAndTurnCard(movePosition: movePosition, duration: cardDuration, isFront: true, afterCardNodeScale: .large)
        
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
                print("different positioin \(i) current(\(handCardNode.position.x),\(handCardNode.position.y)),target(\(movePosition.x),\(movePosition.y))")
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
            let node = CardNode(name: deckCards[i].id.uuidString, card: deckCards[i], cardSize: cardSize, isFront: false)
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

        let playerImageNode = SKSpriteNode(imageNamed: "player_" + String(format: "%02d", player.charactorIndex))
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
            setPlayer(playerIndex: i)
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
