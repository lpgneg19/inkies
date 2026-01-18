# Changelog

All notable changes to this project will be documented in this file.

## 0.5.0 (2026-01-18)

### 🚀 Performance & Infrastructure
- **Swift 6.2 Update**: Upgraded the project to Swift 6.2 to leverage the latest language features and performance improvements.
- **Concurrency Safety**: Refactored `InkCompiler` into an `actor` to ensure strict concurrency safety in line with Swift 6 standards.
- **Dependency Optimization**: Evaluated JSON parsing libraries and optimized for performance by maintaining lightweight native string handling.

### 🆕 New Features
- **What's New Gallery**: Integrated `WhatsNewKit` to provide a visually rich overview of new features when users open the app after an update.

## 0.4.0

### 🎨 Simplified Theme System
- **Cleaner Menu**: The theme selection has been moved up one level for faster access. "Theme" is now a direct picker in the menu bar.
- **Focused Options**: We've removed the "Follow System" option to provide a more predictable manual control over the app's appearance. Choose between **Light Mode** and **Dark Mode**.

### 🛠 Stability and Fixes
- **Build Success**: Resolved critical compilation errors that were affecting the project build pipeline.
- **Improved Reliability**: Fixed issues with HTML generation during web export to ensure consistent output across different themes.

## 0.3.0

### 🎨 Theme Customization
- **Theme Switching**: Introduced the choice between Follow System, Light Mode, and Dark Mode.
- **Dynamic Preview**: The game preview (WebView) adapts its styling to match the selected theme.

### 🚀 CI/CD Automation
- **Automated Releases**: Basic GitHub Actions setup for Universal App builds and DMG packaging.
