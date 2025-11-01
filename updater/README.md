# Shiba Music Updater

Um executável standalone simples e leve para atualizar o Shiba Music.

## Como funciona

1. **Recebe 3 argumentos:**
   - Caminho do ZIP com a atualização
   - Diretório da aplicação
   - Nome do executável (ex: shibamusic.exe)

2. **Processo:**
   - Aguarda 2 segundos para a aplicação principal fechar
   - Cria um script PowerShell temporário
   - Extrai o ZIP em um diretório temporário
   - Copia os arquivos para o diretório da aplicação
   - Limpa os arquivos temporários
   - Reinicia a aplicação

## Compilação

```bash
cd updater
g++ -std=c++11 main.cpp -o updater.exe -mwindows -lshell32 -static
```

## Uso

```bash
updater.exe "C:\path\to\update.zip" "C:\path\to\app" "shibamusic.exe"
```

## Tamanho

- Executável: ~52 KB
- Código: 67 linhas
- Dependências: Apenas Windows API (nenhuma biblioteca Qt)
