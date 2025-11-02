# Controles de Mídia - Shiba Music

## Funcionalidades Adicionadas

Os controles de mídia foram integrados ao Shiba Music, permitindo que os usuários controlem a reprodução através de atalhos de teclado convenientes.

### Atalhos de Teclado

| Atalho | Função | Descrição |
|--------|--------|-----------|
| **Space** | Play/Pause | Alterna entre reproduzir e pausar a música atual |
| **Shift+N** | Próxima | Avança para a próxima faixa da fila |
| **Shift+P** | Anterior | Volta para a faixa anterior ou reinicia a atual |
| **M** | Mute/Unmute | Silencia ou restaura o áudio |
| **↑ (Up)** | Volume + | Aumenta o volume em 5% |
| **↓ (Down)** | Volume - | Diminui o volume em 5% |

### Arquivos Criados/Modificados

#### Novos Arquivos:
1. **src/playback/MediaControls.h** - Interface da classe de controles de mídia
2. **src/playback/MediaControls.cpp** - Implementação dos controles de mídia

#### Arquivos Modificados:
1. **src/playback/PlayerController.h** - Adicionada integração com MediaControls
2. **src/playback/PlayerController.cpp** - Atualização de metadados e estado de reprodução
3. **qml/main.qml** - Adicionados atalhos de teclado globais
4. **CMakeLists.txt** - Incluídos novos arquivos no build

### Recursos Técnicos

- **Sistema de Controles**: Implementado usando Qt Shortcuts no QML
- **Feedback Visual**: Tooltips nas barras de controle mostram os atalhos disponíveis
- **Compatibilidade**: Funciona em Windows, macOS e Linux
- **Integração**: Sincronizado com o estado do player (mpv)

### Como Usar

1. **Reproduzir/Pausar**: Pressione `Space` a qualquer momento
2. **Navegar entre faixas**: Use `Shift+N` (próxima) ou `Shift+P` (anterior)
3. **Controlar volume**: 
   - Use as setas `↑`/`↓` para ajustar
   - Pressione `M` para silenciar instantaneamente
4. **Busca na faixa**: Clique na barra de progresso ou arraste

### Interface Atualizada

A barra de reprodução (NowPlayingBar) agora exibe:
- Tooltips informativos com os atalhos de teclado
- Feedback visual ao passar o mouse sobre os controles
- Indicadores de volume e progresso interativos
- Informações da faixa atual com capa do álbum

### Logs do Sistema

Os controles de mídia registram ações no console para debug:
```
[MediaControls] Controles de mídia inicializados
[MediaControls] Atalhos de teclado habilitados:
  - Space: Play/Pause
  - Shift+N: Próxima faixa
  - Shift+P: Faixa anterior
  - M: Mute/Unmute
  - Up/Down: Ajustar volume
[MediaControls] Tocando: [Nome da Música] - [Artista]
[MediaControls] Estado: ▶ Reproduzindo
```

### Windows System Media Transport Controls (SMTC)

✅ **Implementado** - Estrutura base para Windows SMTC

O projeto agora inclui a infraestrutura para Windows System Media Transport Controls:
- Classe `WindowsSMTC` criada e integrada
- Atualização de metadados (título, artista, álbum)
- Sincronização de estado de reprodução
- Preparado para controles de hardware (teclados multimídia, fones de ouvido)

**Nota sobre Compiladores:**
- ✅ MinGW: Funciona com logging e estrutura base
- 🔄 MSVC: Necessário para API WinRT completa do Windows
- A funcionalidade básica está disponível via atalhos de teclado

## Próximas Melhorias

Possíveis expansões futuras:
- [ ] Integração completa do Windows SMTC com MSVC
- [ ] Integração com MPRIS (Linux D-Bus)
- [ ] macOS Now Playing Center
- [ ] Atalhos personalizáveis pelo usuário
- [ ] Controles globais (funcionam fora da janela do app)
- [ ] Suporte a capas de álbum nos controles do sistema

## Notas de Desenvolvimento

- Compatível com Qt 6.9.3
- Usa apenas componentes do Qt Core (sem dependências extras)
- Mantém compatibilidade com a arquitetura existente
- Implementação leve e eficiente
