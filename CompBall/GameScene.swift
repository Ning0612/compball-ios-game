//
//  GameScene.swift
//  CompBall
//
//  Created by 王政甯 on 2025/4/13.
//

import SpriteKit
import GameplayKit
import AVFoundation

extension Notification.Name {
    static let gameOverScore = Notification.Name("GameOverScore")
}
 
class GameScene: SKScene, SKPhysicsContactDelegate {
    let mode: GameMode
    // MARK: - 遊戲容器區域參數
    private var containerWidth: CGFloat = 0    // 容器寬度（左右邊界距離）
    private var containerHeight: CGFloat = 0   // 容器高度（底部到開口處距離）
    private var containerLeftX: CGFloat = 0    // 容器左側 X 座標
    private var containerRightX: CGFloat = 0   // 容器右側 X 座標
    private var countdownLabel: SKLabelNode?

    // MARK: - 遊戲狀態參數
    private var score: Int = 0                 // 當前分數
    private var scoreLabel: SKLabelNode!       // 顯示分數的標籤節點
    private var gameOver: Bool = false         // 遊戲是否結束的狀態旗標
    
    // 追蹤遊玩時間（倒數模式用）
    private var startTime: TimeInterval = 0
    private var pauseAccum: TimeInterval = 0
    private var pauseBegin: TimeInterval?

    private var waitingForNextBall = false
    private var restartLocked = false     // 防止連點「重新開始」

    private var bgmPlayer: AVAudioPlayer?
        
    // MARK: - 預覽與拖曳相關
    /// 預覽球隊列：第一個元素為即將掉落球（放在容器中間），第二個為右側預覽（下一顆球）
    private var ballQueue: [Int] = [Int]()
    /// 用於右側預覽的球節點（僅顯示下一顆）
    private var previewNodes: [SKSpriteNode] = []
    /// 場景中所有已釋放的球（方便統計及後續清除）
    private var activeBalls: [BallNode] = []
    
    // MARK: - 分數對照表：合成後獲得的分數
    private let scoreValues: [Int] = [
        0,   // index0 不使用
        1,   // 合成 Level1（初始生成最低等級不需合成）
        3,   // Level2 球合成得分 3
        6,   // Level3 球合成得分 6
        10,  // Level4 球合成得分 10
        15,  // Level5 球合成得分 15
        21,  // Level6 球合成得分 21
        28,  // Level7 球合成得分 28
        36,  // Level8 球合成得分 36
        45,  // Level9 球合成得分 45
        55,  // Level10 球合成得分 55
        66   // Level11 球合成得分 66
    ]
    
    /// 各等級升級後補秒（index = 升級後等級）
    private static let bonusSeconds: [Float] = [
        0,  // dummy for index 0
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
    
    // 倒數模式
    private var timeLeft: Double = 30          // 剩餘秒
    private var lastUpdate: TimeInterval = 0
    private var timerLabel: SKLabelNode?

    // MARK: - 拖曳球與結束判斷相關
    /// 正在拖曳的球（即將放下的球，顯示於容器中間）
    private var draggableBall: BallNode?
    /// 拖曳旗標
    private var isDragging: Bool = false
    /// 記錄球持續超出容器頂端的起始時間
    private var gameOverTimer: TimeInterval? = nil
    
    init(size: CGSize, mode: GameMode) {
        self.mode = mode
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - 場景初始化（視圖呈現場景時呼叫）
    override func didMove(to view: SKView) {
        // 設定背景顏色
        self.backgroundColor = SKColor.black
        
        // 調整容器尺寸：原先 containerWidth = size.width * 0.8, containerHeight = size.height * 0.85，現各縮小約 90%
        containerWidth = size.width * 0.72
        containerHeight = size.height * 0.765
        containerLeftX = (size.width - containerWidth) / 2
        containerRightX = containerLeftX + containerWidth
        
        // 設定物理世界與碰撞代理
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        physicsWorld.contactDelegate = self
        
        // 建立物理邊界（左牆、右牆、底部）以及視覺標示（頂部虛線、底部實線）
        setupContainerBoundaries()
        
        // 添加分數標籤
        setupScoreLabel()
        setupTimerLabel()
        
        // 初始化預覽球隊列：第一顆為即將掉落的球，第二顆為右側預覽（下一顆）
        ballQueue = [randomBallLevel(), randomBallLevel()]
        // 右側預覽只保留下一顆
        showPreviewQueue()
        // 準備顯示放球區中間的可拖曳球（取自 ballQueue[0]）
        prepareDroppableBall()
        score = 0
        gameOver = false
        AudioManager.playBGM()
        startTime = CACurrentMediaTime()
        lastUpdate = CACurrentMediaTime()
    }
    
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
        bottomEdgeNode.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x: containerLeftX, y: 0),
                                                   to: CGPoint(x: containerRightX, y: 0))
        bottomEdgeNode.physicsBody?.categoryBitMask = PhysicsCategory.boundary
        bottomEdgeNode.physicsBody?.collisionBitMask = PhysicsCategory.ball
        addChild(bottomEdgeNode)
        
