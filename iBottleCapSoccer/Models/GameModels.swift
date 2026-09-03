enum Team: String {
    case home
    case away

    var opponent: Team { self == .home ? .away : .home }
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
