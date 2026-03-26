const express = require('express');
const FriendRequest = require('../models/FriendRequest');
const User = require('../models/User');
const { protect } = require('../middleware/auth');

const router = express.Router();

router.use(protect);

// Send a friend request
// POST /api/friends/request
router.post('/request', async (req, res) => {
  try {
    const fromId = req.user.id;
    const { toUserId } = req.body;

    if (!toUserId) {
      return res.status(400).json({ success: false, message: 'toUserId is required' });
    }

    if (toUserId === fromId) {
      return res.status(400).json({ success: false, message: 'Cannot send request to yourself' });
    }

    const toUser = await User.findById(toUserId);
    if (!toUser) return res.status(404).json({ success: false, message: 'Recipient not found' });

    // Check already friends
    const alreadyFriends = await User.findOne({ _id: fromId, friends: toUserId });
    if (alreadyFriends) return res.status(400).json({ success: false, message: 'Already friends' });

    // Check existing pending request in either direction
    const existing = await FriendRequest.findOne({
      $or: [
        { from: fromId, to: toUserId },
        { from: toUserId, to: fromId },
      ],
    });
    if (existing) return res.status(400).json({ success: false, message: 'Friend request already exists' });

    const fr = new FriendRequest({ from: fromId, to: toUserId });
    await fr.save();

    res.json({ success: true, request: fr });
  } catch (error) {
    console.error('Send friend request error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Get incoming friend requests
// GET /api/friends/requests
router.get('/requests', async (req, res) => {
  try {
    const incoming = await FriendRequest.find({ to: req.user.id, status: 'pending' }).populate('from', 'name email');
    res.json({ success: true, requests: incoming });
  } catch (error) {
    console.error('Get friend requests error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Accept a friend request
// POST /api/friends/request/:id/accept
router.post('/request/:id/accept', async (req, res) => {
  try {
    const reqId = req.params.id;
    const fr = await FriendRequest.findById(reqId);
    if (!fr) return res.status(404).json({ success: false, message: 'Friend request not found' });
    if (fr.to.toString() !== req.user.id) return res.status(403).json({ success: false, message: 'Not authorized' });
    if (fr.status !== 'pending') return res.status(400).json({ success: false, message: 'Request not pending' });

    fr.status = 'accepted';
    await fr.save();

    // Add to each other's friends list
    await User.findByIdAndUpdate(req.user.id, { $addToSet: { friends: fr.from } });
    await User.findByIdAndUpdate(fr.from, { $addToSet: { friends: req.user.id } });

    res.json({ success: true, message: 'Friend request accepted' });
  } catch (error) {
    console.error('Accept friend request error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Decline a friend request
// POST /api/friends/request/:id/decline
router.post('/request/:id/decline', async (req, res) => {
  try {
    const reqId = req.params.id;
    const fr = await FriendRequest.findById(reqId);
    if (!fr) return res.status(404).json({ success: false, message: 'Friend request not found' });
    if (fr.to.toString() !== req.user.id) return res.status(403).json({ success: false, message: 'Not authorized' });
    if (fr.status !== 'pending') return res.status(400).json({ success: false, message: 'Request not pending' });

    fr.status = 'declined';
    await fr.save();

    res.json({ success: true, message: 'Friend request declined' });
  } catch (error) {
    console.error('Decline friend request error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// List friends
// GET /api/friends
router.get('/', async (req, res) => {
  try {
    const user = await User.findById(req.user.id).populate('friends', 'name email');
    res.json({ success: true, friends: user.friends || [] });
  } catch (error) {
    console.error('List friends error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Remove friend
// DELETE /api/friends/:id
router.delete('/:id', async (req, res) => {
  try {
    const friendId = req.params.id;
    // Remove friend from both users' lists
    await User.findByIdAndUpdate(req.user.id, { $pull: { friends: friendId } });
    await User.findByIdAndUpdate(friendId, { $pull: { friends: req.user.id } });
    res.json({ success: true, message: 'Friend removed' });
  } catch (error) {
    console.error('Remove friend error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;
