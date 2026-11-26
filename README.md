#  Conviva 

Sistema multiplataforma para gestão de lares de idosos com foco em comunicação, rotina e segurança.

---

##  Sobre o Projeto

Aplicativo mobile (Flutter) + Backend (Spring Boot) para facilitar a comunicação entre idosos, familiares e cuidadores em instituições de longa permanência.

### Funcionalidades Principais

-  **Autenticação Simplificada**: Login por telefone (idosos) e telefone + senha (cuidadores/familiares)
-  **Chat em Tempo Real**: Comunicação direta com histórico persistente
-  **Gestão de Rotinas**: Registro e acompanhamento de atividades diárias
-  **Canal de Denúncias**: Sistema anônimo para reportar problemas

---

##  Arquitetura

```
conviva-system/
├── backend/        # API REST - Spring Boot + PostgreSQL
├── mobile/         # App Mobile - Flutter (Android/iOS)
└── docs/           # Documentação técnica
```

### Stack Tecnológica

#### Backend
- **Framework**: Spring Boot 3.2+
- **Banco de Dados**: PostgreSQL 16
- **Autenticação**: JWT + Spring Security
- **Notificações**: Firebase Cloud Messaging

#### Mobile
- **Framework**: Flutter 3.19+
- **Gerenciamento de Estado**: Bloc
- **Chat em Tempo Real**: Firebase Firestore
- **HTTP Client**: Dio

---

##  Como Executar

### Pré-requisitos

- Java 17+
- PostgreSQL 16+
- Flutter 3.19+
- Firebase Account (FCM + Firestore)

### Backend

```bash
cd backend
./mvnw spring-boot:run
```

### Mobile

```bash
cd mobile
flutter pub get
flutter run
```

---

## 📁 Estrutura de Pastas

### Backend (Clean Architecture)

```
backend/src/main/java/com/conviva/
├── domain/          # Entidades e regras de negócio
├── application/     # Casos de uso
├── infrastructure/  # Implementações (JPA, Firebase)
└── presentation/    # Controllers REST
```

### Mobile (Clean Architecture)

```
mobile/lib/
├── core/            # Funcionalidades compartilhadas
└── features/        # Módulos por funcionalidade
    ├── auth/
    ├── chat/
    ├── rotina/
    └── denuncia/
```

---

##  Segurança

- Criptografia de dados sensíveis (denúncias)
- Multi-tenancy com isolamento lógico
- Auditoria de acessos (LGPD)
- Tokens JWT com expiração

---

##  Documentação

A documentação completa está disponível em `/docs`:

- **Arquitetura**: Diagramas e decisões técnicas
- **API**: Contratos e exemplos de requisições
- **Database**: Schema e migrations

---

##  Equipe

Projeto desenvolvido pela **Conviva** para gestão de lares de idosos.

---

##  Licença

Este projeto é proprietário. Todos os direitos reservados © 2025 Conviva.

---

##  Status do Projeto

**Fase Atual**: MVP - Desenvolvimento Inicial

**Prazo**: Novembro/2025

**Última Atualização**: Fevereiro/2025
