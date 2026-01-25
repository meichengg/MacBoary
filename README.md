# MacBoary

MacBoary is a lightweight, secure clipboard manager for macOS built with Swift and SwiftUI. It sits quietly in your menu bar and keeps track of your clipboard history, allowing you to easily find and paste past items.

## Features

- **Clipboard History**: Automatically saves text and images you copy.
- **Secure**: Optional encryption for your clipboard history using standard macOS Keychain and CryptoKit. Your data is safe.
- **Privacy Focused**: All data is stored locally on your machine.
- **Global Hotkey**: Summon the clipboard history window from anywhere with a customizable keyboard shortcut.
- **Customizable UI**: Choose between system, light, or dark themes, and configure where the popup appears (center of screen or cursor position).
- **Native Experience**: Built with SwiftUI for a seamless macOS look and feel.

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 14.0+ (for building from source)

## Installation

### Building from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/MarcoBaeuml/macboary.git
   ```
2. Open `macboary.xcodeproj` in Xcode.
3. Build and run the `macboary` scheme.

## Usage

1. **Launch the App**: The app runs in the menu bar. Look for the icon in your status bar.
2. **Access History**: Click the menu bar icon or use the global hotkey (default: `Cmd + Shift + V` - *check settings to configure*).
3. **Paste**: Click on an item in the history list to copy it to your clipboard, or double-click to paste directly into the active application.
4. **Settings**: Access preferences via the menu bar icon to configure:
    - Launch at login
    - History retention limits
    - Encryption settings
    - Keyboard shortcuts
    - Appearance themes

## Privacy & Security

MacBoary is designed with privacy in mind.
- **Local Storage**: No data is ever sent to the cloud. Everything stays on your Mac.
- **Encryption**: Enable encryption in settings to protect your clipboard history on disk. The encryption key is securely managed by the macOS Keychain.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

[MIT License](LICENSE)
