# YouTube Music Voice

Aplicativo Flutter para Android/LineageOS que abre o YouTube Music e oferece
controles de reprodução por toque e por comandos de voz em português.

## Ativação por voz

Toque em **Ativar Friday** e permita o acesso ao microfone. Enquanto o app
estiver aberto em primeiro plano, diga **“Friday”** e depois um comando, ou
fale tudo de uma vez, por exemplo, **“Friday, próxima música”**:

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
