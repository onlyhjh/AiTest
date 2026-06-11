//
//  PopupData.swift
//  AiTest
//
//  Created by Joey's Mac mini on 6/10/26.
//

import SwiftUI
import Combine

enum PopupStatus {
    case showSelectCardPopup
    case showSelectButtonPopup
    case showAutoCloseMessagePopup
    case showWinPopup
    case showSpecialWinPopup
    case showAlert
    case closePopup
}

class PopupData: ObservableObject {
    @Published var status: PopupStatus = .closePopup
    var title: String? = nil
    var message: String? = nil
    var cards: [Card] = []
    var players: [Player] = []
    var buttonTexts: [String] = []
    var completion: (_ select: Int) -> Void = { select in }
}
