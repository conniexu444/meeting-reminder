# ✈️ MeetingReminder

A macOS app that flies a hand-drawn pink airplane across your screen five
minutes before each calendar meeting, trailing a pink banner with the meeting
title — e.g. **"Standup in 5 min"**.

Reads from your Mac's Calendar.app (so iCloud, Google, Exchange — anything
you've connected — all work). Native SwiftUI · lives in the Dock **and** menu
bar · floats above fullscreen apps.

---

## Requirements

- **macOS 26 (Tahoe)** or later
- **Xcode 26** or later
- Calendar.app with at least one calendar configured

No paid Apple Developer account required — the project uses ad-hoc signing
(`Sign to Run Locally`), so anyone can clone and build with zero setup.

---

## Setup

```bash
git clone https://github.com/conniexu444/meeting-reminder.git
cd meeting-reminder
open MeetingReminder.xcodeproj
```

In Xcode, press **⌘R**. The hand-drawn airplane appears in your menu bar and
Dock.

---

## Usage

1. Click the ✈️ in the menu bar
2. Click **Grant Calendar access** → click **Allow** on the macOS privacy prompt
3. That's it — every 60 seconds the app checks your calendar and shows the
   flying airplane ~5 minutes before each upcoming meeting

The menu also has a **Test airplane** button that triggers the animation
on demand (with a fake "Test Meeting" event) — useful for tweaking the visuals.

---

## Adding your Google Calendar

MeetingReminder reads from Calendar.app via Apple's `EventKit` framework, so
any calendar you've connected there — including Google — shows up automatically.
No separate Google integration needed. To connect Google to Calendar.app:

1. Open **System Settings → Internet Accounts** (older macOS: **System
   Preferences → Internet Accounts**)
2. Click **Add Account → Google**
3. Sign in and allow access
4. Make sure **Calendars** is toggled on for that account
5. Open **Calendar.app** and confirm your Google events appear
6. Back in MeetingReminder, click **Test airplane** to confirm — or wait for
   the next real meeting

No API keys, no OAuth client setup, no developer console.

If Google events aren't appearing in Calendar.app yet, give it a minute to
sync, then quit and reopen MeetingReminder so it re-reads the calendar list.

---

## Customization

### Visuals — `MeetingReminder/AirplaneView.swift`

| What | Where |
|---|---|
| Flight duration (slower/faster) | `flightDuration` |
| Plane size | `Image("airplane")` → `frame(width:height:)` |
| Banner padding (text-to-edge) | `padding(.horizontal:)` / `padding(.vertical:)` |
| Banner-plane overlap | `HStack(spacing:)` |
| Font / text size / color | `font(.custom("Comic Sans MS", size:))`, `foregroundStyle(...)` |
| Vertical screen position | `MeetingReminder/AirplaneOverlayWindow.swift` → `yPos` |

### Alert timing — `MeetingReminder/CalendarPoller.swift`

```swift
static let alertMinutesBefore = 5   // change to alert at a different lead time
```

### Artwork

Swap the airplane, banner, app icon, or menu bar icon by replacing the PNGs in:
- `MeetingReminder/Assets.xcassets/airplane.imageset/` — flying airplane (right-facing)
- `MeetingReminder/Assets.xcassets/banner.imageset/` — pink banner background
- `MeetingReminder/Assets.xcassets/AppIcon.appiconset/` — Dock + Finder icon
- `MeetingReminder/Assets.xcassets/menubar.imageset/` — menu bar silhouette (template image, monochrome on transparent)

---

## How it works

- **Menu bar + Dock app** — `MenuBarExtra` for the menu, regular `NSApplication`
  for the Dock presence
- **Calendar access** — `EventKit` with a one-time macOS privacy prompt. Reads
  from every calendar configured in Calendar.app, including synced Google /
  iCloud / Exchange accounts
- **Polling** — every 60 seconds, fetches the next hour of events; an in-memory
  set prevents firing the same alert twice
- **The airplane** — a borderless, transparent `NSPanel` at screen-saver
  window level so it floats above every other window, including fullscreen apps.
  Inside is a SwiftUI view that animates `xOffset` from off-left to off-right,
  fading out at the end.

---

## Project structure

```
MeetingReminder/
├── MeetingReminderApp.swift     # @main + MenuBarExtra
├── AppController.swift          # Coordinator: EventKit + poller + overlay
├── MenuBarView.swift            # Status / Grant access / Test / Quit
├── CalendarSource.swift         # CalendarEvent + provider protocol
├── AppleCalendarService.swift   # EventKit implementation
├── CalendarPoller.swift         # 60s timer, fires onMeetingSoon
├── AirplaneView.swift           # SwiftUI airplane + banner animation
├── AirplaneOverlayWindow.swift  # Transparent NSPanel above everything
├── MeetingReminder.entitlements # Sandbox disabled
└── Assets.xcassets/             # Airplane, banner, app icon, menu bar icon
```

---

## License

MIT — do what you want.
