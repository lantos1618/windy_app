# Contributing to Windy

Thank you for your interest in contributing to Windy! This document provides guidelines and information for contributors.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Pull Request Process](#pull-request-process)
- [Issue Reporting](#issue-reporting)
- [Architecture Overview](#architecture-overview)

## Code of Conduct

This project is committed to providing a welcoming and inclusive environment for all contributors. Please be respectful and constructive in all interactions.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally
3. **Create a feature branch** for your changes
4. **Make your changes** following the coding standards
5. **Test your changes** thoroughly
6. **Submit a pull request**

## Development Setup

### Prerequisites

- macOS 13.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

### Setup Steps

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/windy.git
   cd windy
   ```

2. Open the project in Xcode:
   ```bash
   open windy.xcodeproj
   ```

3. Build the project to ensure everything works:
   ```bash
   xcodebuild -project windy.xcodeproj -scheme windy -destination 'platform=macOS' build
   ```

4. Run tests to verify the test suite:
   ```bash
   xcodebuild -project windy.xcodeproj -scheme windy -destination 'platform=macOS' test
   ```

## Coding Standards

### Swift Style Guide

- Follow the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- Use 4 spaces for indentation (no tabs)
- Maximum line length: 120 characters
- Use meaningful variable and function names
- Add documentation comments for public APIs

### Code Organization

- Keep files focused on a single responsibility
- Use extensions to organize code within files
- Group related functionality into separate files
- Follow the existing file structure

### Naming Conventions

- **Classes and Structs**: PascalCase (e.g., `WindyManager`)
- **Functions and Variables**: camelCase (e.g., `snapWindow`)
- **Constants**: camelCase (e.g., `maxCheck`)
- **Enums**: PascalCase (e.g., `SnapDirection`)

### Documentation

- Add documentation comments for all public APIs
- Include parameter descriptions and return value explanations
- Use `///` for single-line documentation
- Use `/**` and `*/` for multi-line documentation

Example:
```swift
/// Snaps a window to the specified direction
/// - Parameters:
///   - window: The window to snap
///   - direction: The direction to snap to
/// - Returns: True if the snap was successful
func snapWindow(_ window: WindyWindow, to direction: SnapDirection) -> Bool
```

## Testing Guidelines

### Unit Tests

- Write unit tests for all new functionality
- Aim for at least 80% code coverage
- Test both success and failure scenarios
- Use descriptive test names that explain the expected behavior

### UI Tests

- Add UI tests for user-facing features
- Test critical user workflows
- Ensure accessibility compliance

### Running Tests

```bash
# Run all tests
xcodebuild -project windy.xcodeproj -scheme windy -destination 'platform=macOS' test

# Run specific test target
xcodebuild -project windy.xcodeproj -scheme windy -destination 'platform=macOS' test -only-testing:windyTests
```

## Pull Request Process

### Before Submitting

1. **Ensure tests pass** locally
2. **Update documentation** if needed
3. **Check for code style** compliance
4. **Test on different screen configurations** if UI-related

### Pull Request Template

Use this template when creating a pull request:

```markdown
## Description
Brief description of the changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] UI tests added/updated
- [ ] Manual testing completed

## Screenshots (if applicable)
Add screenshots for UI changes

## Checklist
- [ ] Code follows the style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] Tests added/updated
```

### Review Process

1. **Automated checks** must pass
2. **Code review** by maintainers
3. **Testing verification** on different configurations
4. **Documentation review** if applicable

## Issue Reporting

### Bug Reports

When reporting bugs, please include:

- **macOS version**
- **Xcode version** (if development-related)
- **Steps to reproduce**
- **Expected behavior**
- **Actual behavior**
- **Screenshots** (if applicable)
- **Console logs** (if available)

### Feature Requests

For feature requests, please include:

- **Use case description**
- **Proposed solution**
- **Alternative approaches** considered
- **Impact on existing functionality**

## Architecture Overview

### Core Components

- **WindyManager**: Main application coordinator
- **GridManager**: Handles grid-based window positioning
- **SnapWindowManager**: Manages window snapping behavior
- **WindyWindow**: Window abstraction and manipulation
- **WindyData**: Application state management

### Key Design Principles

1. **Separation of Concerns**: Each component has a specific responsibility
2. **Dependency Injection**: Components receive dependencies through initialization
3. **Protocol-Oriented Design**: Use protocols for flexibility and testability
4. **Error Handling**: Graceful handling of edge cases and failures

### Known Technical Debt

- **Magic Numbers**: Some coordinate calculations use hardcoded values
- **Multi-Monitor Handling**: Coordinate system conversions need refinement
- **Screen Detection**: Reliance on `NSScreen.main` in some cases

### Areas for Improvement

1. **Coordinate System Utilities**: Formalize coordinate conversion logic
2. **Test Coverage**: Expand automated testing, especially for window manipulation
3. **Error Recovery**: Improve error handling and recovery mechanisms
4. **Performance**: Optimize window manipulation operations

## Getting Help

- **GitHub Issues**: For bugs and feature requests
- **Discussions**: For questions and general discussion
- **Documentation**: Check the README and inline code documentation

## License

By contributing to Windy, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to Windy! Your contributions help make this project better for everyone. 