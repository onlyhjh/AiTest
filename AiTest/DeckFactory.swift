//
//  DeckFactory.swift
//  AiGoStop iOS
//
//  Created by Joey's Mac mini on 5/6/26.
//

class DeckFactory {
    
    func generateFullDeck() -> [Card] {
        var deck: [Card] = []
        
        for month in 0...12 {
            switch month {
            case 0: // Bonus
                deck += [
                    Card(month: 0, type: .pi, isDoublePi: true, image: .hwatu00Bonus01),
                    Card(month: 0, type: .pi, isDoublePi: true, image: .hwatu00Bonus02),
                    Card(month: 0, type: .pi, isDoublePi: true, image: .hwatu00Bonus03),
                ]
            case 1:
                deck += [
                    Card(month: 1, type: .gwang, image: .hwatu01Gwang),
                    Card(month: 1, type: .pi, image: .hwatu01Animal),
                    Card(month: 1, type: .dan, isHongDan: true, image: .hwatu01Ribbon),
                    Card(month: 1, type: .pi, image: .hwatu01Junk)
                ]
            case 2:
                deck += [
                    Card(month: 2, type: .pi, image: .hwatu02Gwang),
                    Card(month: 2, type: .animal, isGodori: true, image: .hwatu02Animal),
                    Card(month: 2, type: .dan, isHongDan: true, image: .hwatu02Ribbon),
                    Card(month: 2, type: .pi, image: .hwatu02Junk)
                ]
            case 3:
                deck += [
                    Card(month: 3, type: .gwang, image: .hwatu03Gwang),
                    Card(month: 3, type: .pi, image: .hwatu03Animal),
                    Card(month: 3, type: .dan, isHongDan: true, image: .hwatu03Ribbon),
                    Card(month: 3, type: .pi, image: .hwatu03Junk)
                ]
            case 4:
                deck += [
                    Card(month: 4, type: .pi, image: .hwatu04Gwang),
                    Card(month: 4, type: .animal, isGodori: true, image: .hwatu04Animal),
                    Card(month: 4, type: .dan, isChoDan: true, image: .hwatu04Ribbon),
                    Card(month: 4, type: .pi, image: .hwatu04Junk)
                ]
            case 5:
                deck += [
                    Card(month: 5, type: .pi, image: .hwatu05Gwang),
                    Card(month: 5, type: .animal, image: .hwatu05Animal),
                    Card(month: 5, type: .dan, isChoDan: true, image: .hwatu05Ribbon),
                    Card(month: 5, type: .pi, image: .hwatu05Junk)
                ]
            case 6:
                deck += [
                    Card(month: 6, type: .pi, image: .hwatu06Gwang),
                    Card(month: 6, type: .animal, image: .hwatu06Animal),
                    Card(month: 6, type: .dan, isChungDan: true, image: .hwatu06Ribbon),
                    Card(month: 6, type: .pi, image: .hwatu06Junk)
                ]
            case 7:
                deck += [
                    Card(month: 7, type: .pi, image: .hwatu07Gwang),
                    Card(month: 7, type: .animal, image: .hwatu07Animal),
                    Card(month: 7, type: .dan, isChoDan: true, image: .hwatu07Ribbon),
                    Card(month: 7, type: .pi, image: .hwatu07Junk)
                ]
            case 8:
                deck += [
                    Card(month: 8, type: .gwang, image: .hwatu08Gwang),
                    Card(month: 8, type: .animal, isGodori: true, image: .hwatu08Animal),
                    Card(month: 8, type: .pi, image: .hwatu08Ribbon),
                    Card(month: 8, type: .pi, image: .hwatu08Junk)
                ]
            case 9:
                deck += [
                    Card(month: 9, type: .pi, image: .hwatu09Gwang),
                    Card(month: 9, type: .animal, isDoublePi: true, image: .hwatu09Animal),
                    Card(month: 9, type: .dan, isChungDan: true, image: .hwatu09Ribbon),
                    Card(month: 9, type: .pi, image: .hwatu09Junk)
                ]
            case 10:
                deck += [
                    Card(month: 10, type: .pi, image: .hwatu10Gwang),
                    Card(month: 10, type: .animal, image: .hwatu10Animal),
                    Card(month: 10, type: .dan, isChungDan: true, image: .hwatu10Ribbon),
                    Card(month: 10, type: .pi, image: .hwatu10Junk)
                ]
            case 11:
                deck += [
                    Card(month: 11, type: .gwang, image: .hwatu11Gwang),
                    Card(month: 11, type: .pi, image: .hwatu11Animal),
                    Card(month: 11, type: .pi, isDoublePi: true, image: .hwatu11Ribbon),
                    Card(month: 11, type: .pi, image: .hwatu11Junk)
                ]
            case 12:
                deck += [
                    Card(month: 12, type: .gwang, image: .hwatu12Gwang),
                    Card(month: 12, type: .animal, image: .hwatu12Animal),
                    Card(month: 12, type: .dan, image: .hwatu12Ribbon),
                    Card(month: 12, type: .pi, isDoublePi: true, image: .hwatu12Junk)
                ]
            default:
                deck += []
            }
        }
        
        return deck.shuffled()
    }

}
