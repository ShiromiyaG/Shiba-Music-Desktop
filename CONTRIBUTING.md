# Contributing to Shiba Music

First off, thank you for considering contributing to Shiba Music! 🎉

## 🚧 Project Status

This project is currently in **active development**. We welcome contributions, but please note that the codebase may change rapidly.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Pull Request Process](#pull-request-process)
- [Coding Guidelines](#coding-guidelines)
- [Commit Messages](#commit-messages)

## 📜 Code of Conduct

This project follows a simple code of conduct:

- Be respectful and inclusive
- Be patient with new contributors
- Focus on constructive feedback
- Accept that people have different opinions

## 🤝 How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues. When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce**
- **Expected behavior**
- **Actual behavior**
- **Screenshots** (if applicable)
- **Environment details** (OS, Qt version, etc.)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Clear title and description**
- **Why this enhancement would be useful**
- **Possible implementation approach**

### Code Contributions

1. Check existing issues or create a new one
2. Fork the repository
3. Create a feature branch
4. Make your changes
5. Test thoroughly
6. Submit a pull request

## 🛠️ Development Setup

### Prerequisites

- Qt 6.9.3+ with MinGW
- CMake 3.21+
- Ninja build system
- libmpv

### Setting Up

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/ShibaMusicCPP.git
cd ShibaMusicCPP

# Add upstream remote
git remote add upstream https://github.com/ORIGINAL_OWNER/ShibaMusicCPP.git

# Setup libmpv
# See LIBMPV_SETUP.md for details

# Build
mkdir build && cd build
cmake -G Ninja -DCMAKE_BUILD_TYPE=Debug ..
cmake --build .
```

### Running Tests

```bash
# From build directory
ctest
```

## 🔄 Pull Request Process

1. **Update your fork**
   ```bash
   git fetch upstream
   git checkout main
   git merge upstream/main
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Write clear, concise code
   - Follow existing code style
   - Add comments for complex logic
   - Update documentation if needed

4. **Test your changes**
   - Build successfully
   - Test affected features
   - Check for memory leaks

5. **Commit your changes**
   ```bash
   git add .
   git commit -m "Add feature: your feature description"
   ```

6. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Create Pull Request**
   - Use a clear title
   - Describe what changes you made
   - Reference related issues
   - Add screenshots if UI changed

## 📝 Coding Guidelines

### C++ Code

- **Style**: Follow existing code style
- **Naming**:
  - Classes: `PascalCase`
  - Functions: `camelCase`
  - Variables: `camelCase`
  - Constants: `UPPER_CASE`
  - Private members: `m_variableName`

- **Comments**:
  ```cpp
  // Use single-line comments for brief explanations
  
  /**
   * Use multi-line comments for detailed explanations
   * of classes, functions, or complex logic
   */
  ```

- **Headers**:
  ```cpp
  #pragma once  // Use pragma once instead of include guards
  ```

### QML Code

- **Naming**:
  - Files: `PascalCase.qml`
  - IDs: `camelCase`
  - Properties: `camelCase`

- **Structure**:
  ```qml
  Item {
      id: root
      
      // Properties
      property string title
      
      // Signals
      signal clicked()
      
      // Child items
      Rectangle {
          // ...
      }
      
      // Functions
      function doSomething() {
          // ...
      }
  }
  ```

### Documentation

- Update README.md if adding features
- Update relevant .md files in `doc/` folder
- Add inline comments for complex logic
- Use clear, descriptive names

## 📝 Commit Messages

Follow these guidelines for commit messages:

### Format

```
<type>: <subject>

<body (optional)>

<footer (optional)>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Examples

```
feat: Add playlist management

Implements basic playlist creation, editing, and deletion.
Closes #123

---

fix: Resolve playback stutter issue

Fixed audio buffer size calculation that was causing stuttering
on some systems.

---

docs: Update build instructions

Added section about libmpv setup for Windows users.
```

## 🧪 Testing

- Test your changes locally before submitting
- Ensure existing functionality still works
- Test on clean environment if possible
- Document any known issues

## 📚 Additional Resources

- [Qt Documentation](https://doc.qt.io/)
- [CMake Documentation](https://cmake.org/documentation/)
- [libmpv Documentation](https://mpv.io/manual/master/)

## ❓ Questions?

Feel free to:
- Open an issue for questions
- Join discussions in existing issues
- Reach out to maintainers

## 🎉 Recognition

All contributors will be recognized in the project. Thank you for your contributions!

---

**Happy coding!** 🚀
