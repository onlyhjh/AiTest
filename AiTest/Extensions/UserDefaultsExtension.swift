//
//  UserDefaultsExtension.swift
//  AiTest
//
//  Created by Joey's Mac mini on 6/15/26.
//

import Foundation

enum UserDefaultKey: String, CaseIterable {
    case savedDeckCards
    case savedWinnerIndex
    case user
    case lastWinnerIndex
    case wasNagari
    case gameSpeed
}

extension UserDefaults {
    var savedDeckCards: Data? {
        get { data(forKey: UserDefaultKey.savedDeckCards.rawValue) }
        set { setValue(newValue, forKey: UserDefaultKey.savedDeckCards.rawValue)}
    }
    
    var savedWinnerIndex: Int? {
        get { value(forKey: UserDefaultKey.savedWinnerIndex.rawValue) as? Int }
        set { setValue(newValue, forKey: UserDefaultKey.savedWinnerIndex.rawValue)}
    }
    
    var user: Data? {
        get { data(forKey: UserDefaultKey.user.rawValue) }
        set { setValue(newValue, forKey: UserDefaultKey.user.rawValue)}
    }
    
    var lastWinnerIndex: Int? {
        get { value(forKey: UserDefaultKey.lastWinnerIndex.rawValue) as? Int }
        set { setValue(newValue, forKey: UserDefaultKey.lastWinnerIndex.rawValue)}
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
