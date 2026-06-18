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
    case nagari             // 나가리
    case ddadak             // 따닥
    case selectCard         // 카드 선택
    case selectWave         // 흔들기 선택
    case selectGoOrStop     // 고, 스톱 선택
    case selectGukjin       // 국진 선택
    case threeTableCards    // 한번에 3장 가져오기
    case threeTableCardsWithPlayerFuck // 자뻑 (한번에 3장 가져오기)
    case go                 // 고
    case stop               // 스톱
    case wave               // 흔들기
    case bomb               // 폭탄
    case kiss               // 쪽
    case emptyTable         // 쓸
    case deckBonus          // 보너스 득
    case handBonus          // 손에 있는 보너스 카드
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
            print("\(#function) Popup type: \(type)")
            switch type {
            case .chongtongWin:
                popupData.title = "총통 승!!!"
                popupData.message = "10만냥씩 줘~ 🥳"
                popupData.status = .showSpecialWinPopup
            case .win:
                popupData.title = "아싸 승!!!"
                popupData.message = message ?? "알아서 언넝 내놔~ 🥳"
                popupData.status = .showWinPopup
            case .nagari:
                popupData.title = "나가리!!!"
                popupData.message = message ?? "다음판은 두배여~ 🥶"
                popupData.button1Text = "확인"
                popupData.status = .showMessagePopup
            case .thirdFuckWin:
                popupData.title = "뻑 3번 승!!!"
                popupData.message = "웃프게 이겼네.. 뭐여 이건~ 😂"
                popupData.status = .showSpecialWinPopup
            case .selectCard:
                popupData.title = "카드 선택!!!"
                popupData.message = "가져올 카드를 선택하삼~ 🥸"
                popupData.status = .showSelectCardPopup
            case .kiss:
                popupData.title = "아싸 쪽!!!"
                popupData.message = "피 한장씩 내놔~ 😘"
                popupData.status = .showAutoCloseMessagePopup
            case .emptyTable:
                popupData.title = "아싸 쓸!!!"
                popupData.message = "피 한장씩 더 내놔~ 😘"
                popupData.status = .showAutoCloseMessagePopup
            case .bomb:
                popupData.title = "폭탄!!!"
                popupData.message = "피 한장씩 내놔~ 🫣"
                popupData.status = .showAutoCloseMessagePopup
            case .selectWave:
                popupData.title = "흔들기!!!"
                popupData.message = "흔들까? 아님 그냥? 😵‍💫"
                popupData.status = .showSelectButtonPopup
                popupData.button1Text = "흔들기"
                popupData.button2Text = "그냥치기"
            case .selectGoOrStop:
                popupData.title = "고 or 스톱???"
                popupData.message = "고할까 아님 안전하게 스톱??? 😵‍💫"
                popupData.status = .showSelectButtonPopup
                popupData.button1Text = "고"
                popupData.button2Text = "스톱"
            case .selectGukjin:
                popupData.title = "국진 쌍피 선택!!!"
                popupData.message = "쌍피로 쓸까? 🥸"
                popupData.status = .showSelectButtonPopup
                popupData.button1Text = "쌍피로"
                popupData.button2Text = "열끗으로"
            case .wave:
                popupData.title = "흔들었으!!!"
                popupData.message = "어질어질 하지~ 😵‍💫"
                popupData.status = .showAutoCloseMessagePopup
            case .fuck:
                popupData.title = "오메 뻑!!!"
                popupData.message = "아놔~ 🤯"
                popupData.status = .showAutoCloseMessagePopup
            case .deckBonus:
                popupData.title = "아싸 보너스!!!"
                popupData.message = "쌍피 추가요~ 🤭"
                popupData.status = .showAutoCloseMessagePopup
            case .handBonus:
                popupData.title = "숨겨둔 보너스!!!"
                popupData.message = "오늘 운빨이 좋구먼~ 🤭"
                popupData.status = .showAutoCloseMessagePopup
            case .firstFuck:
                popupData.title = "오메 첫뻑!!!"
                popupData.message = "웃프다~ 일단 3만냥씩 내놔~ 😂"
                popupData.status = .showAutoCloseMessagePopup
            case .secondFuck:
                popupData.title = "오메메 2연속 뻑!!!"
                popupData.message = "대단하다~ 일단 따블로 6만냥씩 받자~ 😂"
                popupData.status = .showAutoCloseMessagePopup
            case .ddadak:
                popupData.title = "아싸 따닥!!!"
                popupData.message = "피 한장씩 내놔~ 🤩"
                popupData.status = .showAutoCloseMessagePopup
            case .threeTableCards:
                popupData.title = "아싸 쌩큐!!!"
                popupData.message = "피 한장씩 내놔~ 🥳"
                popupData.status = .showAutoCloseMessagePopup
            case .threeTableCardsWithPlayerFuck:
                popupData.title = "아싸 자뻑이었던거 알지!!!"
                popupData.message = "피 두장씩 내놔~ 🥳"
                popupData.status = .showAutoCloseMessagePopup
            case .go:
                popupData.title = message
                popupData.message = "못먹어도 고~ 🥶"
                popupData.status = .showAutoCloseMessagePopup
            case .stop:
                popupData.title = "안전하게 스톱!!!"
                popupData.message = "돈 준비들 하셔~ 🥹"
                popupData.status = .showAutoCloseMessagePopup
            default:
                break
            }
        }
    }
}
