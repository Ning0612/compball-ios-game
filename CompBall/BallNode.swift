//
//  BallNode.swift
//  CompBall
//
//  Created by 王政甯 on 2025/4/13.
//

import SpriteKit

class BallNode: SKSpriteNode {
    
    static let maxLevel: Int = 11
    
    static let radii: [CGFloat] = [
        0, 20, 28, 36, 44, 52, 60, 68, 76, 84, 92, 100
    ]
    
    var level: Int
    
    var isMerging = false


    init(level: Int) {
        self.level = level
        
        let texture = SKTexture(imageNamed: "ball_\(level)")
        let radius = BallNode.radii[level]
        let size = CGSize(width: radius * 2, height: radius * 2)
        
        super.init(texture: texture, color: .clear, size: size)
        
        self.zRotation = 0  // 初始不轉
        
        self.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        self.physicsBody?.isDynamic = true
        self.physicsBody?.restitution = 0.1
        self.physicsBody?.friction = 0.5
        self.physicsBody?.angularDamping = 0.5
        self.physicsBody?.allowsRotation = true
        self.physicsBody?.angularVelocity = CGFloat.random(in: -2.5...2.5)
        
        self.physicsBody?.categoryBitMask = PhysicsCategory.ball
        self.physicsBody?.collisionBitMask = PhysicsCategory.ball | PhysicsCategory.boundary
        self.physicsBody?.contactTestBitMask = PhysicsCategory.ball
    }

    required init?(coder aDecoder: NSCoder) {
        self.level = 1
        super.init(coder: aDecoder)
    }

    func upgrade() {
        guard level < BallNode.maxLevel else { return }
        level += 1
        
        let newTexture = SKTexture(imageNamed: "ball_\(level)")
        self.texture = newTexture
        let newRadius = BallNode.radii[level]
        self.size = CGSize(width: newRadius * 2, height: newRadius * 2)
        
        self.physicsBody = SKPhysicsBody(circleOfRadius: newRadius)
        self.physicsBody?.isDynamic = true
        self.physicsBody?.restitution = 0.1
        self.physicsBody?.friction = 0.5
        self.physicsBody?.angularDamping = 0.5
        self.physicsBody?.allowsRotation = true
        self.physicsBody?.categoryBitMask = PhysicsCategory.ball
        self.physicsBody?.collisionBitMask = PhysicsCategory.ball | PhysicsCategory.boundary
        self.physicsBody?.contactTestBitMask = PhysicsCategory.ball
    }
}


/// 定義物理碰撞的類別位元掩碼，用於分類物理體
struct PhysicsCategory {
    static let ball: UInt32 = 0x1 << 0      // 類別 1：球
    static let boundary: UInt32 = 0x1 << 1  // 類別 2：邊界
}
