# Lembre Saúde

Solução integrada para **aderência medicamentosa**, desenvolvida no **TED — Programação para Dispositivos Móveis**.

O sistema conecta **pacientes** e **cuidadores** (familiares) por meio de um app **Flutter** e uma **API REST Node.js**, com persistência em **Firebase Firestore**, conformidade **LGPD** e lembretes locais no celular.

---

## Sobre o projeto

Milhares de pessoas — especialmente idosos e portadores de doenças crônicas — esquecem de tomar medicamentos no horário correto. Isso compromete tratamentos, gera internações evitáveis e preocupa familiares.

O **Lembre Saúde** oferece:

- Cadastro simples de medicamentos com horários
- Lembretes locais no celular (*"Hora do seu remédio"*)
- Acompanhamento de aderência em percentual
- Vínculo seguro paciente ↔ cuidador por código de convite
- Consentimento LGPD, exportação e exclusão de dados

---

## Arquitetura

```
┌─────────────────┐      HTTP/REST       ┌──────────────────┐      firebase-admin      ┌─────────────────┐
│  App Flutter    │  ─────────────────►  │  API Node.js     │  ─────────────────────►  │ Cloud Firestore │
│  (Android/iOS)  │  ◄─────────────────  │  Express + JWT   │  ◄─────────────────────  │                 │
└─────────────────┘      JSON + JWT      └──────────────────┘                          └─────────────────┘
        │
        └── Notificações locais (flutter_local_notifications)
```

| Camada | Tecnologia |
|--------|------------|
| Frontend | Flutter 3.x, Dart, Google Fonts (Poppins) |
| Backend | Node.js 18+, Express 5, Zod, Swagger OpenAPI 3.0.3 |
| Banco | Firebase Firestore (produção) / memória (testes) |
| Auth | JWT + bcrypt (12 rounds) |
| Perfis | `PATIENT` e `CAREGIVER` |

---

## Estrutura do repositório

```
lembre-saude-api/
├── src/                    # API REST (Express)
├── tests/                  # Testes funcionais (Jest + Supertest)
├── docs/
│   ├── AUDITORIA_INTERNA.md
│   └── FIREBASE_SETUP.md
├── config/                 # Chave Firebase (não commitar)
├── mobile/                 # App Flutter
│   ├── lib/
│   └── android/
├── README.md               # Este arquivo
└── package.json
```

---

## Requisitos

### Backend
- Node.js 18+
- npm
- Projeto Firebase com Firestore ativado → [docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md)

### Frontend (mobile)
- Flutter 3.16+ → [mobile/README.md](mobile/README.md)
- Android SDK (para build Android)
- JDK 17 (Gradle)

---

## Instalação e execução

### 1. Backend (API)

```bash
git clone <url-do-repositorio>
cd lembre-saude-api
npm install
cp .env.example .env
```

Coloque a chave da conta de serviço Firebase em:

```
config/firebase-service-account.json
```

> **Nunca commite** arquivos `.env` ou chaves Firebase. Veja `.gitignore`.

Inicie a API:

```bash
node src/server.js
```

Alternativa com reload automático:

```bash
npm run dev
```

> Se `npm run dev` exibir `clean exit`, use `node src/server.js` diretamente.

A API fica disponível em:

| Recurso | URL |
|---------|-----|
| Base | `http://localhost:3000/api/v1` |
| Health | `http://localhost:3000/api/v1/health` |
| Swagger | `http://localhost:3000/api/v1/docs` |

A API escuta em `0.0.0.0:3000` (acessível na rede local pelo IP do PC).

### 2. Frontend (Flutter)

Consulte o guia completo em **[mobile/README.md](mobile/README.md)**.

Resumo — celular físico na mesma Wi‑Fi:

```bash
cd mobile
flutter pub get

# Substitua pelo IP local do seu PC (hostname -I)
flutter run --release \
  --dart-define=API_BASE_URL=http://192.168.0.191:3000/api/v1
```

Build APK release:

```bash
cd mobile
flutter build apk --release \
  --dart-define=API_BASE_URL=http://192.168.0.191:3000/api/v1
```

APK gerado em: `mobile/build/app/outputs/flutter-apk/app-release.apk`

---

## Funcionalidades

