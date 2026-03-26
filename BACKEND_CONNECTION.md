# Backend Connection Guide

This guide explains how to connect your Flutter app to the backend API.

## Prerequisites

1. **Backend server running**: Make sure your backend is running (see `backend/README.md`)
2. **Dependencies installed**: Run `flutter pub get` to install required packages

## Configuration

### 1. Update API Base URL

Edit `lib/config/api_config.dart` and update the `baseUrl`:

```dart
static const String baseUrl = 'http://localhost:3000';
```

**Important**: The URL depends on where you're running the app:

- **iOS Simulator**: `http://localhost:3000`
- **Android Emulator**: `http://10.0.2.2:3000`
- **Physical Device**: `http://YOUR_COMPUTER_IP:3000` (e.g., `http://192.168.1.100:3000`)

To find your computer's IP address:
- **macOS/Linux**: Run `ifconfig` or `ip addr`
- **Windows**: Run `ipconfig`

### 2. Install Dependencies

Run:
```bash
flutter pub get
```

This will install:
- `http` - For making API calls
- `shared_preferences` - For storing authentication tokens

## API Services Created

The following services are available:

### Authentication
- `AuthApiService.signup()` - Register new user
- `AuthApiService.login()` - Login user
- `AuthApiService.getCurrentUser()` - Get current user
- `AuthApiService.logout()` - Logout

### Meals
- `MealApiService.getMeals()` - Get all meals
- `MealApiService.getMealById()` - Get single meal
- `MealApiService.getRecommendation()` - Get meal recommendation

### Favorites
- `FavoritesApiService.getFavorites()` - Get all favorites
- `FavoritesApiService.addFavorite()` - Add to favorites
- `FavoritesApiService.removeFavorite()` - Remove favorite

### History
- `HistoryApiService.getHistory()` - Get meal history
- `HistoryApiService.getHistoryStats()` - Get statistics
- `HistoryApiService.updateHistoryEntry()` - Update history entry

### User
- `UserApiService.getProfile()` - Get user profile
- `UserApiService.updateProfile()` - Update profile
- `UserApiService.completeOnboarding()` - Complete onboarding

## Usage Examples

### Login Screen
The login screen now calls the API:
```dart
final response = await AuthApiService.login(
  email: email,
  password: password,
);
```

### Home Screen
The "Decide For Me" button now gets recommendations:
```dart
final meal = await MealApiService.getRecommendation();
```

## Error Handling

All API calls include error handling. Errors are displayed as SnackBars to the user.

## Authentication Token Storage

Tokens are automatically stored using `shared_preferences` and included in authenticated requests.

## Testing the Connection

1. Start your backend server:
   ```bash
   cd backend
   npm run dev
   ```

2. Update the API URL in `api_config.dart` for your platform

3. Run the Flutter app:
   ```bash
   flutter run
   ```

4. Try signing up or logging in to test the connection

## Troubleshooting

### Connection Refused
- Make sure the backend server is running
- Check that the URL in `api_config.dart` is correct for your platform
- For physical devices, ensure your phone and computer are on the same network

### CORS Errors (Web)
If running on web, you may need to configure CORS in your backend. Add to `backend/server.js`:
```javascript
app.use(cors({
  origin: '*', // In production, specify your domain
  credentials: true,
}));
```

### SSL/HTTPS Issues
For production, use HTTPS. For development, you may need to allow HTTP connections.

## Next Steps

1. Update other screens (favorites, history, profile) to fetch real data
2. Add loading states and error handling
3. Implement token refresh if needed
4. Add offline support if desired
