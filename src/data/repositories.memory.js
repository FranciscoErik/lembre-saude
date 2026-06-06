/**
 * Repositório em memória — usado nos testes automatizados (npm test).
 */
const store = {
  users: new Map(),
  medications: new Map(),
  doses: new Map(),
  links: new Map(),
  consents: new Map(),
  dataExports: new Map(),
  notificationSettings: new Map(),
};

function resetStore() {
  store.users.clear();
  store.medications.clear();
  store.doses.clear();
  store.links.clear();
  store.consents.clear();
  store.dataExports.clear();
  store.notificationSettings.clear();
}

async function findUserByEmail(email) {
  const normalized = email.toLowerCase();
  return (
    Array.from(store.users.values()).find((u) => u.email.toLowerCase() === normalized) ||
    null
  );
}

async function findUserById(id) {
  return store.users.get(id) || null;
}

async function createUser(user) {
  store.users.set(user.id, user);
  return user;
}

async function deleteUser(id) {
  const medIds = Array.from(store.medications.values())
    .filter((m) => m.userId === id)
    .map((m) => m.id);

  medIds.forEach((medId) => {
    Array.from(store.doses.values())
      .filter((d) => d.medicationId === medId)
      .forEach((d) => store.doses.delete(d.id));
    store.medications.delete(medId);
  });

  Array.from(store.consents.values())
    .filter((c) => c.userId === id)
    .forEach((c) => store.consents.delete(c.id));

  Array.from(store.links.values())
    .filter((l) => l.patientId === id || l.caregiverId === id)
    .forEach((l) => store.links.delete(l.id));

  Array.from(store.dataExports.values())
    .filter((e) => e.userId === id)
    .forEach((e) => store.dataExports.delete(e.id));

  store.notificationSettings.delete(id);
  store.users.delete(id);
}

async function findMedicationsByUserId(userId) {
  return Array.from(store.medications.values()).filter((m) => m.userId === userId);
}

async function findMedicationById(id) {
  return store.medications.get(id) || null;
}

async function createMedication(medication) {
  store.medications.set(medication.id, medication);
  return medication;
}

async function updateMedication(id, fields) {
  const current = store.medications.get(id);
  if (!current) return null;
  const updated = { ...current, ...fields, updatedAt: new Date().toISOString() };
  store.medications.set(id, updated);
  return updated;
}

async function deleteMedication(id) {
  Array.from(store.doses.values())
    .filter((d) => d.medicationId === id)
    .forEach((d) => store.doses.delete(d.id));
  store.medications.delete(id);
}

async function findDosesByUserId(userId) {
  const medIds = Array.from(store.medications.values())
    .filter((m) => m.userId === userId)
    .map((m) => m.id);
  return Array.from(store.doses.values()).filter((d) => medIds.includes(d.medicationId));
}

async function findDoseById(id) {
  return store.doses.get(id) || null;
}

async function createDose(dose) {
  store.doses.set(dose.id, dose);
  return dose;
}

async function updateDose(dose) {
  store.doses.set(dose.id, dose);
  return dose;
}

async function createLink(link) {
  store.links.set(link.id, link);
  return link;
}

async function findLinkById(id) {
  return store.links.get(id) || null;
}

async function findPendingLinkByInviteCode(inviteCode) {
  return (
    Array.from(store.links.values()).find(
      (l) => l.inviteCode === inviteCode && l.status === 'PENDING'
    ) || null
  );
}

async function updateLink(link) {
  store.links.set(link.id, link);
  return link;
}

async function findActiveLinksByCaregiverId(caregiverId) {
  return Array.from(store.links.values()).filter(
    (l) => l.caregiverId === caregiverId && l.status === 'ACTIVE'
  );
}

async function findConsentsByUserId(userId) {
  return Array.from(store.consents.values()).filter((c) => c.userId === userId);
}

async function createConsent(consent) {
  store.consents.set(consent.id, consent);
  return consent;
}

async function getNotificationSettings(userId) {
  return store.notificationSettings.get(userId) || null;
}

async function upsertNotificationSettings(userId, { enabled, remindBeforeMinutes }) {
  const now = new Date().toISOString();
  const existing = store.notificationSettings.get(userId);
  const settings = {
    userId,
    enabled,
    remindBeforeMinutes: remindBeforeMinutes ?? existing?.remindBeforeMinutes ?? 0,
    updatedAt: now,
  };
  store.notificationSettings.set(userId, settings);
  return settings;
}

async function getOrCreateNotificationSettings(userId) {
  const existing = await getNotificationSettings(userId);
  if (existing) return existing;
  return upsertNotificationSettings(userId, { enabled: true, remindBeforeMinutes: 0 });
}

async function createDataExport(record) {
  store.dataExports.set(record.id, record);
  return record;
}

module.exports = {
  resetStore,
  findUserByEmail,
  findUserById,
  createUser,
  deleteUser,
  findMedicationsByUserId,
  findMedicationById,
  createMedication,
  updateMedication,
  deleteMedication,
  findDosesByUserId,
  findDoseById,
  createDose,
  updateDose,
  findPendingLinkByInviteCode,
  createLink,
  updateLink,
  findActiveLinksByCaregiverId,
  findConsentsByUserId,
  createConsent,
  createDataExport,
  getNotificationSettings,
  getOrCreateNotificationSettings,
  upsertNotificationSettings,
};
