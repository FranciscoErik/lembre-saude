const useMemory =
  process.env.DATA_STORE === 'memory' || process.env.NODE_ENV === 'test';

module.exports = useMemory
  ? require('../repositories.memory')
  : require('../repositories.firestore');
