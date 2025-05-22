//
//  BallNode.swift
//  CompBall
//
//  Created by 王政甯 on 2025/4/13.
//

import SpriteKit

// MARK: - 球本體 ----------------------------------------------------------
final class BallNode: SKSpriteNode {

    // MARK: 常數
    static let maxLevel = 11
    /// 各等級半徑（index 0 保留不用）
    static let radii: [CGFloat] = [
        0, 20, 28, 36, 44, 52, 60, 68, 76, 84, 92, 100
    ]

    // MARK: 變數
    var level: Int
    var isMerging = false

    // MARK: - 初始化
    init(level: Int) {
        self.level = level

        let texture = SKTexture(imageNamed: "ball_\(level)")
        let radius  = BallNode.radii[level]
        super.init(texture: texture,
                   color: .clear,
                   size: CGSize(width: radius * 2, height: radius * 2))

        configurePhysicsBody(radius: radius)
        zRotation = 0                                  // 初始不旋轉
    }

    required init?(coder aDecoder: NSCoder) {
        self.level = 1
        super.init(coder: aDecoder)
    }

    // MARK: - 公用方法
    /// 升一級並同步調整外觀／PhysicsBody
    func upgrade() {
        guard level < Self.maxLevel else { return }
        level += 1

        let newRadius = Self.radii[level]
        texture = SKTexture(imageNamed: "ball_\(level)")
        size    = CGSize(width: newRadius * 2, height: newRadius * 2)

        configurePhysicsBody(radius: newRadius)
    }

    // MARK: - 私用方法
    private func configurePhysicsBody(radius: CGFloat) {
        physicsBody = SKPhysicsBody(circleOfRadius: radius)
        physicsBody?.isDynamic        = true
        physicsBody?.restitution      = 0.1
        physicsBody?.friction         = 0.5
        physicsBody?.angularDamping   = 0.5
        physicsBody?.allowsRotation   = true
        physicsBody?.angularVelocity  = CGFloat.random(in: -2.5...2.5)
        physicsBody?.categoryBitMask  = PhysicsCategory.ball
        physicsBody?.collisionBitMask = PhysicsCategory.ball | PhysicsCategory.boundary
        physicsBody?.contactTestBitMask = PhysicsCategory.ball
    }
}

// MARK: - 物理碰撞分類 -----------------------------------------------------
struct PhysicsCategory {
    static let ball:     UInt32 = 0x1 << 0   // 球
    static let boundary: UInt32 = 0x1 << 1   // 邊界
}
