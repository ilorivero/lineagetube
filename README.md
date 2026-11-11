# LineageTube

LineageTube é um aplicativo Flutter que abre o YouTube Music em uma WebView e
oferece controles de reprodução por toque e por comandos de voz. O projeto foi
pensado primeiro para Android, inclusive dispositivos com LineageOS, e também
tem suporte de desenvolvimento para macOS.

O aplicativo não é um cliente oficial do YouTube Music, não hospeda músicas e
não implementa autenticação Google ou Firebase. A reprodução e a conta são
gerenciadas pelo site do YouTube Music carregado na WebView.

## O que o aplicativo faz

- Abre `https://music.youtube.com/?hl=pt-BR`.
- Inicia a solicitação de acesso ao microfone e a escuta por voz ao abrir.
- Detecta a palavra de ativação **“Friday”** (pronunciada “fraidei”) ou
  **“sexta-feira”** e interpreta comandos de reprodução em português.
- Também permite controlar reprodução por botões na interface.
- Reinicia sessões de reconhecimento de fala enquanto a escuta estiver ativa e
  o app estiver em primeiro plano.
- Mostra o estado do player, da escuta e do último comando reconhecido.

## Comandos de voz

Diga a palavra de ativação seguida de um comando, ou fale tudo de uma vez:

- **Reproduzir:** “tocar”, “toque”, “reproduzir”, “continuar”, “retomar” ou
  “play”.
- **Pausar:** “pausar”, “pausa”, “parar”, “pare” ou “stop”.
- **Avançar:** “próxima”, “próximo”, “seguinte” ou “next”.
- **Voltar:** “anterior”, “voltar música” ou “previous”.
- **Aumentar volume:** “aumentar volume”, “subir volume”, “volume mais” ou
  “mais alto”.
- **Diminuir volume:** “diminuir volume”, “abaixar volume”, “volume menos” ou
  “mais baixo”.

Exemplos: “Friday, próxima música”, “fraidei, pausar” e
“sexta-feira, aumenta o volume”.

O botão **Pausar Friday** interrompe temporariamente a escuta. **Ativar Friday**
a retoma. A escuta é pausada quando o app vai para segundo plano e reiniciada
quando ele volta ao primeiro plano. Não há escuta em segundo plano nem um
detector acústico local dedicado de palavra de ativação: o app usa o serviço de
reconhecimento de fala da plataforma, que pode depender de idioma instalado,
conectividade ou serviço de voz disponível.

## Permissões e privacidade

O sistema operacional solicita autorização de microfone e reconhecimento de
fala. LineageTube não pode conceder essa autorização por conta própria,
contornar uma recusa ou garantir que ela permaneça concedida se o usuário ou o
sistema a revogar.

- **Android:** o app declara acesso à Internet e gravação de áudio; o usuário
  deve permitir o microfone quando solicitado.
- **macOS e iOS:** o app declara os motivos de uso do microfone e do
  reconhecimento de fala nos arquivos de configuração de cada plataforma.
- **macOS:** se o acesso for negado, revise **Ajustes do Sistema > Privacidade e
  Segurança > Microfone** e **Reconhecimento de fala**.

O reconhecimento é feito pelo serviço nativo da plataforma. O comportamento de
rede e o processamento de voz dependem desse serviço e das configurações do
dispositivo.

## YouTube Music e login Google

O player usa `webview_flutter`. No macOS, o motor é o WKWebView da Apple; no
Android e iOS são usados os componentes WebView/WKWebView da plataforma. O
Google pode restringir o login em navegadores incorporados e mostrar uma
mensagem solicitando o Chrome. Instalar o Chrome não o transforma no motor de
WebView do app nem transfere a sessão do Chrome para LineageTube.

Se o login for bloqueado, uma alternativa é usar o YouTube Music diretamente
no navegador oficial do dispositivo. Nesse caso, os comandos deste app não
controlam a sessão externa. Alterações na página do YouTube Music também podem
exigir atualização dos seletores JavaScript usados pelos controles.

O Firebase MCP configurado no VS Code é uma ferramenta de desenvolvimento. Ele
não é uma dependência de execução do app, não implementa login Google e não
autentica o YouTube Music.

## Plataformas