### Paciente
- Cadastro e login
- Consentimento LGPD (`DATA_PROCESSING`)
- CRUD de medicamentos (nome, dosagem, horário, frequência)
- Confirmação de doses (`TAKEN`, `POSTPONED`)
- Aderência medicamentosa (% e resumo)
- Lembretes locais nos horários cadastrados
- Código de convite para vincular cuidador
- Exportação e exclusão de conta (LGPD)

### Cuidador
- Cadastro e login (perfil `CAREGIVER`)
- Aceitar código de convite do paciente
- Painel com pacientes vinculados
- Visualização de **medicamentos** e **aderência** do paciente vinculado

### API / Governança
- Contrato OpenAPI documentado (Swagger)
- Validação de entrada (Zod)
- Controle de acesso por role e ownership (proteção IDOR)
- Auditoria interna documentada
- 14 testes automatizados

---

## Endpoints da API

| Método | Endpoint | Acesso |
|--------|----------|--------|
| GET | `/api/v1/health` | Público |
| POST | `/api/v1/auth/register` | Público |
| POST | `/api/v1/auth/login` | Público |
| GET | `/api/v1/users/me` | Autenticado |
| DELETE | `/api/v1/users/me` | Autenticado |
| GET/PATCH | `/api/v1/users/me/notifications` | Autenticado |
| GET/POST | `/api/v1/users/me/consents` | Autenticado |
| POST | `/api/v1/users/me/data-export` | Autenticado |
| GET/POST/PATCH/DELETE | `/api/v1/medications` | PATIENT |
| POST | `/api/v1/doses/:doseId/confirm` | PATIENT |
| GET | `/api/v1/doses/adherence` | PATIENT |
| POST | `/api/v1/links/invite-code` | PATIENT |
| POST | `/api/v1/links/accept` | CAREGIVER |
| GET | `/api/v1/links/patients` | CAREGIVER |
| GET | `/api/v1/links/patients/:patientId/overview` | CAREGIVER |

Documentação interativa: `http://localhost:3000/api/v1/docs`

---

## Testes

```bash
npm test
```

Os testes usam banco **em memória** (sem Firebase). Resultado esperado: **14 testes passando**.

---

## Variáveis de ambiente

Arquivo `.env` (copie de `.env.example`):

```env
PORT=3000
JWT_SECRET=altere-esta-chave-em-producao
JWT_EXPIRES_IN=24h
CORS_ORIGIN=*

FIREBASE_SERVICE_ACCOUNT_PATH=./config/firebase-service-account.json
```

---

## Segurança

| Medida | Implementação |
|--------|---------------|
| Autenticação | JWT Bearer Token |
| Senhas | bcrypt (12 rounds), hash nunca exposto |
| Headers HTTP | Helmet |
| CORS | Configurável via `CORS_ORIGIN` |
| Validação | Zod em todos os endpoints |
| Autorização | Roles (`PATIENT` / `CAREGIVER`) + ownership |
| LGPD | Consentimento, exportação, exclusão de conta |
| Auditoria | [docs/AUDITORIA_INTERNA.md](docs/AUDITORIA_INTERNA.md) |

---

## Fluxo de demonstração (pitch)

1. **Paciente** — cadastro → LGPD → medicamento → confirmar dose → lembrete
2. **Perfil** — gerar código de convite
3. **Cuidador** — nova conta → vincular código → ver medicamentos e aderência
4. **Técnico** — Swagger + `npm test` como evidência de qualidade

---

## Documentação adicional

| Documento | Descrição |
|-----------|-----------|
| [mobile/README.md](mobile/README.md) | App Flutter — setup, build, notificações |
| [docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md) | Configuração do Firebase Firestore |
| [docs/AUDITORIA_INTERNA.md](docs/AUDITORIA_INTERNA.md) | Relatório de auditoria e governança de TI |

---

## Entrega TED 4

1. Link do repositório Git (código backend + app Flutter)
2. Vídeo de pitch (3–5 min) demonstrando o app integrado
3. Evidências: `npm test`, Swagger, app no celular
4. Relatório de auditoria interna

---

## Equipe

Projeto acadêmico — **Equipe Lembre Saúde**  
Disciplina: Programação para Dispositivos Móveis (TED 2)

---

## Licença

ISC
