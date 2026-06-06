const { Router } = require('express');
const { generateId } = require('../data/store');
const repo = require('../data/repositories');
const { authenticate } = require('../middleware/auth');
const { requireRole } = require('../middleware/role');
const { validate } = require('../middleware/validate');
const { medicationSchema, medicationPatchSchema } = require('../validators/schemas');
const { findMedicationsByUserId, ownsMedication } = require('../utils/helpers');

const router = Router();

router.use(authenticate, requireRole('PATIENT'));

router.get('/', async (req, res) => {
  const medications = await findMedicationsByUserId(req.user.id);
  res.json(medications);
});

router.post('/', validate(medicationSchema), async (req, res) => {
  const medication = await repo.createMedication({
    id: generateId(),
    userId: req.user.id,
    ...req.validated,
    active: req.validated.active ?? true,
    createdAt: new Date().toISOString(),
  });

  await repo.createDose({
    id: generateId(),
    medicationId: medication.id,
    scheduledTime: medication.schedule,
    status: 'PENDING',
    confirmedAt: null,
    createdAt: new Date().toISOString(),
  });

  res.status(201).json(medication);
});

router.patch('/:id', validate(medicationPatchSchema), async (req, res) => {
  if (!(await ownsMedication(req.user.id, req.params.id))) {
    return res.status(404).json({
      code: 'NOT_FOUND',
      message: 'Medicamento não encontrado',
    });
  }

  const updated = await repo.updateMedication(req.params.id, req.validated);
  res.json(updated);
});

router.delete('/:id', async (req, res) => {
  if (!(await ownsMedication(req.user.id, req.params.id))) {
    return res.status(404).json({
      code: 'NOT_FOUND',
      message: 'Medicamento não encontrado',
    });
  }

  await repo.deleteMedication(req.params.id);
  res.status(204).send();
});

module.exports = router;
