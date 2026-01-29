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
    if (alerts.length === 0) {
      console.warn('No alerts in payload');
      return res.status(200).send('OK');
    }

    const messages = [];
    for (const alert of alerts) {
      const summary = alert.annotations?.summary || 'No summary';
      const status = alert.status === 'resolved' ? '✅ Resolved' : '🚨 Firing';
      const labels = Object.entries(alert.labels || {})
        .map(([k, v]) => `${k}=${v}`)
        .join(', ');
      messages.push(`${status}: ${summary}\nLabels: ${labels}`);
    }

    const fullMessage = `🔔 Prometheus Alert\n\n${messages.join('\n\n')}`;
    const to = process.env.WHATSAPP_TO;
    const from = process.env.WHATSAPP_FROM || process.env.TWILIO_WHATSAPP_FROM;

    await client.messages.create({
      body: fullMessage,
      from: from,
      to: to
    });

    console.log(`WhatsApp sent to ${to}: ${fullMessage}`);
    res.status(200).send('OK');
  } catch (err) {
    console.error('Failed to send WhatsApp:', err.message);
    console.error('Stack:', err.stack);
    res.status(500).send('Error');
  }
});

app.get('/health', (req, res) => {
  res.send('OK');
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
