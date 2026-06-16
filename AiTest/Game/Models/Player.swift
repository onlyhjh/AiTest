//
//  Player.swift
//  AiGoStop iOS
//
//  Created by Joey's Mac mini on 5/6/26.
//

import UIKit

struct Player: Codable {
    static let imageNamePrefix = "player_"
    static let unknownImageName = "player_unkown"
    
    let index: Int
    var characterIndex: Int = 0
    var name: String = ""
    var imageName: String = ""
    
    var handCards: [Card] = []
    var capturedCardTypeGroup: [[Card]] = [[],[],[],[]]  // 0 gwang, 1 yeol, 2 dan, 3 pi
    var money: Int = 1000
    var goCount: Int = 0
    var lastGoScore = 0
    var fuckCardMonths: [Int] = [] // 뻑
    var waveCount = 0 // 흔들기
    var scoreText: String?
    
    // MARK: - 계산 프로퍼티
    var piCount: Int {
        // 쌍피는 2점
        capturedCardTypeGroup[CardType.pi.rawValue].count + capturedCardTypeGroup[CardType.pi.rawValue].count(where: { $0.isDoublePi == true })
    }
    
    var ttiCount: Int {
        capturedCardTypeGroup[CardType.tti.rawValue].count
    }
    
    var yeolCount: Int {
        capturedCardTypeGroup[CardType.yeol.rawValue].count
    }
    
    var gwangCount: Int {
        // 3점일때는 비 제외
        capturedCardTypeGroup[CardType.gwang.rawValue].count == 3 && capturedCardTypeGroup[CardType.gwang.rawValue].contains(where: { $0.month == 12 }) ? 2 : capturedCardTypeGroup[CardType.gwang.rawValue].count
    }
    
    var chodanCount: Int {
        capturedCardTypeGroup[CardType.tti.rawValue].count(where: { $0.isChoDan == true })
    }
    
    var hongdanCount: Int {
        capturedCardTypeGroup[CardType.tti.rawValue].count(where: { $0.isChoDan == true })
    }
    
    var chungdanCount: Int {
        capturedCardTypeGroup[CardType.tti.rawValue].count(where: { $0.isChungDan == true })
    }
    
    var godoriCount: Int {
        capturedCardTypeGroup[CardType.yeol.rawValue].count(where: { $0.isGodori == true })
    }
    
    init(index: Int) {
        self.index = index
    }
}
