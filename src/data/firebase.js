const path = require('path');
const admin = require('firebase-admin');

let firestore = null;

function initFirebase() {
  if (firestore) return firestore;

  if (admin.apps.length === 0) {
    if (process.env.FIREBASE_SERVICE_ACCOUNT_PATH) {
      const accountPath = path.resolve(process.cwd(), process.env.FIREBASE_SERVICE_ACCOUNT_PATH);
      // eslint-disable-next-line import/no-dynamic-require, global-require
      const serviceAccount = require(accountPath);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: serviceAccount.project_id,
      });
      console.log(`Firebase projeto: ${serviceAccount.project_id}`);
    } else if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
    } else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      admin.initializeApp({
        credential: admin.credential.applicationDefault(),
      });
    } else {
      throw new Error(
        'Firebase não configurado. Defina FIREBASE_SERVICE_ACCOUNT_PATH no arquivo .env'
      );
    }
  }

  firestore = admin.firestore();
  return firestore;
}

function getFirestore() {
  if (!firestore) {
    return initFirebase();
  }
  return firestore;
}

module.exports = { initFirebase, getFirestore };
