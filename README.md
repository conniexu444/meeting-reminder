# ✈️ MeetingBuddy

A macOS menu bar app that flies a little pink airplane across your screen
five minutes before each Google Calendar meeting, trailing a banner that says
**"Meeting with X in Y min"**.

Native SwiftUI · lives in the menu bar · no Dock icon · works over fullscreen apps.

---

## Requirements

- **macOS 14** (Sonoma) or later
- **Xcode 16** or later
- A **Google account** with calendar events

No Apple Developer account, team ID, or signing certificate required —
the project uses ad-hoc signing (`Sign to Run Locally`).

---

## Setup

### 1. Clone the repo

```bash
git clone https://github.com/YOUR-USERNAME/MeetingBuddy.git
cd MeetingBuddy
```

### 2. Get your Google OAuth credentials

Follow [`GOOGLE_SETUP.md`](GOOGLE_SETUP.md) (≈5 minutes). At the end you'll have
a **Client ID** and **Client Secret** for a Desktop-app OAuth client.

### 3. Create your local config

```bash
cp Config.example.swift MeetingBuddy/Config.swift
```

Open `MeetingBuddy/Config.swift` and paste your Client ID + Secret into the two
placeholder strings. `Config.swift` is in `.gitignore`, so your credentials
stay on your machine.

### 4. Open and run

```bash
open MeetingBuddy.xcodeproj
```

Press **⌘R**. The app launches into the menu bar (no Dock icon).
Look for the ✈️ near the top-right of your screen.

---

## Usage

1. Click the ✈️ in your menu bar
2. **Connect Google Calendar** — a browser tab opens for Google sign-in.
   After you grant access, the tab will say "✅ MeetingBuddy connected!"
3. That's it — the app polls your calendar once a minute and shows the
   airplane ~5 minutes before each upcoming meeting.

The menu also has a **Test airplane** button that triggers the animation on
demand, useful for tweaking the visuals.

---

## Customization

All the visual knobs live in `MeetingBuddy/AirplaneView.swift`:

| What | Where |
|---|---|
| Flight duration (slower/faster) | `flightDuration` |
| Plane size | `Image("airplane")` → `frame(width:height:)` |
| Banner padding (text-to-edge spacing) | `padding(.horizontal:)` + `padding(.vertical:)` |
| Banner-plane overlap | `HStack(spacing:)` |
| Font / text size / color | `font(.custom(...))`, `foregroundStyle(...)` |
| Vertical screen position | `AirplaneOverlayWindow.swift` → `yPos` |

How many minutes before a meeting to alert is in `Config.swift`:

```swift
static let alertMinutesBefore = 5
```

Swap the airplane or banner artwork by replacing the PNGs in
`MeetingBuddy/Assets.xcassets/airplane.imageset/` and `banner.imageset/`.

---

## How it works

- **Menu bar app** — `MenuBarExtra` lives in the menu bar with `LSUIElement = YES`
  so no Dock icon
- **OAuth 2.0** — runs a one-shot localhost server (port 8080) to catch
  Google's redirect, then exchanges the code for access + refresh tokens
- **Calendar polling** — every 60 seconds, fetches the next hour of events
  from the Google Calendar v3 REST API
- **The airplane** — a borderless, transparent `NSPanel` at screen-saver
  window level so it floats above every other window, including fullscreen apps.
  Inside is a SwiftUI view that animates `xOffset` from off-left to off-right.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| Browser opens but Safari says "can't connect to server" | App Sandbox is enabled. Confirm `ENABLE_APP_SANDBOX = NO` in Build Settings |
| App appears in Dock | `LSUIElement` build setting isn't `YES` |
| Build errors about `ObservableObject` or `@Published` | Ensure `import Combine` is at the top of `AppController.swift` |
| Strict-concurrency warnings | Project setting **Default Actor Isolation** → `nonisolated` |

---

## License

MIT — do what you want.
