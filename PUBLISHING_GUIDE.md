# Complete Publishing Guide for DeciDish App

## 📊 Data Storage Overview

### Where Data is Stored

#### 1. **Backend Database (MongoDB)**
All persistent data is stored in MongoDB:

- **Users Collection** (`User` model)
  - User profiles (name, email, password hash)
  - Diet preferences (dietType, allergies, dislikedIngredients, preferredCuisines, calorieRange)
  - Onboarding status

- **Meals Collection** (`Meal` model)
  - Meal information (name, description, imageUrl)
  - Nutrition data (calories, protein, carbs, fat)
  - Diet types, cuisine, ingredients, tags
  - Preparation time and difficulty

- **Favorites Collection** (`Favorite` model)
  - User-meal relationships for favorited meals
  - Links user ID to meal ID

- **History Collection** (`History` model)
  - Meal history for each user
  - Date, rating, and notes for each meal consumed

#### 2. **Local Storage (Flutter App)**
- **Authentication Token** - Stored in `shared_preferences`
  - Location: Device local storage
  - Purpose: Maintains user session
  - File: `lib/services/auth_service.dart`

#### 3. **Assets (App Bundle)**
- **Logo Image** - `assets/logo.png`
  - Included in app bundle
  - Used across all screens

---

## 🚀 Step-by-Step: Making Your App Ready for Publishing

### Phase 1: Backend Setup & Configuration

#### Step 1.1: Production Database Setup
1. **Set up MongoDB Atlas Production Cluster**
   - Go to MongoDB Atlas
   - Create a production cluster (M10 or higher for production)
   - Create a production database user
   - Whitelist your production server IPs
   - Get production connection string

2. **Update Backend Environment Variables**
   ```bash
   cd backend
   # Edit .env file
   ```
   ```env
   NODE_ENV=production
   MONGODB_URI=mongodb+srv://username:password@production-cluster.mongodb.net/decidish
   JWT_SECRET=your-very-secure-random-secret-key-min-32-characters
   JWT_EXPIRE=7d
   PORT=3000
   ```

#### Step 1.2: Backend Deployment
Choose one of these options:

**Option A: Deploy to Heroku**
```bash
cd backend
heroku create decidish-backend
heroku config:set MONGODB_URI=your-production-uri
heroku config:set JWT_SECRET=your-secret
heroku config:set NODE_ENV=production
git push heroku main
```

**Option B: Deploy to Railway**
1. Connect your GitHub repo
2. Set environment variables
3. Deploy automatically

**Option C: Deploy to DigitalOcean/AWS**
- Set up Node.js server
- Install PM2: `npm install -g pm2`
- Run: `pm2 start server.js --name decidish-api`
- Set up reverse proxy (nginx)

#### Step 1.3: Update API URL in Flutter App
1. Open `lib/config/api_config.dart`
2. Update `baseUrl` to your production backend URL:
   ```dart
   static String get baseUrl {
     // Production URL
     return 'https://your-backend-domain.com';
   }
   ```

---

### Phase 2: Flutter App Configuration

#### Step 2.1: Update App Information
1. **Update `pubspec.yaml`**
   ```yaml
   name: decidish
   description: "DeciDish - Your personal meal recommendation app"
   version: 1.0.0+1  # Update version for each release
   ```

2. **Update App Icons**
   - Android: Replace icons in `android/app/src/main/res/mipmap-*/`
   - iOS: Replace icons in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
   - Use your logo image

3. **Update App Name**
   - Android: `android/app/src/main/AndroidManifest.xml`
     ```xml
     <application android:label="DeciDish">
     ```
   - iOS: `ios/Runner/Info.plist`
     ```xml
     <key>CFBundleDisplayName</key>
     <string>DeciDish</string>
     ```

#### Step 2.2: Configure App Permissions
1. **Android** (`android/app/src/main/AndroidManifest.xml`)
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   ```

2. **iOS** (`ios/Runner/Info.plist`)
   ```xml
   <key>NSAppTransportSecurity</key>
   <dict>
     <key>NSAllowsArbitraryLoads</key>
     <false/>
   </dict>
   ```

#### Step 2.3: Set Up Signing
1. **Android Signing**
   ```bash
   # Generate keystore
   keytool -genkey -v -keystore ~/decidish-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias decidish
   
   # Create key.properties in android/
   ```
   ```properties
   storePassword=your-password
   keyPassword=your-password
   keyAlias=decidish
   storeFile=/path/to/decidish-key.jks
   ```

2. **iOS Signing**
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select Runner → Signing & Capabilities
   - Select your team and provisioning profile

---

### Phase 3: Testing & Quality Assurance

#### Step 3.1: Test Checklist
- [ ] User registration works
- [ ] User login works
- [ ] Logout works correctly
- [ ] Meal recommendations load
- [ ] Favorites can be added/removed
- [ ] History displays correctly
- [ ] Profile displays user data
- [ ] Home screen loads all sections
- [ ] Navigation works between screens
- [ ] Error handling works (network errors, etc.)
- [ ] App works on different screen sizes
- [ ] Test on both Android and iOS devices

#### Step 3.2: Performance Testing
- [ ] App loads quickly (< 3 seconds)
- [ ] API calls are optimized
- [ ] Images load efficiently
- [ ] No memory leaks
- [ ] Smooth animations

#### Step 3.3: Security Testing
- [ ] Passwords are hashed (backend)
- [ ] JWT tokens are secure
- [ ] API endpoints require authentication where needed
- [ ] No sensitive data in logs
- [ ] HTTPS is used in production

---

### Phase 4: Build for Production

#### Step 4.1: Build Android APK/AAB
```bash
# Build APK
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release
```

Output:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

#### Step 4.2: Build iOS
```bash
# Build iOS
flutter build ios --release

