const path = require('path');
// `override: true` so values from backend/.env win over empty exports in the shell
// (dotenv’s default is to not override existing env vars).
require('dotenv').config({
  path: path.join(__dirname, '..', '.env'),
  override: true,
});
