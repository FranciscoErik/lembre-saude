require('dotenv').config();

const useMemory =
  process.env.DATA_STORE === 'memory' || process.env.NODE_ENV === 'test';

if (!useMemory) {
  const { initFirebase } = require('./data/firebase');
  initFirebase();
  console.log('Banco de dados: Firebase Firestore');
} else {
  console.log('Banco de dados: memória (testes)');
}

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const swaggerUi = require('swagger-ui-express');
const swaggerDocument = require('./swagger');

const healthRoutes = require('./routes/health');
const authRoutes = require('./routes/auth');
const usersRoutes = require('./routes/users');
const medicationsRoutes = require('./routes/medications');
const dosesRoutes = require('./routes/doses');
const linksRoutes = require('./routes/links');
const { notFound, errorHandler } = require('./middleware/error');

const app = express();

app.use(helmet());
app.use(cors({ origin: process.env.CORS_ORIGIN || '*' }));
app.use(morgan('dev'));
app.use(express.json());

const api = express.Router();
api.use('/health', healthRoutes);
api.use('/auth', authRoutes);
api.use('/users', usersRoutes);
api.use('/medications', medicationsRoutes);
api.use('/doses', dosesRoutes);
api.use('/links', linksRoutes);
api.use('/docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));

app.use('/api/v1', api);
app.use(notFound);
app.use(errorHandler);

module.exports = app;
