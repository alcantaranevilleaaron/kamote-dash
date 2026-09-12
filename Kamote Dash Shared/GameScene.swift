//
//  GameScene.swift
//  Kamote Dash Shared
//
//  Created by Neville Aaron Alcantara on 9/10/26.
//

import SpriteKit

struct PhysicsCategory {
    static let none: UInt32 = 0
    static let player: UInt32 = 1 << 0
    static let obstacle: UInt32 = 1 << 1
    static let coin: UInt32 = 1 << 2
    static let kamote: UInt32 = 1 << 3
}

final class GameScene: SKScene, SKPhysicsContactDelegate {

    private enum Config {
        static let laneCount = 3
        static let roadTopWidthRatio: CGFloat = 0.28
        static let roadBottomWidthRatio: CGFloat = 0.96
        static let horizonYRatio: CGFloat = 0.60
        static let playerYRatio: CGFloat = 0.13
        static let depthSpeed: CGFloat = 0.24
        static let roadAccentRemovalDepth: CGFloat = 1.28
        static let entityStartDepth: CGFloat = 0.02
        static let entityPassedPlayerDepth: CGFloat = 1.04
        static let entityRemovalDepth: CGFloat = 1.34
        static let spawnInterval: TimeInterval = 0.98
        static let swipeThreshold: CGFloat = 30
        static let playerMoveDuration: TimeInterval = 0.14
        static let playerScale: CGFloat = 0.94
    }

    private enum EntityKind { case traffic, coin, kamote }
    private enum AccentPlacement { case divider(Int), roadsideLeft, roadsideRight }

    private final class DepthEntity {
        let node: SKNode
        let lane: Int
        let kind: EntityKind
        var depth: CGFloat
        var hasPassedPlayer = false

        init(node: SKNode, lane: Int, kind: EntityKind, depth: CGFloat) {
            self.node = node
            self.lane = lane
            self.kind = kind
            self.depth = depth
        }
    }

    private final class RoadAccent {
        let node: SKSpriteNode
        let placement: AccentPlacement
        var depth: CGFloat

        init(node: SKSpriteNode, placement: AccentPlacement, depth: CGFloat) {
            self.node = node
            self.placement = placement
            self.depth = depth
        }
    }

    class func newGameScene() -> GameScene {
        let scene = GameScene(size: CGSize(width: 1170, height: 2532))
        scene.scaleMode = .aspectFill
        return scene
    }

    private let worldNode = SKNode()
    private let hudNode = SKNode()

    private let coinLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
    private let kamoteLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
    private var gameOverLabel: SKLabelNode?
    private var restartLabel: SKLabelNode?

    private var player = SKSpriteNode()
    private var playerShadow = SKShapeNode()
    private var currentLane = 1
    private var isGameOver = false

    private var coinCount = 0
    private var kamoteCount = 0

    private var horizonY: CGFloat = 0
    private var playerY: CGFloat = 0
    private var roadTopWidth: CGFloat = 0
    private var roadBottomWidth: CGFloat = 0

    private var roadSurface = SKShapeNode()
    private var roadHaze = SKShapeNode()
    private var roadAccents: [RoadAccent] = []
    private var activeTraffic: [DepthEntity] = []
    private var activeCoins: [DepthEntity] = []
    private var activeKamote: [DepthEntity] = []

    private var touchStartPoint: CGPoint?
    private var touchConsumedSwipe = false
    private var lastUpdateTime: TimeInterval = 0
    private var lastSpawnTime: TimeInterval = 0

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        backgroundColor = SKColor(red: 0.70, green: 0.80, blue: 0.88, alpha: 1)
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        if worldNode.parent == nil { addChild(worldNode) }
        if hudNode.parent == nil { addChild(hudNode) }

