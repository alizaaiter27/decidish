# DeciDish

DeciDish is a Flutter mobile app that helps users decide what to eat through personalized meal recommendations.  
It includes authentication, onboarding-based preference matching, favorites, meal history, social feed/chat surfaces, and streak/check-in support, powered by a Node.js + Express + MongoDB backend.

## Features

- Personalized recommendations based on user preferences
- User onboarding and profile management
- Favorites and meal history tracking
- Daily streak/check-in experience
- Social features (friends, feed, posts, chat, friend requests)
- Push notifications via Firebase Cloud Messaging

## Tech Stack

### Mobile App

- Flutter (Dart)
- Firebase Core + Firebase Messaging
- `http` for API requests
- `shared_preferences` for local token/session storage

### Backend API

- Node.js + Express
- MongoDB + Mongoose
- JWT authentication

## Repository Structure

- `lib/` - Flutter app source (screens, services, models, utils)
- `assets/` - App assets
- `backend/` - Express API and MongoDB integration
- `test/` - Flutter tests
- `android/`, `ios/`, `web/`, `macos/`, `linux/`, `windows/` - Platform runners

## Prerequisites

Install the following before running locally:

- Flutter SDK (with Dart SDK)
- Node.js and npm
- MongoDB (local or hosted)
- Xcode (for iOS simulator) and/or Android Studio (for Android emulator)
- Firebase project configured for push notifications (optional for basic local API testing)

## Local Development Setup

### 1) Start the Backend

```bash
cd backend
npm install
```

Create a `.env` file inside `backend/`:

```env
PORT=3000
NODE_ENV=development
MONGODB_URI=mongodb://localhost:27017/decidish
JWT_SECRET=replace-with-a-secure-secret
JWT_EXPIRE=7d
```

Run the server:

```bash
npm run dev
```

Backend default URL: `http://localhost:3000`

### 2) Run the Flutter App

From project root:

```bash
flutter pub get
flutter run
```

## API Base URL Configuration

API URL is defined in `lib/config/api_config.dart`:

- Android emulator uses: `http://10.0.2.2:3000`
- iOS simulator and desktop use: `http://localhost:3000`

For physical device testing, update `baseUrl` to your machine's LAN IP and ensure your backend is reachable on the same network.

## Useful Commands

### Flutter

```bash
flutter analyze
flutter test
```

### Backend

```bash
cd backend
npm run dev
npm start
```

## Notes

- Keep secrets out of source control (`.env`, API keys, tokens).
- If recommendations/favorites/history fail, verify backend is running and reachable from your target device/emulator.
- For production/release steps, see `PUBLISHING_GUIDE.md`.

## License

This project is currently unlicensed for public reuse. Add a `LICENSE` file if you plan to open-source it.