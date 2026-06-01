//
//  PopupManager.swift
//  AiTest
//
//  Created by Joey's Mac mini on 5/29/26.
//

import SwiftUI

enum PopupType {
    case chongtongWin       // 총통 승리
    case win                // 승리
    case ddadak             // 따닥
    case selectCard         // 카드 선택
    case selectWave         // 흔들기 선택
    case threeTableCards    // 3장 가져오기 (자뻑?)
    case threeTableCardsWithPlayerFuck // 자뻑 3장 가져오기
    case wave               // 흔들기
    case boom               // 폭탄
    case kiss               // 쪽
    case fuck               // 기본 뻑
    case firstFuck          // 첫 뻑
    case secondFuck         // 두번째 뻑 (첫뻑후)
    case thirdFuckWin       // 세번 뻑승
}
class PopupManager {
    static var shared = PopupManager()
    
    func showPopup(popupData: PopupData, type: PopupType, cards: [Card], players: [Player], message: String? = nil, completion: @escaping (Int) -> Void) {
        
        popupData.cards = cards
        popupData.players = players
        popupData.completion = completion
        popupData.status = .closePopup // 이미 팝업이 떠 있는 경우 닫아야함

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
            //print("Popup type: \(type)")
            switch type {
            case .chongtongWin:
                popupData.title = "총통 승!!!"
                popupData.message = "10만냥씩 줘~ 🥳"
                popupData.status = .showSpecialWinPopup
            case .win:
                popupData.title = "아싸 승!!!"
                popupData.message = message ?? "알아서 언넝 내놔~ 🥳"
                popupData.status = .showWinPopup
            case .thirdFuckWin:
                popupData.title = "뻑 3번 승!!!"
                popupData.message = "웃프게 이겼네.. 뭐여 이건~ 😂"
                popupData.status = .showSpecialWinPopup
            case .selectCard:
                popupData.title = "카드 선택!!!"
                popupData.message = "가져올 카드를 선택하삼~ 🥸"
                popupData.status = .showSelectCardPopup
            case .kiss:
                popupData.title = "쪽!!!"
                popupData.message = "피 한장씩 내놔~ 😘"
                popupData.status = .showAutoCloseMessagePopup
            case .boom:
                popupData.title = "폭탄!!!"
                popupData.message = "피 한장씩 내놔~ 🫣"
                popupData.status = .showAutoCloseMessagePopup
            case .selectWave:
                popupData.title = "흔들기!!!"
                popupData.message = "흔들까? 아님 그냥? 😵‍💫"
                popupData.status = .showSelectButtonPopup
                popupData.buttonTexts = ["흔들기", "그냥치기"]
            case .wave:
                popupData.title = "흔들었으!!!"
                popupData.message = "어질어질 하지~ 😵‍💫"
                popupData.status = .showAutoCloseMessagePopup
            case .fuck:
                popupData.title = "뻑!!!"
                popupData.message = "아놔~ 🤯"
                popupData.status = .showAutoCloseMessagePopup
            case .firstFuck:
                popupData.title = "첫뻑!!!"
                popupData.message = "웃프다~ 일단 3만냥씩 내놔~ 😂"
                popupData.status = .showAutoCloseMessagePopup
            case .secondFuck:
                popupData.title = "2연속 뻑!!!"
                popupData.message = "대단하다~ 일단 따블로 6만냥씩 받자~ 😂"
                popupData.status = .showAutoCloseMessagePopup
            case .ddadak:
                popupData.title = "따닥!!!"
                popupData.message = "피 한장씩 내놔~ 🤩"
                popupData.status = .showAutoCloseMessagePopup
            case .threeTableCards:
                popupData.title = "아싸 한번에 3장!!!"
                popupData.message = "피 한장씩 내놔~ 🥳"
                popupData.status = .showAutoCloseMessagePopup
            case .threeTableCardsWithPlayerFuck:
                popupData.title = "아싸 자뻑 3장!!!"
                popupData.message = "자뻑인거 알지? 피 두장씩 내놔~ 🥳"
                popupData.status = .showAutoCloseMessagePopup
            default:
                break
            }
        }
    }
}
