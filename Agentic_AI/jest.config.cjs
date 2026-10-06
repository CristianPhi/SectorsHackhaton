module.exports = {
  preset: 'ts-jest/presets/default-esm',
  testEnvironment: 'node',
  rootDir: '.',
  testRegex: '.*\\.spec\\.ts$',
  extensionsToTreatAsEsm: ['.ts'],
  transform: {
    '^.+\\.tsx?$': ['ts-jest', { useESM: true, tsconfig: { module: 'nodenext', moduleResolution: 'nodenext' } }],
  },
  transformIgnorePatterns: [
    '/node_modules/(?!(?:@nestjs|rxjs|tslib|file-type|iterare|@standard-schema|uuid|mongodb|bson|mongoose|axios|class-transformer|class-validator|reflect-metadata|@google/genai|openai)/)',
  ],
  testPathIgnorePatterns: ['/node_modules/'],
};
