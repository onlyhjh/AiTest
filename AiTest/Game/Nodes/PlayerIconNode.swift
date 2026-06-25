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

    init(player: Player, size: CGSize, isBlink: Bool) {
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
        borderNode.fillColor = isBlink ? .yellow : .clear
        borderNode.zPosition = 100
        
        if isBlink {
            // 깜빡이는 액션
            let fadeOut = SKAction.fadeAlpha(to: 0.0, duration: 0.5)
            let fadeIn = SKAction.fadeAlpha(to: 0.5, duration: 0.5)
            let blink = SKAction.repeatForever(
                SKAction.sequence([fadeOut, fadeIn])
            )
            borderNode.run(blink)
        }
        
        self.name = PlayerIconNode.prefixName + "\(player.index)"
        self.maskNode = playerImageMaskNode
        self.addChild(playerImageNode)
        self.addChild(borderNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}

