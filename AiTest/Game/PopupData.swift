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
    case showMessagePopup
    case showWinnerPopup
    case showSpecialWinnerPopup
    case showAlert
    case closePopup
}

class PopupData: ObservableObject {
    static let defaultAutoCloseDuration: Double = 1.5
    
    @Published var status: PopupStatus = .closePopup
    var title: String? = nil
    var message: String? = nil
    var cards: [Card] = []
    var players: [Player] = []
    var button1Text: String = ""
    var button2Text: String = ""
    var completion: (_ select: Int) -> Void = { select in }
    var autoCloseDuration: Double = 2.0 * (UserDefaults.standard.gameSpeed ?? 1)
    
    init() {
        self.setAutoCloseDuration(gameSpeed: UserDefaults.standard.gameSpeed ?? 0.0)
    }
    
    func setAutoCloseDuration(gameSpeed: Double) {
        self.autoCloseDuration = PopupData.defaultAutoCloseDuration + gameSpeed * -1.0
    }
}
