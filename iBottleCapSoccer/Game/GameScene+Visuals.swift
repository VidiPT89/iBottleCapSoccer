import SpriteKit
import UIKit

/// Generates and caches small procedural textures (glossy sphere shading, soft drop shadows)
/// so caps and the ball read as lit 3D objects instead of flat colored discs.
extension GameScene {
    private static var textureCache: [String: SKTexture] = [:]

    func glossyTexture(base: UIColor, highlight: UIColor, diameter: CGFloat, key: String) -> SKTexture {
        if let cached = Self.textureCache[key] { return cached }
        let size = CGSize(width: diameter, height: diameter)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: size)
            ctx.cgContext.setFillColor(base.cgColor)
            ctx.cgContext.fillEllipse(in: rect)

            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [highlight.withAlphaComponent(0.95).cgColor, highlight.withAlphaComponent(0).cgColor] as CFArray
            guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1]) else { return }
            ctx.cgContext.saveGState()
            ctx.cgContext.addEllipse(in: rect)
            ctx.cgContext.clip()
            let center = CGPoint(x: size.width * 0.34, y: size.height * 0.28)
            ctx.cgContext.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: diameter * 0.62, options: [])
            ctx.cgContext.restoreGState()

            // subtle rim shading for depth
            let rimColors = [UIColor.black.withAlphaComponent(0).cgColor, UIColor.black.withAlphaComponent(0.22).cgColor] as CFArray
            guard let rimGradient = CGGradient(colorsSpace: colorSpace, colors: rimColors, locations: [0, 1]) else { return }
            ctx.cgContext.saveGState()
            ctx.cgContext.addEllipse(in: rect)
            ctx.cgContext.clip()
            ctx.cgContext.drawRadialGradient(rimGradient, startCenter: CGPoint(x: size.width / 2, y: size.height / 2), startRadius: diameter * 0.32, endCenter: CGPoint(x: size.width / 2, y: size.height / 2), endRadius: diameter * 0.5, options: [])
            ctx.cgContext.restoreGState()
        }
        let texture = SKTexture(image: image)
        Self.textureCache[key] = texture
        return texture
    }

    func shadowNode(diameter: CGFloat) -> SKSpriteNode {
        let key = "shadow-\(Int(diameter))"
        let texture: SKTexture
        if let cached = Self.textureCache[key] {
            texture = cached
        } else {
            let size = CGSize(width: diameter, height: diameter)
            let renderer = UIGraphicsImageRenderer(size: size)
            let image = renderer.image { ctx in
                let colorSpace = CGColorSpaceCreateDeviceRGB()
                let colors = [UIColor.black.withAlphaComponent(0.4).cgColor, UIColor.black.withAlphaComponent(0).cgColor] as CFArray
                guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1]) else { return }
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                ctx.cgContext.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: diameter / 2, options: [])
            }
            texture = SKTexture(image: image)
            Self.textureCache[key] = texture
        }
        let node = SKSpriteNode(texture: texture)
        node.zPosition = -1
        node.yScale = 0.45
        return node
    }

    /// Diagonal criss-cross lines inside a goal rect, so it reads as netting instead of a flat tint.
    func addNetMesh(in rect: CGRect) {
        let mesh = SKShapeNode(path: {
            let p = CGMutablePath()
            let step: CGFloat = 14
            var x = rect.minX - rect.height
            while x < rect.maxX {
                p.move(to: CGPoint(x: x, y: rect.minY))
                p.addLine(to: CGPoint(x: x + rect.height, y: rect.maxY))
                x += step
            }
            x = rect.minX
            while x < rect.maxX + rect.height {
                p.move(to: CGPoint(x: x, y: rect.minY))
                p.addLine(to: CGPoint(x: x - rect.height, y: rect.maxY))
                x += step
            }
            return p
        }())
        mesh.strokeColor = SKColor.white.withAlphaComponent(0.22)
        mesh.lineWidth = 1
        let cropNode = SKCropNode()
        let maskShape = SKShapeNode(rect: rect)
        maskShape.fillColor = .white
        cropNode.maskNode = maskShape
        cropNode.addChild(mesh)
        fieldLayer.addChild(cropNode)
    }

    /// Penalty spots, corner arcs and a soft edge vignette — cheap detail that makes the
    /// pitch read as a real markup instead of a plain green rectangle with a box.
    func addFieldDetails(pitch: CGRect, boxH: CGFloat) {
        let dotRadius: CGFloat = 6
        for y in [pitch.minY + boxH - 60, pitch.maxY - boxH + 60] {
            let dot = SKShapeNode(circleOfRadius: dotRadius)
            dot.position = CGPoint(x: Self.fieldWidth / 2, y: y)
            dot.fillColor = SKColor.white.withAlphaComponent(0.85)
            dot.strokeColor = .clear
            fieldLayer.addChild(dot)
        }

        let cornerRadius: CGFloat = 34
        let corners: [(CGPoint, CGFloat, CGFloat)] = [
            (CGPoint(x: pitch.minX, y: pitch.minY), 0, .pi / 2),
            (CGPoint(x: pitch.maxX, y: pitch.minY), .pi / 2, .pi),
            (CGPoint(x: pitch.minX, y: pitch.maxY), -.pi / 2, 0),
            (CGPoint(x: pitch.maxX, y: pitch.maxY), .pi, .pi * 1.5),
        ]
        for (point, start, end) in corners {
            let arc = SKShapeNode(path: {
                let p = CGMutablePath()
                p.addArc(center: point, radius: cornerRadius, startAngle: start, endAngle: end, clockwise: false)
                return p
            }())
            arc.strokeColor = SKColor.white.withAlphaComponent(0.85)
            arc.lineWidth = 4
            arc.fillColor = .clear
            fieldLayer.addChild(arc)
        }

        let vignetteKey = "vignette-\(Int(pitch.width))x\(Int(pitch.height))"
        let vignette: SKTexture
        if let cached = Self.textureCache[vignetteKey] {
            vignette = cached
        } else {
            let size = pitch.size
            let renderer = UIGraphicsImageRenderer(size: size)
            let image = renderer.image { ctx in
                let colorSpace = CGColorSpaceCreateDeviceRGB()
                let colors = [UIColor.black.withAlphaComponent(0).cgColor, UIColor.black.withAlphaComponent(0.32).cgColor] as CFArray
                guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1]) else { return }
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = max(size.width, size.height) * 0.72
                ctx.cgContext.drawRadialGradient(gradient, startCenter: center, startRadius: radius * 0.55, endCenter: center, endRadius: radius, options: [.drawsAfterEndLocation])
            }
            vignette = SKTexture(image: image)
            Self.textureCache[vignetteKey] = vignette
        }
        let vignetteNode = SKSpriteNode(texture: vignette)
        vignetteNode.position = CGPoint(x: pitch.midX, y: pitch.midY)
        vignetteNode.zPosition = 2
        fieldLayer.addChild(vignetteNode)
    }

    /// A one-shot confetti burst from the scored goal, in the brand palette. Self-removing.
    func spawnGoalConfetti(atBottom: Bool) {
        let key = "confetti-dot"
        let texture: SKTexture
        if let cached = Self.textureCache[key] {
            texture = cached
        } else {
            let size = CGSize(width: 8, height: 8)
            let renderer = UIGraphicsImageRenderer(size: size)
            let image = renderer.image { ctx in
                ctx.cgContext.setFillColor(UIColor.white.cgColor)
                ctx.cgContext.fill(CGRect(origin: .zero, size: size))
            }
            texture = SKTexture(image: image)
            Self.textureCache[key] = texture
        }

        let emitter = SKEmitterNode()
        emitter.particleTexture = texture
        emitter.position = CGPoint(x: Self.fieldWidth / 2, y: atBottom ? wall + 30 : Self.fieldHeight - wall - 30)
        emitter.zPosition = 60
        emitter.particleBirthRate = 500
        emitter.numParticlesToEmit = 50
        emitter.particleLifetime = 1.0
        emitter.particleLifetimeRange = 0.5
        emitter.particlePositionRange = CGVector(dx: goalWidth * 0.9, dy: 10)
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi * 0.85
        emitter.particleSpeed = 280
        emitter.particleSpeedRange = 180
        emitter.yAcceleration = -420
        emitter.particleAlpha = 1
        emitter.particleAlphaSpeed = -1.1
        emitter.particleScale = 0.55
        emitter.particleScaleRange = 0.3
        emitter.particleRotationRange = .pi * 2
        emitter.particleRotationSpeed = 3
        emitter.particleColorBlendFactor = 1
        emitter.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [Brand.uiOrange, Brand.uiOrangeLight, SKColor.white, SKColor(red: 0.85, green: 0.6, blue: 0.12, alpha: 1)],
            times: [0, 0.33, 0.66, 1]
        )
        addChild(emitter)
        emitter.run(.sequence([.wait(forDuration: 2.0), .removeFromParent()]))
    }
}
