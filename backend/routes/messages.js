const express = require('express');
const Message = require('../models/Message');
const User = require('../models/User');
const { protect } = require('../middleware/auth');

const router = express.Router();

router.use(protect);

// Send a message to a friend
// POST /api/messages
router.post('/', async (req, res) => {
  try {
    const senderId = req.user.id;
    const { toUserId, content } = req.body;

    if (!toUserId || !content) return res.status(400).json({ success: false, message: 'toUserId and content are required' });
    if (toUserId === senderId) return res.status(400).json({ success: false, message: 'Cannot message yourself' });

    // Ensure recipient exists
    const recipient = await User.findById(toUserId);
    if (!recipient) return res.status(404).json({ success: false, message: 'Recipient not found' });

    // Ensure they are friends
    const areFriends = await User.findOne({ _id: senderId, friends: toUserId });
    if (!areFriends) return res.status(403).json({ success: false, message: 'Can only message friends' });

    const message = new Message({ sender: senderId, recipient: toUserId, content });
    await message.save();

    res.json({ success: true, message: message });
  } catch (error) {
    console.error('Send message error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Get messages between current user and another user
// GET /api/messages/:userId
router.get('/:userId', async (req, res) => {
  try {
    const userA = req.user.id;
    const userB = req.params.userId;

    // Ensure they are friends
    const areFriends = await User.findOne({ _id: userA, friends: userB });
    if (!areFriends) return res.status(403).json({ success: false, message: 'Can only view messages with friends' });

    const messages = await Message.find({
      $or: [
        { sender: userA, recipient: userB },
        { sender: userB, recipient: userA },
      ],
    }).sort('createdAt');

    res.json({ success: true, messages });
  } catch (error) {
    console.error('Get messages error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;
