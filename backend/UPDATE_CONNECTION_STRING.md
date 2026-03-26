# How to Get Your MongoDB Cluster URL

## Your Credentials (Already Added)
- **Username**: `alizaaiter_db_user`
- **Password**: `As.0259`

## Step-by-Step: Get Your Cluster URL

### Step 1: Log into MongoDB Atlas
1. Go to: https://cloud.mongodb.com/
2. Log in with your account

### Step 2: Get Connection String
1. Click **"Database"** in the left sidebar
2. Find your cluster and click the **"Connect"** button
3. Choose **"Connect your application"**
4. Select **"Node.js"** as driver
5. You'll see a connection string like:
   ```
   mongodb+srv://alizaaiter_db_user:<password>@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority
   ```

### Step 3: Extract the Cluster URL
From the connection string above, copy the part between `@` and `/?`:
- Example: `cluster0.abc123.mongodb.net`
- This is your **CLUSTER_URL**

### Step 4: Update .env File
1. Open `backend/.env`
2. Find the line:
   ```env
   MONGODB_URI=mongodb+srv://alizaaiter_db_user:As.0259@CLUSTER_URL/decidish?retryWrites=true&w=majority
   ```
3. Replace `CLUSTER_URL` with your actual cluster URL

**Final example:**
```env
MONGODB_URI=mongodb+srv://alizaaiter_db_user:As.0259@cluster0.abc123.mongodb.net/decidish?retryWrites=true&w=majority
```

### Step 5: Test Connection
Restart your backend server:
```bash
cd backend
npm run dev
```

You should see:
```
MongoDB connected successfully
Server is running on port 3000
```

---

## Quick Alternative: Copy Full Connection String

If you prefer, you can copy the entire connection string from MongoDB Atlas and just replace `<password>` with `As.0259`:

1. Copy the connection string from MongoDB Atlas
2. Replace `<password>` with `As.0259`
3. Add `/decidish` before the `?` to specify the database name
4. Paste it into `.env` as `MONGODB_URI=...`

---

## Need Help?

If you can't find your cluster:
- Make sure you've created a cluster in MongoDB Atlas
- Check that the cluster is not paused
- Verify you're logged into the correct account
