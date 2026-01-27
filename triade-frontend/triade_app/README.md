Ícone de notificação:

O arquivo é um vector XML em android/app/src/main/res/drawable/ic_notification.xml
Regra Android: ícones de notificação DEVEM ser monocromáticos (branco puro #FFFFFF com fundo transparente)
Você pode criar seu próprio ícone usando Android Studio (New > Vector Asset) ou converter um SVG

Nota: Para notificação no iOS funcionar completamente, você precisará:

Abrir o projeto no Xcode
Ir em Runner > Build Phases > Copy Bundle Resources
Adicionar o arquivo Sounds/notification.aiff
Habilitar "Push Notifications" no Signing & Capabilities


1. Build APK não atualizando:
O problema era cache do Flutter. Executei:

flutter clean - limpa todo o cache de build
flutter pub get - reinstala as dependências
flutter build apk --release - novo build limpo