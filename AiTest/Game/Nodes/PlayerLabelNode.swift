//
//  PlayerLabelNode.swift
//  AiTest
//
//  Created by Joey's Mac mini on 6/11/26.
//

import SpriteKit

class PlayerLabelNode: SKLabelNode {
    
    static let prefixName = "playerLabelNode_"
    
    init(player: Player) {
        super.init()
        
        self.fontName = "System"
        self.name = PlayerLabelNode.prefixName + "\(player.index)"
        self.text = player.name + " (\(player.money)만냥)"
        self.fontColor = .white.withAlphaComponent(0.7)
        self.fontSize = 20
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
