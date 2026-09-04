import SpriteKit
import UIKit
import QuartzCore

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
    /// Beyond this drag distance the shot is already at full power — kept short so a normal
    /// flick gesture (not a huge cross-screen swipe) reaches max force.
    private let maxDrag: CGFloat = 150
    let maxImpulse: CGFloat = 170
    /// The goalkeeper is allowed a stronger flick than a field cap, per the traditional rule
    /// that the GR defends with more forceful clears from inside the box.
    private let gkImpulseBonus: CGFloat = 1.35
    /// A drag that barely clears the `dist > 8` no-op threshold still lands a real shot,
    /// not a token nudge — this is the power floor for it.
    private let minPowerRatio: CGFloat = 0.3

    weak var viewModel: GameViewModel?

    var ball: SKShapeNode!
    var homeCaps: [SKShapeNode] = []
    var awayCaps: [SKShapeNode] = []
    var fieldLayer: SKNode!

    private var dragNode: SKShapeNode?
    private var dragStart: CGPoint = .zero
    private var aimLine: SKShapeNode?

    var wasSimulating = false
    var awaitingReset = false
    private var allBodies: [SKPhysicsBody] = []
    /// A body under this speed counts as "stopped" for turn purposes — doesn't need to reach
    /// exactly zero, just slow enough that waiting any longer wouldn't visibly change anything.
    private let stoppedSpeedThreshold: CGFloat = 5
    /// Safety net: force the turn to end after this long even if something is still crawling
    /// along a wall (e.g. a shallow-angle bounce that never quite drops below the threshold).
    private let maxSimulationSeconds: TimeInterval = 3.5
    private var simulationStartTime: TimeInterval?

    /// Which team took the shot currently settling, and whether that cap was already in the
    /// opponent's half at the moment of release — the official rule requires that to shoot on
    /// goal. An own goal (the ball ending up in your OWN net) always counts regardless of this;
    /// only a shot at the OPPONENT's goal needs the acting cap to have been advanced.
    private var lastShotTeam: Team?
    private var lastShotFromOpponentHalf = false

    /// Foul tracking: a "carga" is the acting cap hitting an opponent cap before it ever
    /// touches the ball. Three fouls in a row by the same team hands the opponent a free kick
    /// (an extra, uninterrupted turn), per the traditional rule in section 6.1 of the design doc.
    private weak var lastShotNode: SKShapeNode?
    private var shotTouchedBall = false
    private var foulRegisteredThisShot = false
    private var foulStreak: [Team: Int] = [.home: 0, .away: 0]

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

        let centerDot = SKShapeNode(circleOfRadius: 6)
        centerDot.position = CGPoint(x: Self.fieldWidth / 2, y: Self.fieldHeight / 2)
        centerDot.fillColor = SKColor.white.withAlphaComponent(0.85)
        centerDot.strokeColor = .clear
        fieldLayer.addChild(centerDot)

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
        addFieldDetails(pitch: pitch, boxH: boxH)
    }

    private func buildGoal(atBottom: Bool) {
        let gx0 = Self.fieldWidth / 2 - goalWidth / 2
        let y = atBottom ? wall - goalDepth : Self.fieldHeight - wall
        let rect = CGRect(x: gx0, y: y, width: goalWidth, height: goalDepth)

        let net = SKShapeNode(rect: rect)
        net.fillColor = SKColor.white.withAlphaComponent(0.12)
        net.strokeColor = SKColor.white.withAlphaComponent(0.7)
        net.lineWidth = 3
        fieldLayer.addChild(net)
        addNetMesh(in: rect)

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

        // Seals each goal mouth for caps only (the ball's collisionBitMask doesn't include
        // this category, so it still passes through freely to reach the goal sensor and score).
        func capOnlyGoalLine(_ from: CGPoint, _ to: CGPoint) {
            let node = SKNode()
            node.physicsBody = SKPhysicsBody(edgeFrom: from, to: to)
            node.physicsBody?.categoryBitMask = PhysicsCategory.goalLine
            node.physicsBody?.collisionBitMask = PhysicsCategory.cap
            addChild(node)
        }

        wallSeg(CGPoint(x: pitch.minX, y: pitch.minY), CGPoint(x: pitch.minX, y: pitch.maxY))
        wallSeg(CGPoint(x: pitch.maxX, y: pitch.minY), CGPoint(x: pitch.maxX, y: pitch.maxY))
        wallSeg(CGPoint(x: pitch.minX, y: pitch.minY), CGPoint(x: gx0, y: pitch.minY))
        wallSeg(CGPoint(x: gx1, y: pitch.minY), CGPoint(x: pitch.maxX, y: pitch.minY))
        wallSeg(CGPoint(x: pitch.minX, y: pitch.maxY), CGPoint(x: gx0, y: pitch.maxY))
        wallSeg(CGPoint(x: gx1, y: pitch.maxY), CGPoint(x: pitch.maxX, y: pitch.maxY))

        capOnlyGoalLine(CGPoint(x: gx0, y: pitch.minY), CGPoint(x: gx1, y: pitch.minY))
        capOnlyGoalLine(CGPoint(x: gx0, y: pitch.maxY), CGPoint(x: gx1, y: pitch.maxY))
    }

    // MARK: - Caps & ball

    private func makeCap(team: Team, isGK: Bool, at point: CGPoint, index: Int) -> SKShapeNode {
        let radius = isGK ? gkRadius : capRadius
        let node = SKShapeNode(circleOfRadius: radius)
        node.position = point
        node.name = "\(team.rawValue)-\(isGK ? "gk" : "\(index)")"
        let kit = team == .home ? KitManager.shared.homeKit : KitManager.shared.awayKit
        node.fillColor = .white
        node.fillTexture = glossyTexture(base: kit.base, highlight: kit.highlight, diameter: radius * 2, key: "cap-\(kit.rawValue)-\(Int(radius))")
        node.strokeColor = SKColor.black.withAlphaComponent(0.35)
        node.lineWidth = 2
        node.zPosition = 5
        node.addChild(shadowNode(diameter: radius * 2.4))

        if isGK {
            let dot = SKShapeNode(circleOfRadius: radius * 0.38)
            dot.fillColor = .white
            dot.strokeColor = .clear
            dot.zPosition = 0.1
            node.addChild(dot)
        }

        let body = SKPhysicsBody(circleOfRadius: radius)
        body.mass = isGK ? 0.15 : 0.275
        // The goalkeeper is lighter and less damped than a field cap — more agile inside the
        // box, matching the traditional rule that the GR gets stronger, freer flicks to defend.
        body.linearDamping = isGK ? 0.88 : 0.95
        body.restitution = 0.65
        body.friction = 0.2
        body.allowsRotation = false
        body.affectedByGravity = false
        body.usesPreciseCollisionDetection = true
        body.categoryBitMask = PhysicsCategory.cap
        body.collisionBitMask = PhysicsCategory.cap | PhysicsCategory.ball | PhysicsCategory.wall | PhysicsCategory.goalLine
        // Needed to detect fouls (a cap charging into an opponent cap before the ball).
        body.contactTestBitMask = PhysicsCategory.cap | PhysicsCategory.ball
        node.physicsBody = body

        return node
    }

    private func makeBall(at point: CGPoint) -> SKShapeNode {
        let node = SKShapeNode(circleOfRadius: ballRadius)
        node.position = point
        node.name = "ball"
        node.fillColor = .white
        node.fillTexture = glossyTexture(base: SKColor(white: 0.93, alpha: 1), highlight: .white, diameter: ballRadius * 2, key: "ball-\(Int(ballRadius))")
        node.strokeColor = SKColor.black.withAlphaComponent(0.2)
        node.lineWidth = 1.5
        node.zPosition = 6
        node.addChild(shadowNode(diameter: ballRadius * 2.6))

        let body = SKPhysicsBody(circleOfRadius: ballRadius)
        body.mass = 0.06
        body.linearDamping = 0.7
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
        dragNode = nil
        aimLine?.removeFromParent()
        aimLine = nil

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
        simulationStartTime = nil
        lastShotTeam = nil
        lastShotFromOpponentHalf = false
        lastShotNode = nil
        shotTouchedBall = false
        foulRegisteredThisShot = false
        foulStreak = [.home: 0, .away: 0]
        viewModel?.isSimulating = false
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
        let stillMoving = allBodies.contains { hypot($0.velocity.dx, $0.velocity.dy) > stoppedSpeedThreshold }
        let timedOut = simulationStartTime.map { currentTime - $0 > maxSimulationSeconds } ?? false
        let moving = stillMoving && !timedOut

        if moving {
            if !wasSimulating { simulationStartTime = currentTime }
            wasSimulating = true
            if viewModel?.isSimulating == false { viewModel?.isSimulating = true }
        } else if wasSimulating {
            wasSimulating = false
            simulationStartTime = nil
            for b in allBodies { b.velocity = .zero }
            viewModel?.isSimulating = false
            guard !awaitingReset else { return }

            if let team = lastShotTeam {
                if foulRegisteredThisShot {
                    foulStreak[team, default: 0] += 1
                    if foulStreak[team, default: 0] >= 3 {
                        foulStreak[team] = 0
                        viewModel?.grantFreeKick(to: team.opponent)
                    } else {
                        viewModel?.reportFoul(team: team, streak: foulStreak[team, default: 0])
                    }
                } else {
                    foulStreak[team] = 0
                }
            }

            let turnPassed = viewModel?.turnEnded() ?? false
            if viewModel?.mode.isOnline == true {
                // Only hand the turn to Game Center once this device's full turn (all its
                // actions) is used up — mid-turn actions stay purely local.
                if turnPassed { submitOnlineTurnIfNeeded() }
            } else {
                highlightActiveTeam()
                scheduleBotTurnIfNeeded()
            }
        }
    }

    // MARK: - Contacts (goal detection)

    func didBegin(_ contact: SKPhysicsContact) {
        guard !awaitingReset else { return }

        if !shotTouchedBall, !foulRegisteredThisShot, let acting = lastShotNode, let actingTeam = lastShotTeam {
            let a = contact.bodyA.node, b = contact.bodyB.node
            let other: SKNode? = a === acting ? b : (b === acting ? a : nil)
            if let other {
                if other.name == "ball" {
                    shotTouchedBall = true
                } else if let otherName = other.name, otherName.hasPrefix(actingTeam.opponent.rawValue) {
                    foulRegisteredThisShot = true
                }
            }
        }

        let names = [contact.bodyA.node?.name, contact.bodyB.node?.name]
        if names.contains("goal-bottom") {
            // Bottom net belongs to home. Away benefits either by a legal shot (their cap was
            // already in home's half) or by home putting it in their own net (always counts).
            if lastShotTeam == .away, !lastShotFromOpponentHalf { return }
            awaitingReset = true
            goalFeedback.notificationOccurred(.success)
            SoundManager.shared.play(.goal)
            spawnGoalConfetti(atBottom: true)
            viewModel?.goalScored(by: .away)
        } else if names.contains("goal-top") {
            if lastShotTeam == .home, !lastShotFromOpponentHalf { return }
            awaitingReset = true
            goalFeedback.notificationOccurred(.success)
            SoundManager.shared.play(.goal)
            spawnGoalConfetti(atBottom: false)
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
        // Point-and-release: drag in the direction you want the cap to go (not a slingshot
        // pull-back) — the shot direction is the same as the drag vector, not its opposite.
        let dx = point.x - dragStart.x
        let dy = point.y - dragStart.y
        let rawDist = hypot(dx, dy)
        let ratio = min(rawDist / maxDrag, 1)
        // Clamp the drawn line to the drag distance that actually caps out the power, so what
        // the player sees always matches what they'll get — dragging further doesn't lie.
        let clampedDist = min(rawDist, maxDrag)
        let angle = atan2(dy, dx)
        let tip = CGPoint(x: node.position.x + cos(angle) * clampedDist, y: node.position.y + sin(angle) * clampedDist)

        aimLine?.removeFromParent()
        let line = SKShapeNode(path: {
            let p = CGMutablePath()
            p.move(to: node.position)
            p.addLine(to: tip)
            return p
        }())
        line.strokeColor = SKColor(
            red: 1,
            green: 0.75 - ratio * 0.55,
            blue: 0.1 + (1 - ratio) * 0.1,
            alpha: 1
        )
        line.lineWidth = 5 + ratio * 4
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
        let dx = point.x - dragStart.x
        let dy = point.y - dragStart.y
        let rawDist = hypot(dx, dy)
        guard rawDist > 8 else { return }
        let ratio = min(rawDist / maxDrag, 1)
        let angle = atan2(dy, dx)
        // Curved (not linear) so short-to-medium drags still feel like a real kick, not a nudge.
        let curved = max(minPowerRatio, pow(ratio, 0.6))
        let power = curved * maxImpulse
        applyShot(to: node, direction: CGVector(dx: cos(angle), dy: sin(angle)), power: power)
        impactFeedback.impactOccurred(intensity: curved)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        dragNode = nil
        aimLine?.removeFromParent()
        aimLine = nil
    }

    /// Shared by human drag-release and the bot: launches `node` in `direction` (unit vector) with `power`.
    func applyShot(to node: SKShapeNode, direction: CGVector, power: CGFloat) {
        var power = power
        if let name = node.name {
            let team: Team = name.hasPrefix("home-") ? .home : .away
            lastShotTeam = team
            // Opponent's half: above the midline for home (attacking upward), below it for away.
            lastShotFromOpponentHalf = team == .home
                ? node.position.y > Self.fieldHeight / 2
                : node.position.y < Self.fieldHeight / 2
            if name.hasSuffix("gk") { power *= gkImpulseBonus }
        }
        lastShotNode = node
        shotTouchedBall = false
        foulRegisteredThisShot = false
        node.physicsBody?.velocity = .zero
        node.physicsBody?.applyImpulse(CGVector(dx: direction.dx * power, dy: direction.dy * power))
        viewModel?.isSimulating = true
        wasSimulating = true
        SoundManager.shared.play(.kick)
        // Set here (not just in `update`) so the safety timeout also covers the very first
        // frame after a shot — `update`'s own start-time capture only fires on a moving->moving
        // transition, which never happens for a shot that's already marked as simulating.
        simulationStartTime = CACurrentMediaTime()
    }

    func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(a.x - b.x, a.y - b.y)
    }
}