# Then open Xcode and archive
open ios/Runner.xcworkspace
```

In Xcode:
1. Product → Archive
2. Distribute App
3. Choose App Store Connect

---

### Phase 5: App Store Submission

#### Step 5.1: Google Play Store

1. **Create Developer Account**
   - Go to https://play.google.com/console
   - Pay $25 one-time fee
   - Complete account setup

2. **Create App Listing**
   - App name: DeciDish
   - Short description: "Personal meal recommendation app"
   - Full description: Write compelling description
   - Screenshots: Take screenshots of all screens
   - App icon: Use your logo
   - Feature graphic: 1024x500px banner

3. **Upload AAB**
   - Go to Production → Create new release
   - Upload your `.aab` file
   - Add release notes

4. **Content Rating**
   - Complete content rating questionnaire
   - Usually rated "Everyone"

5. **Submit for Review**
   - Review all information
   - Submit app

#### Step 5.2: Apple App Store

1. **Create Developer Account**
   - Go to https://developer.apple.com
   - Pay $99/year fee
   - Complete enrollment

2. **Create App in App Store Connect**
   - Go to https://appstoreconnect.apple.com
   - Create new app
   - Fill in app information
   - Upload screenshots
   - Set pricing

3. **Upload Build**
   - Use Xcode or Transporter app
   - Upload your `.ipa` file
   - Wait for processing

4. **Submit for Review**
   - Complete all required information
   - Submit for review

---

### Phase 6: Post-Launch

#### Step 6.1: Monitor Your App
- Set up error tracking (Sentry, Firebase Crashlytics)
- Monitor API performance
- Track user analytics

#### Step 6.2: Update Backend
- Monitor server logs
- Set up automated backups for MongoDB
- Scale resources as needed

#### Step 6.3: Marketing
- Create app website
- Social media presence
- App Store Optimization (ASO)
- User feedback collection

---

## 📋 Pre-Publishing Checklist

### Backend
- [ ] Production MongoDB cluster set up
- [ ] Environment variables configured
- [ ] Backend deployed and accessible
- [ ] API endpoints tested
- [ ] CORS configured for production domain
- [ ] SSL/HTTPS enabled
- [ ] Database backups configured
- [ ] Error logging set up

### Flutter App
- [ ] API URL updated to production
- [ ] App name and description updated
- [ ] App icons replaced
- [ ] Version number updated
- [ ] Signing configured (Android & iOS)
- [ ] Permissions configured
- [ ] All features tested
- [ ] Error handling implemented
- [ ] Loading states implemented
- [ ] Offline error messages user-friendly

### Assets
- [ ] Logo image optimized
- [ ] App icons for all platforms
- [ ] Screenshots prepared
- [ ] App Store graphics ready

### Legal & Privacy
- [ ] Privacy Policy created
- [ ] Terms of Service created
- [ ] Privacy Policy URL added to app stores
- [ ] Data collection disclosed

---

## 🔧 Configuration Files Summary

### Backend Files
- `backend/.env` - Environment variables (NEVER commit)
- `backend/server.js` - Main server file
- `backend/models/` - Database models
- `backend/routes/` - API routes

### Flutter Files
- `lib/config/api_config.dart` - API configuration
- `lib/services/` - API service classes
- `lib/models/` - Data models
- `lib/screens/` - UI screens
- `pubspec.yaml` - Dependencies and app info
- `android/app/build.gradle` - Android build config
- `ios/Runner/Info.plist` - iOS configuration

---

## 🎯 Quick Start Commands

### Development
```bash
# Start backend
cd backend
npm run dev

# Run Flutter app
flutter run
```

### Production Build
```bash
# Android
flutter build appbundle --release

# iOS
flutter build ios --release
```

### Testing
```bash
# Run tests
flutter test

# Check for issues
flutter analyze
```

---

## 📞 Support & Troubleshooting

### Common Issues

1. **API Connection Errors**
   - Check backend is running
   - Verify API URL in `api_config.dart`
   - Check CORS settings

2. **Build Errors**
   - Run `flutter clean`
   - Run `flutter pub get`
   - Check signing configuration

3. **App Store Rejection**
   - Review App Store guidelines
   - Fix any policy violations
   - Resubmit with fixes

---

## 🎉 You're Ready!

Once you complete all these steps, your app will be ready for publishing. Good luck with your launch! 🚀
