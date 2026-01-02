import express from 'express';
import { getEmergencyContacts, addEmergencyContact, deleteEmergencyContact, getAlertSettings, updateAlertSettings } from '../services/emergency.service.js';

const router = express.Router();

router.get('/contacts/:userId', async (req, res) => {
  try {
    const contacts = await getEmergencyContacts(req.params.userId);
    res.json(contacts);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/contacts/:userId', async (req, res) => {
  const { name, phone, relation, priority } = req.body;
  try {
    const contact = await addEmergencyContact(req.params.userId, { name, phone, relation, priority });
    res.status(201).json(contact);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

router.delete('/contacts/:userId/:contactId', async (req, res) => {
  try {
    await deleteEmergencyContact(req.params.userId, req.params.contactId);
    res.json({ message: 'Contact deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/settings/:userId', async (req, res) => {
  try {
    const settings = await getAlertSettings(req.params.userId);
    res.json(settings);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/settings/:userId', async (req, res) => {
  try {
    const settings = await updateAlertSettings(req.params.userId, req.body);
    res.json(settings);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

export default router;
