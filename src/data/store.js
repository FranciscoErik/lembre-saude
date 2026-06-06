const crypto = require('crypto');

function generateId() {
  return crypto.randomUUID();
}

/** Limpa dados em memória (apenas nos testes). */
function resetStore() {
  const useMemory =
    process.env.DATA_STORE === 'memory' || process.env.NODE_ENV === 'test';
  if (useMemory) {
    const { resetStore: resetMemory } = require('./repositories.memory');
    resetMemory();
  }
}

module.exports = { generateId, resetStore };
