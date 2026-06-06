const repo = require('../data/repositories');

function sanitizeUser(user) {
  if (!user) return null;
  const { passwordHash, ...safe } = user;
  return safe;
}

async function findMedicationsByUserId(userId) {
  return repo.findMedicationsByUserId(userId);
}

async function findDosesByUserId(userId) {
  return repo.findDosesByUserId(userId);
}

async function ownsMedication(userId, medicationId) {
  const med = await repo.findMedicationById(medicationId);
  return Boolean(med && med.userId === userId);
}

async function ownsDose(userId, doseId) {
  const dose = await repo.findDoseById(doseId);
  if (!dose) return false;
  return ownsMedication(userId, dose.medicationId);
}

async function caregiverHasActiveLink(caregiverId, patientId) {
  const links = await repo.findActiveLinksByCaregiverId(caregiverId);
  return links.some((l) => l.patientId === patientId);
}

function buildAdherencePayload(doses, { from, to } = {}) {
  let filtered = doses;

  if (from) {
    filtered = filtered.filter((d) => new Date(d.scheduledTime || d.createdAt) >= new Date(from));
  }
  if (to) {
    filtered = filtered.filter((d) => new Date(d.scheduledTime || d.createdAt) <= new Date(to));
  }

  const total = filtered.length;
  const taken = filtered.filter((d) => d.status === 'TAKEN').length;
  const skipped = filtered.filter((d) => d.status === 'SKIPPED').length;
  const postponed = filtered.filter((d) => d.status === 'POSTPONED').length;
  const pending = filtered.filter((d) => d.status === 'PENDING').length;

  return {
    period: { from: from || null, to: to || null },
    summary: { total, taken, skipped, postponed, pending },
    adherenceRate: total > 0 ? Math.round((taken / total) * 100) : 0,
    doses: filtered,
  };
}

module.exports = {
  sanitizeUser,
  findMedicationsByUserId,
  findDosesByUserId,
  ownsMedication,
  ownsDose,
  caregiverHasActiveLink,
  buildAdherencePayload,
};
