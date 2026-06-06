function validate(schema) {
  return (req, res, next) => {
    const result = schema.safeParse(req.body);
    if (!result.success) {
      const details = result.error.issues.map((i) => ({
        field: i.path.join('.'),
        message: i.message,
      }));
      return res.status(400).json({
        code: 'VALIDATION_ERROR',
        message: 'Dados inválidos',
        details,
      });
    }
    req.validated = result.data;
    next();
  };
}

module.exports = { validate };
