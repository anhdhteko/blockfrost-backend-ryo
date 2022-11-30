import { getInstance } from '../../utils';
import fixtures from '../../fixtures/mainnet/nutlink';
import { describe, test, expect } from 'vitest';

describe('nutlink endpoint', () => {
  fixtures.map(fixture => {
    fixture.endpoints.map(async endpoint => {
      test(fixture.testName, async () => {
        const client = getInstance();
        const response = await client.get(endpoint).json();

        expect(response).toStrictEqual(fixture.response);
      });
    });
  });
});