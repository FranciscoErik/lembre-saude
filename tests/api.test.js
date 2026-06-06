const request = require('supertest');
const app = require('../src/app');
const { resetStore } = require('../src/data/store');

beforeEach(() => {
  resetStore();
});

describe('Lembre Saúde API — Testes Funcionais', () => {
  let patientToken;
  let caregiverToken;
  let medicationId;
  let doseId;
  let inviteCode;

  test('GET /api/v1/health retorna status ok', async () => {
    const res = await request(app).get('/api/v1/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
    expect(res.body.timestamp).toBeDefined();
  });

  test('POST /auth/register cria paciente', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({
        name: 'Maria Paciente',
        email: 'maria@test.com',
        password: '123456',
        role: 'PATIENT',
      });
    expect(res.status).toBe(201);
    expect(res.body.token).toBeDefined();
    expect(res.body.user.role).toBe('PATIENT');
    expect(res.body.user.passwordHash).toBeUndefined();
    patientToken = res.body.token;
  });

  test('POST /auth/register cria cuidador', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({
        name: 'João Cuidador',
        email: 'joao@test.com',
        password: '123456',
        role: 'CAREGIVER',
      });
    expect(res.status).toBe(201);
    caregiverToken = res.body.token;
  });

  test('POST /auth/login autentica usuário', async () => {
    await request(app)
      .post('/api/v1/auth/register')
      .send({ name: 'Test', email: 'login@test.com', password: '123456', role: 'PATIENT' });

    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: 'login@test.com', password: '123456' });
    expect(res.status).toBe(200);
    expect(res.body.token).toBeDefined();
  });

  test('GET /users/me sem token retorna 401', async () => {
    const res = await request(app).get('/api/v1/users/me');
    expect(res.status).toBe(401);
  });

  test('GET /users/me com token retorna perfil', async () => {
    const reg = await request(app)
      .post('/api/v1/auth/register')
      .send({ name: 'Perfil', email: 'perfil@test.com', password: '123456', role: 'PATIENT' });

    const res = await request(app)
      .get('/api/v1/users/me')
      .set('Authorization', `Bearer ${reg.body.token}`);
    expect(res.status).toBe(200);
    expect(res.body.email).toBe('perfil@test.com');
  });

  test('CRUD de medicamentos (PATIENT)', async () => {
    const reg = await request(app)
      .post('/api/v1/auth/register')
      .send({ name: 'Med', email: 'med@test.com', password: '123456', role: 'PATIENT' });
    const token = reg.body.token;

    const create = await request(app)
      .post('/api/v1/medications')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Paracetamol', dosage: '500mg', schedule: '08:00', frequency: 'daily' });
    expect(create.status).toBe(201);
    medicationId = create.body.id;

    const list = await request(app)
      .get('/api/v1/medications')
      .set('Authorization', `Bearer ${token}`);
    expect(list.status).toBe(200);
    expect(list.body.length).toBe(1);

    const patch = await request(app)
      .patch(`/api/v1/medications/${medicationId}`)
      .set('Authorization', `Bearer ${token}`)
      .send({ dosage: '750mg' });
    expect(patch.status).toBe(200);
    expect(patch.body.dosage).toBe('750mg');
  });

  test('Cuidador não acessa medicamentos (403)', async () => {
    const reg = await request(app)
      .post('/api/v1/auth/register')
      .send({ name: 'CG', email: 'cg@test.com', password: '123456', role: 'CAREGIVER' });

    const res = await request(app)
      .get('/api/v1/medications')
      .set('Authorization', `Bearer ${reg.body.token}`);
    expect(res.status).toBe(403);
  });

  test('Confirmar dose e consultar aderência', async () => {
    const reg = await request(app)
      .post('/api/v1/auth/register')
      .send({ name: 'Dose', email: 'dose@test.com', password: '123456', role: 'PATIENT' });
    const token = reg.body.token;

    const med = await request(app)
      .post('/api/v1/medications')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Vitamina D', dosage: '1000UI', schedule: '09:00', frequency: 'daily' });

    const adherenceBefore = await request(app)
      .get('/api/v1/doses/adherence')
      .set('Authorization', `Bearer ${token}`);
    doseId = adherenceBefore.body.doses[0].id;

    const confirm = await request(app)
      .post(`/api/v1/doses/${doseId}/confirm`)
      .set('Authorization', `Bearer ${token}`)
      .send({ status: 'TAKEN' });
    expect(confirm.status).toBe(200);
    expect(confirm.body.status).toBe('TAKEN');

    const adherence = await request(app)
      .get('/api/v1/doses/adherence')
      .set('Authorization', `Bearer ${token}`);
    expect(adherence.body.summary.taken).toBe(1);
    expect(adherence.body.adherenceRate).toBe(100);
  });

  test('Fluxo de vínculo paciente-cuidador', async () => {
    const patient = await request(app)
      .post('/api/v1/auth/register')
      .send({ name: 'Pac', email: 'pac@test.com', password: '123456', role: 'PATIENT' });

    const caregiver = await request(app)
      .post('/api/v1/auth/register')
      .send({ name: 'Cui', email: 'cui@test.com', password: '123456', role: 'CAREGIVER' });

    const invite = await request(app)
      .post('/api/v1/links/invite-code')
      .set('Authorization', `Bearer ${patient.body.token}`);
    expect(invite.status).toBe(201);
    inviteCode = invite.body.inviteCode;

    const accept = await request(app)
      .post('/api/v1/links/accept')
      .set('Authorization', `Bearer ${caregiver.body.token}`)
      .send({ inviteCode });
    expect(accept.status).toBe(200);
    expect(accept.body.link.status).toBe('ACTIVE');

    const patients = await request(app)
      .get('/api/v1/links/patients')
      .set('Authorization', `Bearer ${caregiver.body.token}`);
    expect(patients.status).toBe(200);
    expect(patients.body.length).toBe(1);
  });

  test('Cuidador consulta medicamentos e aderência do paciente vinculado', async () => {
    const patient = await request(app)
      .post('/api/v1/auth/register')
      .send({ name: 'Ana Paciente', email: 'ana@test.com', password: '123456', role: 'PATIENT' });

    const caregiver = await request(app)
      .post('/api/v1/auth/register')
      .send({ name: 'Carlos Cuidador', email: 'carlos@test.com', password: '123456', role: 'CAREGIVER' });

    const invite = await request(app)
      .post('/api/v1/links/invite-code')
      .set('Authorization', `Bearer ${patient.body.token}`);

    await request(app)
      .post('/api/v1/links/accept')
      .set('Authorization', `Bearer ${caregiver.body.token}`)
      .send({ inviteCode: invite.body.inviteCode });

    await request(app)
      .post('/api/v1/medications')
      .set('Authorization', `Bearer ${patient.body.token}`)
      .send({ name: 'Losartana', dosage: '50mg', schedule: '08:00', frequency: 'daily' });

    const patientId = patient.body.user.id;

    const overview = await request(app)
      .get(`/api/v1/links/patients/${patientId}/overview`)
      .set('Authorization', `Bearer ${caregiver.body.token}`);
    expect(overview.status).toBe(200);
    expect(overview.body.medications.length).toBe(1);
    expect(overview.body.medications[0].name).toBe('Losartana');
    expect(overview.body.adherence.summary.total).toBe(1);

    const blocked = await request(app)
      .get('/api/v1/links/patients/00000000-0000-0000-0000-000000000000/overview')
      .set('Authorization', `Bearer ${caregiver.body.token}`);
    expect(blocked.status).toBe(404);
  });

  test('Consentimentos e exportação de dados (LGPD)', async () => {
    const reg = await request(app)
      .post('/api/v1/auth/register')
      .send({ name: 'LGPD', email: 'lgpd@test.com', password: '123456', role: 'PATIENT' });
    const token = reg.body.token;

    const consent = await request(app)
      .post('/api/v1/users/me/consents')
      .set('Authorization', `Bearer ${token}`)
      .send({ type: 'DATA_PROCESSING' });
    expect(consent.status).toBe(201);

    const consents = await request(app)
      .get('/api/v1/users/me/consents')
      .set('Authorization', `Bearer ${token}`);
    expect(consents.body.length).toBe(1);

    const exportData = await request(app)
      .post('/api/v1/users/me/data-export')
      .set('Authorization', `Bearer ${token}`);
    expect(exportData.status).toBe(201);
    expect(exportData.body.data.user).toBeDefined();
  });

  test('Preferências de notificações', async () => {
    const reg = await request(app)
      .post('/api/v1/auth/register')
      .send({ name: 'Notif', email: 'notif@test.com', password: '123456', role: 'PATIENT' });
    const token = reg.body.token;

    const get = await request(app)
      .get('/api/v1/users/me/notifications')
      .set('Authorization', `Bearer ${token}`);
    expect(get.status).toBe(200);
    expect(get.body.enabled).toBe(true);

    const patch = await request(app)
      .patch('/api/v1/users/me/notifications')
      .set('Authorization', `Bearer ${token}`)
      .send({ enabled: false, remindBeforeMinutes: 15 });
    expect(patch.status).toBe(200);
    expect(patch.body.enabled).toBe(false);
    expect(patch.body.remindBeforeMinutes).toBe(15);
  });

  test('DELETE /users/me exclui conta', async () => {
    const reg = await request(app)
      .post('/api/v1/auth/register')
      .send({ name: 'Del', email: 'del@test.com', password: '123456', role: 'PATIENT' });

    const del = await request(app)
      .delete('/api/v1/users/me')
      .set('Authorization', `Bearer ${reg.body.token}`);
    expect(del.status).toBe(204);

    const me = await request(app)
      .get('/api/v1/users/me')
      .set('Authorization', `Bearer ${reg.body.token}`);
    expect(me.status).toBe(404);
  });
});
