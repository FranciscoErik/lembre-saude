const { Router } = require('express');
const { generateId } = require('../data/store');
const repo = require('../data/repositories');
const { authenticate } = require('../middleware/auth');
const { requireRole } = require('../middleware/role');
const { validate } = require('../middleware/validate');
const { acceptLinkSchema } = require('../validators/schemas');
const { sanitizeUser, findMedicationsByUserId, findDosesByUserId, caregiverHasActiveLink, buildAdherencePayload } = require('../utils/helpers');

const router = Router();

function generateInviteCode() {
  return Math.random().toString(36).substring(2, 8).toUpperCase();
}

router.post('/invite-code', authenticate, requireRole('PATIENT'), async (req, res) => {
  const inviteCode = generateInviteCode();
  const link = await repo.createLink({
    id: generateId(),
    patientId: req.user.id,
    caregiverId: null,
    inviteCode,
    status: 'PENDING',
    createdAt: new Date().toISOString(),
    acceptedAt: null,
  });

  res.status(201).json({ inviteCode, linkId: link.id, status: link.status });
});

router.post('/accept', authenticate, requireRole('CAREGIVER'), validate(acceptLinkSchema), async (req, res) => {
  const { inviteCode } = req.validated;

  const link = await repo.findPendingLinkByInviteCode(inviteCode);

  if (!link) {
    return res.status(404).json({
      code: 'INVALID_INVITE',
      message: 'Código de convite inválido ou já utilizado',
    });
  }

  const updated = await repo.updateLink({
    ...link,
    caregiverId: req.user.id,
    status: 'ACTIVE',
    acceptedAt: new Date().toISOString(),
  });

  const patient = await repo.findUserById(updated.patientId);
  res.json({
    link: updated,
    patient: sanitizeUser(patient),
  });
});

router.get('/patients', authenticate, requireRole('CAREGIVER'), async (req, res) => {
  const links = await repo.findActiveLinksByCaregiverId(req.user.id);

  const patients = await Promise.all(
    links.map(async (l) => {
      const patient = await repo.findUserById(l.patientId);
      return {
        linkId: l.id,
        patient: sanitizeUser(patient),
        linkedAt: l.acceptedAt,
      };
    })
  );

  res.json(patients);
});

router.get('/patients/:patientId/overview', authenticate, requireRole('CAREGIVER'), async (req, res) => {
  const { patientId } = req.params;

  if (!(await caregiverHasActiveLink(req.user.id, patientId))) {
    return res.status(404).json({
      code: 'NOT_FOUND',
      message: 'Paciente não vinculado a este cuidador',
    });
  }

  const patient = await repo.findUserById(patientId);
  if (!patient) {
    return res.status(404).json({
      code: 'NOT_FOUND',
      message: 'Paciente não encontrado',
    });
  }

  const medications = await findMedicationsByUserId(patientId);
  const doses = await findDosesByUserId(patientId);
  const { from, to } = req.query;

  res.json({
    patient: sanitizeUser(patient),
    medications,
    adherence: buildAdherencePayload(doses, { from, to }),
  });
});

module.exports = router;
