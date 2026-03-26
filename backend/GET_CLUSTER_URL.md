# How to Get Your MongoDB Cluster URL

## The Error You're Seeing
```
MongoDB connection error: Error: querySrv ENOTFOUND _mongodb._tcp.CLUSTER_URL
```

This means you need to replace `CLUSTER_URL` in your `.env` file with your actual MongoDB Atlas cluster URL.

## Step-by-Step Instructions

### Step 1: Log into MongoDB Atlas
1. Go to: https://cloud.mongodb.com/
2. Log in with your account

### Step 2: Find Your Cluster
1. Click **"Database"** in the left sidebar
2. You should see your cluster listed (usually named "Cluster0" or similar)

### Step 3: Get Connection String
1. Click the **"Connect"** button on your cluster
2. A popup will appear - choose **"Connect your application"**
3. Select **"Node.js"** as the driver
4. Select version **"4.1 or later"**
5. You'll see a connection string that looks like:
   ```
   mongodb+srv://alizaaiter_db_user:<password>@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority
   ```

### Step 4: Extract the Cluster URL
From the connection string, copy the part between `@` and `/?`:

**Example:**
- Connection string: `mongodb+srv://alizaaiter_db_user:<password>@cluster0.abc123.mongodb.net/?retryWrites=true&w=majority`
- Cluster URL: `cluster0.abc123.mongodb.net`

### Step 5: Update Your .env File
1. Open `backend/.env` in a text editor
2. Find this line:
   ```env
   MONGODB_URI=mongodb+srv://alizaaiter_db_user:As.0259@CLUSTER_URL/decidish?retryWrites=true&w=majority
   ```
3. Replace `CLUSTER_URL` with your actual cluster URL

**Example result:**
```env
MONGODB_URI=mongodb+srv://alizaaiter_db_user:As.0259@cluster0.abc123.mongodb.net/decidish?retryWrites=true&w=majority
```

### Step 6: Save and Restart
1. Save the `.env` file
2. The server should auto-restart (nodemon will detect the change)
3. You should see: `MongoDB connected successfully`

---

## Quick Method: Copy Full String

Alternatively, you can:
1. Copy the entire connection string from MongoDB Atlas
2. Replace `<password>` with `As.0259`
3. Add `/decidish` before the `?` to specify the database name
4. Paste it into `.env` as `MONGODB_URI=...`

---

## Still Can't Find It?

- Make sure you've created a cluster in MongoDB Atlas
- Check that the cluster is not paused
- Verify you're logged into the correct MongoDB Atlas account
- If you don't have a cluster yet, create one (it's free!)

