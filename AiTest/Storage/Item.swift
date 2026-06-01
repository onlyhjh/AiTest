//
//  Item.swift
//  AiTest
//
//  Created by Joey's Mac mini on 5/20/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