        // 建立右側邊界的視覺化顯示
        let rightEdgePath = CGMutablePath()
        rightEdgePath.move(to: CGPoint(x: containerRightX, y: 0))
        rightEdgePath.addLine(to: CGPoint(x: containerRightX, y: containerHeight))
        let rightEdgeShape = SKShapeNode(path: rightEdgePath)
        rightEdgeShape.strokeColor = .white   // 設定邊界顏色為紅色，可依需求調整
        rightEdgeShape.lineWidth = 2
        addChild(rightEdgeShape)
        
        // 建立右側邊界的視覺化顯示
        let leftEdgePath = CGMutablePath()
        leftEdgePath.move(to: CGPoint(x: containerLeftX, y: 0))
        leftEdgePath.addLine(to: CGPoint(x: containerLeftX, y: containerHeight))
        let leftEdgeShape = SKShapeNode(path: leftEdgePath)
        leftEdgeShape.strokeColor = .white   // 設定邊界顏色為紅色，可依需求調整
        leftEdgeShape.lineWidth = 2
        addChild(leftEdgeShape)
        
        // 視覺標示：頂部虛線
        let topPath = CGMutablePath()
        topPath.move(to: CGPoint(x: containerLeftX, y: containerHeight))
        topPath.addLine(to: CGPoint(x: containerRightX, y: containerHeight))
        let topEdge = SKShapeNode(path: topPath)
        topEdge.strokeColor = SKColor.white.withAlphaComponent(0.3)
        topEdge.lineWidth = 2
        addChild(topEdge)
         
        
        // 視覺標示：底部實線
        let bottomPath = CGMutablePath()
        bottomPath.move(to: CGPoint(x: containerLeftX, y: 0))
        bottomPath.addLine(to: CGPoint(x: containerRightX, y: 0))
        let bottomEdgeShape = SKShapeNode(path: bottomPath)
        bottomEdgeShape.strokeColor = .white
        bottomEdgeShape.lineWidth = 2
        addChild(bottomEdgeShape)
    }
    
    /// 設定並添加顯示分數的標籤
    private func setupScoreLabel() {
        scoreLabel = SKLabelNode(fontNamed: "Arial")
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: containerLeftX + 10, y: containerHeight + 30)
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.text = "Score: 0"
        addChild(scoreLabel)
    }
    
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
                let baseY = containerHeight + 50   // 預覽區 Y 起始位置
                let radius = BallNode.radii[level]

                // 原本用 SKShapeNode 畫圓＋填貼圖
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
    
    private func setupTimerLabel() {
        guard mode == .countdown else { return }      // 只在倒數模式顯示
        let label = SKLabelNode(fontNamed: "Arial-BoldMT")
        label.fontSize = 26
        label.fontColor = .green
        // —— 位置：分數標籤正下方 35pt ——
        label.horizontalAlignmentMode = .left
        label.position = CGPoint(x: scoreLabel.position.x,
                                 y: scoreLabel.position.y - 35)
        label.text = String(format: "TIME  %.1f", timeLeft)
        addChild(label)
        timerLabel = label
    }

    // MARK: - 觸碰事件處理（拖曳放球）
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !self.isPaused else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if gameOver && !restartLocked{
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
    
    // MARK: - 外部控制
    /// 當遊戲被暫停 / 恢復時呼叫，以重置「球超出邊界」倒數計時
    func resetBoundaryCountdown() {
        gameOverTimer = nil          
    }
    
    func sceneDidPause() {
        pauseBegin = CACurrentMediaTime()
    }

    func sceneDidResume() {
        if let p = pauseBegin {
            pauseAccum += CACurrentMediaTime() - p
        }
        pauseBegin = nil
    }

    
    // MARK: - 物理碰撞處理
    func didBegin(_ contact: SKPhysicsContact) {
        guard let ballA = contact.bodyA.node as? BallNode,
              let ballB = contact.bodyB.node as? BallNode else { return }

        // 等級不符 or 任一球已在合成中 → 不處理
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

        // 延遲升級下方球
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
                
                if self.mode == .countdown {
                    let bonus = GameScene.bonusSeconds[lowerBall.level]
                    self.timeLeft += Double(bonus)
                    self.timerLabel?.fontColor = self.timeLeft <= 10 ? .red : .green
                    self.timerLabel?.text = String(format: "TIME  %.1f", self.timeLeft)
                }

                let newLevel = lowerBall.level
                if newLevel < self.scoreValues.count {
                    self.score += self.scoreValues[newLevel]
                }

                self.scoreLabel.text = "Score: \(self.score)"
            }
        ]))
    }


    
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

        // （以下為你原本已有的遊戲結束檢查）
        let ballAboveExists = activeBalls.contains { ball in
            guard ball.parent != nil else { return false }
            let radius = BallNode.radii[ball.level]
            return ball.position.y + radius > containerHeight
        }
        
        if mode == .countdown && !isPaused {
            let dt = currentTime - lastUpdate
            timeLeft -= dt
            timerLabel?.text = String(format: "TIME  %.1f", max(0, timeLeft))
            timerLabel?.fontColor = timeLeft <= 10 ? .red : .green
            if timeLeft <= 0 { triggerGameOver() }
        }
        lastUpdate = currentTime

        if ballAboveExists {
            if gameOverTimer == nil {
                gameOverTimer = currentTime
            }

            let elapsed = currentTime - (gameOverTimer ?? currentTime)
            let remaining = max(0, 5.0 - elapsed)

            if countdownLabel == nil {
                let label = SKLabelNode(fontNamed: "Arial-BoldMT")
                label.fontSize = 24
                label.fontColor = .red
                label.position = CGPoint(x: size.width / 2, y: containerHeight + 60)
                label.zPosition = 100
                countdownLabel = label
                addChild(label)
            }
            
            if remaining < 4.5 {
                countdownLabel?.text = String(format: "⚠️ 倒數 %.1f 秒", remaining)
            }

            if remaining <= 0 {
                triggerGameOver()
            }

        } else {
            gameOverTimer = nil
            countdownLabel?.removeFromParent()
            countdownLabel = nil
        }
    }


    /// 遊戲結束處理：停止物理模擬、顯示分數及重新開始選項，並儲存分數
    private func triggerGameOver() {
        gameOver = true
        physicsWorld.speed = 0
        
        let gameOverLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        gameOverLabel.text = "遊戲結束! 得分: \(score)"
        gameOverLabel.fontSize = 32
        gameOverLabel.fontColor = .yellow
        gameOverLabel.position = CGPoint(x: size.width / 2, y: containerHeight / 2 + 40)
        addChild(gameOverLabel)
        
        let restartLabel = SKLabelNode(fontNamed: "Arial")
        restartLabel.text = "重新開始"
        restartLabel.fontSize = 28
        restartLabel.fontColor = .white
        restartLabel.position = CGPoint(x: size.width / 2, y: containerHeight / 2 - 20)
        restartLabel.name = "restartButton"
        addChild(restartLabel)
        
        // 取得目前榜單
        let currentTop: [Any]
            switch mode {
                case .normal:     currentTop = ScoreManager.topNormal()
                case .countdown:  currentTop = ScoreManager.topCountdown()
        }

        // 判斷是否進榜
        let threshold = (currentTop as? [NormalEntry])?.last?.score ??
                        (currentTop as? [CountdownEntry])?.last?.score ?? 0
        let qualifies = currentTop.count < 10 || score > threshold

        if qualifies {
            var info: [String: Any] = ["score": score]
            if mode == .countdown {
                let elapsed = Int(CACurrentMediaTime() - startTime - pauseAccum)
                info["seconds"] = elapsed
            }
            NotificationCenter.default.post(name: .gameOverScore,
                                            object: nil,
                                            userInfo: info)
            self.isPaused = true
        } else {
            // 直接寫入
            if mode == .normal {
                ScoreManager.addNormal(name: "Player", score: score)
            } else {
                let elapsed = Int(CACurrentMediaTime() - startTime - pauseAccum)
                ScoreManager.addCountdown(name: "Player", score: score, seconds: elapsed)
            }
        }

        // let elapsed = Int(CACurrentMediaTime() - startTime - pauseAccum)
        
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
            bestLabel.fontSize = 20
            bestLabel.fontColor = .white
            bestLabel.position = CGPoint(x: size.width/2, y: containerHeight/2 - 60)
            addChild(bestLabel)
        }

    }
    
    /// 重新開始遊戲：重設狀態、清除節點並初始化
    private func restartGame() {
        NotificationCenter.default.post(name: .gameOverScore, object: nil, userInfo: [:])
        restartLocked = false
        gameOver      = false
        physicsWorld.speed = 1
        self.isPaused = false

        removeAllChildren()
        activeBalls.removeAll()
        previewNodes.removeAll()
        countdownLabel = nil
        timerLabel     = nil

        score = 0
        gameOverTimer = nil
        waitingForNextBall = false
        timeLeft = (mode == .countdown) ? 30 : 0
        startTime = CACurrentMediaTime()
        lastUpdate = startTime

        setupContainerBoundaries()
        setupScoreLabel()
        setupTimerLabel()

        ballQueue = [randomBallLevel(), randomBallLevel()]
        showPreviewQueue()
        prepareDroppableBall()
    }

    
    private func playBackgroundMusic() {
        if let url = Bundle.main.url(forResource: "background", withExtension: "mp3") {
            do {
                bgmPlayer = try AVAudioPlayer(contentsOf: url)
                bgmPlayer?.numberOfLoops = -1  // 無限循環播放
                bgmPlayer?.volume = 0.5        // 可調整音量
                bgmPlayer?.prepareToPlay()
                bgmPlayer?.play()
            } catch {
                print("背景音樂載入失敗: \(error)")
            }
        }
    }
}
