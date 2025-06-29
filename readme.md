# Windy - macOS Window Manager

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/macOS-10.15+-blue.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.0+-orange.svg)](https://swift.org/)

A powerful and intuitive window management utility for macOS that helps you organize and control your windows with keyboard shortcuts and mouse gestures.

## ✨ Features

### 🎯 **Grid-Based Window Management**
- **Customizable Grid Layouts**: Set up 1x1 to 6x6 grid layouts per screen
- **Keyboard Shortcuts**: Move and resize windows with simple key combinations
- **Visual Grid Preview**: See your grid layout with customizable accent colors
- **Multi-Monitor Support**: Independent grid settings for each display

### 🖱️ **Mouse-Based Window Snapping**
- **Drag to Snap**: Drag windows to screen edges for instant snapping
- **Visual Feedback**: See snap preview while dragging
- **ESC to Cancel**: Hold ESC while dragging to cancel snapping
- **2x2 Grid Snapping**: Quick snap to quarters of the screen

### ⌨️ **Keyboard Shortcuts**
- **Window Movement**: `⌘⌥⌃ + Arrow Keys` to move windows within screen
- **Cross-Screen Movement**: `⌘⌥⌃⇧ + Arrow Keys` to move windows between screens
- **Customizable**: All shortcuts can be customized in the app preferences

### 🎨 **Visual Customization**
- **Accent Colors**: Customize the visual feedback color
- **Grid Preview**: Toggle grid overlay to see your layout
- **Status Bar Icon**: Quick access to settings from the menu bar

## 🚀 Installation

### Prerequisites
- macOS 10.15 (Catalina) or later
- Xcode 12.0 or later (for building from source)
- Accessibility permissions (required for window management)

### Option 1: Build from Source (Recommended)

1. **Clone the repository**
   ```bash
   git clone https://github.com/lantos1618/windy_app.git
   cd windy_app
   ```

2. **Open in Xcode**
   ```bash
   open windy.xcodeproj
   ```

3. **Build and Run**
   - Select your target device (Mac)
   - Press `⌘R` to build and run
   - The app will request accessibility permissions on first launch

### Option 2: Download Release (Coming Soon)
- Download the latest release from the [Releases page](https://github.com/lantos1618/windy_app/releases)
- Drag Windy to your Applications folder
- Launch and grant accessibility permissions

## 🔧 Setup & Configuration

### First Launch
1. **Launch Windy** from Applications or Xcode
2. **Grant Accessibility Permissions**:
   - Click "Open Accessibility Permissions" in the setup dialog
   - In System Preferences → Security & Privacy → Privacy → Accessibility
   - Add Windy and check the box to enable it
3. **Restart Windy** after granting permissions

### Basic Configuration
1. **Open Settings**: Click the Windy icon in the menu bar
2. **Configure Grid Layouts**:
   - Select a screen from the dropdown
   - Use +/- buttons to set columns and rows (1-6 each)
   - Click the eye icon to preview your grid layout
3. **Customize Appearance**:
   - Choose an accent color for visual feedback
   - Toggle "Launch at Login" if desired

## 📖 Usage Guide

### Window Movement
- **Move Left/Right**: `⌘⌥⌃ + ←/→`
- **Move Up/Down**: `⌘⌥⌃ + ↑/↓`
- **Move Between Screens**: `⌘⌥⌃⇧ + Arrow Keys`

### Window Resizing
- **Resize Left/Right**: `⌘⌥⌃ + ←/→` (when window is at screen edge)
- **Resize Up/Down**: `⌘⌥⌃ + ↑/↓` (when window is at screen edge)

### Mouse Snapping
1. **Start Dragging** any window
2. **Drag to Screen Edge** (within 100px of edge)
3. **Release** to snap the window to that position
4. **Hold ESC** while dragging to cancel

### Grid Preview
- **Toggle Preview**: Click the eye icon in settings
- **Customize Color**: Use the color picker in settings
- **Hide Preview**: Click the eye icon again or close the settings

## 🛠️ Troubleshooting

### Common Issues

**"Windy requires accessibility permissions"**
- Go to System Preferences → Security & Privacy → Privacy → Accessibility
- Add Windy and check the box
- Restart Windy

**Keyboard shortcuts not working**
- Check that accessibility permissions are granted
- Verify shortcuts aren't conflicting with other apps
- Try resetting keyboard shortcuts in settings

**Windows not moving correctly**
- Ensure the target application allows window manipulation
- Some system apps (Finder, System Preferences) may be restricted
- Try restarting Windy

**Grid preview not showing**
- Check that "Show Grid Preview" is enabled in settings
- Verify the accent color isn't set to transparent
- Try toggling the preview off and on

### Performance Issues
- **High CPU Usage**: Reduce grid complexity (fewer columns/rows)
- **Slow Response**: Close unnecessary applications
- **Memory Usage**: Restart Windy if it becomes unresponsive

## 🏗️ Development

### Project Structure
```
windy_app/
├── windy/                    # Main application code
│   ├── windyApp.swift       # App entry point
│   ├── windyManager.swift   # Core window management
│   ├── gridManager.swift    # Grid-based window control
│   ├── snapWindow.swift     # Mouse-based snapping
│   ├── windyWindow.swift    # Window abstraction layer
│   ├── utils.swift          # Utility functions
│   └── MenuPopover.swift    # Settings UI
├── windyTests/              # Unit tests
├── windyUITests/            # UI tests
└── todos/                   # Development todos
```

### Building for Development
1. **Clone and open** the project in Xcode
2. **Select target**: Choose "windy" scheme
3. **Build**: `⌘B` to build, `⌘R` to run
4. **Test**: `⌘U` to run tests

### Key Components
- **GridManager**: Handles grid-based window movement and resizing
- **SnapWindowManager**: Manages mouse-based window snapping
- **WindyWindow**: Wrapper for Accessibility framework window operations
- **WindyData**: Observable data model for settings and state

### Architecture Notes
- Uses **Accessibility framework** for window manipulation
- **Combine** for reactive data binding
- **SwiftUI** for modern UI components
- **KeyboardShortcuts** for global hotkey management

## 🤝 Contributing

We welcome contributions! Here's how to get started:

### Development Setup
1. **Fork** the repository
2. **Clone** your fork locally
3. **Create** a feature branch: `git checkout -b feature/amazing-feature`
4. **Make changes** and test thoroughly
5. **Commit** with clear messages: `git commit -m 'Add amazing feature'`
6. **Push** to your branch: `git push origin feature/amazing-feature`
7. **Open** a Pull Request

### Code Style
- Follow Swift style guidelines
- Add comments for complex logic
- Include tests for new features
- Update documentation as needed

### Areas for Contribution
- **Bug fixes** and performance improvements
- **New features** and enhancements
- **Documentation** improvements
- **Testing** coverage
- **UI/UX** improvements

### Reporting Issues
- Use the [Issues page](https://github.com/lantos1618/windy_app/issues)
- Include macOS version and Windy version
- Describe steps to reproduce
- Attach screenshots if relevant

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](licence.txt) file for details.

## 🙏 Acknowledgments

- **Accessibility Framework**: For window manipulation capabilities
- **KeyboardShortcuts**: For global hotkey management
- **LaunchAtLogin**: For automatic startup functionality
- **macOS Community**: For inspiration and feedback

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/lantos1618/windy_app/issues)
- **Discussions**: [GitHub Discussions](https://github.com/lantos1618/windy_app/discussions)
- **Email**: [Contact via GitHub](https://github.com/lantos1618)

---

**Made with ❤️ for the macOS community**
