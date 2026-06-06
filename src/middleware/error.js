function notFound(req, res) {
  res.status(404).json({
    code: 'NOT_FOUND',
    message: `Rota ${req.method} ${req.originalUrl} não encontrada`,
  });
}

function errorHandler(err, req, res, _next) {
  console.error(err);

  // Firestore não criado/ativado no projeto Firebase (gRPC NOT_FOUND)
  const msg = typeof err.message === 'string' ? err.message : '';

  if (err.code === 5 || msg.includes('NOT_FOUND')) {
    return res.status(503).json({
      code: 'FIRESTORE_NOT_AVAILABLE',
      message:
        'Firestore não está disponível. No Firebase Console, crie o banco em Firestore Database (modo Nativo).',
    });
  }

  if (err.code === 7 || msg.includes('PERMISSION_DENIED')) {
    const apiDisabled = msg.includes('SERVICE_DISABLED') || msg.includes('has not been used');
    if (apiDisabled) {
      return res.status(503).json({
        code: 'FIRESTORE_API_DISABLED',
        message:
          'Habilite a API Cloud Firestore no projeto lembresaude-a5547: https://console.developers.google.com/apis/api/firestore.googleapis.com/overview?project=lembresaude-a5547',
      });
    }
    return res.status(503).json({
      code: 'FIRESTORE_PERMISSION_DENIED',
      message:
        'A conta de serviço não tem permissão no Firestore. No Google Cloud IAM, adicione a role "Cloud Datastore User" para firebase-adminsdk-fbsvc@lembresaude-a5547.iam.gserviceaccount.com',
    });
  }

  res.status(err.status || 500).json({
    code: err.code || 'INTERNAL_ERROR',
    message: err.message || 'Erro interno do servidor',
  });
}

module.exports = { notFound, errorHandler };
