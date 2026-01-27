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



2. Setup de Recuperação de Senha via E-mail
Analisei sua implementação e aqui está o status:

| Componente | Status | Observação |
|------------|--------|------------|
| **Frontend - Tela** | ✅ Pronto |  está completo com formulário, validação de email, estados de loading e mensagem de sucesso |
| **Frontend - Service** | ✅ Pronto |  faz POST para  |
| **Backend - Endpoint** | ⚠️ Parcial |  recebe o email e gera o token, mas **NÃO envia o email** |

O que falta para integrar:

Configurar um serviço de email no backend (ex: SMTP, SendGrid, Mailgun, AWS SES)
Salvar o token de reset no banco de dados com data de expiração
Enviar o email com o link de recuperação
Criar endpoint /auth/reset-password para validar o token e permitir a nova senha
Criar tela de "Nova Senha" no frontend para quando o usuário clicar no link do email