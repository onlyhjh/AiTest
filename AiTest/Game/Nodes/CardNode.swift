//
//  CardNode.swift
//  AiTest
//
//  Created by Joey's Mac mini on 5/20/26.
//

import SpriteKit

enum CardNodeScale: CGFloat {
    case zoom = 3.0
    case large = 1.7
    case normal = 1.0
    case small = 0.5
}

class CardNode: SKSpriteNode {
     
    static let borderNodeName = "borderNode"
    
    let card: Card
    var isFront: Bool
    let frontImage: UIImage
    
    init(name: String, card: Card, cardSize: CGSize, isFront: Bool) {
        self.card = card
        self.isFront = isFront
        
        self.frontImage = UIImage(named: card.imageName ?? Card.backImageName) ?? .hwatuBack
        let texture = SKTexture(image: isFront ? frontImage : .hwatuBack)
        
        super.init(texture: texture, color: .clear, size: cardSize)
        
        self.name = name
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    func moveAndTurnCard(movePosition: CGPoint, duration: TimeInterval = 0, isFront: Bool, zPosition: Int = 0, movingUpScale: CardNodeScale? = .zoom, afterCardNodeScale: CardNodeScale, completion: (() -> Void)? = nil) {
        self.zPosition = 1000
        var sequnce: [SKAction] = []
        if let movingUpScale {
            let halfPosition = CGPoint(x: movePosition.x - ((movePosition.x - self.position.x) / 2), y: movePosition.y - ((movePosition.y - self.position.y) / 2))
            //print("\(#function) halfPosition: \(halfPosition) = movePosition: \(movePosition) - self.position: \(self.position)  ")
            let move1Action = SKAction.move(to: halfPosition, duration: duration / 2)
            let scaleUpAction = SKAction.scale(to: movingUpScale.rawValue, duration: duration / 2)
            let moveWithScaleUpAction = SKAction.group([move1Action, scaleUpAction])
            
            let move2Action = SKAction.move(to: movePosition, duration: duration / 2)
            let scaleDownAction = SKAction.scale(to: afterCardNodeScale.rawValue, duration: duration / 2)
            let moveWithScaleDownAction = SKAction.group([move2Action, scaleDownAction])
            
            sequnce = [moveWithScaleUpAction, moveWithScaleDownAction]
        }
        else {
            let moveAction = SKAction.move(to: movePosition, duration: duration)
            //print("?\(#function) ??? scale compare 1:\(afterCardNodeScale.rawValue) <> 2:\(self.xScale)")
            if afterCardNodeScale.rawValue == self.xScale  {
                sequnce = [moveAction]
            }
            else {
                let scaleAction = SKAction.scale(to: afterCardNodeScale.rawValue, duration: duration)
                let moveWithChangeScaleAction = SKAction.group([moveAction, scaleAction])
                sequnce = [moveWithChangeScaleAction]
            }
        }
        
        if isFront != self.isFront {
            self.isFront = isFront
            let texture = SKTexture(image: isFront ? self.frontImage : .hwatuBack)
            let setTexture = SKAction.setTexture(texture)
            sequnce.append(setTexture)
        }
        
        run(SKAction.sequence(sequnce), completion: {
            self.zPosition = CGFloat(zPosition)
            completion?()
        })
    }
    
    func addStrokeWithBlink(size: CGSize) {
        self.removeAllChildren()
        let borderNode = SKShapeNode(rectOf: size, cornerRadius: 5)
        borderNode.name = CardNode.borderNodeName
        borderNode.strokeColor = .yellow
        borderNode.lineWidth = 2.0
        borderNode.fillColor = .clear
        self.addChild(borderNode)
        
        // 깜빡이는 액션
        let fadeOut = SKAction.fadeAlpha(to: 0.2, duration: 0.3)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.3)

        let blink = SKAction.repeatForever(
            SKAction.sequence([fadeOut, fadeIn])
        )
        borderNode.run(blink)
    }
    
    func removeStroke() {
        self.removeAllChildren()
    }
}
