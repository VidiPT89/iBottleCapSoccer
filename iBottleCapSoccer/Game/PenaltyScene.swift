import SpriteKit

/// Standalone free-practice mode: one attacking cap, one ball, one keeper that shuffles side
/// to side before each attempt. Deliberately simpler than `GameScene` (flat colors, no teams,
/// no turns) since this is just a flick-and-power sandbox, not a match.
final class PenaltyScene: SKScene, SKPhysicsContactDelegate {
    static let fieldWidth: CGFloat = 700
    static let fieldHeight: CGFloat = 900
    private let wall: CGFloat = 40
    private let goalWidth: CGFloat = 220
    private let capRadius: CGFloat = 32
    private let ballRadius: CGFloat = 18
    private let maxDrag: CGFloat = 150
    private let maxImpulse: CGFloat = 170

    var onAttemptResolved: ((Bool) -> Void)?

    private var cap: SKShapeNode!
    private var ball: SKShapeNode!
    private var keeper: SKShapeNode!
    private var dragNode: SKShapeNode?
    private var dragStart: CGPoint = .zero
    private var aimLine: SKShapeNode?
    private var awaitingResolution = false
    private var wasSimulating = false

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.059, green: 0.29, blue: 0.169, alpha: 1)
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = .zero
        buildField()
        resetAttempt()
    }

    private func buildField() {
        let pitch = CGRect(x: wall, y: wall, width: Self.fieldWidth - 2 * wall, height: Self.fieldHeight - 2 * wall)
        let border = SKShapeNode(rect: pitch)
        border.strokeColor = SKColor.white.withAlphaComponent(0.85)
        border.lineWidth = 4
        border.fillColor = .clear
        addChild(border)

        let goalX0 = Self.fieldWidth / 2 - goalWidth / 2
        let goalX1 = Self.fieldWidth / 2 + goalWidth / 2
        let goalRect = CGRect(x: goalX0, y: Self.fieldHeight - wall, width: goalWidth, height: 26)
        let net = SKShapeNode(rect: goalRect)
        net.fillColor = SKColor.white.withAlphaComponent(0.12)
        net.strokeColor = SKColor.white.withAlphaComponent(0.7)
        net.lineWidth = 3
        addChild(net)

        func wallSeg(_ from: CGPoint, _ to: CGPoint) {
            let node = SKNode()
            node.physicsBody = SKPhysicsBody(edgeFrom: from, to: to)
            node.physicsBody?.categoryBitMask = PhysicsCategory.wall
            node.physicsBody?.collisionBitMask = PhysicsCategory.cap | PhysicsCategory.ball
            addChild(node)
        }
        wallSeg(CGPoint(x: pitch.minX, y: pitch.minY), CGPoint(x: pitch.minX, y: pitch.maxY))
        wallSeg(CGPoint(x: pitch.maxX, y: pitch.minY), CGPoint(x: pitch.maxX, y: pitch.maxY))
        wallSeg(CGPoint(x: pitch.minX, y: pitch.minY), CGPoint(x: pitch.maxX, y: pitch.minY))
        wallSeg(CGPoint(x: pitch.minX, y: pitch.maxY), CGPoint(x: goalX0, y: pitch.maxY))
        wallSeg(CGPoint(x: goalX1, y: pitch.maxY), CGPoint(x: pitch.maxX, y: pitch.maxY))

        let sensor = SKNode()
        sensor.position = CGPoint(x: goalRect.midX, y: goalRect.midY)
        let body = SKPhysicsBody(rectangleOf: CGSize(width: goalWidth - 20, height: 26))
        body.isDynamic = false
        body.categoryBitMask = PhysicsCategory.goalSensor
        body.contactTestBitMask = PhysicsCategory.ball
        body.collisionBitMask = PhysicsCategory.none
        sensor.physicsBody = body
        sensor.name = "goal"
        addChild(sensor)
    }

    private func makeCircle(radius: CGFloat, color: SKColor, name: String, category: UInt32, collides: UInt32) -> SKShapeNode {
        let node = SKShapeNode(circleOfRadius: radius)
        node.name = name
        node.fillColor = color
        node.strokeColor = SKColor.black.withAlphaComponent(0.35)
        node.lineWidth = 2
        let body = SKPhysicsBody(circleOfRadius: radius)
        body.mass = 0.25
        body.linearDamping = 0.95
        body.restitution = 0.6
        body.friction = 0.2
        body.allowsRotation = false
        body.affectedByGravity = false
        body.usesPreciseCollisionDetection = true
        body.categoryBitMask = category
        body.collisionBitMask = collides
        body.contactTestBitMask = PhysicsCategory.none
        node.physicsBody = body
        return node
    }

    func resetAttempt() {
        dragNode = nil
        aimLine?.removeFromParent()
        aimLine = nil
        cap?.removeFromParent()
        ball?.removeFromParent()
        keeper?.removeFromParent()

        cap = makeCircle(radius: capRadius, color: Brand.uiOrange, name: "attacker",
                          category: PhysicsCategory.cap, collides: PhysicsCategory.ball | PhysicsCategory.wall)
        cap.position = CGPoint(x: Self.fieldWidth / 2, y: wall + 140)
        addChild(cap)

        ball = makeCircle(radius: ballRadius, color: .white, name: "ball",
                           category: PhysicsCategory.ball, collides: PhysicsCategory.cap | PhysicsCategory.wall)
        ball.position = CGPoint(x: Self.fieldWidth / 2, y: wall + 220)
        ball.physicsBody?.contactTestBitMask = PhysicsCategory.goalSensor
        addChild(ball)

        keeper = makeCircle(radius: capRadius * 1.05, color: SKColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1), name: "keeper",
                             category: PhysicsCategory.cap, collides: PhysicsCategory.ball | PhysicsCategory.wall)
        keeper.position = CGPoint(x: Self.fieldWidth / 2, y: Self.fieldHeight - wall - 60)
        keeper.physicsBody?.isDynamic = false
        addChild(keeper)
        patrolKeeper()

        awaitingResolution = false
        wasSimulating = false
    }

    private func patrolKeeper() {
        let goalX0 = Self.fieldWidth / 2 - goalWidth / 2 + capRadius
        let goalX1 = Self.fieldWidth / 2 + goalWidth / 2 - capRadius
        let left = SKAction.moveTo(x: goalX0, duration: 0.9)
        let right = SKAction.moveTo(x: goalX1, duration: 0.9)
        left.timingMode = .easeInEaseOut
        right.timingMode = .easeInEaseOut
        keeper.run(.repeatForever(.sequence([left, right])))
    }

    func didBegin(_ contact: SKPhysicsContact) {
        guard !awaitingResolution else { return }
        let names = [contact.bodyA.node?.name, contact.bodyB.node?.name]
        if names.contains("goal") {
            awaitingResolution = true
            keeper.removeAllActions()
            onAttemptResolved?(true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in self?.resetAttempt() }
        }
    }

    override func update(_ currentTime: TimeInterval) {
        guard let capBody = cap?.physicsBody, let ballBody = ball?.physicsBody else { return }
        let moving = hypot(capBody.velocity.dx, capBody.velocity.dy) > 5 || hypot(ballBody.velocity.dx, ballBody.velocity.dy) > 5
        if moving {
            wasSimulating = true
        } else if wasSimulating, !awaitingResolution {
            wasSimulating = false
            capBody.velocity = .zero
            ballBody.velocity = .zero
            awaitingResolution = true
            keeper.removeAllActions()
            onAttemptResolved?(false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in self?.resetAttempt() }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !awaitingResolution, let touch = touches.first else { return }
        let point = touch.location(in: self)
        guard hypot(cap.position.x - point.x, cap.position.y - point.y) < capRadius * 1.8 else { return }
        dragNode = cap
        dragStart = cap.position
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard dragNode != nil, let touch = touches.first else { return }
        let point = touch.location(in: self)
        let dx = dragStart.x - point.x, dy = dragStart.y - point.y
        let clampedDist = min(hypot(dx, dy), maxDrag)
        let angle = atan2(dy, dx)
        let tip = CGPoint(x: cap.position.x - cos(angle) * clampedDist, y: cap.position.y - sin(angle) * clampedDist)
        aimLine?.removeFromParent()
        let line = SKShapeNode(path: {
            let p = CGMutablePath(); p.move(to: cap.position); p.addLine(to: tip); return p
        }())
        line.strokeColor = Brand.uiOrangeLight
        line.lineWidth = 5
        line.lineCap = .round
        addChild(line)
        aimLine = line
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        defer { dragNode = nil; aimLine?.removeFromParent(); aimLine = nil }
        guard dragNode != nil, let touch = touches.first else { return }
        let point = touch.location(in: self)
        let dx = dragStart.x - point.x, dy = dragStart.y - point.y
        let rawDist = hypot(dx, dy)
        guard rawDist > 8 else { return }
        let ratio = min(rawDist / maxDrag, 1)
        let angle = atan2(dy, dx)
        let curved = max(0.3, pow(ratio, 0.6))
        let power = curved * maxImpulse
        cap.physicsBody?.applyImpulse(CGVector(dx: cos(angle) * power, dy: sin(angle) * power))
        wasSimulating = true
    }
}
