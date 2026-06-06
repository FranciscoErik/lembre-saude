const { Router } = require('express');
const repo = require('../data/repositories');
const { authenticate } = require('../middleware/auth');
const { requireRole } = require('../middleware/role');
const { validate } = require('../middleware/validate');
const { confirmDoseSchema } = require('../validators/schemas');
const { ownsDose, findDosesByUserId, buildAdherencePayload } = require('../utils/helpers');

const router = Router();

router.use(authenticate, requireRole('PATIENT'));

router.post('/:doseId/confirm', validate(confirmDoseSchema), async (req, res) => {
  if (!(await ownsDose(req.user.id, req.params.doseId))) {
    return res.status(404).json({
      code: 'NOT_FOUND',
      message: 'Dose não encontrada',
    });
  }

  const dose = await repo.findDoseById(req.params.doseId);
  const updated = await repo.updateDose({
    ...dose,
    status: req.validated.status,
    confirmedAt: new Date().toISOString(),
  });

  res.json(updated);
});

router.get('/adherence', async (req, res) => {
  const { from, to } = req.query;
  const doses = await findDosesByUserId(req.user.id);
  res.json(buildAdherencePayload(doses, { from, to }));
});

module.exports = router;
