//
//  UserDefaultsExtension.swift
//  AiTest
//
//  Created by Joey's Mac mini on 6/15/26.
//

import Foundation

enum UserDefaultKey: String, CaseIterable {
    case testDeckCards
    case user
    case lastWinIndex
    case wasNagari
    case gameSpeed
}

extension UserDefaults {
    var deckCards: Data? {
        get { data(forKey: UserDefaultKey.testDeckCards.rawValue) }
        set { setValue(newValue, forKey: UserDefaultKey.testDeckCards.rawValue)}
    }
    
    var user: Data? {
        get { data(forKey: UserDefaultKey.user.rawValue) }
        set { setValue(newValue, forKey: UserDefaultKey.user.rawValue)}
    }
    
    var lastWinnerIndex: Int? {
        get { value(forKey: UserDefaultKey.lastWinIndex.rawValue) as? Int }
        set { setValue(newValue, forKey: UserDefaultKey.lastWinIndex.rawValue)}
    }
    
    var wasNagari: Bool? {
        get { value(forKey: UserDefaultKey.wasNagari.rawValue) as? Bool }
        set { setValue(newValue, forKey: UserDefaultKey.wasNagari.rawValue)}
    }
    
    var gameSpeed: Double? {
        get { value(forKey: UserDefaultKey.gameSpeed.rawValue) as? Double }
        set { setValue(newValue, forKey: UserDefaultKey.gameSpeed.rawValue)}
    }
}
