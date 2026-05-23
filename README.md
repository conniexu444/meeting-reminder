# ✈️ MeetingReminder

A macOS app that flies a little pink airplane across your screen five minutes
before each calendar meeting, trailing a banner that says
**"Meeting with X in Y min"**.

Reads from your Mac's Calendar.app (which can include iCloud, Google,
Exchange — anything you've connected). Native SwiftUI · lives in the Dock and
menu bar · works over fullscreen apps.

---

## Requirements

- **macOS 14** (Sonoma) or later
- **Xcode 16** or later
- A configured Calendar.app

No Apple Developer account required — the project uses ad-hoc signing
(`Sign to Run Locally`).

---

## Setup

```bash
git clone https://github.com/conniexu444/meeting-reminder.git
cd meeting-reminder
open MeetingReminder.xcodeproj
```

In Xcode, press **⌘R**. The ✈️ appears in your menu bar.

## Usage

1. Click the ✈️ in the menu bar
2. Click **Grant Calendar access** → click **Allow** on the macOS prompt
3. That's it — the app polls your calendar once a minute and shows the
   airplane ~5 minutes before each upcoming meeting

The menu also has a **Test airplane** button that triggers the animation on
demand, useful for tweaking the visuals.

---

## Adding your Google Calendar

MeetingReminder reads from Apple's Calendar.app via `EventKit`, which means any
calendar you've connected there — including Google — shows up automatically.
You don't need a separate Google integration. Just connect Google to Calendar.app:

1. Open **System Settings → Internet Accounts** (older macOS: **System
   Preferences → Internet Accounts**)
2. Click **Add Account → Google**
3. Sign in with your Google account and allow access
4. Make sure **Calendars** is toggled on for that account
5. Open **Calendar.app** and confirm your Google events appear
6. Back in MeetingReminder, click **Test airplane** to confirm it's reading
   from your calendars — or wait for the next real meeting

That's it. No API keys, no OAuth client setup, no developer console.

If your Google events aren't showing up in Calendar.app yet, give it a minute
to sync, then quit and reopen MeetingReminder so it re-reads the calendar list.

---

## Customization

All the visual knobs live in `MeetingReminder/AirplaneView.swift`:

| What | Where |
|---|---|
| Flight duration (slower/faster) | `flightDuration` |
| Plane size | `Image("airplane")` → `frame(width:height:)` |
| Banner padding | `padding(.horizontal:)` + `padding(.vertical:)` |
| Banner-plane overlap | `HStack(spacing:)` |
| Font / text size / color | `font(.custom(...))`, `foregroundStyle(...)` |
| Vertical screen position | `AirplaneOverlayWindow.swift` → `yPos` |

How many minutes before a meeting to alert is in `CalendarPoller.swift`:

```swift
static let alertMinutesBefore = 5
```

Swap the airplane or banner artwork by replacing the PNGs in
`MeetingReminder/Assets.xcassets/airplane.imageset/` and `banner.imageset/`.

---

## How it works

- **Menu bar + Dock app** — `MenuBarExtra` for the menu, regular Dock icon
- **Calendar access** — uses Apple's `EventKit` framework. One macOS privacy
  prompt the first time you grant access. Reads from every calendar configured
  in Calendar.app, including any synced Google/Exchange accounts.
- **Polling** — every 60 seconds, fetches the next hour of events
- **The airplane** — a borderless, transparent `NSPanel` at screen-saver
  window level so it floats above every other window, including fullscreen apps.
  Inside is a SwiftUI view that animates `xOffset` from off-left to off-right.

---

## License

MIT — do what you want.
