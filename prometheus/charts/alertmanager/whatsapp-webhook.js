const express = require('express');
const twilio = require('twilio');
const app = express();

const PORT = process.env.PORT || 3000;
const client = twilio(
  process.env.TWILIO_ACCOUNT_SID,
  process.env.TWILIO_AUTH_TOKEN
);

app.use(express.urlencoded({ extended: true }));

app.post('/webhook', async (req, res) => {
  const { From, Body } = req.body;
  const to = process.env.WHATSAPP_TO;

  try {
    await client.messages.create({
      body: `🔔 Alert: ${Body}`,
      from: process.env.TWILIO_WHATSAPP_FROM,
      to
    });
    console.log(`Message sent to ${to}`);
    res.status(200).send('OK');
  } catch (err) {
    console.error('Failed to send WhatsApp:', err.message);
    res.status(500).send('Error');
  }
});

app.get('/health', (req, res) => {
  res.send('OK');
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
