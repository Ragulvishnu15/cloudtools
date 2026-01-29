// https://raw.githubusercontent.com/Ragulvishnu15/cloudtools/main/prometheus/charts/alertmanager/whatsapp-webhook.js
const express = require('express');
const twilio = require('twilio');
const app = express();
const PORT = process.env.PORT || 3000;

const client = twilio(
  process.env.TWILIO_ACCOUNT_SID,
  process.env.TWILIO_AUTH_TOKEN
);

// Parse JSON (Alertmanager sends JSON)
app.use(express.json());

app.post('/webhook', async (req, res) => {
  try {
    const alerts = req.body.alerts || [];
    if (alerts.length === 0) return res.status(200).send('OK');

    const messages = alerts.map(a => {
      const summary = a.annotations?.summary || 'No summary';
      const status = a.status === 'resolved' ? '✅ Resolved' : '🚨 Firing';
      return `${status}: ${summary}`;
    });

    const fullMsg = `🔔 Prometheus Alert\n\n${messages.join('\n')}`;
    const to = process.env.WHATSAPP_TO;
    const from = process.env.WHATSAPP_FROM; // ← Must match your secret key

    await client.messages.create({ body: fullMsg, from, to });
    console.log(`Sent to ${to}: ${fullMsg}`);
    res.status(200).send('OK');
  } catch (err) {
    console.error('WhatsApp send failed:', err.message);
    res.status(500).send('Error');
  }
});

app.get('/health', (req, res) => res.send('OK'));
app.listen(PORT, () => console.log(`Webhook running on ${PORT}`));
