const { Router } = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { generateId } = require('../data/store');
const repo = require('../data/repositories');
const { validate } = require('../middleware/validate');
const { registerSchema, loginSchema } = require('../validators/schemas');
const { sanitizeUser } = require('../utils/helpers');

const router = Router();

router.post('/register', validate(registerSchema), async (req, res) => {
  const { name, email, password, role } = req.validated;

  const exists = await repo.findUserByEmail(email);
  if (exists) {
    return res.status(409).json({
      code: 'EMAIL_EXISTS',
      message: 'E-mail já cadastrado',
    });
  }

  const passwordHash = await bcrypt.hash(password, 12);
  const user = await repo.createUser({
    id: generateId(),
    name,
    email: email.toLowerCase(),
    passwordHash,
    role,
    createdAt: new Date().toISOString(),
  });

  await repo.getOrCreateNotificationSettings(user.id);

  const token = jwt.sign(
    { id: user.id, email: user.email, role: user.role },
    process.env.JWT_SECRET || 'dev-secret',
    { expiresIn: process.env.JWT_EXPIRES_IN || '24h' }
  );

  res.status(201).json({
    user: sanitizeUser(user),
    token,
  });
});

router.post('/login', validate(loginSchema), async (req, res) => {
  const { email, password } = req.validated;

  const user = await repo.findUserByEmail(email);
  if (!user) {
    return res.status(401).json({
      code: 'INVALID_CREDENTIALS',
      message: 'E-mail ou senha inválidos',
    });
  }

  const valid = await bcrypt.compare(password, user.passwordHash);
  if (!valid) {
    return res.status(401).json({
      code: 'INVALID_CREDENTIALS',
      message: 'E-mail ou senha inválidos',
    });
  }

  const token = jwt.sign(
    { id: user.id, email: user.email, role: user.role },
    process.env.JWT_SECRET || 'dev-secret',
    { expiresIn: process.env.JWT_EXPIRES_IN || '24h' }
  );

  res.json({
    user: sanitizeUser(user),
    token,
  });
});

module.exports = router;
