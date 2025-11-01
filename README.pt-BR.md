# 🚧 Shiba Music - Em Desenvolvimento Ativo 🚧

> **⚠️ TRABALHO EM ANDAMENTO:** Este projeto está atualmente em desenvolvimento ativo. Funcionalidades podem estar incompletas e mudanças podem ocorrer.

<div align="center">

![Platform](https://img.shields.io/badge/platform-Windows-blue)
![Qt](https://img.shields.io/badge/Qt-6.9.3-green)
![License](https://img.shields.io/badge/license-MIT-blue)
![Status](https://img.shields.io/badge/status-em_desenvolvimento-orange)

**Um player de música moderno e nativo para Navidrome/Subsonic construído com Qt 6 e C++**

[Funcionalidades](#-funcionalidades) • [Instalação](#-instalação) • [Compilar](#-compilar-do-código-fonte) • [Contribuir](#-contribuindo)

</div>

---

## ✨ Funcionalidades

### Implementadas
- 🎵 **Suporte nativo Navidrome/Subsonic** - Integração direta com seu servidor de música
- 🎨 **UI moderna Material Design** - Construído com Qt Quick Controls 2
- 🔊 **Reprodução sem gaps** - Powered by libmpv
- 🔍 **Busca avançada** - Encontre músicas, artistas e álbuns instantaneamente
- 📋 **Gerenciamento de fila** - Controle total sobre sua fila de reprodução
- ⭐ **Sistema de favoritos** - Marque suas músicas favoritas
- 📱 **Discord Rich Presence** - Mostre o que está ouvindo
- 🎚️ **Suporte a ReplayGain** - Níveis de volume consistentes
- 🌙 **Tema escuro** - Suave para os olhos

### Planejadas
- 🎧 Gerenciamento de playlists
- 📻 Modo rádio
- 🎼 Exibição de letras
- 🔄 Suporte multi-plataforma (Linux, macOS)
- 📱 Versão mobile
- 🎨 Customização de temas

---

## 📥 Instalação

### Usando Releases Pré-compiladas

1. Vá para [Releases](../../releases)
2. Baixe o último `ShibaMusic-Windows-x64.zip`
3. Extraia e execute `shibamusic.exe`

### Requisitos
- Windows 10/11 (x64)
- Um servidor Navidrome ou compatível com Subsonic

---

## 🛠️ Compilar do Código Fonte

### Pré-requisitos

- **Qt 6.9.3+** com MinGW
  - Módulos: Quick, Network, Core5Compat
- **CMake 3.21+**
- **Ninja** build system
- **libmpv** para reprodução de áudio

### Configurar libmpv

1. Baixe libmpv do [SourceForge](https://sourceforge.net/projects/mpv-player-windows/files/libmpv/)
2. Extraia para o diretório `libs/mpv/`:
   ```
   libs/mpv/
   ├── include/
   ├── lib/
   └── bin/
   ```

Veja `LIBMPV_SETUP.md` para instruções detalhadas.

### Passos para Compilar

```bash
# Clone o repositório
git clone https://github.com/<seu-usuario>/ShibaMusicCPP.git
cd ShibaMusicCPP

# Configure com CMake
mkdir build && cd build
cmake -G Ninja -DCMAKE_BUILD_TYPE=Release ..

# Compile
cmake --build .

# Deploy das dependências Qt
windeployqt shibamusic.exe
```

### Executar

```bash
.\shibamusic.exe
```

---

## 🚀 Releases Automáticas

Este projeto usa GitHub Actions para compilação e release automáticas.

### Para Desenvolvedores

Crie uma nova release em um comando:

```bash
.\bump-version.ps1 1.0.1
```

Isso irá:
1. ✅ Atualizar versão em `version.txt`
2. ✅ Criar um commit
3. ✅ Fazer push para o GitHub
4. ✅ **Criar tag automaticamente** `v1.0.1`
5. ✅ **Compilar automaticamente** o projeto
6. ✅ **Publicar automaticamente** release com executável

**Nenhuma tag ou build manual necessário!** 🎉

Veja [RELEASE.md](RELEASE.md) para detalhes.

---

## 📚 Documentação

- 📖 [Guia de Release](RELEASE.md) - Como criar releases
- 🎮 [Guia de Configuração do Discord](doc/DISCORD-SETUP.md) - Configure Rich Presence
- 🌍 [Guia de Internacionalização](doc/I18N-README.md) - Adicione novos idiomas
- 🔧 [Documentação dos Workflows](.github/workflows/README.md) - Setup CI/CD
- 🐛 [Troubleshooting](doc/TROUBLESHOOTING.md) - Problemas comuns

---

## 🤝 Contribuindo

Contribuições são bem-vindas! Este projeto está em desenvolvimento ativo e adoraríamos sua ajuda.

### Como Contribuir

1. Faça um fork do repositório
2. Crie uma branch de feature (`git checkout -b feature/funcionalidade-incrivel`)
3. Commit suas mudanças (`git commit -m 'Adiciona funcionalidade incrível'`)
4. Push para a branch (`git push origin feature/funcionalidade-incrivel`)
5. Abra um Pull Request

### Diretrizes de Desenvolvimento

- Siga o estilo de código existente
- Teste suas mudanças localmente
- Atualize a documentação conforme necessário
- Mantenha commits focados e descritivos

---

## 📝 Estrutura do Projeto

```
ShibaMusicCPP/
├── src/
│   ├── core/           # Funcionalidade core (API, rede)
│   ├── playback/       # Reprodução de áudio (integração mpv)
│   └── discord/        # Discord Rich Presence
├── qml/
│   ├── pages/          # Páginas da UI
│   ├── components/     # Componentes UI reutilizáveis
│   └── icons/          # Recursos de ícones
├── .github/
│   └── workflows/      # Automação CI/CD
└── libs/               # Bibliotecas de terceiros (gitignored)
```

---

## 🛣️ Roadmap

- [ ] **v1.0** - Funcionalidades core estáveis
  - [x] Reprodução básica
  - [x] Funcionalidade de busca
  - [x] Gerenciamento de fila
  - [x] Sistema de favoritos
  - [ ] Gerenciamento de playlists
  
- [ ] **v1.1** - Funcionalidades aprimoradas
  - [ ] Exibição de letras
  - [ ] Modo rádio
  - [ ] Playlists inteligentes
  
- [ ] **v2.0** - Multi-plataforma
  - [ ] Suporte Linux
  - [ ] Suporte macOS
  - [ ] Versão mobile

---

## 📄 Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

---

## 🙏 Agradecimentos

- **Qt Framework** - Toolkit de UI
- **libmpv** - Engine de reprodução de áudio
- **Navidrome** - Servidor de música
- **Material Design** - Sistema de design

---

## 📬 Contato

Dúvidas ou sugestões? Sinta-se livre para abrir uma issue!

---

<div align="center">

**Feito com ❤️ e Qt**

⭐ Dê uma estrela neste repo se você achar útil!

</div>
