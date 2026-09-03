import SpriteKit
import UIKit

final class GameScene: SKScene, SKPhysicsContactDelegate {

    // MARK: Layout constants (points, matches Field cm ratio 110x170)
    static let fieldWidth: CGFloat = 1000
    static let fieldHeight: CGFloat = 1600
    let wall: CGFloat = 46
    let goalWidth: CGFloat = 190
    private let goalDepth: CGFloat = 30
    let capRadius: CGFloat = 32
    private let gkRadius: CGFloat = 34
    private let ballRadius: CGFloat = 20
    private let maxDrag: CGFloat = 220
    let maxImpulse: CGFloat = 130

    weak var viewModel: GameViewModel?

    var ball: SKShapeNode!
    var homeCaps: [SKShapeNode] = []
    var awayCaps: [SKShapeNode] = []
    private var fieldLayer: SKNode!

    private var dragNode: SKShapeNode?
    private var dragStart: CGPoint = .zero
    private var aimLine: SKShapeNode?

    var wasSimulating = false
    var awaitingReset = false
    private var allBodies: [SKPhysicsBody] = []

    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let goalFeedback = UINotificationFeedbackGenerator()

    override func didMove(to view: SKView) {
        scaleMode = .aspectFit
        backgroundColor = SKColor(red: 0.05, green: 0.05, blue: 0.06, alpha: 1)
        prepareIfNeeded()
    }

    /// Builds the field and kicks off, if that hasn't happened yet. Safe to call before the
    /// scene is ever presented in a `SpriteView` — needed so an online match can be seeded
    /// (and its initial state sent to Game Center) before the player navigates to the game screen.
    func prepareIfNeeded() {
        guard fieldLayer == nil else { return }
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = .zero
        buildField()
        resetKickoff()
    }

    // MARK: - Field

    private func buildField() {
        fieldLayer = SKNode()
        addChild(fieldLayer)

        let pitch = CGRect(x: wall, y: wall, width: Self.fieldWidth - 2 * wall, height: Self.fieldHeight - 2 * wall)
        let stripes = 12
        let stripeH = pitch.height / CGFloat(stripes)
        for i in 0..<stripes {
            let stripe = SKShapeNode(rect: CGRect(x: pitch.minX, y: pitch.minY + CGFloat(i) * stripeH, width: pitch.width, height: stripeH + 1))
            stripe.fillColor = i % 2 == 0 ? SKColor(red: 0.059, green: 0.29, blue: 0.169, alpha: 1) : SKColor(red: 0.078, green: 0.388, blue: 0.220, alpha: 1)
            stripe.strokeColor = .clear
            fieldLayer.addChild(stripe)
        }

        let border = SKShapeNode(rect: pitch)
        border.strokeColor = SKColor.white.withAlphaComponent(0.85)
        border.lineWidth = 4
        border.fillColor = .clear
        fieldLayer.addChild(border)

        let midLine = SKShapeNode(path: {
            let p = CGMutablePath()
            p.move(to: CGPoint(x: pitch.minX, y: Self.fieldHeight / 2))
            p.addLine(to: CGPoint(x: pitch.maxX, y: Self.fieldHeight / 2))
            return p
        }())
        midLine.strokeColor = SKColor.white.withAlphaComponent(0.85)
        midLine.lineWidth = 4
        fieldLayer.addChild(midLine)

        let circle = SKShapeNode(circleOfRadius: 110)
        circle.position = CGPoint(x: Self.fieldWidth / 2, y: Self.fieldHeight / 2)
        circle.strokeColor = SKColor.white.withAlphaComponent(0.85)
        circle.lineWidth = 4
        circle.fillColor = .clear
        fieldLayer.addChild(circle)

        let boxW: CGFloat = 420, boxH: CGFloat = 200
        for y in [wall, Self.fieldHeight - wall - boxH] {
            let box = SKShapeNode(rect: CGRect(x: Self.fieldWidth / 2 - boxW / 2, y: y, width: boxW, height: boxH))
            box.strokeColor = SKColor.white.withAlphaComponent(0.85)
            box.lineWidth = 4
            box.fillColor = .clear
            fieldLayer.addChild(box)
        }

        buildGoal(atBottom: true)
        buildGoal(atBottom: false)
        buildOuterWalls(pitch: pitch)
    }

    private func buildGoal(atBottom: Bool) {
        let gx0 = Self.fieldWidth / 2 - goalWidth / 2
        let y = atBottom ? wall - goalDepth : Self.fieldHeight - wall
        let rect = CGRect(x: gx0, y: y, width: goalWidth, height: goalDepth)

        let net = SKShapeNode(rect: rect)
        net.fillColor = SKColor.white.withAlphaComponent(0.16)
        net.strokeColor = SKColor.white.withAlphaComponent(0.7)
        net.lineWidth = 3
        fieldLayer.addChild(net)

        let sensor = SKNode()
        sensor.position = CGPoint(x: rect.midX, y: rect.midY)
        let body = SKPhysicsBody(rectangleOf: CGSize(width: goalWidth - 20, height: goalDepth))
        body.isDynamic = false
        body.categoryBitMask = PhysicsCategory.goalSensor
        body.contactTestBitMask = PhysicsCategory.ball
        body.collisionBitMask = PhysicsCategory.none
        sensor.physicsBody = body
        sensor.name = atBottom ? "goal-bottom" : "goal-top"
        addChild(sensor)
    }

