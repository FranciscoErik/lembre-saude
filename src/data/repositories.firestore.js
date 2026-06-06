const { getFirestore } = require('./firebase');

const COL = {
  users: 'users',
  medications: 'medications',
  doses: 'doses',
  links: 'links',
  consents: 'consents',
  dataExports: 'data_exports',
  notificationSettings: 'notification_settings',
};

function docToUser(id, data) {
  if (!data) return null;
  return {
    id,
    name: data.name,
    email: data.email,
    passwordHash: data.passwordHash,
    role: data.role,
    createdAt: data.createdAt,
  };
}

function docToMedication(id, data) {
  if (!data) return null;
  return {
    id,
    userId: data.userId,
    name: data.name,
    dosage: data.dosage,
    schedule: data.schedule,
    frequency: data.frequency,
    active: data.active ?? true,
    createdAt: data.createdAt,
    updatedAt: data.updatedAt ?? null,
  };
}

function docToDose(id, data) {
  if (!data) return null;
  return {
    id,
    medicationId: data.medicationId,
    scheduledTime: data.scheduledTime,
    status: data.status,
    confirmedAt: data.confirmedAt ?? null,
    createdAt: data.createdAt,
  };
}

function docToLink(id, data) {
  if (!data) return null;
  return {
    id,
    patientId: data.patientId,
    caregiverId: data.caregiverId ?? null,
    inviteCode: data.inviteCode,
    status: data.status,
    createdAt: data.createdAt,
    acceptedAt: data.acceptedAt ?? null,
  };
}

function docToConsent(id, data) {
  if (!data) return null;
  return {
    id,
    userId: data.userId,
    type: data.type,
    grantedAt: data.grantedAt,
    revokedAt: data.revokedAt ?? null,
  };
}

function docToNotificationSettings(id, data) {
  if (!data) return null;
  return {
    userId: id,
    enabled: data.enabled ?? true,
    remindBeforeMinutes: data.remindBeforeMinutes ?? 0,
    updatedAt: data.updatedAt,
  };
}

async function findUserByEmail(email) {
  const db = getFirestore();
  const snap = await db
    .collection(COL.users)
    .where('emailLower', '==', email.toLowerCase())
    .limit(1)
    .get();
  if (snap.empty) return null;
  const doc = snap.docs[0];
  return docToUser(doc.id, doc.data());
}

async function findUserById(id) {
  const doc = await getFirestore().collection(COL.users).doc(id).get();
  if (!doc.exists) return null;
  return docToUser(doc.id, doc.data());
}

async function createUser(user) {
  const db = getFirestore();
  await db
    .collection(COL.users)
    .doc(user.id)
    .set({
      name: user.name,
      email: user.email,
      emailLower: user.email.toLowerCase(),
      passwordHash: user.passwordHash,
      role: user.role,
      createdAt: user.createdAt,
    });
  return findUserById(user.id);
}

async function deleteUser(id) {
  const db = getFirestore();
  const batch = db.batch();

  const meds = await db.collection(COL.medications).where('userId', '==', id).get();
  for (const medDoc of meds.docs) {
    const doses = await db
      .collection(COL.doses)
      .where('medicationId', '==', medDoc.id)
      .get();
    doses.docs.forEach((d) => batch.delete(d.ref));
    batch.delete(medDoc.ref);
  }

  const consents = await db.collection(COL.consents).where('userId', '==', id).get();
  consents.docs.forEach((d) => batch.delete(d.ref));

  const linksPatient = await db.collection(COL.links).where('patientId', '==', id).get();
  linksPatient.docs.forEach((d) => batch.delete(d.ref));

  const linksCaregiver = await db.collection(COL.links).where('caregiverId', '==', id).get();
  linksCaregiver.docs.forEach((d) => batch.delete(d.ref));

  const exports = await db.collection(COL.dataExports).where('userId', '==', id).get();
  exports.docs.forEach((d) => batch.delete(d.ref));

  batch.delete(db.collection(COL.notificationSettings).doc(id));
  batch.delete(db.collection(COL.users).doc(id));

  await batch.commit();
}

async function findMedicationsByUserId(userId) {
  const snap = await getFirestore()
    .collection(COL.medications)
    .where('userId', '==', userId)
    .get();
  return snap.docs.map((d) => docToMedication(d.id, d.data()));
}

async function findMedicationById(id) {
  const doc = await getFirestore().collection(COL.medications).doc(id).get();
  if (!doc.exists) return null;
  return docToMedication(doc.id, doc.data());
}

async function createMedication(medication) {
  await getFirestore()
    .collection(COL.medications)
    .doc(medication.id)
    .set({
      userId: medication.userId,
      name: medication.name,
      dosage: medication.dosage,
      schedule: medication.schedule,
      frequency: medication.frequency,
      active: medication.active ?? true,
      createdAt: medication.createdAt,
    });
  return findMedicationById(medication.id);
}

