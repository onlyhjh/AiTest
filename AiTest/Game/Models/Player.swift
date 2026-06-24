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
    var money: Int = 1000
    
    // 이하 각 게임마다 clear 대상
    var handCards: [Card] = []
    var capturedCardTypeGroups: [[Card]] = [[],[],[],[]]  // 0 gwang, 1 yeol, 2 dan, 3 pi
    var goCount: Int = 0
    var lastGoScore = 0
    var fuckCardMonths: [Int] = [] // 뻑
    var waveCount = 0 // 흔들기
    
    // Score 표시 용
    // winner
    var isChongTongWin = false
    var is3FuckWin = false
    var isGokbak = false
    var wasNagari = false

    // looser
    var isPiBak = false
    var isGwangBak = false
    var isGoBak = false // 독박과 동일
    var finalScore = 0
    
    // MARK: - 계산 프로퍼티
    // 피 10개 1점
    var piScore: Int {
        piCount > 9 ? piCount - 9 : 0
    }
    var piCount: Int {
        // 쌍피는 2개로
        capturedCardTypeGroups[CardType.pi.rawValue].count + capturedCardTypeGroups[CardType.pi.rawValue].count(where: { $0.isDoublePi == true })
    }
    
    // 띠 5개 1점
    var ttiScore: Int {
        ttiCount > 4 ? ttiCount - 4 : 0
    }
    var ttiCount: Int {
        capturedCardTypeGroups[CardType.tti.rawValue].count
    }
    
    // 열 5개 1점
    var yeolScore: Int {
        yeolCount > 4 ? yeolCount - 4 : 0
    }
    var yeolCount: Int {
        capturedCardTypeGroups[CardType.yeol.rawValue].count
    }
    
    var isMungtungguri : Bool {
        yeolCount > 6
    }
    
    // 광 3개 1점, 5광 15점 (비광 3점제외)
    var gwangScore: Int {
        gwangCount > 4 ? 15 : gwangCount > 2 ? gwangCount - 2 : 0
    }
    var gwangCount: Int {
        // 5광 15점
        capturedCardTypeGroups[CardType.gwang.rawValue].count == 5 ? 15 :
        // 3점일때는 비 제외
        capturedCardTypeGroups[CardType.gwang.rawValue].count == 3 && capturedCardTypeGroups[CardType.gwang.rawValue].contains(where: { $0.month == 12 }) ? 2 : capturedCardTypeGroups[CardType.gwang.rawValue].count
    }
    
    // 초단 3점
    var chodanScore: Int {
        chodanCount > 2 ? 3 : 0
    }
    var chodanCount: Int {
        capturedCardTypeGroups[CardType.tti.rawValue].count(where: { $0.isChoDan == true })
    }
    
    // 홍단 3점
    var hongdanScore: Int {
        hongdanCount > 2 ? 3 : 0
    }
    var hongdanCount: Int {
        capturedCardTypeGroups[CardType.tti.rawValue].count(where: { $0.isChoDan == true })
    }
    
    // 청단 3점
    var chungdanScore: Int {
        chungdanCount > 2 ? 3 : 0
    }
    var chungdanCount: Int {
        capturedCardTypeGroups[CardType.tti.rawValue].count(where: { $0.isChungDan == true })
    }
    
    // 고도리 5점
    var godoriScore: Int {
        godoriCount > 2 ? 5 : 0
    }
    var godoriCount: Int {
        capturedCardTypeGroups[CardType.yeol.rawValue].count(where: { $0.isGodori == true })
    }
    
    var baseScore: Int {
        gwangScore + yeolScore + ttiScore + piScore + chodanScore + hongdanScore + chodanScore + godoriScore + goCount
    }
    
    var subtotalScore: Int {
        baseScore * (goCount > 2 ? Int(pow(2, Double(goCount - 2))) : 1) * (waveCount > 0 ? Int(pow(2, Double(waveCount))) : 1) * (wasNagari ? 2 : 1) * (isMungtungguri ? 2 : 1)
    }
    
    init(index: Int) {
        self.index = index
    }
}
