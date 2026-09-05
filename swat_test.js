const https = require('https');

function sendWhatsAppMessage(recipientPhone, messageText) {
    const token = process.env.META_WHATSAPP_ACCESS_TOKEN;
    const phoneId = '1252720684596029';

    if (!token) {
        throw new Error('META_WHATSAPP_ACCESS_TOKEN must be set.');
    }

    const data = JSON.stringify({
        messaging_product: 'whatsapp',
        to: recipientPhone,
        type: 'text',
        text: { body: messageText }
    });

    const options = {
        hostname: 'graph.facebook.com',
        path: '/v18.0/' + phoneId + '/messages',
        method: 'POST',
        headers: {
            'Authorization': 'Bearer ' + token,
            'Content-Type': 'application/json'
        }
    };

    const req = https.request(options, res => {
        let responseBody = '';
        res.on('data', chunk => responseBody += chunk);
        res.on('end', () => console.log('WhatsApp Response:', responseBody));
    });

    req.on('error', error => console.error('Error sending message:', error));
    req.write(data);
    req.end();
}

sendWhatsAppMessage('923299911387', 'Hello from Swat Ride! Your permanent token is successfully configured and working.');
