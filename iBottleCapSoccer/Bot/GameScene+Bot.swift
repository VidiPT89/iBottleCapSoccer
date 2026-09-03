import SpriteKit

/// Heuristic bot: no board-game-style lookahead (SpriteKit physics can't be cheaply
/// "forked" for a dry-run simulation), so difficulty is expressed through how well the
/// bot aims/powers its shot and how tactically it picks a target, not through search depth.
extension GameScene {

    /// Schedules the bot's move, if it's currently the bot's turn.
    func scheduleBotTurnIfNeeded() {
        guard let vm = viewModel, case .bot(let difficulty) = vm.mode,
              vm.currentTeam == vm.botTeam, !vm.isPaused, !vm.isFullTime, !awaitingReset else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + difficulty.thinkingDelay) { [weak self] in
            self?.performBotShot(difficulty: difficulty)
        }
    }

    private func performBotShot(difficulty: BotDifficulty) {
        guard let vm = viewModel, vm.currentTeam == vm.botTeam, !vm.isSimulating, !vm.isPaused, !vm.isFullTime else { return }
        let team = vm.botTeam
        let caps = team == .home ? homeCaps : awayCaps
        guard !caps.isEmpty, let ball else { return }

        let oppGoalY: CGFloat = team == .home ? Self.fieldHeight - wall : wall
        let ownGoalY: CGFloat = team == .home ? wall : Self.fieldHeight - wall
        let advancing: CGFloat = team == .home ? 1 : -1 // sign of "toward opponent goal" along Y

        let cap = pickActingCap(from: caps, ball: ball.position, advancing: advancing, difficulty: difficulty)

        // Danger check: is the ball dangerously close to our own goal, closer to us than the ball is to goal?
        let ballDangerDistance = abs(ball.position.y - ownGoalY)
        let inOwnDangerZone = ballDangerDistance < 260

        var target: CGPoint
        if difficulty.playsTactically, inOwnDangerZone {
            // Clear the ball away from goal and off-center, toward midfield.
            let clearX = ball.position.x < Self.fieldWidth / 2 ? Self.fieldWidth * 0.78 : Self.fieldWidth * 0.22
            target = CGPoint(x: clearX, y: ball.position.y + advancing * 320)
        } else if difficulty.playsTactically, isGoodShotOnGoal(from: cap.position, ball: ball.position, oppGoalY: oppGoalY, advancing: advancing) {
            target = CGPoint(x: Self.fieldWidth / 2 + CGFloat.random(in: -50...50), y: oppGoalY)
        } else {
            // Just nudge the ball forward, roughly toward the opponent goal.
            let forward = CGPoint(x: ball.position.x, y: ball.position.y + advancing * 260)
            target = forward
        }

        // Aim from the cap, through the ball, toward the target — with an angle jitter for difficulty.
        let throughBall = atan2(ball.position.y - cap.position.y, ball.position.x - cap.position.x)
        let toTarget = atan2(target.y - ball.position.y, target.x - ball.position.x)
        let blended = angleLerp(throughBall, toTarget, t: 0.55)
        let jitter = CGFloat.random(in: -difficulty.aimJitterDegrees...difficulty.aimJitterDegrees) * .pi / 180
        let finalAngle = blended + jitter

        let distToBall = distance(cap.position, ball.position)
        let basePower = min(maxImpulse, 42 + distToBall * 0.26)
        let variance = CGFloat.random(in: difficulty.powerVarianceRange.lowerBound...difficulty.powerVarianceRange.upperBound)
        let power = min(maxImpulse, basePower * variance)

        applyShot(to: cap, direction: CGVector(dx: cos(finalAngle), dy: sin(finalAngle)), power: power)
    }

    private func pickActingCap(from caps: [SKShapeNode], ball: CGPoint, advancing: CGFloat, difficulty: BotDifficulty) -> SKShapeNode {
        guard difficulty.picksBestCap else {
            return caps.min(by: { distance($0.position, ball) < distance($1.position, ball) }) ?? caps[0]
        }
        // Hard: prefer a cap that's both close to the ball and already goal-side of it.
        return caps.min(by: { lhs, rhs in
            score(lhs, ball: ball, advancing: advancing) < score(rhs, ball: ball, advancing: advancing)
        }) ?? caps[0]
    }

    private func score(_ cap: SKShapeNode, ball: CGPoint, advancing: CGFloat) -> CGFloat {
        let behindBonus: CGFloat = (ball.y - cap.position.y) * advancing > 0 ? -60 : 0 // cap is on the "attacking" side of the ball
        return distance(cap.position, ball) + behindBonus
    }

    private func isGoodShotOnGoal(from capPoint: CGPoint, ball: CGPoint, oppGoalY: CGFloat, advancing: CGFloat) -> Bool {
        let ballIsAdvanced = (ball.y - Self.fieldHeight / 2) * advancing > 0
        let closeEnough = abs(ball.y - oppGoalY) < 620
        let capBehindBall = (ball.y - capPoint.y) * advancing > 0
        return ballIsAdvanced && closeEnough && capBehindBall
    }

    private func angleLerp(_ a: CGFloat, _ b: CGFloat, t: CGFloat) -> CGFloat {
        var diff = b - a
        while diff > .pi { diff -= 2 * .pi }
        while diff < -.pi { diff += 2 * .pi }
        return a + diff * t
    }
}
