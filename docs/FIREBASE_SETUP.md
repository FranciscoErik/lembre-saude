# Configurar Firebase (Firestore) — Lembre Saúde

O backend usa **Cloud Firestore** como banco de dados via `firebase-admin`.

## 1. Criar projeto no Firebase

1. Acesse [Firebase Console](https://console.firebase.google.com/)
2. **Adicionar projeto** → ex.: `lembresaude-a5547`
3. Ative **Google Analytics** (opcional)

## 2. Ativar Firestore

1. No menu: **Build → Firestore Database**
2. **Criar banco de dados** → modo **Produção** (ou teste para desenvolvimento)
3. Escolha a região (ex.: `southamerica-east1`)

## 3. Chave de conta de serviço (API Node.js)

1. **Configurações do projeto** (ícone engrenagem) → **Contas de serviço**
2. **Gerar nova chave privada** → baixa um JSON
3. Salve como `config/firebase-service-account.json` na raiz do repositório  
   (este arquivo **não** deve ir para o Git)

## 4. Variáveis de ambiente

Copie `.env.example` para `.env` e configure:

```env
FIREBASE_SERVICE_ACCOUNT_PATH=./config/firebase-service-account.json
```

Alternativa (CI/Docker): cole o JSON inteiro em uma linha:

```env
FIREBASE_SERVICE_ACCOUNT_JSON={"type":"service_account",...}
```

## 5. Índices do Firestore

Na primeira consulta composta, o Firebase pode pedir um índice. Use o arquivo `firestore.indexes.json` na raiz ou crie manualmente no console:

| Coleção | Campos |
|---------|--------|
| `links` | `inviteCode` + `status` |
| `links` | `caregiverId` + `status` |

## 6. Coleções criadas automaticamente

| Coleção | Conteúdo |
|---------|----------|
| `users` | Usuários (paciente/cuidador) |
| `medications` | Medicamentos |
| `doses` | Doses / adesão |
| `links` | Vínculo paciente–cuidador |
| `consents` | Consentimentos LGPD |
| `notification_settings` | Preferências de lembrete |
| `data_exports` | Exportações LGPD |

## 7. Rodar a API

```bash
npm install
npm run dev
```

No log deve aparecer: `Banco de dados: Firebase Firestore`

## 8. Testes automatizados

`npm test` usa **memória** (`DATA_STORE=memory`), sem precisar do Firebase.

## Segurança

- Nunca commite `firebase-service-account.json`
- No Firebase Console, restrinja regras do Firestore se o app Flutter acessar direto no futuro
- Hoje o acesso aos dados é **somente pela API Node.js** (Admin SDK)
