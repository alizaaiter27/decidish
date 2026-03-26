# MongoDB Setup Guide

## Option 1: MongoDB Atlas (Cloud - Recommended) ⭐

### Step 1: Create Free Account
1. Go to https://www.mongodb.com/cloud/atlas/register
2. Sign up for a free account

### Step 2: Create a Cluster
1. Click "Build a Database"
2. Choose "M0 FREE" (Free tier)
3. Select a cloud provider and region (choose closest to you)
4. Click "Create"

### Step 3: Create Database User
1. Go to "Database Access" in the left menu
2. Click "Add New Database User"
3. Choose "Password" authentication
4. Enter username and password (save these!)
5. Set privileges to "Atlas admin" or "Read and write to any database"
6. Click "Add User"

### Step 4: Whitelist Your IP
1. Go to "Network Access" in the left menu
2. Click "Add IP Address"
3. Click "Allow Access from Anywhere" (for development) or add your IP
4. Click "Confirm"

### Step 5: Get Connection String
1. Go to "Database" in the left menu
2. Click "Connect" on your cluster
3. Choose "Connect your application"
4. Copy the connection string (looks like: `mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/decidish?retryWrites=true&w=majority`)
5. Replace `<password>` with your actual password
6. Replace `<dbname>` with `decidish` or remove it

### Step 6: Update Backend Configuration
1. Create `.env` file in backend directory:
   ```bash
   cd backend
   cp env.example .env
   ```

2. Edit `.env` and update:
   ```env
   MONGODB_URI=mongodb+srv://yourusername:yourpassword@cluster0.xxxxx.mongodb.net/decidish?retryWrites=true&w=majority
   ```

3. Restart your backend server

---

## Option 2: Install MongoDB Locally

### macOS (via Homebrew)

1. Tap the MongoDB Homebrew repository:
   ```bash
   brew tap mongodb/brew
   ```

2. Install MongoDB:
   ```bash
   brew install mongodb-community
   ```

3. Start MongoDB:
   ```bash
   brew services start mongodb-community
   ```

4. Verify it's running:
   ```bash
   brew services list
   ```

### Alternative: Use Docker

If you have Docker installed:

```bash
docker run -d -p 27017:27017 --name mongodb mongo:latest
```

Then use: `mongodb://localhost:27017/decidish`

---

## Verify Connection

After setup, restart your backend and you should see:
```
MongoDB connected successfully
Server is running on port 3000
```
