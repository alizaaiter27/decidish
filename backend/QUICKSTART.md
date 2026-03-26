# Quick Start Guide

Get your DeciDish backend up and running in minutes!

## Step 1: Install Dependencies

```bash
cd backend
npm install
```

## Step 2: Set Up Environment Variables

Copy the example environment file:
```bash
cp env.example .env
```

Edit `.env` and update the MongoDB URI if needed. For local MongoDB:
```env
MONGODB_URI=mongodb://localhost:27017/decidish
```

## Step 3: Start MongoDB

Make sure MongoDB is running on your system:

**macOS (using Homebrew):**
```bash
brew services start mongodb-community
```

**Linux:**
```bash
sudo systemctl start mongod
```

**Windows:**
Start MongoDB service from Services panel

**Or use MongoDB Atlas (cloud):**
- Sign up at https://www.mongodb.com/cloud/atlas
- Create a free cluster
- Get your connection string
- Update `MONGODB_URI` in `.env`

## Step 4: Seed Sample Data (Optional)

Populate the database with sample meals:
```bash
npm run seed
```

## Step 5: Start the Server

**Development mode (with auto-reload):**
```bash
npm run dev
```

**Production mode:**
```bash
npm start
```

The server will be running at `http://localhost:3000`

## Step 6: Test the API

Check if the server is running:
```bash
curl http://localhost:3000/api/health
```

You should see:
```json
{"status":"OK","message":"DeciDish API is running"}
```

## Next Steps

1. Test authentication:
   - Sign up: `POST /api/auth/signup`
   - Login: `POST /api/auth/login`

2. Get a recommendation:
   - `GET /api/recommendations` (requires authentication token)

3. See the full API documentation in `README.md`

## Troubleshooting

**MongoDB connection error:**
- Make sure MongoDB is running
- Check your `MONGODB_URI` in `.env`
- For MongoDB Atlas, ensure your IP is whitelisted

**Port already in use:**
- Change `PORT` in `.env` to a different port (e.g., 3001)

**Module not found:**
- Run `npm install` again
- Make sure you're in the `backend` directory
