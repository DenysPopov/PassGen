# PassGen

A lightweight macOS menu bar app for generating secure passwords.

## Features

- **Cryptographically secure** — uses `SecRandomCopyBytes` with modulo-bias rejection
- **Customizable character sets** — toggle uppercase, lowercase, numbers, and symbols
- **Adjustable length** — 8 to 128 characters
- **Password strength indicator** — entropy-based (bits) with color coding
- **One-click copy** — click the password field or the Copy button
- **Copy history** — stores the last 10 copied passwords
- **Advanced settings** — edit exactly which characters are included in each category
- **Clipboard auto-clear** — clears the clipboard 45 seconds after copying
- **Launch at login** — optional, configurable in settings
- **Global hotkey** — press `⇧⌘7` anywhere to generate & copy without opening the app
- **Right-click menu** — generate and copy a new password without opening the popover
- **Keyboard shortcuts** — `⌘G` generate, `⌘C` copy, `⌘,` settings, `Esc` close

## Requirements

- macOS 13 Ventura or later
- Xcode 15 or later (to build from source)

## Installation

### Build from source

1. Clone the repository
   ```bash
   git clone https://github.com/denyspopov/PassGen.git
   ```
2. Open `PassGen.xcodeproj` in Xcode
3. Select your Team in **Signing & Capabilities**
4. Build and run (`⌘R`)
5. Drag `PassGen.app` from the Products folder to `/Applications`

## Usage

Click the **key icon** in the menu bar to open the password generator.

| Action | How |
|--------|-----|
| Generate new password | Click **Generate** or press `⌘G` |
| Copy password | Click the password field, the **Copy** button, or press `⌘C` |
| Change length | Drag the **Length** slider |
| Toggle character types | Check/uncheck **Uppercase**, **Lowercase**, **Numbers**, **Symbols** |
| Customize character sets | Click the gear icon → Advanced Settings |
| View copy history | Click the clock icon |
| Generate & copy silently | Press `⇧⌘7` from anywhere, or right-click the menu bar icon |
| Close popover | Click outside or press `Esc` |

## Permissions

The global hotkey (`⇧⌘7`) requires **Accessibility** permission. PassGen will prompt you on first launch — grant access in **System Settings → Privacy & Security → Accessibility**.

## License

MIT License — see [LICENSE](LICENSE) for details.
