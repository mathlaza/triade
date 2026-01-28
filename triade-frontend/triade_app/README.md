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



📊 Estrutura de Tiers Proposta
🆓 PLANO FREE (sempre grátis)

✅ Daily View completo
✅ Criar até 10 tarefas ativas por dia (limite soft)
✅ 3 níveis de energia
✅ Completar tarefas
✅ Pending Review Modal
✅ Notificações básicas
❌ Weekly View (bloqueado)
❌ Dashboard/Analytics (bloqueado)
❌ Tarefas recorrentes (bloqueado)
❌ Delegação (bloqueado)

⭐ PLANO PREMIUM (~R$ 14,90 − 19,90 / mes ou R$ 99,90/ano)

✅ Tudo do Free
✅ Weekly Planning com drag-drop
✅ Dashboard completo com gráficos
✅ Insights de IA (alertas de burnout, balanço)
✅ Tarefas recorrentes ilimitadas
✅ Delegação de tarefas
✅ Histórico completo com busca
✅ Configuração de horas por dia
✅ Suporte prioritário
🔮 Futuro: Offline mode, Export, Widgets

🎯 Por que essa divisão?
Daily View grátis = usuário experimenta o core do app e desenvolve hábito
Weekly View premium = feature de alto valor que power users vão querer
Analytics premium = justifica o pagamento com dados valiosos
Limite soft de tarefas = não frustra demais, mas incentiva upgrade


┌─────────────────────────────────────────────────────────────┐
│                         BACKEND                              │
├─────────────────────────────────────────────────────────────┤
│  User Model → adicionar campo: subscription_tier (free/premium)  │
│            → adicionar campo: subscription_expires (datetime)     │
│            → adicionar campo: stripe_customer_id (opcional)       │
├─────────────────────────────────────────────────────────────┤
│  Novo endpoint: GET /auth/subscription → retorna tier atual │
│  Novo endpoint: POST /auth/upgrade → webhook de pagamento   │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                        FRONTEND                              │
├─────────────────────────────────────────────────────────────┤
│  SubscriptionProvider → gerencia estado de assinatura       │
│  PremiumGate widget → wrapper que bloqueia features         │
│  UpgradeScreen → tela de benefícios + botão de compra      │
│  RevenueCat ou compra direta via stores                     │
└─────────────────────────────────────────────────────────────┘


💡  Dica de Lançamento
Primeiro mês: Lance 100% grátis para atrair usuários e reviews
Após 1-2 meses: Introduza o Premium gradualmente
Usuários early adopters: Dê 3-6 meses grátis de Premium como agradecimento





MIGRAR BACKEND???

Fase 1: Adicionar Observabilidade (FAÇA AGORA)
Ferramenta	Propósito	Custo
Sentry	Crash reporting (Android + iOS + Backend)	Grátis até 5K erros/mês
Firebase Crashlytics	Alternativa ao Sentry (só mobile)	100% grátis
// No Flutter, adicione Sentry:
// pubspec.yaml → sentry_flutter: ^7.0.0
// Captura crashes automaticamente



Fase 2: Manter PythonAnywhere + SQLite (próximos 3-6 meses)
Por quê?

Você já está funcionando
Migração agora é distração do lançamento
SQLite aguenta centenas de usuários tranquilamente
PythonAnywhere é barato e simples
Mas adicione:

Sentry no backend para logs de erro
Backup automático (você já tem!)


Fase 3: Migrar quando precisar (após validar product-market fit)
Quando tiver >500 usuários ativos ou problemas de performance, migre para:


Componente	Migrar Para	Por quê
Banco	Supabase (PostgreSQL gerenciado)	Interface visual, queries fáceis, grátis até 500MB
Hosting	Railway ou Render	Deploy fácil, logs persistentes, métricas
Alternativa Full	Firebase	Se quiser offline mode nativo (Firestore)
🆚 Comparativo de Opções
Plataforma	Prós	Contras	Custo
PythonAnywhere	Simples, barato, já funciona	Sem métricas, interface fraca	~$5/mês
Supabase	Postgres grátis, UI incrível, APIs prontas	Precisa reescrever queries	Grátis → $25/mês
Firebase	Offline nativo, Crashlytics, fácil	NoSQL (diferente), lock-in Google	Grátis → $25/mês
Railway	Deploy fácil, Postgres incluso	Mais caro em escala	Grátis → $20/mês
Render	Similar ao Railway	Cold starts no free tier	Grátis → $7/mês

✅ Plano de Ação Recomendado

AGORA (antes do lançamento):
├── Adicionar Sentry ou Firebase Crashlytics no Flutter
├── Adicionar Sentry no backend Python
└── Manter PythonAnywhere + SQLite

APÓS 3-6 MESES (se crescer):
├── Migrar banco para Supabase (PostgreSQL)
├── Migrar backend para Railway ou Render
└── Adicionar Redis para cache (se precisar)

APÓS 1 ANO (se escalar muito):
├── Considerar Firebase para offline mode
├── CDN para assets
└── Kubernetes se virar enterprise