async function updateMedication(id, fields) {
  const current = await findMedicationById(id);
  if (!current) return null;

  const updated = {
    ...current,
    ...fields,
    updatedAt: new Date().toISOString(),
  };

  await getFirestore()
    .collection(COL.medications)
    .doc(id)
    .update({
      name: updated.name,
      dosage: updated.dosage,
      schedule: updated.schedule,
      frequency: updated.frequency,
      active: updated.active,
      updatedAt: updated.updatedAt,
    });

  return findMedicationById(id);
}

async function deleteMedication(id) {
  const db = getFirestore();
  const batch = db.batch();
  const doses = await db.collection(COL.doses).where('medicationId', '==', id).get();
  doses.docs.forEach((d) => batch.delete(d.ref));
  batch.delete(db.collection(COL.medications).doc(id));
  await batch.commit();
}

async function findDosesByUserId(userId) {
  const meds = await findMedicationsByUserId(userId);
  if (meds.length === 0) return [];

  const db = getFirestore();
  const allDoses = [];
  for (const med of meds) {
    const snap = await db.collection(COL.doses).where('medicationId', '==', med.id).get();
    snap.docs.forEach((d) => allDoses.push(docToDose(d.id, d.data())));
  }
  return allDoses;
}

async function findDoseById(id) {
  const doc = await getFirestore().collection(COL.doses).doc(id).get();
  if (!doc.exists) return null;
  return docToDose(doc.id, doc.data());
}

async function createDose(dose) {
  await getFirestore()
    .collection(COL.doses)
    .doc(dose.id)
    .set({
      medicationId: dose.medicationId,
      scheduledTime: dose.scheduledTime,
      status: dose.status,
      confirmedAt: dose.confirmedAt,
      createdAt: dose.createdAt,
    });
  return findDoseById(dose.id);
}

async function updateDose(dose) {
  await getFirestore().collection(COL.doses).doc(dose.id).update({
    status: dose.status,
    confirmedAt: dose.confirmedAt,
  });
  return findDoseById(dose.id);
}

async function createLink(link) {
  await getFirestore()
    .collection(COL.links)
    .doc(link.id)
    .set({
      patientId: link.patientId,
      caregiverId: link.caregiverId,
      inviteCode: link.inviteCode,
      status: link.status,
      createdAt: link.createdAt,
      acceptedAt: link.acceptedAt,
    });
  return docToLink(link.id, link);
}

async function findPendingLinkByInviteCode(inviteCode) {
  const snap = await getFirestore()
    .collection(COL.links)
    .where('inviteCode', '==', inviteCode)
    .where('status', '==', 'PENDING')
    .limit(1)
    .get();
  if (snap.empty) return null;
  const doc = snap.docs[0];
  return docToLink(doc.id, doc.data());
}

async function updateLink(link) {
  await getFirestore().collection(COL.links).doc(link.id).update({
    caregiverId: link.caregiverId,
    status: link.status,
    acceptedAt: link.acceptedAt,
  });
  return docToLink(link.id, link);
}

async function findActiveLinksByCaregiverId(caregiverId) {
  const snap = await getFirestore()
    .collection(COL.links)
    .where('caregiverId', '==', caregiverId)
    .where('status', '==', 'ACTIVE')
    .get();
  return snap.docs.map((d) => docToLink(d.id, d.data()));
}

async function findConsentsByUserId(userId) {
  const snap = await getFirestore()
    .collection(COL.consents)
    .where('userId', '==', userId)
    .get();
  return snap.docs.map((d) => docToConsent(d.id, d.data()));
}

async function createConsent(consent) {
  await getFirestore().collection(COL.consents).doc(consent.id).set({
    userId: consent.userId,
    type: consent.type,
    grantedAt: consent.grantedAt,
    revokedAt: consent.revokedAt,
  });
  return consent;
}

async function getNotificationSettings(userId) {
  const doc = await getFirestore().collection(COL.notificationSettings).doc(userId).get();
  if (!doc.exists) return null;
  return docToNotificationSettings(doc.id, doc.data());
}

async function upsertNotificationSettings(userId, { enabled, remindBeforeMinutes }) {
  const now = new Date().toISOString();
  const existing = await getNotificationSettings(userId);
  const data = {
    enabled,
    remindBeforeMinutes: remindBeforeMinutes ?? existing?.remindBeforeMinutes ?? 0,
    updatedAt: now,
  };
  await getFirestore().collection(COL.notificationSettings).doc(userId).set(data, { merge: true });
  return getNotificationSettings(userId);
}

async function getOrCreateNotificationSettings(userId) {
  const existing = await getNotificationSettings(userId);
  if (existing) return existing;
  return upsertNotificationSettings(userId, { enabled: true, remindBeforeMinutes: 0 });
}

async function createDataExport(record) {
  await getFirestore()
    .collection(COL.dataExports)
    .doc(record.id)
    .set({
      userId: record.userId,
      requestedAt: record.requestedAt,
      data: record.data,
    });
  return record;
}

module.exports = {
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
