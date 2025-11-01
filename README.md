# 🚧 Shiba Music - Under Active Development 🚧

> **⚠️ WORK IN PROGRESS:** This project is currently in active development. Features may be incomplete and breaking changes may occur.

> 🌍 **[Leia em Português (Read in Portuguese)](README.pt-BR.md)**

<div align="center">

![Platform](https://img.shields.io/badge/platform-Windows-blue)
![Qt](https://img.shields.io/badge/Qt-6.9.3-green)
![License](https://img.shields.io/badge/license-MIT-blue)
![Status](https://img.shields.io/badge/status-in_development-orange)

**A modern, native Navidrome/Subsonic music player built with Qt 6 and C++**

[Features](#-features) • [Installation](#-installation) • [Building](#-building-from-source) • [Contributing](#-contributing)

</div>

---

## ✨ Features

### Current
- 🎵 **Native Navidrome/Subsonic support** - Direct integration with your music server
- 🎨 **Modern Material Design UI** - Built with Qt Quick Controls 2
- 🔊 **Gapless playback** - Powered by libmpv
- 🔍 **Advanced search** - Find songs, artists, and albums instantly
- 📋 **Queue management** - Full control over your playback queue
- ⭐ **Favorites system** - Star your favorite tracks
- 📱 **Discord Rich Presence** - Show what you're listening to
- 🎚️ **ReplayGain support** - Consistent volume levels
- 🌙 **Dark theme** - Easy on the eyes

### Planned
- 🎧 Playlist management
- 🔄 Cross-platform support (Linux, macOS)
- 📱 Mobile version
- 🎨 Theme customization

---

## 📥 Installation

### Using Pre-built Releases

1. Go to [Releases](../../releases)
2. Download the latest `ShibaMusic-Windows-x64.zip`
3. Extract and run `shibamusic.exe`

### Requirements
- Windows 10/11 (x64)
- A Navidrome or Subsonic-compatible server

---

## 🛠️ Building from Source

### Prerequisites

- **Qt 6.9.3+** with MinGW
  - Modules: Quick, Network, Core5Compat
- **CMake 3.21+**
- **Ninja** build system
- **libmpv** for audio playback

### Setup libmpv

1. Download libmpv from [SourceForge](https://sourceforge.net/projects/mpv-player-windows/files/libmpv/)
2. Extract to `libs/mpv/` directory:
   ```
   libs/mpv/
   ├── include/
   ├── lib/
   └── bin/
   ```

See `LIBMPV_SETUP.md` for detailed instructions.

### Build Steps

```bash
# Clone the repository
git clone https://github.com/ShiromiyaG/Shiba-Music-Desktop.git
cd Shiba-Music-Desktop

# Configure with CMake
mkdir build && cd build
cmake -G Ninja -DCMAKE_BUILD_TYPE=Release ..

# Build
cmake --build .

# Deploy Qt dependencies
windeployqt shibamusic.exe
```

### Running

```bash
.\shibamusic.exe
```

---

## 📚 Documentation

- 📖 [Release Guide](RELEASE.md) - How to create releases
- 🔧 [Workflow Documentation](.github/workflows/README.md) - CI/CD setup
- 🐛 [Troubleshooting](.github/workflows/TROUBLESHOOTING.md) - Common issues

---

## 🤝 Contributing

Contributions are welcome! This project is in active development and we'd love your help.

### How to Contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow existing code style
- Test your changes locally
- Update documentation as needed
- Keep commits focused and descriptive

---

## 📝 Project Structure

```
ShibaMusicCPP/
├── src/
│   ├── core/           # Core functionality (API, network)
│   ├── playback/       # Audio playback (mpv integration)
│   └── discord/        # Discord Rich Presence
├── qml/
│   ├── pages/          # UI pages
│   ├── components/     # Reusable UI components
│   └── icons/          # Icon resources
├── .github/
│   └── workflows/      # CI/CD automation
└── libs/               # Third-party libraries (gitignored)
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Qt Framework** - UI toolkit
- **libmpv** - Audio playback engine
- **Navidrome** - Music server
- **Material Design** - Design system

---

## 📬 Contact

Questions or suggestions? Feel free to open an issue!

---

<div align="center">

**Made with ❤️ and Qt**

⭐ Star this repo if you find it useful!

</div>