    private func buildOuterWalls(pitch: CGRect) {
        let gx0 = Self.fieldWidth / 2 - goalWidth / 2
        let gx1 = Self.fieldWidth / 2 + goalWidth / 2

        func wallSeg(_ from: CGPoint, _ to: CGPoint) {
            let node = SKNode()
            node.physicsBody = SKPhysicsBody(edgeFrom: from, to: to)
            node.physicsBody?.categoryBitMask = PhysicsCategory.wall
            node.physicsBody?.collisionBitMask = PhysicsCategory.cap | PhysicsCategory.ball
            addChild(node)
        }

        wallSeg(CGPoint(x: pitch.minX, y: pitch.minY), CGPoint(x: pitch.minX, y: pitch.maxY))
        wallSeg(CGPoint(x: pitch.maxX, y: pitch.minY), CGPoint(x: pitch.maxX, y: pitch.maxY))
        wallSeg(CGPoint(x: pitch.minX, y: pitch.minY), CGPoint(x: gx0, y: pitch.minY))
        wallSeg(CGPoint(x: gx1, y: pitch.minY), CGPoint(x: pitch.maxX, y: pitch.minY))
        wallSeg(CGPoint(x: pitch.minX, y: pitch.maxY), CGPoint(x: gx0, y: pitch.maxY))
        wallSeg(CGPoint(x: gx1, y: pitch.maxY), CGPoint(x: pitch.maxX, y: pitch.maxY))
    }

    // MARK: - Caps & ball

    private func makeCap(team: Team, isGK: Bool, at point: CGPoint, index: Int) -> SKShapeNode {
        let radius = isGK ? gkRadius : capRadius
        let node = SKShapeNode(circleOfRadius: radius)
        node.position = point
        node.name = "\(team.rawValue)-\(isGK ? "gk" : "\(index)")"
        node.fillColor = team == .home ? SKColor(red: 1, green: 0.478, blue: 0.102, alpha: 1) : SKColor(red: 0.17, green: 0.17, blue: 0.19, alpha: 1)
        node.strokeColor = SKColor.black.withAlphaComponent(0.35)
        node.lineWidth = 2
        node.zPosition = 5

        if isGK {
            let dot = SKShapeNode(circleOfRadius: radius * 0.38)
            dot.fillColor = .white
            dot.strokeColor = .clear
            node.addChild(dot)
        }

        let body = SKPhysicsBody(circleOfRadius: radius)
        body.mass = isGK ? 0.15 : 0.275
        body.linearDamping = 0.55
        body.restitution = 0.65
        body.friction = 0.2
        body.allowsRotation = false
        body.affectedByGravity = false
        body.usesPreciseCollisionDetection = true
        body.categoryBitMask = PhysicsCategory.cap
        body.collisionBitMask = PhysicsCategory.cap | PhysicsCategory.ball | PhysicsCategory.wall
        body.contactTestBitMask = PhysicsCategory.none
        node.physicsBody = body

        return node
    }

    private func makeBall(at point: CGPoint) -> SKShapeNode {
        let node = SKShapeNode(circleOfRadius: ballRadius)
        node.position = point
        node.name = "ball"
        node.fillColor = SKColor(white: 0.97, alpha: 1)
        node.strokeColor = SKColor.black.withAlphaComponent(0.2)
        node.lineWidth = 1.5
        node.zPosition = 6

        let body = SKPhysicsBody(circleOfRadius: ballRadius)
        body.mass = 0.06
        body.linearDamping = 0.4
        body.restitution = 0.78
        body.friction = 0.05
        body.allowsRotation = false
        body.affectedByGravity = false
        body.usesPreciseCollisionDetection = true
        body.categoryBitMask = PhysicsCategory.ball
        body.collisionBitMask = PhysicsCategory.cap | PhysicsCategory.ball | PhysicsCategory.wall
        body.contactTestBitMask = PhysicsCategory.goalSensor
        node.physicsBody = body
        return node
    }

