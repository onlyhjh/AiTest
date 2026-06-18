//
//  CapsuledLabelNode.swift
//  AiTest
//
//  Created by Joey's Mac mini on 6/11/26.
//

import SpriteKit
import UIKit

class CapsuledLabelNode: SKLabelNode {
    
    static let prefixPlayerName = "playerNameLabelNode_"
    static let prefixPlayerScore = "playerScoreLabelNode_"
    static let prefixPlayerCapturedGroup = "playerCapturedGroupNode_"

    init(player: Player) {
        super.init()
        self.fontName = "Helvetica-Bold"
        self.fontSize = 20
        self.text = player.name
        self.name = CapsuledLabelNode.prefixPlayerName + "\(player.index)"
        self.fontColor = UIColor.white
        self.position = CGPoint(x: 0, y: 0)
        self.zPosition = 100
        
        let size = CGSize(width: self.frame.width + 15, height: self.frame.height + 6)
        let rect = CGRect(x: size.width / -2, y: self.frame.height / -2 + 5, width: size.width, height: size.height)
        let shapeNode = SKShapeNode(rect: rect, cornerRadius: size.height / 2)
        shapeNode.fillColor = .black.withAlphaComponent(0.5)
        shapeNode.zPosition = -1
        shapeNode.strokeColor = .clear
        self.addChild(shapeNode)
    }
    
    init(player: Player, goCount: Int) {
        super.init()
        self.fontName = "System"
        self.text = "\(goCount)고"
        self.name = CapsuledLabelNode.prefixPlayerScore + "\(player.index)"
        self.fontColor = UIColor.yellow
        self.fontSize = 20
        self.position = CGPoint(x: 0, y: 0)
        self.zPosition = 100
        
        let size = CGSize(width: self.frame.width + 15, height: self.frame.height + 6)
        let rect = CGRect(x: size.width / -2, y: self.frame.height / -2 + 5, width: size.width, height: size.height)
        let shapeNode = SKShapeNode(rect: rect, cornerRadius: size.height / 2)
        shapeNode.fillColor = .red.withAlphaComponent(0.5)
        shapeNode.zPosition = -1
        shapeNode.strokeColor = .clear
        self.addChild(shapeNode)
    }
    
    init(player: Player, groupIndex: Int, score: Int) {
        super.init()
        self.fontName = "System"
        self.text = String(format: "%2d", score)
        self.name = CapsuledLabelNode.prefixPlayerCapturedGroup + "\(player.index)_\(groupIndex)"
        self.fontColor = UIColor.yellow
        self.fontSize = 18
        self.position = CGPoint(x: 0, y: 0)
        self.zPosition = 100
        
        let size = CGSize(width: self.frame.width + 15, height: self.frame.height + 6)
        let rect = CGRect(x: size.width / -2, y: self.frame.height / -2 + 5, width: size.width, height: size.height)
        let shapeNode = SKShapeNode(rect: rect, cornerRadius: size.height / 2)
        shapeNode.fillColor = .black.withAlphaComponent(0.5)
        shapeNode.zPosition = -1
        shapeNode.strokeColor = .clear
        self.addChild(shapeNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
