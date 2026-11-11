# YouTube Music Voice

Aplicativo Flutter para Android/LineageOS que abre o YouTube Music e oferece
controles de reprodução por toque e por comandos de voz em português.

## Ativação por voz

Ao abrir o app, ele inicia a escuta automaticamente e solicita autorização para
o microfone e o reconhecimento de fala quando necessário. A autorização é
concedida pelo sistema operacional para cada instalação/dispositivo; o app não
pode concedê-la sozinho nem ignorar uma revogação. A escuta contínua funciona
enquanto o app está aberto em primeiro plano; ao voltar ao app, ela é retomada
automaticamente. **Pausar Friday** interrompe a escuta até você tocar em
**Ativar Friday**. Diga **“Friday”** (pronunciado “fraidei”) ou
**“sexta-feira”**, seguido de um comando; também pode falar tudo de uma vez,
por exemplo, **“sexta-feira, próxima música”**:

- “tocar”, “continuar” ou “reproduzir”
- “pausar” ou “parar”
- “próxima” ou “faixa seguinte”
- “anterior”
- “aumentar o volume” ou “diminuir o volume”

A detecção usa o serviço de reconhecimento de voz do Android, em sessões que
são reiniciadas automaticamente. Não é um detector local dedicado de palavra
de ativação: pode depender de internet e do serviço de voz instalado no
LineageOS. A escuta fica ativa apenas enquanto **Ativar Friday** estiver ligado
e o app estiver em primeiro plano; tocar em **Desativar Friday** interrompe o
microfone. Ao sair do app, a ativação é pausada.

No macOS, se a permissão for negada, habilite o acesso em **Ajustes do Sistema >
Privacidade e Segurança > Microfone** e **Reconhecimento de fala**. Para testar
o bundle recém-compilado, execute `flutter build macos --debug` e abra
`build/macos/Build/Products/Debug/youtubealexa.app`; um app antigo em
`/Applications` não recebe as alterações do workspace automaticamente.

## Gerar APK

Com Flutter e Android SDK instalados:

```sh
flutter pub get
flutter build apk --release
```

O APK será gerado em `build/app/outputs/flutter-apk/app-release.apk`. Para
instalá-lo com um dispositivo conectado e depuração USB habilitada:

```sh
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Na primeira utilização, permita o acesso ao microfone. O reconhecimento
depende de um serviço de voz Android instalado e de um idioma português
disponível; alguns builds do LineageOS não incluem esse serviço.

## Limitações de compatibilidade

O player é carregado em uma WebView Android. O YouTube pode restringir o login
Google em navegadores incorporados, e alterações no site podem exigir ajustes
nos controles JavaScript. O Echo Show normalmente usa Fire OS, não LineageOS;
portanto, a instalação depende de o dispositivo realmente executar uma versão
Android compatível com este APK e com uma WebView atualizada.

No macOS, o Flutter usa o WKWebView do sistema, não o Google Chrome. O Chrome
não pode ser selecionado como motor de WebView nessa configuração. Se o
YouTube/Google pedir Chrome ao tentar entrar, é uma limitação de login em
navegadores incorporados; instalar o Chrome não transfere sua sessão para a
WebView. Abrir o YouTube Music no Chrome instalado é uma alternativa, mas o app
não poderá controlar essa sessão por meio da WebView.

## Firebase MCP no VS Code

O workspace configura o servidor MCP oficial do Firebase em
`.vscode/mcp.json`. Com Node.js e npm instalados, abra o projeto no VS Code e
inicie ou reinicie o servidor Firebase MCP pela interface de MCP do Copilot.
Quando solicitado, autorize o acesso à sua conta Firebase; o servidor usa as
credenciais locais do Firebase CLI.

Se ainda não estiver autenticado no Firebase CLI, execute
`npx firebase-tools login` no terminal. O MCP pode ajudar a configurar serviços
do Firebase, mas não autentica o YouTube Music nem compartilha a sessão Google
com a WebView do aplicativo.
