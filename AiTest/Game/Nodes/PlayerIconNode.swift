//
//  PlayerIconNode.swift
//  AiTest
//
//  Created by Joey's Mac mini on 6/11/26.
//

import SpriteKit

class PlayerIconNode: SKCropNode {
    
    static let prefixName = "playerIconNode_"
    static let borderNodeName = "borderNode"
    static let blinkBorderName = "blinkBorderNode"
    
    init(player: Player, position: CGPoint, size: CGSize) {
        super.init()
        
        let playerImageNode = SKSpriteNode(imageNamed: player.imageName)
        playerImageNode.name = "playerImageNode_\(player.index)"
        playerImageNode.size = size
        let playerImageMaskPath = UIBezierPath(roundedRect: playerImageNode.frame, cornerRadius: size.width / 2)
        let playerImageMaskNode = SKShapeNode(path: playerImageMaskPath.cgPath)
        playerImageMaskNode.name = "playerImageMaskNode_\(player.index)"
        playerImageMaskNode.fillColor = .black
        playerImageMaskNode.strokeColor = .white
        playerImageMaskNode.lineWidth = 2
        let borderNode = SKShapeNode(rectOf: size, cornerRadius: size.width / 2)
        borderNode.name = PlayerIconNode.borderNodeName
        borderNode.strokeColor = .white.withAlphaComponent(0.5)
        borderNode.lineWidth = 3.0
        borderNode.fillColor = .clear
        borderNode.zPosition = 100
        
        self.name = PlayerIconNode.prefixName + "\(player.index)"
        self.maskNode = playerImageMaskNode
        self.addChild(playerImageNode)
        self.addChild(borderNode)
        self.position.x = position.x + size.height / 2
        self.position.y = position.y + size.height / 2
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}

