const express = require('express');
const mongoose = require('mongoose');
const Post = require('../models/Post');
const User = require('../models/User');
const { protect } = require('../middleware/auth');

const router = express.Router();

router.use(protect);

function serializePost(p, userId) {
  const uid = new mongoose.Types.ObjectId(userId);
  const likes = p.likes || [];
  const liked = likes.some((id) => id.equals(uid));
  return {
    id: p._id,
    content: p.content,
    createdAt: p.createdAt,
    likesCount: likes.length,
    likedByMe: liked,
    user: p.user
      ? { id: p.user._id, name: p.user.name, email: p.user.email }
      : null,
  };
}

// Create a post
// POST /api/posts
router.post('/', async (req, res) => {
  try {
    const userId = req.user.id;
    const { content } = req.body;

    if (!content || !content.trim()) {
      return res.status(400).json({ success: false, message: 'Content is required' });
    }

    const post = await Post.create({ user: userId, content: content.trim() });
    await post.populate('user', 'name email');

    res.status(201).json({ success: true, post });
  } catch (error) {
    console.error('Create post error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Get recent posts
// GET /api/posts
router.get('/', async (req, res) => {
  try {
    const posts = await Post.find()
      .sort({ createdAt: -1 })
      .limit(50)
      .populate('user', 'name email');

    const list = posts.map((p) => serializePost(p, req.user.id));

    res.json({ success: true, posts: list });
  } catch (error) {
    console.error('List posts error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// POST /api/posts/:id/like
router.post('/:id/like', async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) {
      return res.status(404).json({ success: false, message: 'Post not found' });
    }
    const uid = new mongoose.Types.ObjectId(req.user.id);
    const has = (post.likes || []).some((id) => id.equals(uid));
    if (!has) {
      post.likes = post.likes || [];
      post.likes.push(uid);
      await post.save();
    }
    await post.populate('user', 'name email');
    res.json({
      success: true,
      ...serializePost(post, req.user.id),
    });
  } catch (error) {
    console.error('Like post error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// DELETE /api/posts/:id/like
router.delete('/:id/like', async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) {
      return res.status(404).json({ success: false, message: 'Post not found' });
    }
    const uid = req.user.id;
    post.likes = (post.likes || []).filter((id) => id.toString() !== uid);
    await post.save();
    await post.populate('user', 'name email');
    res.json({
      success: true,
      ...serializePost(post, req.user.id),
    });
  } catch (error) {
    console.error('Unlike post error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;
