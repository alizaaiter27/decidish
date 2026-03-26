# API Connection Status

## ✅ Connected Screens

1. **Login Screen** - Uses `AuthApiService.login()`
2. **Signup Screen** - Uses `AuthApiService.signup()`
3. **Home Screen** - Uses `MealApiService.getRecommendation()`

## ❌ Not Connected (Still Using Mock Data)

1. **Favorites Screen** - Needs `FavoritesApiService.getFavorites()`
2. **History Screen** - Needs `HistoryApiService.getHistory()`
3. **Profile Screen** - Needs `UserApiService.getProfile()` and logout
4. **Recommendation Screen** - Needs to receive meal data from navigation arguments

## Summary

**3 out of 7 screens are connected to the API.**

The remaining screens need to be updated to fetch real data from the backend instead of using mock data.
