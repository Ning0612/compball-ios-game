//
//  GameScene.swift
//  CompBall
//
//  Created by 王政甯 on 2025/4/13.
//

import SpriteKit
import GameplayKit
import AVFoundation

// MARK: - Notification Extension
extension Notification.Name {
    static let gameOverScore = Notification.Name("GameOverScore")
}

// MARK: - GameSceneClass
class GameScene: SKScene, SKPhysicsContactDelegate {

    // MARK: - Game Mode Property
    let mode: GameMode

    // MARK: - Game Container Area Properties
    private var containerWidth: CGFloat = 0        // 容器寬度（左右邊界距離）
    private var containerHeight: CGFloat = 0       // 容器高度（底部到開口處距離）
    private var containerLeftX: CGFloat = 0        // 容器左側 X 座標
    private var containerRightX: CGFloat = 0       // 容器右側 X 座標

    // MARK: - Game State Properties
    private var score: Int = 0                     // 當前分數
    private var scoreLabel: SKLabelNode!           // 顯示分數的標籤節點
    private var gameOver: Bool = false             // 遊戲是否結束的狀態旗標
    private var waitingForNextBall = false         // 判斷是否需要等待球完全落下才能生成新球
    private var restartLocked = false              // 防止連點「重新開始」按鈕

    // MARK: - Timer Related Properties (Countdown Mode)
    private var startTime: TimeInterval = 0        // 遊戲開始時間
    private var pauseAccum: TimeInterval = 0       // 累計暫停時間
    private var pauseBegin: TimeInterval?          // 暫停開始時間
    private var timeLeft: Double = 30              // 倒數模式剩餘秒數
    private var lastUpdate: TimeInterval = 0       // 上次更新時間
    private var timerLabel: SKLabelNode?           // 顯示時間的標籤節點
    private var countdownLabel: SKLabelNode?       // 顯示遊戲結束倒數的標籤

    // MARK: - Ball Preview and Dragging Properties
    /// 預覽球隊列：第一個元素為即將掉落球（放在容器中間），第二個為右側預覽（下一顆球）
    private var ballQueue: [Int] = []
    /// 用於右側預覽的球節點（僅顯示下一顆）
    private var previewNodes: [SKSpriteNode] = []
    /// 場景中所有已釋放的球（方便統計及後續清除）
    private var activeBalls: [BallNode] = []
    /// 正在拖曳的球（即將放下的球，顯示於容器中間）
    private var draggableBall: BallNode?
    /// 拖曳旗標
    private var isDragging: Bool = false
    /// 記錄球持續超出容器頂端的起始時間
    private var gameOverTimer: TimeInterval? = nil

    // MARK: - Game Data (Scores and Bonus)
    /// 分數對照表：合成後獲得的分數（索引為合成後的等級）
    private let scoreValues: [Int] = [
        0,   // index 0 不
        1,   // Level 1 球合成得分 1 (初始生成最低等級不需合成)
        3,   // Level 2 球合成得分 3
        6,   // Level 3 球合成得分 6
        10,  // Level 4 球合成得分 10
        15,  // Level 5 球合成得分 15
        21,  // Level 6 球合成得分 21
        28,  // Level 7 球合成得分 28
        36,  // Level 8 球合成得分 36
        45,  // Level 9 球合成得分 45
        55,  // Level 10 球合成得分 55
        66   // Level 11 球合成得分 66
    ]

    /// 各等級升級後補秒（索引為升級後等級）
    private static let bonusSeconds: [Float] = [
        0,   // dummy for index 0
        0,
        0.2,
        0.4,
        0.6,
        0.9,
        1.3,
        1.7,
        2.3,
        3.4,
        4.5,
        6
    ]

    // MARK: - Initialization
    init(size: CGSize, mode: GameMode) {
        self.mode = mode
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        // 加入背景圖
        let background = SKSpriteNode(imageNamed: "game_background")
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.zPosition = -1 // 放到最底層
        background.size = size
        addChild(background)


        // 計算遊戲容器的尺寸與位置
        containerWidth = size.width * 0.6
        containerHeight = size.height * 0.85
        containerLeftX = (size.width - containerWidth) / 2
        containerRightX = containerLeftX + containerWidth

        // 設定物理世界與碰撞代理
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        physicsWorld.contactDelegate = self

        // 建立物理邊界及視覺標示
        setupContainerBoundaries()

        // 添加分數與時間標籤
        setupScoreLabel()
        setupTimerLabel()

        // 初始化遊戲狀態
        score = 0
        gameOver = false
        waitingForNextBall = false
        timeLeft = (mode == .countdown) ? 30 : 0
        startTime = CACurrentMediaTime()
        lastUpdate = CACurrentMediaTime()
        pauseAccum = 0
        pauseBegin = nil

        // 初始化預覽球隊列並顯示
        ballQueue = [randomBallLevel(), randomBallLevel()]
        showPreviewQueue()
        prepareDroppableBall()

        // 播放背景音樂
        AudioManager.playBGM()
    }

