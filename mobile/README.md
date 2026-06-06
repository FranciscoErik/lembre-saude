# Lembre Saúde — App Flutter

Frontend mobile do **Lembre Saúde**, integrado à API REST Node.js (`/api/v1`).

Disponível para **Android** e **iOS**, com lembretes locais de medicamentos, fluxo paciente/cuidador e conformidade LGPD.

---

## Pré-requisitos

- [Flutter 3.16+](https://docs.flutter.dev/get-started/install)
- API backend rodando (veja [README na raiz](../README.md))
- **Android:** Android SDK + JDK 17 (para build)
- **Celular físico ou emulador** para testar notificações

---

## Instalação

```bash
cd mobile
flutter pub get
```

---

## Configuração da API

A URL da API é definida em tempo de compilação via `--dart-define`.

### Valores padrão (sem `--dart-define`)

| Plataforma | URL base |
|------------|----------|
| Linux / Web / iOS simulador | `http://localhost:3000/api/v1` |
| Android emulador | `http://10.0.2.2:3000/api/v1` |

### Celular físico (recomendado para demo)

1. PC e celular na **mesma rede Wi‑Fi**
2. Descubra o IP do PC:

```bash
hostname -I
# Exemplo: 192.168.0.191
```

3. Confirme que a API responde no celular (navegador):

```
http://SEU_IP:3000/api/v1/health
```

4. Rode ou compile com o IP:

```bash
flutter run --release \
  --dart-define=API_BASE_URL=http://192.168.0.191:3000/api/v1
```

### Build APK (instalação direta)

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=http://192.168.0.191:3000/api/v1
```

APK: `build/app/outputs/flutter-apk/app-release.apk`

Instalar via USB:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Alternativa: cabo USB (sem Wi‑Fi)

```bash
adb reverse tcp:3000 tcp:3000

flutter run --release \
  --dart-define=API_BASE_URL=http://127.0.0.1:3000/api/v1
```

---

## Executar

**Terminal 1 — API:**

```bash
cd ..
node src/server.js
```

**Terminal 2 — App:**

```bash
cd mobile
export ANDROID_HOME=$HOME/Android/Sdk   # se necessário
export PATH="$ANDROID_HOME/platform-tools:$PATH"

flutter devices
flutter run --release -d <ID_DO_CELULAR> \
  --dart-define=API_BASE_URL=http://192.168.0.191:3000/api/v1
```

---

## Fluxo do app

### Primeiro acesso
1. **Boas-vindas** → Criar conta ou Entrar
2. **LGPD** → Aceitar consentimento `DATA_PROCESSING`
3. Redirecionamento conforme perfil (`PATIENT` ou `CAREGIVER`)

### Paciente
| Tela | Função |
|------|--------|
| **Início** | Aderência do dia, doses pendentes, confirmar/adiar |
| **Medicamentos** | Lista e exclusão |
| **Histórico** | Doses anteriores |
| **Perfil** | Lembretes, código de convite, sair, excluir conta |

### Cuidador
| Tela | Função |
|------|--------|
| **Início** | Pacientes vinculados, aderência e medicamentos de cada um |
| **Vincular** | Aceitar código de convite do paciente |
| **Perfil** | Dados da conta, sair |

---

## Notificações (lembretes de dose)

No **Android** e **iOS**, o app agenda **notificações locais** diárias no horário de cada medicamento.

| Item | Detalhe |
|------|---------|
| Título | *"Hora do seu remédio"* |
| Corpo | Nome + dosagem + horário |
| Ativar/desativar | **Perfil → Lembretes de medicamentos** |
| Persistência | Preferência salva na API (`GET/PATCH /users/me/notifications`) |
| Reagendamento | Automático ao cadastrar/alterar medicamentos |

### Testar notificação (2 minutos)

1. **Perfil** → Lembretes **ligados** (aceite permissões do Android)
2. Cadastre medicamento com horário **2 min à frente** (ex.: agora 18:05 → use `18:07`)
3. Volte na **Home** (atualiza agendamento)
4. Minimize o app → aguarde o alerta

> **Linux/desktop:** lembretes não funcionam. Use celular Android ou emulador.

> Se o horário já passou hoje, o lembrete agenda para **amanhã**.

---

## Endpoints consumidos

| Grupo | Endpoints |
|-------|-----------|
| Auth | `POST /auth/register`, `POST /auth/login` |
| Usuário | `GET /users/me`, `DELETE /users/me` |
| LGPD | `GET/POST /users/me/consents`, `POST /users/me/data-export` |
| Notificações | `GET/PATCH /users/me/notifications` |
| Medicamentos | `GET/POST/DELETE /medications` |
| Doses | `GET /doses/adherence`, `POST /doses/:id/confirm` |
| Vínculos | `POST /links/invite-code`, `POST /links/accept`, `GET /links/patients`, `GET /links/patients/:id/overview` |

---

## Estrutura do código

```
lib/
├── main.dart
├── app_scope.dart
├── config/
│   └── api_config.dart          # URL base da API
├── models/
│   ├── user.dart
│   ├── medication.dart
│   ├── dose.dart
│   ├── patient_link.dart
│   ├── patient_overview.dart    # Visão cuidador (meds + aderência)
│   └── notification_settings.dart
├── services/
│   ├── api_service.dart         # Cliente HTTP REST
│   ├── auth_storage.dart        # JWT em SharedPreferences
│   └── notification_service.dart
├── screens/
│   ├── splash_screen.dart
│   ├── onboarding_screen.dart
│   ├── login_screen.dart
│   ├── privacy_lgpd_screen.dart
│   ├── patient/                 # Home, meds, histórico, perfil
│   └── caregiver/               # Dashboard, vincular
├── theme/
│   └── app_theme.dart
└── widgets/                     # Botões, cards, header, etc.
```

---

## Permissões Android

Configuradas em `android/app/src/main/AndroidManifest.xml`:

| Permissão | Uso |
|-----------|-----|
| `INTERNET` | Comunicação com a API |
| `POST_NOTIFICATIONS` | Lembretes de medicamento |
| `SCHEDULE_EXACT_ALARM` | Alarme no horário exato |
| `VIBRATE` | Vibração na notificação |

HTTP local habilitado via `network_security_config.xml` (desenvolvimento/demo).

---

## Solução de problemas

| Problema | Solução |
|----------|---------|
| *"Sem conexão com a API"* | API rodando? Mesma Wi‑Fi? Teste `/health` no navegador do celular |
| `npm run dev` com `clean exit` | Use `node src/server.js` |
| Flutter não vê o celular | `adb devices` → aceite depuração USB |
| Notificação não aparece | Perfil → lembretes ligados; horário 1–3 min no futuro; não use Linux desktop |
| Cuidador não vê medicamentos | Paciente gerou código? Cuidador aceitou em **Vincular**? Puxe para atualizar |

---

## Análise estática

```bash
flutter analyze
```

---

## Dependências principais

| Pacote | Uso |
|--------|-----|
| `http` | Cliente REST |
| `shared_preferences` | Token JWT local |
| `flutter_local_notifications` | Lembretes no celular |
| `google_fonts` | Tipografia Poppins |
| `intl` | Formatação de datas (pt_BR) |

---

## Documentação relacionada

- [README principal](../README.md)
- [Firebase Setup](../docs/FIREBASE_SETUP.md)
- [Auditoria Interna](../docs/AUDITORIA_INTERNA.md)