| Plataforma | Situação |
|---|---|
| Android | Plataforma principal. Requer WebView e serviço de reconhecimento de fala compatíveis. |
| macOS | Suporte de desenvolvimento com WKWebView e reconhecimento de fala do sistema. |
| iOS | As dependências nativas oferecem suporte; build e execução dependem de Xcode, dispositivo e assinatura. |
| Web, Windows e Linux | Há diretórios de runner gerados pelo Flutter, mas a combinação de WebView e reconhecimento de fala não é suportada/testada como produto nessas plataformas. |

O Echo Show normalmente executa Fire OS, não LineageOS. A instalação de um APK
depende de o dispositivo aceitar apps Android e ter versões compatíveis da
WebView e do serviço de voz.

## Requisitos de desenvolvimento

- Flutter estável e Dart compatíveis com o intervalo declarado em
  [`pubspec.yaml`](pubspec.yaml).
- Para Android: Android SDK e ferramentas de build configurados.
- Para macOS/iOS: macOS e Xcode; a compilação iOS para distribuição também
  requer configuração de assinatura.
- Node.js e npm são necessários somente para o servidor Firebase MCP do VS Code.

Confira o ambiente com:

```sh
flutter doctor -v
```

## Executar e compilar

Instale as dependências:

```sh
flutter pub get
```

Executar em um dispositivo Android conectado:

```sh
flutter devices
flutter run -d DEVICE_ID
```

Compilar APK Android:

```sh
flutter build apk --release
```

O APK fica em `build/app/outputs/flutter-apk/app-release.apk`. Para instalar
em um dispositivo conectado com depuração USB habilitada:

```sh
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Executar ou compilar para macOS:

```sh
flutter run -d macos
flutter build macos --release
```

O app compilado fica em
`build/macos/Build/Products/Release/LineageTube.app`. Para testar o build
Debug atual, use `build/macos/Build/Products/Debug/LineageTube.app`, não uma
cópia antiga instalada em `/Applications`.

Compilar para simulador iOS ou dispositivo:

```sh
flutter build ios --simulator --debug
flutter build ios --release
```

O build de dispositivo requer assinatura e configuração de equipe no Xcode.

## Testes e análise

```sh
flutter analyze
flutter test
```

Os testes de comandos de voz estão em
[`test/playback_command_test.dart`](test/playback_command_test.dart). Eles não
substituem testes em dispositivos reais para permissões, fala, WebView ou
autenticação.

## Estrutura do projeto

- [`lib/main.dart`](lib/main.dart): inicialização do app, interface,
  controlador da WebView, ciclo de vida, permissões e sessões de reconhecimento
  de voz.
- [`lib/playback_command.dart`](lib/playback_command.dart): normalização de
  texto, reconhecimento das palavras de ativação e comandos, mensagens de
  confirmação e JavaScript para os controles do player.
- [`test/`](test): testes unitários de reconhecimento de comandos de voz.
- [`android/`](android), [`ios/`](ios) e [`macos/`](macos): configuração nativa,
  nomes de exibição, permissões e integração de plugins por plataforma.
- [`web/`](web), [`windows/`](windows) e [`linux/`](linux): arquivos de runner
  gerados pelo Flutter; não significam que todos os plugins do app funcionem
  nesses alvos.
- [`.vscode/mcp.json`](.vscode/mcp.json): configuração local de desenvolvimento
  do Firebase MCP para o Copilot no VS Code.

## Solução de problemas

- **O reconhecimento não fica disponível:** confirme a permissão de microfone
  e reconhecimento de fala nas configurações do sistema. No Android, verifique
  também se há um serviço de voz instalado e português disponível.
- **O app solicita Chrome durante o login:** é uma restrição do login Google
  dentro de uma WebView. Use o navegador oficial do dispositivo; a sessão
  externa não é compartilhada com o app.
- **O app macOS antigo ainda aparece:** feche a cópia anterior e abra o bundle
  compilado no caminho `build/macos/Build/Products/Debug/LineageTube.app`.
- **Os botões não controlam o player:** verifique se uma página do YouTube
  Music terminou de carregar. Mudanças no site podem exigir atualizar os
  seletores usados em `lib/playback_command.dart`.

## Identificadores do aplicativo

O nome de exibição e o pacote Dart são `LineageTube`/`lineagetube`. Os
identificadores de instalação nativos (Android `applicationId`, bundle IDs da
Apple e ID GTK do Linux) foram mantidos para preservar a identidade de
instalações já existentes. Alterá-los exige planejar migração, assinatura e
publicação separadamente.
