# Documentação - Conviva System

Documentação técnica completa do projeto.

---

## 📁 Estrutura

```
docs/
├── architecture/    # Diagramas e decisões arquiteturais
├── api/            # Contratos de API (OpenAPI/Swagger)
└── database/       # Schema, migrations e modelo de dados
```

---

## 📚 Conteúdo

### `/architecture`

- **Diagrama de Arquitetura**: Visão geral do sistema
- **Decisões Técnicas**: ADRs (Architecture Decision Records)
- **Fluxos de Uso**: Diagramas de sequência

### `/api`

- **Contratos REST**: Especificação OpenAPI 3.0
- **Exemplos de Requisições**: Postman Collection
- **Autenticação**: Fluxo JWT

### `/database`

- **Modelo de Dados**: Diagrama ER
- **Schema SQL**: DDL completo
- **Migrations**: Histórico de mudanças (Flyway)

---

## 🛠️ Ferramentas Recomendadas

### Diagramas

- [Draw.io](https://app.diagrams.net/) - Diagramas gerais
- [dbdiagram.io](https://dbdiagram.io/) - Modelo de dados

### API

- [Swagger Editor](https://editor.swagger.io/) - Edição de contratos
- [Postman](https://www.postman.com/) - Testes de API

### Colaboração

- [Notion](https://notion.so) - Documentação viva
- [Confluence](https://www.atlassian.com/software/confluence) - Wiki técnico

---

## 📝 Convenções

### Nomeclatura de Arquivos

```
<categoria>-<nome>-<versão>.md

Exemplos:
- arch-clean-architecture-v1.md
- api-auth-endpoints-v2.md
- db-schema-v1.sql
```

### Versionamento

- `v1`: Versão inicial
- `v2`: Atualização após mudanças significativas
- Data no rodapé: `Última atualização: 02/02/2025`

---

## 🔄 Atualização

A documentação deve ser atualizada:

- ✅ **Sempre** antes de implementar mudanças arquiteturais
- ✅ Após conclusão de features grandes
- ✅ Quando houver alterações de API
- ✅ Ao adicionar/remover tabelas do banco

---

**Status**: Estrutura inicial - aguardando documentação técnica
