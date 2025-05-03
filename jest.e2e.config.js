module.exports = {
  testMatch: ['**/tests/e2e/**/*.test.js'],
  testTimeout: 30000,
  testEnvironment: 'node',
  setupFilesAfterEnv: ['./tests/setup.js']
};