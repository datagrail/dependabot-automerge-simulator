const axios = require('axios');

async function fetchAll(urls) {
  return Promise.all(urls.map((url) => axios.get(url)))
    .then((responses) => responses.map((r) => r.data));
}

module.exports = { fetchAll };
