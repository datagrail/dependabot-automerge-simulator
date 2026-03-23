const axios = require('axios');

async function fetchAll(urls) {
  return axios
    .all(urls.map((url) => axios.get(url)))
    .then(axios.spread((...responses) => responses.map((r) => r.data)));
}

module.exports = { fetchAll };
