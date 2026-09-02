# ⚽ iBottleCapSoccer

> A native iOS bottle cap soccer game — flick, aim and score, built with SwiftUI and SpriteKit.

[Report Bug](https://github.com/VidiPT89/iBottleCapSoccer/issues) · [Request Feature](https://github.com/VidiPT89/iBottleCapSoccer/issues)

## ✨ Features

- ✅ Realistic flick-based physics (friction, collisions, bounces) powered by SpriteKit
- ✅ Turn-based two-player local matches, home vs away
- ✅ Full match flow: kickoff, goals, half-time, full-time
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

## 📖 Usage

1. Watch the intro splash or tap **Skip** to jump straight into the match.
2. Drag a cap from your own team and release to flick it toward the ball.
3. Reach the opponent's half to be able to shoot on goal.
4. First half, half-time break, second half — highest score wins.
5. Use the top bar to switch language (PT/EN), cycle the appearance (system/light/dark), check the rules, or start a new game.

## 🧪 Testing

Manual testing was performed in the iOS Simulator, covering drag-to-shoot input, goal detection, turn switching, timer flow, appearance switching and language switching.

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
