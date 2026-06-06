const { Router } = require('express');
const { generateId } = require('../data/store');
const repo = require('../data/repositories');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validate');
const { consentSchema, notificationSettingsSchema } = require('../validators/schemas');
const { sanitizeUser, findMedicationsByUserId, findDosesByUserId } = require('../utils/helpers');

const router = Router();

router.get('/me', authenticate, async (req, res) => {
  const user = await repo.findUserById(req.user.id);
  if (!user) {
    return res.status(404).json({ code: 'NOT_FOUND', message: 'Usuário não encontrado' });
  }
  res.json(sanitizeUser(user));
});

router.delete('/me', authenticate, async (req, res) => {
  await repo.deleteUser(req.user.id);
  res.status(204).send();
});

router.get('/me/consents', authenticate, async (req, res) => {
  const consents = await repo.findConsentsByUserId(req.user.id);
  res.json(consents);
});

router.post('/me/consents', authenticate, validate(consentSchema), async (req, res) => {
  const consent = await repo.createConsent({
    id: generateId(),
    userId: req.user.id,
    type: req.validated.type,
    grantedAt: new Date().toISOString(),
    revokedAt: null,
  });
  res.status(201).json(consent);
});

router.get('/me/notifications', authenticate, async (req, res) => {
  const settings = await repo.getOrCreateNotificationSettings(req.user.id);
  res.json(settings);
});

router.patch('/me/notifications', authenticate, validate(notificationSettingsSchema), async (req, res) => {
  const current = await repo.getOrCreateNotificationSettings(req.user.id);
  const settings = await repo.upsertNotificationSettings(req.user.id, {
    enabled: req.validated.enabled,
    remindBeforeMinutes:
      req.validated.remindBeforeMinutes ?? current.remindBeforeMinutes,
  });
  res.json(settings);
});

router.post('/me/data-export', authenticate, async (req, res) => {
  const user = await repo.findUserById(req.user.id);
  const medications = await findMedicationsByUserId(req.user.id);
  const doses = await findDosesByUserId(req.user.id);
  const consents = await repo.findConsentsByUserId(req.user.id);

  const exportRecord = {
    id: generateId(),
    userId: req.user.id,
    requestedAt: new Date().toISOString(),
    data: {
      user: sanitizeUser(user),
      medications,
      doses,
      consents,
    },
  };

  await repo.createDataExport(exportRecord);

  res.status(201).json({
    id: exportRecord.id,
    requestedAt: exportRecord.requestedAt,
    message: 'Exportação de dados solicitada com sucesso',
    data: exportRecord.data,
  });
});

module.exports = router;
