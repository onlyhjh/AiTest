//
//  Player.swift
//  AiGoStop iOS
//
//  Created by Joey's Mac mini on 5/6/26.
//

import UIKit

final class Player {
    let index: Int
    var name: String = ""
    var imageName: String?
    var handCards: [Card] = []
    var capturedCardTypeGroup: [[Card]] = [[],[],[],[]]  // 0 gwang, 1 yeol, 2 dan, 3 pi
    var money: Int = 1000
    var goCount: Int = 0
    var characterIndex: Int = 0 // -1 이면 사용자 사진
    
    // 뻑
    var fuckCardMonths: [Int] = []
    // 흔들기
    var waveCount = 0
    var scoreText: String?
    
    // MARK: - 계산 프로퍼티
    var piCount: Int {
        capturedCardTypeGroup[CardType.pi.rawValue].count
    }
    
    var ttiCount: Int {
        capturedCardTypeGroup[CardType.tti.rawValue].count
    }
    
    var yeolCount: Int {
        capturedCardTypeGroup[CardType.yeol.rawValue].count
    }
    
    var gwangCount: Int {
        capturedCardTypeGroup[CardType.gwang.rawValue].count
    }
    
    var choDanCount: Int {
        capturedCardTypeGroup[CardType.tti.rawValue].count(where: { $0.isChoDan == true })
    }
    
    var hongDanCount: Int {
        capturedCardTypeGroup[CardType.tti.rawValue].count(where: { $0.isChoDan == true })
    }
    
    var chungDanCount: Int {
        capturedCardTypeGroup[CardType.tti.rawValue].count(where: { $0.isChungDan == true })
    }
    
    var godoriCount: Int {
        capturedCardTypeGroup[CardType.yeol.rawValue].count(where: { $0.isGodori == true })
    }
    
    init(index: Int) {
        self.index = index
    }
    
    // 국진일 경우 type 강제 할당
    func capture(card: Card, forcedType: CardType? = nil) {
        self.capturedCardTypeGroup[forcedType?.rawValue ?? card.type.rawValue].append(card)
    }
    
    // 국진일 경우 type 강제 할당
    func getCapturedCardIndexByType(card: Card, forcedType: CardType? = nil) -> Int {
        return self.capturedCardTypeGroup[forcedType?.rawValue ?? card.type.rawValue].firstIndex{ c in c.id == card.id } ?? 0
    }
}
