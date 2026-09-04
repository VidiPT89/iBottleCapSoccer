# ⚽ iBottleCapSoccer

> A native iOS bottle cap soccer game — flick, aim and score, built with SwiftUI and SpriteKit.

[Report Bug](https://github.com/VidiPT89/iBottleCapSoccer/issues) · [Request Feature](https://github.com/VidiPT89/iBottleCapSoccer/issues)

## ✨ Features

- ✅ Realistic flick-based physics (friction, collisions, bounces, a stronger/more agile goalkeeper) powered by SpriteKit, with pinch-to-zoom on the pitch
- ✅ Three game modes: local 1 vs 1, 1 vs Bot (3 difficulty levels), and online multiplayer via Game Center
- ✅ Full match flow: kickoff, goals, half-time, full-time — Local/Bot play 2×15min with an optional early-finish goal limit (e.g. first to 5), online plays to a fixed first-to-5 with no clock
- ✅ Fouls: charging an opponent's cap before touching the ball is a foul; three in a row hand the opponent a free kick (an extra turn)
- ✅ Penalty Training mode — free flick practice against a patrolling keeper, with a conversion counter
- ✅ Career mode — a 7-stage ladder of Bot opponents with rising difficulty, unlocked sequentially
- ✅ Team kit customization (6 colors per side) and lifetime stats (goals scored, matches played/won)
- ✅ Procedural sound effects (kick, goal, whistle) and a soft ambient loop — no bundled audio assets
- ✅ Bilingual interface — Portuguese (PT-PT) and English, switchable in-app
- ✅ Light, dark and system appearance modes
- ✅ Animated splash intro on launch
- ✅ In-app rules reference

## 🛠️ Tech Stack

| Category    | Technology            |
|-------------|------------------------|
| Language    | Swift                  |
| UI          | SwiftUI                |
| Physics/2D  | SpriteKit              |
| Online multiplayer | GameKit (`GKTurnBasedMatch`) |
| Project     | Xcode (generated via [XcodeGen](https://github.com/yonaskolb/XcodeGen)) |

## 🚀 Quick Start

### Prerequisites
- macOS with Xcode 16 or later
- iOS 16+ simulator or device

### Installation

```bash
git clone https://github.com/VidiPT89/iBottleCapSoccer.git
cd iBottleCapSoccer
open iBottleCapSoccer.xcodeproj
```

Then build and run (`Cmd+R`) on a simulator or device.

> The project is defined in `project.yml`. If you change it, regenerate the `.xcodeproj` with [XcodeGen](https://github.com/yonaskolb/XcodeGen): `xcodegen generate`.

> **Online multiplayer requires the Game Center capability to be enabled for the App ID** in the Apple Developer portal (and Game Center configured in App Store Connect), plus signing in with sandbox tester accounts on two devices to actually test a match — this repo ships the client-side integration (`GameCenterManager`, entitlements, turn sync) but that portal-side setup has to be done by whoever holds the Apple Developer account.

## 📖 Usage

1. Watch the intro splash or tap **Skip** to jump straight into the menu.
2. Tap **Play** and choose a mode: **1 vs 1** (pass the device between two players), **1 vs Bot** (pick Easy/Medium/Hard), or **Online** (Game Center, turn-based) — optionally set a goal limit for Local/Bot before starting.
3. Drag a cap from your own team and release to flick it toward the ball; pinch to zoom in on the pitch.
4. Reach the opponent's half to be able to shoot on goal. Charging an opponent's cap before touching the ball is a foul.
5. Local and bot matches play 2×15 minute halves (or end early on the chosen goal limit); online matches play to first-to-5-goals with no clock.
6. From the menu, also try **Penalty Training** (free practice) or **Career** (a ladder of Bot opponents).
7. Use the gear menu to switch language (PT/EN), pick a light/dark/system appearance, customize your team's colors, check lifetime stats, toggle ambient sound, or check the rules.

## 🧪 Testing

Manual testing was performed in the iOS Simulator, covering drag-to-shoot input, goal detection, foul/free-kick detection, turn switching, timer and goal-limit flow, penalty training, career progression, appearance switching, language switching, and the bot's decision-making across all three difficulties. Game Center connectivity between two real devices has not been end-to-end tested — see the note above.

## 📄 License

Distributed under the MIT License. See [`LICENSE`](LICENSE) for details.

## 👨‍💻 Author

**David Arsénio Martins**
🌐 Website: [ividi.dev](https://ividi.dev)
🐙 GitHub: [@VidiPT89](https://github.com/VidiPT89)

## 🤝 Contributing

Issues and pull requests are welcome. For major changes, please open an issue first to discuss what you'd like to change.

---

<p align="center">Developed by <a href="https://ividi.dev">David Arsénio Martins</a><br>If you like this project, consider giving it a ⭐</p>
