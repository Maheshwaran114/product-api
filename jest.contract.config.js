module.exports = {
  testMatch: ['**/tests/contract/**/*.test.js'],
  testEnvironment: 'node',
  setupFilesAfterEnv: ['./tests/setup.js'],
  testTimeout: 10000,
};