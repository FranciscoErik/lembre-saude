function requireRole(...roles) {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return res.status(403).json({
        code: 'FORBIDDEN',
        message: 'Acesso negado para este perfil',
      });
    }
    next();
  };
}

module.exports = { requireRole };
