const axios = require('axios');
const { fetchAll } = require('./src/api_client');

test('arithmetic', () => {
  expect(1 + 1).toBe(2);
});

test('string', () => {
  expect('hello'.toUpperCase()).toBe('HELLO');
});

describe('fetchAll', () => {
  beforeAll(() => {
    jest.spyOn(axios, 'get').mockImplementation((url) =>
      Promise.resolve({ data: `response for ${url}` })
    );
    jest.spyOn(axios, 'all').mockImplementation((promises) => Promise.all(promises));
  });

  afterAll(() => {
    jest.restoreAllMocks();
  });

  test('returns data from multiple urls', async () => {
    const result = await fetchAll(['http://a.com', 'http://b.com']);
    expect(result).toEqual(['response for http://a.com', 'response for http://b.com']);
  });
});
