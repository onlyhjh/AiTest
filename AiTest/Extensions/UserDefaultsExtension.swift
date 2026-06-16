//
//  UserDefaultsExtension.swift
//  AiTest
//
//  Created by Joey's Mac mini on 6/15/26.
//

import Foundation

enum UserDefaultKey: String, CaseIterable {
    case testDeckCards1
    case testDeckCards2
    case user
    case lastWinIndex
}

extension UserDefaults {
    var deckCards1: Data? {
        get { data(forKey: UserDefaultKey.testDeckCards1.rawValue) }
        set { setValue(newValue, forKey: UserDefaultKey.testDeckCards1.rawValue)}
    }
    
    var deckCards2: Data? {
        get { data(forKey: UserDefaultKey.testDeckCards2.rawValue) }
        set { setValue(newValue, forKey: UserDefaultKey.testDeckCards2.rawValue)}
    }
    
    var user: Data? {
        get { data(forKey: UserDefaultKey.user.rawValue) }
        set { setValue(newValue, forKey: UserDefaultKey.user.rawValue)}
    }
    
    var lastWinnerIndex: Int? {
        get { value(forKey: UserDefaultKey.lastWinIndex.rawValue) as? Int }
        set { setValue(newValue, forKey: UserDefaultKey.lastWinIndex.rawValue)}
    }
}