        rebuildScene(resetRun: true)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard view != nil else { return }
        rebuildScene(resetRun: false)
    }

    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
            return
        }

        let dt = CGFloat(min(currentTime - lastUpdateTime, 1.0 / 20.0))
        lastUpdateTime = currentTime
        let depthAdvance = Config.depthSpeed * dt

        updateRoadAccents(depthAdvance: depthAdvance)
        updateEntities(&activeTraffic, depthAdvance: depthAdvance)
        updateEntities(&activeCoins, depthAdvance: depthAdvance)
        updateEntities(&activeKamote, depthAdvance: depthAdvance)

        if !isGameOver, currentTime - lastSpawnTime >= Config.spawnInterval {
            lastSpawnTime = currentTime
            spawnEncounter()
        }
    }

    private func rebuildScene(resetRun: Bool) {
        if resetRun {
            isGameOver = false
            coinCount = 0
            kamoteCount = 0
            currentLane = 1
            touchStartPoint = nil
            touchConsumedSwipe = false
            lastUpdateTime = 0
            lastSpawnTime = 0
        }

        gameOverLabel?.removeFromParent(); gameOverLabel = nil
        restartLabel?.removeFromParent(); restartLabel = nil
        worldNode.removeAllChildren()
        hudNode.removeAllChildren()
        roadAccents.removeAll()
        activeTraffic.removeAll()
        activeCoins.removeAll()
        activeKamote.removeAll()

        setupPerspectiveMetrics()
        setupBackdrop()
        setupRoadSurface()
        setupRoadAccents()
        setupPlayer()
        setupHUD()
        layoutHUD()
        updateHUDText()
    }

    private func setupPerspectiveMetrics() {
        horizonY = size.height * Config.horizonYRatio
        playerY = size.height * Config.playerYRatio
        roadTopWidth = size.width * Config.roadTopWidthRatio
        roadBottomWidth = size.width * Config.roadBottomWidthRatio
    }

    private func setupBackdrop() {
        let haze = SKShapeNode(rectOf: CGSize(width: size.width * 1.15, height: 110), cornerRadius: 34)
        haze.fillColor = SKColor(white: 1, alpha: 0.18)
        haze.strokeColor = .clear
        haze.position = CGPoint(x: size.width * 0.5, y: horizonY + 20)
        haze.zPosition = -40
        worldNode.addChild(haze)

        let skyline = SKNode()
        skyline.zPosition = -35
        let baseY = horizonY + 10
        let leftBuildings: [(CGFloat, CGFloat, CGFloat)] = [(42, 140, 0.30), (72, 180, 0.24), (56, 110, 0.18), (84, 210, 0.28)]
        var x: CGFloat = 36
        for (w, h, alpha) in leftBuildings {
            let building = SKSpriteNode(color: SKColor(red: 0.45, green: 0.40, blue: 0.42, alpha: alpha), size: CGSize(width: w, height: h))
            building.position = CGPoint(x: x, y: baseY + h * 0.5)
            skyline.addChild(building)
            x += w + 12
        }

        let rightBuildings: [(CGFloat, CGFloat, CGFloat)] = [(56, 190, 0.22), (72, 150, 0.26), (48, 240, 0.20)]
        x = size.width - 40
        for (w, h, alpha) in rightBuildings.reversed() {
            let building = SKSpriteNode(color: SKColor(red: 0.45, green: 0.40, blue: 0.42, alpha: alpha), size: CGSize(width: w, height: h))
            building.position = CGPoint(x: x - w * 0.5, y: baseY + h * 0.5)
            skyline.addChild(building)
            x -= w + 14
        }

        worldNode.addChild(skyline)
    }

    private func setupRoadSurface() {
        let bottomLeft = (size.width - roadBottomWidth) * 0.5
        let bottomRight = bottomLeft + roadBottomWidth
        let topLeft = (size.width - roadTopWidth) * 0.5
        let topRight = topLeft + roadTopWidth

        roadSurface = SKShapeNode(path: trapezoidPath(
            bottomLeft: CGPoint(x: bottomLeft, y: 0),
            bottomRight: CGPoint(x: bottomRight, y: 0),
            topRight: CGPoint(x: topRight, y: horizonY),
            topLeft: CGPoint(x: topLeft, y: horizonY)
        ))
        roadSurface.fillColor = SKColor(red: 0.14, green: 0.14, blue: 0.16, alpha: 1)
        roadSurface.strokeColor = SKColor(white: 0.02, alpha: 0.45)
        roadSurface.lineWidth = 2
        roadSurface.zPosition = -5
        worldNode.addChild(roadSurface)

        roadHaze = SKShapeNode(rectOf: CGSize(width: roadTopWidth * 1.2, height: 64), cornerRadius: 20)
        roadHaze.fillColor = SKColor(white: 1, alpha: 0.08)
        roadHaze.strokeColor = .clear
        roadHaze.position = CGPoint(x: size.width * 0.5, y: horizonY + 6)
        roadHaze.zPosition = -4
        worldNode.addChild(roadHaze)
    }

    private func setupRoadAccents() {
        let dividerCount = 20
        let dividerStep = Config.roadAccentRemovalDepth / CGFloat(dividerCount)
        for divider in 1...2 {
            for index in 0..<dividerCount {
                let dash = SKSpriteNode(color: SKColor(red: 0.95, green: 0.95, blue: 0.92, alpha: 1), size: CGSize(width: 5, height: 32))
                dash.zPosition = 1
                let accent = RoadAccent(node: dash, placement: .divider(divider), depth: CGFloat(index) * dividerStep)
                roadAccents.append(accent)
                worldNode.addChild(dash)
                applyPerspective(to: accent)
            }
        }

        let roadsideCount = 16
        let roadsideStep = Config.roadAccentRemovalDepth / CGFloat(roadsideCount)
        for index in 0..<roadsideCount {
            let depth = CGFloat(index) * roadsideStep
            let leftMarker = SKSpriteNode(color: SKColor(red: 0.0, green: 0.36, blue: 0.63, alpha: 1), size: CGSize(width: 26, height: 8))
            let leftAccent = RoadAccent(node: leftMarker, placement: .roadsideLeft, depth: depth)
            roadAccents.append(leftAccent)
            worldNode.addChild(leftMarker)
            applyPerspective(to: leftAccent)

            let rightMarker = SKSpriteNode(color: SKColor(red: 0.0, green: 0.36, blue: 0.63, alpha: 1), size: CGSize(width: 26, height: 8))
            let rightAccent = RoadAccent(node: rightMarker, placement: .roadsideRight, depth: depth + roadsideStep * 0.5)
            roadAccents.append(rightAccent)
            worldNode.addChild(rightMarker)
            applyPerspective(to: rightAccent)
        }
    }

    private func setupPlayer() {
        player.removeFromParent()
        playerShadow.removeFromParent()

        playerShadow = SKShapeNode(ellipseOf: CGSize(width: 62, height: 14))
        playerShadow.fillColor = SKColor(white: 0, alpha: 0.22)
        playerShadow.strokeColor = .clear
        playerShadow.zPosition = 55
        worldNode.addChild(playerShadow)

        player = SKSpriteNode(color: .clear, size: CGSize(width: 60, height: 98))
        player.zPosition = 60
        player.name = "player"

        let rearWheel = SKShapeNode(circleOfRadius: 11)
        rearWheel.fillColor = SKColor(white: 0.06, alpha: 1)
        rearWheel.strokeColor = SKColor(white: 0.35, alpha: 1)
        rearWheel.position = CGPoint(x: 0, y: -31)
        player.addChild(rearWheel)

        let frontWheel = SKShapeNode(circleOfRadius: 9)
        frontWheel.fillColor = SKColor(white: 0.06, alpha: 1)
        frontWheel.strokeColor = SKColor(white: 0.35, alpha: 1)
        frontWheel.position = CGPoint(x: 0, y: 33)
        player.addChild(frontWheel)

        let body = SKShapeNode(rectOf: CGSize(width: 24, height: 56), cornerRadius: 7)
        body.fillColor = SKColor(red: 0.82, green: 0.07, blue: 0.13, alpha: 1)
        body.strokeColor = SKColor(red: 0.48, green: 0.03, blue: 0.07, alpha: 1)
        body.position = CGPoint(x: 0, y: 4)
        player.addChild(body)

        let seat = SKShapeNode(rectOf: CGSize(width: 18, height: 20), cornerRadius: 5)
        seat.fillColor = SKColor(white: 0.16, alpha: 1)
        seat.strokeColor = .clear
        seat.position = CGPoint(x: 0, y: -8)
        player.addChild(seat)

        let handle = SKShapeNode(rectOf: CGSize(width: 28, height: 4), cornerRadius: 2)
        handle.fillColor = SKColor(white: 0.80, alpha: 1)
        handle.strokeColor = .clear
        handle.position = CGPoint(x: 0, y: 40)
        player.addChild(handle)

        let windshield = SKShapeNode(rectOf: CGSize(width: 14, height: 16), cornerRadius: 4)
        windshield.fillColor = SKColor(white: 0.90, alpha: 0.45)
        windshield.strokeColor = .clear
        windshield.position = CGPoint(x: 0, y: 22)
        player.addChild(windshield)

        player.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 34, height: 70))
        player.physicsBody?.isDynamic = true
        player.physicsBody?.affectedByGravity = false
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.categoryBitMask = PhysicsCategory.player
        player.physicsBody?.contactTestBitMask = PhysicsCategory.obstacle | PhysicsCategory.coin | PhysicsCategory.kamote
        player.physicsBody?.collisionBitMask = PhysicsCategory.none

        worldNode.addChild(player)
        updatePlayerPosition(animated: false)
    }

    private func setupHUD() {
        coinLabel.fontSize = 18
        coinLabel.fontColor = .white
        coinLabel.horizontalAlignmentMode = .left
        coinLabel.zPosition = 200
        hudNode.addChild(coinLabel)

        kamoteLabel.fontSize = 18
        kamoteLabel.fontColor = SKColor(red: 0.93, green: 0.76, blue: 1.0, alpha: 1)
        kamoteLabel.horizontalAlignmentMode = .left
        kamoteLabel.zPosition = 200
        hudNode.addChild(kamoteLabel)
    }

    private func layoutHUD() {
        let safeTop: CGFloat
        #if os(iOS) || os(tvOS)
        safeTop = view?.safeAreaInsets.top ?? 0
        #else
        safeTop = 0
        #endif

        let topY = size.height - safeTop - 18
        coinLabel.position = CGPoint(x: 16, y: topY)
        kamoteLabel.position = CGPoint(x: 16, y: topY - 24)
    }

    private func updateHUDText() {
        coinLabel.text = "Coins: \(coinCount)"
        kamoteLabel.text = "Kamote: \(kamoteCount)"
    }

    private func roadWidth(at depth: CGFloat) -> CGFloat {
        let t = easedDepth(depth)
        return roadTopWidth + (roadBottomWidth - roadTopWidth) * t
    }

    private func y(for depth: CGFloat) -> CGFloat {
        let t = easedDepth(depth)
        return horizonY + (playerY - horizonY) * t
    }

    private func entityApproachProgress(for depth: CGFloat) -> CGFloat {
        let span = max(1 - Config.entityStartDepth, 0.001)
        return min(max((depth - Config.entityStartDepth) / span, 0), 1)
    }

    private func entityExitProgress(for depth: CGFloat) -> CGFloat {
        let span = max(Config.entityRemovalDepth - 1, 0.001)
        return min(max((depth - 1) / span, 0), 1)
    }

    private func roadAccentApproachProgress(for depth: CGFloat) -> CGFloat {
        min(max(depth, 0), 1)
    }

    private func roadAccentExitProgress(for depth: CGFloat) -> CGFloat {
        let span = max(Config.roadAccentRemovalDepth - 1, 0.001)
        return min(max((depth - 1) / span, 0), 1)
    }

    private func entityY(for depth: CGFloat) -> CGFloat {
        if depth <= 1 {
            let t = easedDepth(min(max(depth, Config.entityStartDepth), 1))
            return horizonY + (playerY - horizonY) * t
        }

        let exitDistance = playerY + max(size.height * 0.12, 96)
        return playerY - entityExitProgress(for: depth) * exitDistance
    }

    private func roadAccentY(for depth: CGFloat) -> CGFloat {
        if depth <= 1 {
            let t = easedDepth(roadAccentApproachProgress(for: depth))
            return horizonY + (playerY - horizonY) * t
        }

        let exitDistance = playerY + max(size.height * 0.10, 84)
        return playerY - roadAccentExitProgress(for: depth) * exitDistance
    }

    private func roadAccentScale(for accent: RoadAccent) -> CGFloat {
        let approachScale = 0.42 + easedDepth(roadAccentApproachProgress(for: accent.depth)) * 1.05
        let exitScale = approachScale + roadAccentExitProgress(for: accent.depth) * 0.10
        return exitScale
    }

    private func laneX(for lane: Int, depth: CGFloat) -> CGFloat {
        let width = roadWidth(at: depth)
        let left = (size.width - width) * 0.5
        let laneWidth = width / CGFloat(Config.laneCount)
        return left + laneWidth * (CGFloat(lane) + 0.5)
    }

    private func dividerX(for divider: Int, depth: CGFloat) -> CGFloat {
        let width = roadWidth(at: depth)
        let left = (size.width - width) * 0.5
        let laneWidth = width / CGFloat(Config.laneCount)
        return left + laneWidth * CGFloat(divider)
    }

    private func roadsideX(isLeft: Bool, depth: CGFloat) -> CGFloat {
        let width = roadWidth(at: depth)
        let left = (size.width - width) * 0.5
        return isLeft ? left - 36 : left + width + 36
    }

    private func laneSplitX(leftLane: Int, depth: CGFloat) -> CGFloat {
        dividerX(for: min(leftLane + 1, Config.laneCount - 1), depth: depth)
    }

    private func easedDepth(_ depth: CGFloat) -> CGFloat {
        let clamped = min(max(depth, 0), 1)
        return clamped * clamped * (3 - 2 * clamped)
    }

    private func perspectiveScale(for depth: CGFloat) -> CGFloat {
        0.42 + easedDepth(depth) * 1.05
    }

    private func entityScale(for entity: DepthEntity) -> CGFloat {
        let approachScale = 0.18 + entityApproachProgress(for: entity.depth) * 0.48
        let exitScale = approachScale + entityExitProgress(for: entity.depth) * 0.08

        let kindMultiplier: CGFloat
        switch entity.kind {
        case .traffic:
            kindMultiplier = 1.0
        case .coin:
            kindMultiplier = 0.82
        case .kamote:
            kindMultiplier = 0.86
        }

        return exitScale * kindMultiplier
    }

    private func trapezoidPath(bottomLeft: CGPoint, bottomRight: CGPoint, topRight: CGPoint, topLeft: CGPoint) -> CGPath {
        let path = CGMutablePath()
        path.move(to: bottomLeft)
        path.addLine(to: bottomRight)
        path.addLine(to: topRight)
        path.addLine(to: topLeft)
        path.closeSubpath()
        return path
    }

    private func updateRoadAccents(depthAdvance: CGFloat) {
        for accent in roadAccents {
            accent.depth += depthAdvance
            if accent.depth >= Config.roadAccentRemovalDepth {
                accent.depth -= Config.roadAccentRemovalDepth
            }
            applyPerspective(to: accent)
        }
    }

    private func applyPerspective(to accent: RoadAccent) {
        let laneDepth = min(max(accent.depth, 0), 1)
        let scale = roadAccentScale(for: accent)
        let yPosition = roadAccentY(for: accent.depth)

        switch accent.placement {
        case .divider(let divider):
            accent.node.position = CGPoint(x: dividerX(for: divider, depth: laneDepth), y: yPosition)
            accent.node.setScale(scale * 0.62)
            accent.node.alpha = 0.22 + roadAccentApproachProgress(for: accent.depth) * 0.76
            accent.node.zPosition = 1 + (roadAccentApproachProgress(for: accent.depth) + roadAccentExitProgress(for: accent.depth) * 0.20) * 4
        case .roadsideLeft:
            accent.node.position = CGPoint(x: roadsideX(isLeft: true, depth: laneDepth), y: yPosition)
            accent.node.setScale(scale * 0.50)
            accent.node.alpha = 0.18 + roadAccentApproachProgress(for: accent.depth) * 0.72
            accent.node.zPosition = (roadAccentApproachProgress(for: accent.depth) + roadAccentExitProgress(for: accent.depth) * 0.20) * 3
        case .roadsideRight:
            accent.node.position = CGPoint(x: roadsideX(isLeft: false, depth: laneDepth), y: yPosition)
            accent.node.setScale(scale * 0.50)
            accent.node.alpha = 0.18 + roadAccentApproachProgress(for: accent.depth) * 0.72
            accent.node.zPosition = (roadAccentApproachProgress(for: accent.depth) + roadAccentExitProgress(for: accent.depth) * 0.20) * 3
        }
    }

    private func updateEntities(_ entities: inout [DepthEntity], depthAdvance: CGFloat) {
        for index in entities.indices.reversed() {
            let entity = entities[index]
            entity.depth += depthAdvance

            applyPerspective(to: entity)

            if !entity.hasPassedPlayer,
               entity.depth >= Config.entityPassedPlayerDepth,
               entity.node.frame.maxY < player.frame.minY - 8 {
                entity.hasPassedPlayer = true
                deactivate(entity)
            }

            if entity.depth >= Config.entityRemovalDepth || entity.node.frame.maxY < -40 {
                deactivate(entity)
                entity.node.removeFromParent()
                entities.remove(at: index)
            }
        }
    }

    private func deactivate(_ entity: DepthEntity) {
        entity.node.physicsBody = nil
        entity.node.name = nil
    }

    private func deactivateAndRemove(_ node: SKNode) {
        node.physicsBody = nil
        node.name = nil
        node.removeFromParent()
    }

    private func applyPerspective(to entity: DepthEntity) {
        let laneDepth = min(max(entity.depth, Config.entityStartDepth), 1)
        let scale = entityScale(for: entity)

        let xPosition: CGFloat
        switch entity.kind {
        case .traffic, .coin:
            xPosition = laneX(for: entity.lane, depth: laneDepth)
        case .kamote:
            xPosition = laneSplitX(leftLane: entity.lane, depth: laneDepth)
        }

        entity.node.position = CGPoint(x: xPosition, y: entityY(for: entity.depth))
        entity.node.setScale(scale)
        entity.node.alpha = 0.30 + entityApproachProgress(for: entity.depth) * 0.70
        let depthLayer = entityApproachProgress(for: entity.depth) + entityExitProgress(for: entity.depth) * 0.18
        entity.node.zPosition = entity.kind == .traffic ? 20 + depthLayer * 60 : 24 + depthLayer * 60
    }

    private func updatePlayerPosition(animated: Bool) {
        let targetX = laneX(for: currentLane, depth: 1)
        player.position = CGPoint(x: targetX, y: playerY)
        playerShadow.position = CGPoint(x: targetX, y: playerY - 18)
        player.setScale(Config.playerScale)

        if !animated {
            player.removeAllActions()
            playerShadow.removeAllActions()
        }
    }

    private func movePlayer(by direction: Int) {
        guard !isGameOver else { return }
        let nextLane = min(max(currentLane + direction, 0), Config.laneCount - 1)
        guard nextLane != currentLane else { return }

        currentLane = nextLane
        let action = SKAction.moveTo(x: laneX(for: currentLane, depth: 1), duration: Config.playerMoveDuration)
        action.timingMode = .easeOut
        player.run(action, withKey: "laneMove")

        let shadowMove = SKAction.moveTo(x: laneX(for: currentLane, depth: 1), duration: Config.playerMoveDuration)
        shadowMove.timingMode = .easeOut
        playerShadow.run(shadowMove, withKey: "laneMove")
    }

    private func spawnEncounter() {
        let blockedLane = Int.random(in: 0..<Config.laneCount)
        spawnTraffic(inLane: blockedLane)

        let safeLanes = (0..<Config.laneCount).filter { $0 != blockedLane }
        if let safeLane = safeLanes.randomElement() {
            spawnCoin(inLane: safeLane)
        }

        if let split = riskyLaneSplit(for: blockedLane) {
            spawnKamote(inLaneSplit: split)
        }
    }

    private func riskyLaneSplit(for obstacleLane: Int) -> (Int, Int)? {
        if obstacleLane == 0 { return (0, 1) }
        if obstacleLane == Config.laneCount - 1 { return (1, 2) }
        return Bool.random() ? (0, 1) : (1, 2)
    }

    private func spawnTraffic(inLane lane: Int) {
        let isJeepney = Bool.random()
        let size = isJeepney ? CGSize(width: 96, height: 88) : CGSize(width: 72, height: 82)
        let node = SKSpriteNode(color: isJeepney ? SKColor(red: 0.17, green: 0.55, blue: 0.34, alpha: 1) : SKColor(red: 0.85, green: 0.74, blue: 0.21, alpha: 1), size: size)
        node.name = "obstacle"

        let windshield = SKSpriteNode(color: SKColor(white: 0.18, alpha: 0.9), size: CGSize(width: size.width * 0.70, height: max(10, size.height * 0.14)))
        windshield.position = CGPoint(x: 0, y: size.height * 0.14)
        node.addChild(windshield)

        if isJeepney {
            let stripe = SKSpriteNode(color: SKColor(red: 0.95, green: 0.20, blue: 0.20, alpha: 1), size: CGSize(width: size.width * 0.82, height: 7))
            stripe.position = CGPoint(x: 0, y: -size.height * 0.20)
            node.addChild(stripe)
        } else {
            let roofLight = SKSpriteNode(color: .white, size: CGSize(width: size.width * 0.34, height: 6))
            roofLight.position = CGPoint(x: 0, y: size.height * 0.28)
            node.addChild(roofLight)
        }

        node.physicsBody = SKPhysicsBody(rectangleOf: size)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.allowsRotation = false
        node.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
        node.physicsBody?.contactTestBitMask = PhysicsCategory.player
        node.physicsBody?.collisionBitMask = PhysicsCategory.none

        let entity = DepthEntity(node: node, lane: lane, kind: .traffic, depth: Config.entityStartDepth)
        activeTraffic.append(entity)
        worldNode.addChild(node)
        applyPerspective(to: entity)
    }

    private func spawnCoin(inLane lane: Int) {
        let node = SKShapeNode(circleOfRadius: 10)
        node.fillColor = SKColor.systemYellow
        node.strokeColor = SKColor(red: 0.90, green: 0.74, blue: 0.08, alpha: 1)
        node.lineWidth = 2
        node.name = "coin"

        let shine = SKShapeNode(circleOfRadius: 4)
        shine.fillColor = SKColor(white: 1, alpha: 0.72)
        shine.strokeColor = .clear
        shine.position = CGPoint(x: -3, y: 4)
        node.addChild(shine)

        node.physicsBody = SKPhysicsBody(circleOfRadius: 10)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.allowsRotation = false
        node.physicsBody?.categoryBitMask = PhysicsCategory.coin
        node.physicsBody?.contactTestBitMask = PhysicsCategory.player
        node.physicsBody?.collisionBitMask = PhysicsCategory.none

        let entity = DepthEntity(node: node, lane: lane, kind: .coin, depth: Config.entityStartDepth)
        activeCoins.append(entity)
        worldNode.addChild(node)
        applyPerspective(to: entity)
    }

    private func spawnKamote(inLaneSplit split: (Int, Int)) {
        let node = SKShapeNode(ellipseOf: CGSize(width: 26, height: 16))
        node.fillColor = SKColor(red: 0.57, green: 0.26, blue: 0.74, alpha: 1)
        node.strokeColor = SKColor(red: 0.36, green: 0.12, blue: 0.52, alpha: 1)
        node.lineWidth = 2
        node.name = "kamote"

        let label = SKLabelNode(text: "K")
        label.fontName = "HelveticaNeue-Bold"
        label.fontSize = 13
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        node.addChild(label)

        node.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 26, height: 16))
        node.physicsBody?.isDynamic = false
        node.physicsBody?.allowsRotation = false
        node.physicsBody?.categoryBitMask = PhysicsCategory.kamote
        node.physicsBody?.contactTestBitMask = PhysicsCategory.player
        node.physicsBody?.collisionBitMask = PhysicsCategory.none

        let entity = DepthEntity(node: node, lane: split.0, kind: .kamote, depth: Config.entityStartDepth)
        activeKamote.append(entity)
        worldNode.addChild(node)
        applyPerspective(to: entity)
    }

    private func collectCoin(node: SKNode) {
        deactivateAndRemove(node)
        coinCount += 1
        updateHUDText()
        activeCoins.removeAll { $0.node === node }
    }

    private func collectKamote(node: SKNode) {
        deactivateAndRemove(node)
        kamoteCount += 1
        updateHUDText()
        activeKamote.removeAll { $0.node === node }
    }

    private func didPickNode(_ node: SKNode, expectedName: String) -> Bool {
        node.name == expectedName
    }

    private func showGameOver() {
        isGameOver = true
        player.removeAllActions()
        playerShadow.removeAllActions()

        for entity in activeTraffic { deactivate(entity) }
        for entity in activeCoins { deactivate(entity) }
        for entity in activeKamote { deactivate(entity) }

        let label = SKLabelNode(text: "Game Over")
        label.fontName = "HelveticaNeue-Bold"
        label.fontSize = 44
        label.fontColor = .white
        label.position = CGPoint(x: size.width * 0.5, y: size.height * 0.56)
        label.zPosition = 250
        hudNode.addChild(label)
        gameOverLabel = label

        let restart = SKLabelNode(text: "Tap to Restart")
        restart.fontName = "HelveticaNeue-Medium"
        restart.fontSize = 22
        restart.fontColor = SKColor(white: 1, alpha: 0.92)
        restart.position = CGPoint(x: size.width * 0.5, y: size.height * 0.42)
        restart.zPosition = 250
        hudNode.addChild(restart)
        restartLabel = restart
    }

    private func restartGame() {
        rebuildScene(resetRun: true)
    }

    func didBegin(_ contact: SKPhysicsContact) {
        guard !isGameOver else { return }

        let a = contact.bodyA
        let b = contact.bodyB

        func isPair(_ first: UInt32, _ second: UInt32) -> Bool {
            (a.categoryBitMask == first && b.categoryBitMask == second)
            || (a.categoryBitMask == second && b.categoryBitMask == first)
        }

        if isPair(PhysicsCategory.player, PhysicsCategory.obstacle) {
            showGameOver()
        } else if isPair(PhysicsCategory.player, PhysicsCategory.coin) {
            if let node = a.node?.name == "coin" ? a.node : b.node, didPickNode(node, expectedName: "coin") {
                collectCoin(node: node)
            }
        } else if isPair(PhysicsCategory.player, PhysicsCategory.kamote) {
            if let node = a.node?.name == "kamote" ? a.node : b.node, didPickNode(node, expectedName: "kamote") {
                collectKamote(node: node)
            }
        }
    }

    #if os(iOS) || os(tvOS)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGameOver {
            restartGame()
            return
        }
        touchConsumedSwipe = false
        touchStartPoint = touches.first?.location(in: self)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isGameOver, !touchConsumedSwipe, let start = touchStartPoint, let touch = touches.first else { return }

        let current = touch.location(in: self)
        let dx = current.x - start.x
        let dy = current.y - start.y
        guard abs(dx) > abs(dy), abs(dx) > Config.swipeThreshold else { return }

        touchConsumedSwipe = true
        movePlayer(by: dx > 0 ? 1 : -1)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isGameOver else {
            restartGame()
            return
        }

        guard !touchConsumedSwipe, let start = touchStartPoint, let touch = touches.first else {
            touchStartPoint = nil
            touchConsumedSwipe = false
            return
        }

        let end = touch.location(in: self)
        let dx = end.x - start.x
        let dy = end.y - start.y
        if abs(dx) > abs(dy), abs(dx) > Config.swipeThreshold {
            movePlayer(by: dx > 0 ? 1 : -1)
        }

        touchStartPoint = nil
        touchConsumedSwipe = false
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchStartPoint = nil
        touchConsumedSwipe = false
    }
    #endif
}
