# TheMealDB API Documentation for AI Agent

## Overview
TheMealDB is a free RESTful Recipe API that provides meal recipes, ingredients, categories, cooking instructions, meal images, and filtering/search functionality.

Base URL:
https://www.themealdb.com/api/json/v1/1/

Authentication:
- No authentication required for development/testing.
- Use test API key: `1`
- Production/public apps require a supporter API key.

Response Format:
- All responses are returned in JSON format.

---

# Main Features
The API allows:
- Search meals by name
- Search meals by first letter
- Get full meal details
- Get random meals
- Filter meals by ingredient
- Filter meals by category
- Filter meals by country/area
- Get meal categories
- Get ingredients list
- Access meal and ingredient images

---

# Important Notes

## Multiple Ingredient Search
Multi-ingredient filtering is only available in Premium API v2.

Example:
https://www.themealdb.com/api/json/v2/1/filter.php?i=chicken_breast,garlic,salt

## Free Version Limitation
Free version only supports:
- Single ingredient filtering
- Basic meal search
- Standard lookup endpoints

---

# API Endpoints

---

## 1. Search Meal By Name

### Endpoint
search.php?s={meal_name}

### Example
https://www.themealdb.com/api/json/v1/1/search.php?s=Arrabiata

### Purpose
Searches meals by full or partial meal name.

### Returns
- Meal name
- Instructions
- Ingredients
- Measures
- Meal thumbnail
- Category
- Area
- YouTube video
- Tags

---

## 2. Search Meals By First Letter

### Endpoint
search.php?f={letter}

### Example
https://www.themealdb.com/api/json/v1/1/search.php?f=a

### Purpose
Returns all meals starting with a specific letter.

---

## 3. Lookup Full Meal Details By ID

### Endpoint
lookup.php?i={meal_id}

### Example
https://www.themealdb.com/api/json/v1/1/lookup.php?i=52772

### Purpose
Returns complete meal details using meal ID.

### Recommended Usage
Use this after filter/search endpoints to get full recipe details.

---

## 4. Get Random Meal

### Endpoint
random.php

### Example
https://www.themealdb.com/api/json/v1/1/random.php

### Purpose
Returns one random recipe.

---

## 5. Get 10 Random Meals (Premium Only)

### Endpoint
randomselection.php

### Example
https://www.themealdb.com/api/json/v2/1/randomselection.php

---

## 6. List All Categories

### Endpoint
categories.php

### Example
https://www.themealdb.com/api/json/v1/1/categories.php

### Returns
- Category name
- Category description
- Category image

---

## 7. Latest Meals (Premium Only)

### Endpoint
latest.php

### Example
https://www.themealdb.com/api/json/v2/1/latest.php

---

# List Endpoints

---

## 8. List All Categories

### Endpoint
list.php?c=list

### Example
https://www.themealdb.com/api/json/v1/1/list.php?c=list

---

## 9. List All Areas/Countries

### Endpoint
list.php?a=list

### Example
https://www.themealdb.com/api/json/v1/1/list.php?a=list

---

## 10. List All Ingredients

### Endpoint
list.php?i=list

### Example
https://www.themealdb.com/api/json/v1/1/list.php?i=list

### Returns
- Ingredient name
- Description
- Ingredient type

---

# Filter Endpoints

---

## 11. Filter By Ingredient

### Endpoint
filter.php?i={ingredient}

### Example
https://www.themealdb.com/api/json/v1/1/filter.php?i=chicken_breast

### Purpose
Returns meals containing a specific ingredient.

### Returns Only
- Meal ID
- Meal Name
- Meal Thumbnail

### Important
This endpoint does NOT return full recipe details.
Use `lookup.php?i=MEAL_ID` afterwards.

---

## 12. Filter By Multiple Ingredients (Premium Only)

### Endpoint
filter.php?i=ingredient1,ingredient2,ingredient3

### Example
https://www.themealdb.com/api/json/v2/1/filter.php?i=chicken_breast,garlic,salt

### Purpose
Returns meals matching multiple ingredients.

---

## 13. Filter By Category

### Endpoint
filter.php?c={category}

### Example
https://www.themealdb.com/api/json/v1/1/filter.php?c=Seafood

---

## 14. Filter By Area/Country

### Endpoint
filter.php?a={area}

### Example
https://www.themealdb.com/api/json/v1/1/filter.php?a=Canadian

---

# Images

---

## Meal Images

### Format
/images/media/meals/{image}.jpg

### Sizes
- small
- medium
- large

### Example
https://www.themealdb.com/images/media/meals/llcbn01574260722.jpg/medium

---

## Ingredient Images

### Format
https://www.themealdb.com/images/ingredients/{ingredient}.png

### Example
https://www.themealdb.com/images/ingredients/lime.png

### Sizes
- small
- medium
- large

### Example
https://www.themealdb.com/images/ingredients/lime-large.png

---

# Recommended App Flow For Ingredient-Based Recipe App

## Step 1
User enters ingredients:
```text
chicken, rice, garlic