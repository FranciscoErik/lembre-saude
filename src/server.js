require('dotenv').config();
const app = require('./app');

const PORT = process.env.PORT || 3000;

if (require.main === module) {
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`Lembre Saúde API rodando em http://localhost:${PORT}`);
    console.log(`Swagger UI: http://localhost:${PORT}/api/v1/docs`);
  });
}

module.exports = app;
