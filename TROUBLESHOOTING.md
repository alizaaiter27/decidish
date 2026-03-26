# Troubleshooting Connection Issues

## "Connection Refused" Error

This error means your Flutter app cannot reach the backend server. Here's how to fix it:

### Step 1: Make Sure Backend is Running

1. Open a terminal and navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Start the backend server:
   ```bash
   npm run dev
   ```

3. You should see:
   ```
   MongoDB connected successfully
   Server is running on port 3000
   ```

### Step 2: Check Your Platform

The API URL is automatically configured based on your platform:

- **Android Emulator**: Uses `http://10.0.2.2:3000` (automatic)
- **iOS Simulator**: Uses `http://localhost:3000` (automatic)
- **Physical Device**: Needs manual configuration (see below)

### Step 3: For Physical Devices

If you're testing on a **physical device** (phone/tablet), you need to:

1. **Find your computer's IP address:**
   - **macOS/Linux**: Run `ifconfig` or `ip addr` in terminal
   - **Windows**: Run `ipconfig` in command prompt
   - Look for your local network IP (usually starts with `192.168.x.x` or `10.x.x.x`)

2. **Update the API config:**
   - Edit `lib/config/api_config.dart`
   - Uncomment and set the IP address:
   ```dart
   static const String baseUrl = 'http://192.168.1.100:3000'; // Your IP
   ```

3. **Make sure your device and computer are on the same WiFi network**

4. **Check firewall settings** - your computer's firewall might be blocking port 3000

### Step 4: Verify Backend is Accessible

Test if your backend is running by opening in a browser:
- Android Emulator: `http://10.0.2.2:3000/api/health`
- iOS Simulator: `http://localhost:3000/api/health`
- Physical Device: `http://YOUR_IP:3000/api/health`

You should see: `{"status":"OK","message":"DeciDish API is running"}`

### Step 5: Check MongoDB

Make sure MongoDB is running:
- **macOS**: `brew services start mongodb-community`
- **Linux**: `sudo systemctl start mongod`
- **Windows**: Check Services panel

### Common Issues

#### Issue: "Connection refused" on Android Emulator
**Solution**: The code now automatically uses `10.0.2.2:3000` for Android. Make sure backend is running.

#### Issue: "Connection refused" on Physical Device
**Solution**: 
1. Use your computer's IP address (not localhost)
2. Ensure same WiFi network
3. Check firewall allows port 3000

#### Issue: Backend starts but MongoDB connection fails
**Solution**: 
1. Make sure MongoDB is installed and running
2. Check `backend/.env` has correct `MONGODB_URI`
3. For MongoDB Atlas, ensure your IP is whitelisted

#### Issue: CORS errors (web platform)
**Solution**: The backend already has CORS enabled. If issues persist, check `backend/server.js` CORS configuration.

### Quick Test

Run this command to test if backend is accessible:
```bash
curl http://localhost:3000/api/health
```

If this works, the backend is running correctly. The issue is with the Flutter app's connection.
