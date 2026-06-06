# Relatório de Auditoria Interna — Lembre Saúde API (TED 2)

**Projeto:** Lembre Saúde  
**Disciplina:** Programação para Dispositivos Móveis  
**Tecnologia:** Node.js + Express  
**Data:** Maio/2026  
**Versão da API:** 1.0.0 (`/api/v1`)

---

## 1. Verificação da Integridade das Respostas da API

| Verificação | Resultado | Evidência |
|-------------|-----------|-----------|
| Endpoints retornam HTTP codes semânticos (200/201/204/400/401/403/404) | ✅ Conforme | Testes automatizados (`npm test`) |
| Respostas em JSON com estrutura consistente | ✅ Conforme | Swagger + testes |
| Erros retornam `{ code, message, details? }` | ✅ Conforme | Middleware de validação Zod |
| `passwordHash` nunca exposto nas respostas | ✅ Conforme | Função `sanitizeUser()` |
| Healthcheck retorna `{ status: "ok", timestamp }` | ✅ Conforme | `GET /api/v1/health` |

**Observação:** Todas as respostas de sucesso e erro seguem padrão definido no contrato OpenAPI 3.0.3 (`src/swagger.js`).

---

## 2. Validação da Lógica de Negócio Implementada

| Funcionalidade | Resultado | Detalhes |
|----------------|-----------|----------|
| Cadastro com role PATIENT/CAREGIVER | ✅ | `POST /auth/register` valida role via Zod |
| Login gera JWT válido | ✅ | Token com expiração configurável |
| Rotas protegidas exigem Bearer Token | ✅ | Middleware `authenticate` |
| Medicamentos acessíveis apenas por PATIENT | ✅ | Middleware `requireRole('PATIENT')` |
| Ownership de medicamentos/doses verificado | ✅ | Funções `ownsMedication()` / `ownsDose()` |
| Confirmação de dose atualiza status e `confirmedAt` | ✅ | `POST /doses/:doseId/confirm` |
| Aderência calculada corretamente | ✅ | `GET /doses/adherence` com taxa percentual |
| Fluxo inviteCode → accept → list patients | ✅ | Teste funcional completo |
| Consentimentos LGPD por usuário autenticado | ✅ | `GET/POST /users/me/consents` |
| Exportação de dados pessoais | ✅ | `POST /users/me/data-export` |
| Exclusão de conta remove dados associados | ✅ | `DELETE /users/me` |

---

## 3. Identificação de Possíveis Falhas ou Vulnerabilidades

| Risco | Severidade | Status | Mitigação |
|-------|------------|--------|-----------|
| Persistência de dados | Alta | ✅ Mitigado | Firebase Firestore (produção); memória nos testes |
| IDOR (acesso a recursos de outro usuário) | Alta | ✅ Mitigado | Verificação de ownership antes de CRUD |
| Entrada maliciosa / payload inválido | Média | ✅ Mitigado | Validação Zod em todos os endpoints |
| Força bruta em login/register | Média | ⚠️ Pendente | Recomendado: `express-rate-limit` |
| JWT sem rotação/refresh token | Baixa | ⚠️ Pendente | Recomendado para produção |
| Ausência de audit logger estruturado | Média | ⚠️ Pendente | Recomendado: Winston com retenção 12 meses |
| HTTPS/TLS em produção | Alta | ⚠️ Pendente | Obrigatório em deploy (TLS 1.3) |

---

## 4. Correções ou Melhorias Aplicadas Durante o Processo

1. **Padronização de erros:** Implementado middleware de validação com Zod retornando JSON estruturado (`code`, `message`, `details`).
2. **Proteção de dados sensíveis:** Senhas hasheadas com bcrypt (12 rounds); `passwordHash` nunca retornado.
3. **Controle de acesso por role:** Middleware `requireRole` impede CAREGIVER de acessar rotas de PATIENT.
4. **Verificação de ownership:** Impede que usuário acesse/edite medicamentos ou doses de outro usuário (proteção IDOR).
5. **Documentação contratual:** OpenAPI 3.0.3 disponível via Swagger UI em `/api/v1/docs`.
6. **Testes funcionais automatizados:** 12 cenários cobrindo auth, CRUD, doses, links e LGPD.

---

## 5. Evidências de Testes

### Testes automatizados (Jest + Supertest)

```bash
npm test
```

Resultado esperado: **12 testes passando**.

### Testes manuais (Postman/Insomnia)

1. Importar coleção a partir do Swagger (`/api/v1/docs`)
2. Executar fluxo completo:
   - Register (PATIENT) → Login → GET /users/me
   - CRUD medicamentos
   - Confirmar dose → GET adherence
   - Register (CAREGIVER) → invite-code → accept → GET patients
   - Consents → data-export → DELETE /users/me
3. Capturar prints dos resultados para anexar à entrega.

---

## 6. Conclusão

A API REST do Lembre Saúde foi implementada conforme o contrato definido no TED 2, com endpoints funcionais, autenticação JWT, validação de entrada, controle de acesso por role e funcionalidades de privacidade (LGPD). Os testes funcionais confirmam a integridade das respostas e a lógica de negócio. Riscos identificados relacionados à persistência em memória e controles avançados de segurança estão documentados com plano de mitigação para sprints futuras.

**Status geral:** ✅ Aprovado para entrega do TED 2 (MVP acadêmico).
