//
//  Card.swift
//  AiGoStop iOS
//
//  Created by Joey's Mac mini on 5/6/26.
//

import UIKit

// month : 1 소나무(송학), 2 매화(매조), 3 벚꽃(사쿠라), 4 등나무(흑싸리), 5 난초, 6 모란, 7 홍싸리, 8 억새(공산), 9 국화(국진), 10 단풍, 11 오동나무(오동), 12 버드나무(비)

enum CardType: Int {
    case gwang // 광
    case animal  // (10)끗
    case dan    // 단(띠)
    case pi     // 피
}

struct Card: Identifiable, Equatable, Hashable {
    let id = UUID()
    let month: Int
    let type: CardType
    let isGodori: Bool
    let isChungDan: Bool
    let isHongDan: Bool
    let isChoDan: Bool
    let isDoublePi: Bool
    let image: UIImage
    
    init(month: Int, type: CardType, isGodori: Bool = false, isChungDan: Bool = false, isHongDan: Bool = false, isChoDan: Bool = false, isDoublePi: Bool = false, image: UIImage) {
        self.month = month
        self.type = type
        self.isGodori = isGodori
        self.isChungDan = isChungDan
        self.isHongDan = isHongDan
        self.isChoDan = isChoDan
        self.isDoublePi = isDoublePi
        self.image = image
    }
}
