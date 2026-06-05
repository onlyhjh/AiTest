//
//  CardNode.swift
//  AiTest
//
//  Created by Joey's Mac mini on 5/20/26.
//

import SpriteKit

enum CardNodeScale: CGFloat {
    case zoom = 3.0
    case large = 1.5
    case normal = 1.0
    case small = 0.5
}

class CardNode: SKSpriteNode {
    
    let card: Card
    var isFront: Bool
    let frontImage: UIImage
    
    init(name: String, card: Card, cardSize: CGSize, isFront: Bool) {
        self.card = card
        self.isFront = isFront
        
        self.frontImage = UIImage(named: card.imageName ?? "hwatu_back") ?? .hwatuBack
        let texture = SKTexture(image: isFront ? frontImage : .hwatuBack)
        
        super.init(texture: texture, color: .clear, size: cardSize)
        
        self.name = name
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    func moveAndTurnCard(movePosition: CGPoint, duration: TimeInterval = 0, isFront: Bool, zPosition: Int = 0, movingUpScale: CardNodeScale? = .zoom, afterCardNodeScale: CardNodeScale) {
        self.zPosition = 1000
        var sequnce: [SKAction] = []
        if let mus = movingUpScale {
            let halfPosition = CGPoint(x: movePosition.x - ((movePosition.x - self.position.x) / 2), y: movePosition.y - ((movePosition.y - self.position.y) / 2))
            //print("\(#function) halfPosition: \(halfPosition) = movePosition: \(movePosition) - self.position: \(self.position)  ")
            let move1Action = SKAction.move(to: halfPosition, duration: duration / 2)
            let scaleUpAction = SKAction.scale(to: mus.rawValue, duration: duration / 2)
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
        
        run(SKAction.sequence(sequnce), completion: { self.zPosition = CGFloat(zPosition) })
    }

}