    func resetKickoff() {
        homeCaps.forEach { $0.removeFromParent() }
        awayCaps.forEach { $0.removeFromParent() }
        ball?.removeFromParent()
        homeCaps = []
        awayCaps = []

        let xs: [CGFloat] = [0.22, 0.38, 0.5, 0.62, 0.78].map { $0 * Self.fieldWidth }

        for (i, x) in xs.enumerated() {
            let homeY = Self.fieldHeight * 0.16 + (i % 2 == 0 ? 40 : 0)
            homeCaps.append(makeCap(team: .home, isGK: false, at: CGPoint(x: x, y: homeY), index: i))
            let awayY = Self.fieldHeight * 0.84 - (i % 2 == 0 ? 40 : 0)
            awayCaps.append(makeCap(team: .away, isGK: false, at: CGPoint(x: x, y: awayY), index: i))
        }
        homeCaps.append(makeCap(team: .home, isGK: true, at: CGPoint(x: Self.fieldWidth / 2, y: wall + 60), index: 0))
        awayCaps.append(makeCap(team: .away, isGK: true, at: CGPoint(x: Self.fieldWidth / 2, y: Self.fieldHeight - wall - 60), index: 0))

        (homeCaps + awayCaps).forEach { addChild($0) }

        ball = makeBall(at: CGPoint(x: Self.fieldWidth / 2, y: Self.fieldHeight / 2))
        addChild(ball)

        allBodies = (homeCaps + awayCaps + [ball]).compactMap { $0.physicsBody }
        awaitingReset = false
        wasSimulating = false
        highlightActiveTeam()
    }

    func highlightActiveTeam() {
        for cap in homeCaps + awayCaps {
            cap.removeAction(forKey: "highlight")
            cap.strokeColor = SKColor.black.withAlphaComponent(0.35)
            cap.lineWidth = 2
        }
        guard let vm = viewModel, !vm.isSimulating else { return }
        let active = vm.currentTeam == .home ? homeCaps : awayCaps
        for cap in active {
            cap.strokeColor = Brand.uiOrangeLight
            cap.lineWidth = 3
        }
    }

    // MARK: - Simulation

    override func update(_ currentTime: TimeInterval) {
        guard !allBodies.isEmpty else { return }
        let moving = allBodies.contains { hypot($0.velocity.dx, $0.velocity.dy) > 1.2 }

        if moving {
            wasSimulating = true
            if viewModel?.isSimulating == false { viewModel?.isSimulating = true }
        } else if wasSimulating {
            wasSimulating = false
            for b in allBodies { b.velocity = .zero }
            viewModel?.isSimulating = false
            guard !awaitingReset else { return }

            if viewModel?.mode.isOnline == true {
                viewModel?.turnEnded()
                submitOnlineTurnIfNeeded()
            } else {
                viewModel?.turnEnded()
                highlightActiveTeam()
                scheduleBotTurnIfNeeded()
            }
        }
    }

    // MARK: - Contacts (goal detection)

    func didBegin(_ contact: SKPhysicsContact) {
        guard !awaitingReset else { return }
        let names = [contact.bodyA.node?.name, contact.bodyB.node?.name]
        if names.contains("goal-bottom") {
            awaitingReset = true
            goalFeedback.notificationOccurred(.success)
            viewModel?.goalScored(by: .away)
        } else if names.contains("goal-top") {
            awaitingReset = true
            goalFeedback.notificationOccurred(.success)
            viewModel?.goalScored(by: .home)
        }
    }

    // MARK: - Touch input (drag to shoot)

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let vm = viewModel, !vm.isSimulating, !vm.isPaused, !vm.isFullTime, vm.isMyTurn, let touch = touches.first else { return }
        if case .bot = vm.mode, vm.currentTeam == vm.botTeam { return }
        let point = touch.location(in: self)
        let ownCaps = vm.currentTeam == .home ? homeCaps : awayCaps
        guard let hit = ownCaps.min(by: { distance($0.position, point) < distance($1.position, point) }),
              distance(hit.position, point) < capRadius * 1.8 else { return }
        dragNode = hit
        dragStart = hit.position
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let node = dragNode, let touch = touches.first else { return }
        let point = touch.location(in: self)
        aimLine?.removeFromParent()
        let line = SKShapeNode(path: {
            let p = CGMutablePath()
            p.move(to: node.position)
            p.addLine(to: point)
            return p
        }())
        line.strokeColor = Brand.uiOrange
        line.lineWidth = 5
        line.lineCap = .round
        line.zPosition = 20
        addChild(line)
        aimLine = line
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        defer {
            dragNode = nil
            aimLine?.removeFromParent()
            aimLine = nil
        }
        guard let node = dragNode, let touch = touches.first else { return }
        let point = touch.location(in: self)
        let dx = dragStart.x - point.x
        let dy = dragStart.y - point.y
        let dist = min(hypot(dx, dy), maxDrag)
        guard dist > 8 else { return }
        let angle = atan2(dy, dx)
        let power = (dist / maxDrag) * maxImpulse
        applyShot(to: node, direction: CGVector(dx: cos(angle), dy: sin(angle)), power: power)
        impactFeedback.impactOccurred(intensity: dist / maxDrag)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        dragNode = nil
        aimLine?.removeFromParent()
        aimLine = nil
    }

    /// Shared by human drag-release and the bot: launches `node` in `direction` (unit vector) with `power`.
    func applyShot(to node: SKShapeNode, direction: CGVector, power: CGFloat) {
        node.physicsBody?.velocity = .zero
        node.physicsBody?.applyImpulse(CGVector(dx: direction.dx * power, dy: direction.dy * power))
        viewModel?.isSimulating = true
        wasSimulating = true
    }

    func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(a.x - b.x, a.y - b.y)
    }
}
