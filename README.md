# Conviva

Aplicativo para gestão de lares de idosos com foco em comunicação, rotina e segurança.

---

## 📖 Sobre o Projeto

O Conviva aproxima idosos, familiares e cuidadores em instituições de longa permanência. O app (Flutter) usa o Firebase como backend e foi pensado para ser simples de usar pelos idosos, com ajustes de acessibilidade e um assistente virtual.

### Perfis de usuário

| Perfil | O que faz no app |
| --- | --- |
| **Idoso** | Vê a rotina do dia, conversa por chat, fala com o assistente Auri e pode fazer denúncias |
| **Cuidador** | Acompanha os residentes, cria e edita tarefas da rotina e vê as pendências do dia |
| **Familiar** | Vincula-se a um idoso, acompanha a rotina e conversa com ele |
| **Suporte** | Acesso próprio para a equipe de suporte |

### Funcionalidades principais

- 🔐 **Autenticação**: idoso entra com **código de acesso + senha**; cuidador e familiar entram com **e-mail + senha** (com verificação de e-mail). Recuperação de senha do idoso aprovada por um familiar ou cuidador responsável.
- 💬 **Chat**: conversas entre idosos, cuidadores e familiares, com mensagens de texto, imagens, áudio e emojis, além de contador de mensagens não lidas.
- 📅 **Rotina**: tarefas diárias com horário, repetição semanal, calendário do mês, marcação de conclusão e lembretes quando chega a hora da tarefa.
- 🤖 **Auri, assistente virtual**: perguntas e respostas sobre tecnologia usando IA (Google Gemini), com leitura em voz alta e ditado por voz.
- 🚨 **Central de denúncias**: fluxo para denunciar abusos de forma anônima, pessoal ou de terceiros.
- 🔔 **Notificações**: sino de notificações no app e push em segundo plano, que somem do sino depois de visualizadas.
- ♿ **Acessibilidade e personalização**: tamanho e grossura da fonte, volume, tamanho de ícones e botões, paleta de cores e intensidade.
- 🧭 **Tutorial para idosos**: depois do cadastro, o idoso pode personalizar o app e fazer um tour guiado pelas telas.
- 👪 **Vínculo familiar**: o familiar se vincula ao idoso pelo código de acesso, e o idoso aceita ou recusa o pedido pelo perfil.

---

## 🏗️ Arquitetura

```
conviva/
├── mobile/           # App Flutter (Android e Web)
├── functions/        # Cloud Functions (não publicadas, veja "Observações")
├── worker/           # Cloudflare Worker "conviva-push" (relé gratuito de push)
└── firestore-tests/  # Testes das regras de segurança do Firestore
```

### Stack tecnológica

#### Backend (Firebase + Cloudflare, só recursos gratuitos)
- **Autenticação**: Firebase Authentication
- **Banco de dados e chat em tempo real**: Cloud Firestore
- **Segurança**: Firestore Security Rules por perfil (`firestore.rules`) e índices (`firestore.indexes.json`)
- **Push**: Firebase Cloud Messaging, com envio feito por um Cloudflare Worker
- **Assistente Auri**: Google Gemini (`google_generative_ai`)

#### Mobile
- **Framework**: Flutter (Dart `^3.11.5`)
- **Gerenciamento de estado**: Riverpod
- **Navegação**: go_router
- **Rotina e lembretes**: table_calendar, flutter_local_notifications, timezone
- **Mídia no chat**: image_picker, record, audioplayers, emoji_picker_flutter
- **Voz do Auri**: flutter_tts, speech_to_text
- **Preferências locais**: shared_preferences

---

## 🚀 Como Executar

### Pré-requisitos

- Flutter com Dart `^3.11.5`
- Projeto no Firebase com Authentication (e-mail e senha), Firestore e Cloud Messaging
- Firebase CLI (para publicar as regras e os índices do Firestore)
- Chave da API do Google Gemini (para o Auri)
- Conta gratuita na Cloudflare e Node.js (só para o envio de push)

### Mobile

```bash
cd mobile
flutter pub get
flutter run --dart-define=GEMINI_API_KEY=SUA_CHAVE
```

Para rodar no navegador durante o desenvolvimento:

```bash
flutter run -d chrome --dart-define=GEMINI_API_KEY=SUA_CHAVE
```

Sem a `GEMINI_API_KEY`, o app funciona normalmente, mas o Auri não responde.

### Firestore

Publique as regras e os índices no seu projeto Firebase:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

### Push em segundo plano (opcional)

O envio de push usa o Worker da pasta `worker/`. Depois de publicá-lo, a URL fica em `mobile/lib/core/constants/push_relay_config.dart`. Se o campo ficar vazio, o envio de push é desligado e o app continua funcionando.

O Worker precisa do segredo `SERVICE_ACCOUNT_JSON` (conta de serviço do Firebase) cadastrado na Cloudflare.

---

## 📁 Estrutura de pastas

### Mobile

```
mobile/lib/
├── core/            # Constantes, rotas, serviços, configurações e temas
├── shared/          # Widgets, formatadores e utilitários compartilhados
└── features/        # Módulos por funcionalidade
    ├── auth/            # Cadastro, login, recuperação de senha e vínculo familiar
    ├── onboarding/      # Splash e apresentação inicial
    ├── home/            # Telas iniciais do idoso, do cuidador e do familiar
    ├── menu/            # Menu de funções
    ├── routine/         # Rotina, tarefas e calendário
    ├── chat/            # Conversas e mensagens
    ├── auri/            # Assistente virtual
    ├── reports/         # Central de denúncias
    ├── notifications/   # Sino e notificações
    ├── profile/         # Perfil, instituto, vínculos e código de acesso
    ├── settings/        # Acessibilidade e aparência
    ├── tutorial/        # Personalização inicial e tour guiado do idoso
    └── support/         # Área do suporte
```

Cada módulo segue a mesma divisão interna, quando necessário: `models/`, `pages/`, `providers/`, `widgets/`, `services/` e `repositories/`.

### Dados no Firestore

Principais coleções: `institutions`, `users` (com `preferences`, `devices` e `notifications`), `chats` (com `messages`), `familyLinks`, `routines` e `tasks`, `reports`, `auriChats` e as coleções da recuperação de senha.

---

## 🔒 Segurança

- Regras de segurança do Firestore por perfil de usuário, versionadas em `firestore.rules`
- Dados organizados por instituição (`institutionId`)
- Recuperação de senha do idoso aprovada por um responsável, com limite de tentativas
- Verificação de e-mail para cuidadores e familiares
- Denúncias que podem ser feitas de forma anônima

---

## ⚠️ Observações

- **Somente recursos gratuitos**: o projeto não usa nenhum plano pago do Firebase. Por isso as Cloud Functions da pasta `functions/` não estão no ar, e o push de mensagens passa pelo Worker da Cloudflare.
- **Chave do Auri**: a `GEMINI_API_KEY` é passada com `--dart-define` e não deve ser enviada ao repositório.

---

## 👥 Equipe

Projeto desenvolvido pela **Conviva** para gestão de lares de idosos.

---

## 📄 Licença

Este projeto é proprietário. Todos os direitos reservados © 2025 Conviva.

---

## 📌 Status do Projeto

**Fase atual**: Concluido

**Última atualização**: Novembro/2026
