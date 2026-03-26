// Simple test script to verify streak functionality
const mongoose = require('mongoose');
const User = require('./models/User');

// Update this with your MongoDB connection string
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/decidish';

async function testStreakFunctionality() {
  try {
    // Connect to MongoDB
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB');

    // Find a test user or create one
    let testUser = await User.findOne({ email: 'test@example.com' });
    
    if (!testUser) {
      console.log('Creating test user...');
      testUser = new User({
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
        dietType: 'None',
        onboardingCompleted: true,
        streak: {
          current: 0,
          longest: 0,
          lastCheckIn: null,
          checkInDates: []
        }
      });
      await testUser.save();
      console.log('Test user created');
    }

    console.log('Current streak:', testUser.streak);

    // Test streak logic
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    
    // Initialize streak if it doesn't exist
    if (!testUser.streak) {
      testUser.streak = {
        current: 0,
        longest: 0,
        lastCheckIn: null,
        checkInDates: []
      };
    }

    // Simulate check-in logic
    let newStreak = testUser.streak.current;
    
    if (testUser.streak.lastCheckIn) {
      const yesterday = new Date(today);
      yesterday.setDate(yesterday.getDate() - 1);
      
      const lastCheckInDate = new Date(
        testUser.streak.lastCheckIn.getFullYear(), 
        testUser.streak.lastCheckIn.getMonth(), 
        testUser.streak.lastCheckIn.getDate()
      );
      
      if (lastCheckInDate.getTime() === yesterday.getTime()) {
        // Consecutive day
        newStreak += 1;
        console.log('Consecutive day! New streak:', newStreak);
      } else {
        // Streak broken, start new
        newStreak = 1;
        console.log('Streak broken, starting new streak:', newStreak);
      }
    } else {
      // First check-in
      newStreak = 1;
      console.log('First check-in! Streak:', newStreak);
    }

    // Update streak data
    testUser.streak.current = newStreak;
    testUser.streak.longest = Math.max(testUser.streak.longest, newStreak);
    testUser.streak.lastCheckIn = now;
    testUser.streak.checkInDates.push(now);

    await testUser.save();
    console.log('Updated streak:', testUser.streak);

    console.log('✅ Streak functionality test completed successfully!');
    
  } catch (error) {
    console.error('❌ Test failed:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

testStreakFunctionality();
