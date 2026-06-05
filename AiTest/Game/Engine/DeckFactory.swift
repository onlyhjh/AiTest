//
//  DeckFactory.swift
//  AiGoStop iOS
//
//  Created by Joey's Mac mini on 5/6/26.
//

import Foundation
class DeckFactory {
    
    func generateFullDeck() -> [Card] {
        var deck: [Card] = []
        
        for month in 0...12 {
            switch month {
            case 0: // Bonus
                deck += [
                    Card(month: 0, type: .pi, isDoublePi: true, piNum: 0),
                    Card(month: 0, type: .pi, isDoublePi: true, piNum: 1),
                    Card(month: 0, type: .pi, isDoublePi: true, piNum: 2),
                ]
            case 1:
                deck += [
                    Card(month: 1, type: .gwang),
                    Card(month: 1, type: .pi, piNum: 0),
                    Card(month: 1, type: .tti, isHongDan: true),
                    Card(month: 1, type: .pi, piNum: 1)
                ]
            case 2:
                deck += [
                    Card(month: 2, type: .pi, piNum: 0),
                    Card(month: 2, type: .yeol, isGodori: true),
                    Card(month: 2, type: .tti, isHongDan: true),
                    Card(month: 2, type: .pi, piNum: 1)
                ]
            case 3:
                deck += [
                    Card(month: 3, type: .gwang),
                    Card(month: 3, type: .pi, piNum: 0),
                    Card(month: 3, type: .tti, isHongDan: true),
                    Card(month: 3, type: .pi, piNum: 1)
                ]
            case 4:
                deck += [
                    Card(month: 4, type: .pi, piNum: 0),
                    Card(month: 4, type: .yeol, isGodori: true),
                    Card(month: 4, type: .tti, isChoDan: true),
                    Card(month: 4, type: .pi, piNum: 1)
                ]
            case 5:
                deck += [
                    Card(month: 5, type: .pi, piNum: 0),
                    Card(month: 5, type: .yeol),
                    Card(month: 5, type: .tti, isChoDan: true),
                    Card(month: 5, type: .pi, piNum: 1)
                ]
            case 6:
                deck += [
                    Card(month: 6, type: .pi, piNum: 0),
                    Card(month: 6, type: .yeol),
                    Card(month: 6, type: .tti, isChungDan: true),
                    Card(month: 6, type: .pi, piNum: 1)
                ]
            case 7:
                deck += [
                    Card(month: 7, type: .pi, piNum: 0),
                    Card(month: 7, type: .yeol),
                    Card(month: 7, type: .tti, isChoDan: true),
                    Card(month: 7, type: .pi, piNum: 1)
                ]
            case 8:
                deck += [
                    Card(month: 8, type: .gwang),
                    Card(month: 8, type: .yeol, isGodori: true),
                    Card(month: 8, type: .pi, piNum: 0),
                    Card(month: 8, type: .pi, piNum: 1)
                ]
            case 9:
                deck += [
                    Card(month: 9, type: .pi, piNum: 0),
                    Card(month: 9, type: .yeol, isDoublePi: true),
                    Card(month: 9, type: .tti, isChungDan: true),
                    Card(month: 9, type: .pi, piNum: 1)
                ]
            case 10:
                deck += [
                    Card(month: 10, type: .pi, piNum: 0),
                    Card(month: 10, type: .yeol),
                    Card(month: 10, type: .tti, isChungDan: true),
                    Card(month: 10, type: .pi, piNum: 1)
                ]
            case 11:
                deck += [
                    Card(month: 11, type: .gwang),
                    Card(month: 11, type: .pi, piNum: 0),
                    Card(month: 11, type: .pi, isDoublePi: true, piNum: 1),
                    Card(month: 11, type: .pi, piNum: 2)
                ]
            case 12:
                deck += [
                    Card(month: 12, type: .gwang),
                    Card(month: 12, type: .yeol),
                    Card(month: 12, type: .tti),
                    Card(month: 12, type: .pi, isDoublePi: true, piNum: 0)
                ]
            default:
                deck += []
            }
        }
        
        // 이미지 이름 넣기
        for (i, card) in deck.enumerated() {
            deck[i].imageName = String(format: "hwatu_%02d_", card.month) + String(describing: card.type) + (card.type == .pi ? "_\(card.piNum)" : "")
            //print("card imageName :\(imageName)  >>> \(card.piNum) ")
        }
        
        return deck.shuffled()
    }
}
