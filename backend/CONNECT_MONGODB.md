# Connect Your Application to MongoDB

## Quick Setup: MongoDB Atlas (Cloud - Recommended) ⭐

### Step 1: Create MongoDB Atlas Account
1. Go to: https://www.mongodb.com/cloud/atlas/register
2. Click "Try Free" or "Sign Up"
3. Fill in your details and create account

### Step 2: Create a Free Cluster
1. After logging in, click **"Build a Database"**
2. Choose **"M0 FREE"** (Free tier - perfect for development)
3. Select a cloud provider (AWS, Google Cloud, or Azure)
4. Choose a region closest to you
5. Click **"Create"** (takes 1-3 minutes)

### Step 3: Create Database User
1. In the left sidebar, click **"Database Access"**
2. Click **"Add New Database User"**
3. Choose **"Password"** authentication method
4. Enter:
   - **Username**: (e.g., `decidishuser`)
   - **Password**: (create a strong password - **SAVE THIS!**)
5. Under "Database User Privileges", select **"Atlas admin"** or **"Read and write to any database"**
6. Click **"Add User"**

### Step 4: Whitelist Your IP Address
1. In the left sidebar, click **"Network Access"**
2. Click **"Add IP Address"**
3. For development, click **"Allow Access from Anywhere"** (adds `0.0.0.0/0`)
   - ⚠️ For production, add specific IPs only
4. Click **"Confirm"**

### Step 5: Get Your Connection String
1. In the left sidebar, click **"Database"**
2. Click **"Connect"** button on your cluster
3. Choose **"Connect your application"**
4. Select **"Node.js"** as driver and **"4.1 or later"** as version
5. Copy the connection string (looks like):
   ```
   mongodb+srv://<username>:<password>@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority
   ```

### Step 6: Update Your .env File
1. Open `backend/.env` file
2. Replace the `MONGODB_URI` line with your connection string
3. Replace `<username>` with your database username
4. Replace `<password>` with your database password
5. Add `/decidish` before the `?` to specify database name:

**Example:**
```env
MONGODB_URI=mongodb+srv://decidishuser:YourPassword123@cluster0.abc123.mongodb.net/decidish?retryWrites=true&w=majority
```

### Step 7: Restart Your Backend Server
1. Stop your current server (Ctrl+C)
2. Start it again:
   ```bash
   cd backend
   npm run dev
   ```

3. You should see:
   ```
   MongoDB connected successfully
   Server is running on port 3000
   ```

---

## Alternative: Install MongoDB Locally

If you prefer local MongoDB:

### macOS Installation:
```bash
# Add MongoDB tap
brew tap mongodb/brew

# Install MongoDB
brew install mongodb-community

# Start MongoDB service
brew services start mongodb-community

# Verify it's running
brew services list
```

Then use in `.env`:
```env
MONGODB_URI=mongodb://localhost:27017/decidish
```

### Verify Local MongoDB:
```bash
# Check if MongoDB is running
brew services list | grep mongodb

# Or test connection
mongosh
```

---

## Troubleshooting

### Error: "MongoServerError: Authentication failed"
- Check your username and password in the connection string
- Make sure you replaced `<username>` and `<password>` with actual values

### Error: "MongoServerError: IP not whitelisted"
- Go to MongoDB Atlas → Network Access
- Add your current IP address or "Allow Access from Anywhere"

### Error: "Connection timeout"
- Check your internet connection
- Verify the connection string is correct
- Make sure MongoDB Atlas cluster is running (not paused)

### Error: "MongoParseError: Invalid connection string"
- Make sure the connection string starts with `mongodb+srv://`
- Check for special characters in password (may need URL encoding)
- Verify the database name is included: `/decidish`

---

## Test Your Connection

After setup, test by making a request:
```bash
curl http://localhost:3000/api/health
```

Or try signing up in your Flutter app - if MongoDB is connected, it should work!

---

## Security Notes

- **Never commit `.env` file to git** (it's already in `.gitignore`)
- For production, use environment variables or secure secret management
- Change default JWT_SECRET in production
- Use specific IP whitelisting in production (not 0.0.0.0/0)
