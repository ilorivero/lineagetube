# Contexto para agentes de IA

LineageTube é um app Flutter que controla o player do YouTube Music carregado
em uma WebView. Consulte o [README](README.md) para descrição funcional,
comandos, requisitos, builds, testes e limitações de plataforma.

## Arquitetura

- `lib/main.dart` contém a tela, WebView, ciclo de vida e integração com
  `speech_to_text`.
- `lib/playback_command.dart` converte frases em comandos e gera o JavaScript
  que controla os elementos do player do YouTube Music.
- `test/` contém testes unitários de comandos e teste de interface.
- `android/`, `ios/` e `macos/` contêm as permissões e configurações nativas.

## Regras importantes

- Preserve a identidade de pacote existente em Android/iOS/macOS/Linux, salvo
  pedido explícito para migrá-la; trocar esses IDs pode criar outro app para o
  sistema ou afetar atualizações instaladas.
- O microfone requer consentimento do sistema. Nunca contorne permissões nem
  prometa escuta em segundo plano: o reconhecimento atual funciona em primeiro
  plano e depende dos serviços de voz da plataforma.
- A WebView não pode ser substituída pelo Chrome instalado. Login Google pode
  ser bloqueado em navegador incorporado; não prometa compartilhar cookies ou
  sessão com um navegador externo.
- Os seletores JavaScript dependem do DOM do YouTube Music. Preserve falhas
  explícitas e teste mudanças de reconhecimento de comandos com
  `flutter test test/playback_command_test.dart`.
- Firebase MCP é ferramenta de desenvolvimento configurada em
  `.vscode/mcp.json`; não é serviço de autenticação ou dependência de execução
  do app.

## Validação

Depois de mudanças Dart, execute `flutter analyze` e os testes Flutter
relevantes. Para alterações de plataforma, compile também o alvo afetado quando
o SDK correspondente estiver disponível. Atualize o README quando mudar
comportamento, permissões, plataformas ou comandos de build.
