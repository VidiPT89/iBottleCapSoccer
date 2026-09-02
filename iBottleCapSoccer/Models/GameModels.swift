import CoreGraphics

enum Team: String {
    case home
    case away

    var opponent: Team { self == .home ? .away : .home }
}

struct Carica: Identifiable {
    let id: String
    let team: Team
    var position: CGPoint
    let weight: Double
    let isGoalkeeper: Bool
}

struct Ball {
    var position: CGPoint
    var velocity: CGVector
    var isMoving: Bool
}

struct Field {
    static let width: CGFloat = 110
    static let length: CGFloat = 170
    static let goalWidth: CGFloat = 15.5
    static let goalDepth: CGFloat = 5.5
}

enum MatchHalf: Int {
    case first = 1
    case second = 2
}

enum PhysicsCategory {
    static let none: UInt32 = 0
    static let cap: UInt32 = 0x1 << 0
    static let ball: UInt32 = 0x1 << 1
    static let wall: UInt32 = 0x1 << 2
    static let goalSensor: UInt32 = 0x1 << 3
}
