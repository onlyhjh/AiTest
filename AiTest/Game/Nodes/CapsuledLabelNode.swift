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
    static let prefixPlayerWinningCount = "playerWinningCount_"
    static let prefixPlayerMoney = "playerMoney_"
    static let prefixPlayerCapturedGroup = "playerCapturedGroupNode_"
    
    init(playerIndex: Int, playerName: String) {
        super.init()
        self.fontName = "Helvetica-Bold"
        self.fontSize = 20
        self.text = playerName
        self.name = CapsuledLabelNode.prefixPlayerName + "\(playerIndex)"
        self.fontColor = UIColor.white
        self.position = CGPoint(x: 0, y: 0)
        self.zPosition = 100
        
        let size = CGSize(width: self.frame.width + 15, height: self.frame.height + 6)
        let rect = CGRect(x: size.width / -2, y: self.frame.height / -2 + 5, width: size.width, height: size.height)
        let shapeNode = SKShapeNode(rect: rect, cornerRadius: size.height / 2)
        shapeNode.fillColor = .black.withAlphaComponent(0.5)
        shapeNode.zPosition = -1
        shapeNode.strokeColor = .black
        self.addChild(shapeNode)
    }
    
    init(playerIndex: Int, winningCount: Int) {
        super.init()
        self.fontName = "Helvetica-Bold"
        self.fontSize = 20
        self.text = winningCount == 1 ? "先" : "\(winningCount)연승"
        self.name = CapsuledLabelNode.prefixPlayerWinningCount + "\(playerIndex)"
        self.fontColor = UIColor.white
        self.position = CGPoint(x: 0, y: 0)
        self.zPosition = 100
        
        let size = CGSize(width: self.frame.width + 15, height: self.frame.height + 6)
        let rect = CGRect(x: size.width / -2, y: self.frame.height / -2 + 5, width: size.width, height: size.height)
        let shapeNode = SKShapeNode(rect: rect, cornerRadius: size.height / 2)
        shapeNode.fillColor = .red
        shapeNode.zPosition = -1
        shapeNode.strokeColor = .black
        self.addChild(shapeNode)
    }
    
    init(playerIndex: Int, money: Int) {
        super.init()
        self.fontName = "Helvetica"
        self.fontSize = 20
        self.text = "\(money)만냥"
        self.name = CapsuledLabelNode.prefixPlayerMoney + "\(playerIndex)"
        self.fontColor = UIColor.white
        self.position = CGPoint(x: 0, y: 0)
        self.zPosition = 100
        
        let size = CGSize(width: self.frame.width + 15, height: self.frame.height + 6)
        let rect = CGRect(x: size.width / -2, y: self.frame.height / -2 + 5, width: size.width, height: size.height)
        let shapeNode = SKShapeNode(rect: rect, cornerRadius: size.height / 2)
        shapeNode.fillColor = .blue
        shapeNode.zPosition = -1
        shapeNode.strokeColor = .black
        self.addChild(shapeNode)
    }
    
    init(playerIndex: Int, goCount: Int) {
        super.init()
        self.fontName = "System"
        self.text = "\(goCount)고"
        self.name = CapsuledLabelNode.prefixPlayerScore + "\(playerIndex)"
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
    
    init(playerIndex: Int, groupIndex: Int, score: Int) {
        super.init()
        self.fontName = "System"
        self.text = String(format: "%2d", score)
        self.name = CapsuledLabelNode.prefixPlayerCapturedGroup + "\(playerIndex)_\(groupIndex)"
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
