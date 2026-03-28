const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/users', require('./routes/users'));
app.use('/api/meals', require('./routes/meals'));
app.use('/api/recommendations', require('./routes/recommendations'));
app.use('/api/favorites', require('./routes/favorites'));
app.use('/api/history', require('./routes/history'));
app.use('/api/friends', require('./routes/friends'));
app.use('/api/messages', require('./routes/messages'));
app.use('/api/posts', require('./routes/posts'));
app.use('/api/feed', require('./routes/feed'));

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', message: 'DeciDish API is running' });
});

// Drop legacy unique index so users can add multiple MealRating rows per meal.
async function ensureMealRatingIndexes() {
  const MealRating = require('./models/MealRating');
  const coll = mongoose.connection.db.collection('mealratings');
  try {
    await coll.dropIndex('user_1_meal_1');
    console.log(
      'Removed legacy unique index mealratings.user_1_meal_1 (multiple reviews per meal enabled).'
    );
  } catch (e) {
    const code = e.code;
    const msg = (e.message || '').toLowerCase();
    const missing =
      code === 27 ||
      code === 125 ||
      msg.includes('index not found') ||
      msg.includes('ns not found');
    if (!missing) {
      console.warn('mealratings dropIndex user_1_meal_1:', e.message);
    }
  }
  try {
    await MealRating.syncIndexes();
  } catch (e) {
    console.warn('MealRating.syncIndexes:', e.message);
  }
}

// Database connection
const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/decidish');
    console.log('MongoDB connected successfully');
    await ensureMealRatingIndexes();
  } catch (error) {
    console.error('MongoDB connection error:', error);
    process.exit(1);
  }
};

connectDB();

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(err.status || 500).json({
    message: err.message || 'Internal Server Error',
    error: process.env.NODE_ENV === 'development' ? err : {},
  });
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
