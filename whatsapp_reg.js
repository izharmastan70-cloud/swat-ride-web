const https = require('node:https');

const accessToken = process.env.META_WHATSAPP_ACCESS_TOKEN;

if (!accessToken) {
  console.error('Missing META_WHATSAPP_ACCESS_TOKEN environment variable.');
  process.exit(1);
}

const requestBody = JSON.stringify({
  messaging_product: 'whatsapp',
  pin: '123456',
});

const request = https.request({
  hostname: 'graph.facebook.com',
  path: '/v18.0/1252720684598029/register',
  method: 'POST',
  headers: {
    Authorization: `Bearer ${accessToken}`,
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(requestBody),
  },
}, (response) => {
  let responseBody = '';

  response.setEncoding('utf8');
  response.on('data', (chunk) => {
    responseBody += chunk;
  });
  response.on('end', () => {
    console.log(`Status: ${response.statusCode}`);
    console.log(responseBody);
  });
});

request.on('error', (error) => {
  console.error('WhatsApp registration failed:', error.message);
});

request.write(requestBody);
request.end();