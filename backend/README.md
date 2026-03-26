# DeciDish Backend API

A Node.js/Express backend API for the DeciDish meal recommendation Flutter application.

## Features

- User authentication (JWT-based)
- User profile management
- Meal recommendations based on user preferences
- Favorites management
- Meal history tracking
- RESTful API design

## Tech Stack

- **Node.js** - Runtime environment
- **Express** - Web framework
- **MongoDB** - Database
- **Mongoose** - ODM for MongoDB
- **JWT** - Authentication
- **bcryptjs** - Password hashing

## Prerequisites

- Node.js (v14 or higher)
- MongoDB (local or MongoDB Atlas)
- npm or yarn

## Installation

1. Navigate to the backend directory:
```bash
cd backend
```

2. Install dependencies:
```bash
npm install
```

3. Create a `.env` file in the backend directory:
```bash
cp .env.example .env
```

4. Update the `.env` file with your configuration:
```env
PORT=3000
NODE_ENV=development
MONGODB_URI=mongodb://localhost:27017/decidish
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRE=7d
```

## Running the Server

### Development Mode (with auto-reload):
```bash
npm run dev
```

### Production Mode:
```bash
npm start
```

The server will start on `http://localhost:3000` (or the port specified in your `.env` file).

## API Endpoints

### Authentication
- `POST /api/auth/signup` - Register a new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/me` - Get current user (requires auth)

### Users
- `GET /api/users/profile` - Get user profile (requires auth)
- `PUT /api/users/profile` - Update user profile (requires auth)
- `POST /api/users/onboarding` - Complete onboarding (requires auth)

### Meals
- `GET /api/meals` - Get all meals (with optional filters)
- `GET /api/meals/:id` - Get single meal by ID

### Recommendations
- `GET /api/recommendations` - Get meal recommendation (requires auth)

### Favorites
- `GET /api/favorites` - Get all favorites (requires auth)
- `POST /api/favorites` - Add meal to favorites (requires auth)
- `DELETE /api/favorites/:id` - Remove favorite (requires auth)
- `DELETE /api/favorites/meal/:mealId` - Remove favorite by meal ID (requires auth)

### History
- `GET /api/history` - Get meal history (requires auth)
- `GET /api/history/stats` - Get history statistics (requires auth)
- `PUT /api/history/:id` - Update history entry (requires auth)

### Health Check
- `GET /api/health` - Check API status

## Authentication

Most endpoints require authentication. Include the JWT token in the Authorization header:

```
Authorization: Bearer <your-jwt-token>
```

## Example Requests

### Sign Up
```bash
curl -X POST http://localhost:3000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "password123"
  }'
```

### Login
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "password123"
  }'
```

### Get Recommendation
```bash
curl -X GET http://localhost:3000/api/recommendations \
  -H "Authorization: Bearer <your-token>"
```

## Database Models

### User
- name, email, password
- dietType (Vegetarian, Vegan, Omnivore, Keto, Paleo, Gluten-Free, None)
- preferences (allergies, dislikedIngredients, preferredCuisines, calorieRange)
- onboardingCompleted

### Meal
- name, description, imageUrl
- nutrition (calories, protein, carbs, fat)
- dietTypes, cuisine, ingredients, tags
- preparationTime, difficulty

### Favorite
- user (reference to User)
- meal (reference to Meal)

### History
- user (reference to User)
- meal (reference to Meal)
- date, rating, notes

## Seeding Sample Data

To seed the database with sample meals, you can create a script or use MongoDB directly. Example meal structure:

```json
{
  "name": "Grilled Chicken Caesar Salad",
  "description": "Fresh romaine lettuce with grilled chicken",
  "nutrition": {
    "calories": 420,
    "protein": 35,
    "carbs": 28,
    "fat": 18
  },
  "dietTypes": ["Omnivore"],
  "cuisine": "American",
  "ingredients": ["chicken", "lettuce", "caesar dressing", "parmesan"],
  "tags": ["healthy", "quick"]
}
```

## Error Handling

The API returns consistent error responses:

```json
{
  "success": false,
  "message": "Error message"
}
```

Success responses:

```json
{
  "success": true,
  "data": {...}
}
```

## Development

- Use `nodemon` for auto-reload during development
- Follow RESTful API conventions
- Validate input using express-validator
- Use middleware for authentication

## Production Considerations

- Use environment variables for sensitive data
- Set a strong JWT_SECRET
- Enable CORS appropriately
- Use MongoDB Atlas or a managed database service
- Implement rate limiting
- Add request logging
- Set up error monitoring

## License

ISC