    // MARK: - Setup Methods
    /// 建立容器的物理邊界（左牆、右牆、底部）以及視覺標示：頂部虛線、底部實線
    private func setupContainerBoundaries() {
        // 左側邊界
        let leftEdge = SKNode()
        leftEdge.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x: containerLeftX, y: 0),
                                             to: CGPoint(x: containerLeftX, y: containerHeight))
        leftEdge.physicsBody?.categoryBitMask = PhysicsCategory.boundary
        leftEdge.physicsBody?.collisionBitMask = PhysicsCategory.ball
        addChild(leftEdge)

        // 右側邊界
        let rightEdge = SKNode()
        rightEdge.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x: containerRightX, y: 0),
                                              to: CGPoint(x: containerRightX, y: containerHeight))
        rightEdge.physicsBody?.categoryBitMask = PhysicsCategory.boundary
        rightEdge.physicsBody?.collisionBitMask = PhysicsCategory.ball
        addChild(rightEdge)
        
        // 底部物理邊界節點
        let bottomEdgeNode = SKNode()
        bottomEdgeNode.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x: containerLeftX, y:22),
                                                   to: CGPoint(x: containerRightX, y: 22))
        bottomEdgeNode.physicsBody?.categoryBitMask = PhysicsCategory.boundary
        bottomEdgeNode.physicsBody?.collisionBitMask = PhysicsCategory.ball
        addChild(bottomEdgeNode)

        /*
        // 視覺化顯示：左側邊界線
        let leftEdgePath = CGMutablePath()
        leftEdgePath.move(to: CGPoint(x: containerLeftX, y: 22))
        leftEdgePath.addLine(to: CGPoint(x: containerLeftX, y: containerHeight))
        let leftEdgeShape = SKShapeNode(path: leftEdgePath)
        leftEdgeShape.strokeColor = .white
        leftEdgeShape.lineWidth = 2
        addChild(leftEdgeShape)

        // 視覺化顯示：右側邊界線
        let rightEdgePath = CGMutablePath()
        rightEdgePath.move(to: CGPoint(x: containerRightX, y: 22))
        rightEdgePath.addLine(to: CGPoint(x: containerRightX, y: containerHeight))
        let rightEdgeShape = SKShapeNode(path: rightEdgePath)
        rightEdgeShape.strokeColor = .white
        rightEdgeShape.lineWidth = 2
        addChild(rightEdgeShape)

        // 視覺化顯示：頂部虛線（遊戲結束判斷線）
        let topPath = CGMutablePath()
        topPath.move(to: CGPoint(x: containerLeftX, y: containerHeight))
        topPath.addLine(to: CGPoint(x: containerRightX, y: containerHeight))
        let topEdge = SKShapeNode(path: topPath)
        topEdge.strokeColor = SKColor.white.withAlphaComponent(0.3)
        topEdge.lineWidth = 2
        addChild(topEdge)

        // 視覺化顯示：底部實線
        let bottomPath = CGMutablePath()
        bottomPath.move(to: CGPoint(x: containerLeftX, y: 22))
        bottomPath.addLine(to: CGPoint(x: containerRightX, y: 22))
        let bottomEdgeShape = SKShapeNode(path: bottomPath)
        bottomEdgeShape.strokeColor = .white
        bottomEdgeShape.lineWidth = 2
        addChild(bottomEdgeShape)
        */
    }

    /// 設定並添加顯示分數的標籤
    private func setupScoreLabel() {
        scoreLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        scoreLabel.fontSize = 34
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: containerLeftX - 140, y: containerHeight + 50)
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.text = "Score: 0"
        addChild(scoreLabel)
    }

    /// 設定並添加顯示時間的標籤 (僅限倒數模式)
    private func setupTimerLabel() {
        guard mode == .countdown else { return } // 只在倒數模式顯示
        let label = SKLabelNode(fontNamed: "Arial-BoldMT")
        label.fontSize = 32
        label.fontColor = .green
        label.horizontalAlignmentMode = .left
        label.position = CGPoint(x: scoreLabel.position.x,
                                 y: scoreLabel.position.y - 40)
        label.text = String(format: "Time  %.1f", timeLeft)
        addChild(label)
        timerLabel = label
    }

    // MARK: - Ball Management
    /// 隨機產生 1～5 級的球（較低等級機率較高）
    private func randomBallLevel() -> Int {
        let rand = Int.random(in: 1...100)
        if rand <= 30 {
            return 1
        } else if rand <= 50 {
            return 2
        } else if rand <= 70 {
            return 3
        } else if rand <= 90 {
            return 4
        } else {
            return 5
        }
    }

    /// 右側預覽區僅顯示下一顆球（ballQueue[1]）
    private func showPreviewQueue() {
        for node in previewNodes {
            node.removeFromParent()
        }
        previewNodes.removeAll()

        if ballQueue.count > 1 {
            let level = ballQueue[1]
            let baseX = containerRightX + 60  // 預覽區 X 位置
            let baseY = containerHeight + 50    // 預覽區 Y 起始位置
            let radius = BallNode.radii[level]

            let previewBall = SKSpriteNode(texture: SKTexture(imageNamed: "ball_\(level)"))
            previewBall.size = CGSize(width: radius * 2, height: radius * 2)
            previewBall.position = CGPoint(x: baseX, y: baseY)
            addChild(previewBall)
            previewNodes.append(previewBall)
        }
    }

    /// 準備顯示放球區中間可拖曳的球（取自 ballQueue[0]）
    private func prepareDroppableBall() {
        let level = ballQueue[0]
        let ball = BallNode(level: level)
        let radius = BallNode.radii[level]
        let spawnX = (containerLeftX + containerRightX) / 2
        let spawnY = containerHeight + radius
        ball.position = CGPoint(x: spawnX, y: spawnY)
        ball.physicsBody?.isDynamic = false  // 預覽時暫停物理作用
        addChild(ball)
        draggableBall = ball
    }

    // MARK: - Touch Event Handling (Ball Dropping)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !self.isPaused else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if gameOver && !restartLocked {
            let touchedNodes = nodes(at: location)
            for node in touchedNodes {
                if node.name == "restartButton" {
                    restartGame()
                    return
                }
            }
        } else {
            if let ball = draggableBall {
                // 直接讓球移動到按下位置的 x，y 不變
                let radius = BallNode.radii[ball.level]
                var newX = location.x
                if newX < containerLeftX + radius {
                    newX = containerLeftX + radius + 2
                }
                if newX > containerRightX - radius {
                    newX = containerRightX - radius - 2
                }
                ball.position = CGPoint(x: newX, y: ball.position.y)

                // 啟用拖曳
                isDragging = true
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !self.isPaused else { return }
        guard isDragging, let touch = touches.first, let ball = draggableBall else { return }
        let location = touch.location(in: self)
        let radius = BallNode.radii[ball.level]
        var newX = location.x
        if newX < containerLeftX + radius {
            newX = containerLeftX + radius + 2
        }
        if newX > containerRightX - radius {
            newX = containerRightX - radius - 1
        }
        ball.position = CGPoint(x: newX, y: ball.position.y)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !self.isPaused else { return }
        if isDragging, let ball = draggableBall {
            ball.physicsBody?.isDynamic = true
            activeBalls.append(ball)
            draggableBall = nil
            isDragging = false

            // 更新球隊列
            ballQueue[0] = ballQueue[1]
            ballQueue[1] = randomBallLevel()
            showPreviewQueue()

            // 不立即生成，設旗標等待球完全落下
            waitingForNextBall = true
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !self.isPaused else { return }
        touchesEnded(touches, with: event)
    }

    // MARK: - External Control / Scene State Management
    /// 當遊戲被暫停 / 恢復時呼叫，以重置「球超出邊界」倒數計時
    func resetBoundaryCountdown() {
        gameOverTimer = nil
    }

    /// 記錄遊戲暫停時間
    func sceneDidPause() {
        pauseBegin = CACurrentMediaTime()
    }

    /// 計算遊戲恢復時間
    func sceneDidResume() {
        if let p = pauseBegin {
            pauseAccum += CACurrentMediaTime() - p
        }
        pauseBegin = nil
        lastUpdate = CACurrentMediaTime()
    }

    // MARK: - Physics Contact Delegate
    func didBegin(_ contact: SKPhysicsContact) {
        guard let ballA = contact.bodyA.node as? BallNode,
              let ballB = contact.bodyB.node as? BallNode else { return }

        // 等級不符 或 任一球已在合成中 -> 不處理
        guard ballA.level == ballB.level,
              ballA.level < BallNode.maxLevel,
              !ballA.isMerging, !ballB.isMerging else { return }

        // 設為正在合成，避免重複
        ballA.isMerging = true
        ballB.isMerging = true

        // 決定上、下球
        let (upperBall, lowerBall) = ballA.position.y > ballB.position.y
            ? (ballA, ballB)
            : (ballB, ballA)

        // 移除上方球
        upperBall.removeFromParent()
        if let index = activeBalls.firstIndex(of: upperBall) {
            activeBalls.remove(at: index)
        }

        // 延遲升級下方球並播放特效與音效
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.1),
            SKAction.run {
                // 加入合成特效
                if let emitter = SKEmitterNode(fileNamed: "merge.sks") {
                    emitter.position = lowerBall.position

                    // 動態設定粒子圖片貼圖為合成後等級對應的 ball_x.png
                    let mergedLevel = lowerBall.level + 1
                    let textureName = "ball_\(mergedLevel)"
                    let texture = SKTexture(imageNamed: textureName)
                    emitter.particleTexture = texture

                    emitter.zPosition = 50
                    self.addChild(emitter)

                    // 自動移除特效（建議與 .sks 的 lifetime 對應）
                    emitter.run(SKAction.sequence([
                        SKAction.wait(forDuration: 0.3),
                        SKAction.removeFromParent()
                    ]))
                }

                AudioManager.playEffect(named: "merge.wav", on: self)

                lowerBall.upgrade()
                lowerBall.isMerging = false // 升級完成，釋放旗標
 
                // 更新分數
                let newLevel = lowerBall.level
                if newLevel < self.scoreValues.count {
                    self.score += self.scoreValues[newLevel]
                }
                self.scoreLabel.text = "Score: \(self.score)"
            }
        ]))
    }

    // MARK: - Game Loop
    override func update(_ currentTime: TimeInterval) {
        guard !gameOver else { return }

        // 判斷落球是否還在容器上方（延遲生成新球）
        if waitingForNextBall, let lastBall = activeBalls.last {
            let radius = BallNode.radii[lastBall.level]
            if lastBall.position.y + radius < containerHeight {
                waitingForNextBall = false
                prepareDroppableBall()
            }
        }

        // -------- 倒數模式計時 --------
        let dt = currentTime - lastUpdate
        if mode == .countdown {
            timeLeft -= dt
            timerLabel?.text = String(format: "Time  %.1f", max(0, timeLeft))
            timerLabel?.fontColor = timeLeft <= 10 ? .red : .green
            if timeLeft <= 0 { triggerGameOver() } // 時間到，遊戲結束
        }
        lastUpdate = currentTime

        // -------- 遊戲結束判斷 (球超出容器頂端) --------
        let ballAboveExists = activeBalls.contains { ball in
            guard ball.parent != nil else { return false } // 確保球仍在場景中
            let radius = BallNode.radii[ball.level]
            return ball.position.y + radius > containerHeight
        }

        if ballAboveExists {
            if gameOverTimer == nil {
                gameOverTimer = currentTime // 首次超出頂端，開始計時
            }

            let elapsed = currentTime - (gameOverTimer ?? currentTime)
            let remaining = max(0, 5.0 - elapsed) // 5 秒倒數

            // 顯示倒數警告標籤
            if countdownLabel == nil {
                let label = SKLabelNode(fontNamed: "Arial-BoldMT")
                label.fontSize = 24
                label.fontColor = .red
                label.position = CGPoint(x: size.width / 2, y: containerHeight + 60)
                label.zPosition = 100
                countdownLabel = label
                addChild(label)
            }

            // 更新倒數文字
            if remaining < 4.5 { // 避免剛出現時就顯示倒數
                countdownLabel?.text = String(format: "⚠️ 超界 ⚠️ 倒數 %.1f 秒", remaining)
            }

            if remaining <= 0 {
                triggerGameOver() // 倒數結束，遊戲結束
            }
        } else {
            // 如果沒有球超出頂端，重置計時器並移除警告標籤
            gameOverTimer = nil
            countdownLabel?.removeFromParent()
            countdownLabel = nil
        }
    }

    // MARK: - Game Over & Restart
    /// 遊戲結束處理：停止物理模擬、顯示分數及重新開始選項，並儲存分數
    private func triggerGameOver() {
        gameOver = true
        physicsWorld.speed = 0 // 停止所有物理運動

        // 顯示遊戲結束訊息
        let gameOverLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        gameOverLabel.text = "遊戲結束! 得分: \(score)"
        gameOverLabel.fontSize = 32
        gameOverLabel.fontColor = .yellow
        gameOverLabel.position = CGPoint(x: size.width / 2, y: containerHeight / 2 + 40)
        addChild(gameOverLabel)

        // 顯示重新開始按鈕
        let restartLabel = SKLabelNode(fontNamed: "Arial")
        restartLabel.text = "重新開始"
        restartLabel.fontSize = 36
        restartLabel.fontColor = .white
        restartLabel.position = CGPoint(x: size.width / 2, y: containerHeight / 2 - 20)
        restartLabel.name = "restartButton" // 設定名稱方便觸碰事件識別
        addChild(restartLabel)

        // 取得目前榜單資料
        let currentTop: [Any]
        switch mode {
        case .normal:      currentTop = ScoreManager.topNormal()
        case .countdown:   currentTop = ScoreManager.topCountdown()
        }

        // 判斷是否進榜 (前十名)
        let threshold = (currentTop as? [NormalEntry])?.last?.score ??
                        (currentTop as? [CountdownEntry])?.last?.score ?? 0
        let qualifies = currentTop.count < 10 || score > threshold

        if qualifies {
            // 如果進榜，發送通知讓外部 (e.g., ViewController) 處理輸入玩家名稱
            var info: [String: Any] = ["score": score]
            if mode == .countdown {
                let elapsed = Int(CACurrentMediaTime() - startTime - pauseAccum) // 計算實際遊玩時間
                info["seconds"] = elapsed
            }
            NotificationCenter.default.post(name: .gameOverScore,
                                            object: nil,
                                            userInfo: info)
            self.isPaused = true // 暫停場景，等待名稱輸入
        } else {
            // 未進榜則直接儲存 (Player 作為預設名稱)
            if mode == .normal {
                ScoreManager.addNormal(name: "Player", score: score)
            } else {
                let elapsed = Int(CACurrentMediaTime() - startTime - pauseAccum)
                ScoreManager.addCountdown(name: "Player", score: score, seconds: elapsed)
            }
        }

        // 顯示最高紀錄
        let bestScore: Int? = {
            switch mode {
            case .normal:
                return ScoreManager.topNormal().first?.score
            case .countdown:
                return ScoreManager.topCountdown().first?.score
            }
        }()

        if let best = bestScore {
            let bestLabel = SKLabelNode(fontNamed: "Arial")
            bestLabel.text = "最高紀錄: \(best)"
            bestLabel.fontSize = 28
            bestLabel.fontColor = .white
            bestLabel.position = CGPoint(x: size.width/2, y: containerHeight/2 - 60)
            addChild(bestLabel)
        }
    }

    /// 重新開始遊戲：重設所有遊戲狀態、清除節點並重新初始化
    private func restartGame() {
        // 發送通知清除上一次的遊戲結束分數提示 (如果有的話)
        NotificationCenter.default.post(name: .gameOverScore, object: nil, userInfo: [:])
        
        restartLocked = false // 解鎖重新開始按鈕
        gameOver = false
        physicsWorld.speed = 1 // 恢復物理模擬速度
        self.isPaused = false // 解除場景暫停

        // 移除所有子節點，清除所有球和標籤
        removeAllChildren()
        activeBalls.removeAll()
        previewNodes.removeAll()
        countdownLabel = nil
        timerLabel = nil

        // 重設遊戲數據
        score = 0
        gameOverTimer = nil
        waitingForNextBall = false
        timeLeft = (mode == .countdown) ? 30 : 0
        startTime = CACurrentMediaTime()
        lastUpdate = startTime
        pauseAccum = 0
        pauseBegin = nil

        // 重新設定遊戲元素
        setupContainerBoundaries()
        setupScoreLabel()
        setupTimerLabel()

        // 重新初始化球隊列和可拖曳球
        ballQueue = [randomBallLevel(), randomBallLevel()]
        showPreviewQueue()
        prepareDroppableBall()
        
        let background = SKSpriteNode(imageNamed: "game_background")
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.zPosition = -1 // 放到最底層
        background.size = size
        addChild(background)
    }
}
