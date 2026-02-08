from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS
import mysql.connector
import os
import datetime
import uuid
from functools import wraps
import bcrypt
import jwt
import re

app = Flask(__name__)
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'your-secret-key-here')
CORS(app, supports_credentials=True)

# Database configuration
# Use environment variables for production (Render), fallback to local defaults
DB_CONFIG = {
    "host": os.environ.get("DB_HOST", "localhost"),
    "user": os.environ.get("DB_USER", "root"),
    "password": os.environ.get("DB_PASSWORD", "admin123"),
    "database": os.environ.get("DB_NAME", "recipe_finder"),
    "port": int(os.environ.get("DB_PORT", 3306))
}

def generate_token(user_id):
    """Generate JWT token for a user."""
    payload = {
        "user_id": user_id,
        "exp": datetime.datetime.utcnow() + datetime.timedelta(days=7)
    }
    return jwt.encode(payload, app.config['SECRET_KEY'], algorithm='HS256')

def verify_token(token):
    """Verify JWT token and return the user id if valid."""
    try:
        payload = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
        return payload.get('user_id')
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None

def token_required(f):
    """Decorator to enforce JWT authentication."""
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.headers.get('Authorization', '')

        if not token:
            return jsonify({"error": "Token is missing"}), 401

        if token.startswith('Bearer '):
            token = token[7:]

        user_id = verify_token(token)
        if not user_id:
            return jsonify({"error": "Invalid token"}), 401

        request.user_id = user_id
        return f(*args, **kwargs)
    return decorated

def get_db_connection():
    """Create and return a database connection"""
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        return conn
    except mysql.connector.Error as e:
        print(f"❌ Database connection error: {e}")
        return None

def get_session_id():
    """Generate or get session ID from request"""
    session_id = request.headers.get('X-Session-ID')
    if not session_id:
        session_id = str(uuid.uuid4())
    return session_id


# Auth Routes
@app.route('/register', methods=['POST'])
def register():
    try:
        data = request.get_json() or {}
        username = data.get('username', '').strip()
        email = data.get('email', '').strip().lower()
        password = data.get('password', '')

        if not username or not email or not password:
            return jsonify({"error": "All fields are required"}), 400

        if len(username) < 3:
            return jsonify({"error": "Username must be at least 3 characters"}), 400

        if len(password) < 6:
            return jsonify({"error": "Password must be at least 6 characters"}), 400

        if not re.match(r'^[^@]+@[^@]+\.[^@]+$', email):
            return jsonify({"error": "Invalid email format"}), 400

        conn = get_db_connection()
        if not conn:
            return jsonify({"error": "Database connection failed"}), 500

        cursor = conn.cursor()
        cursor.execute("SELECT id FROM users WHERE email = %s OR username = %s", (email, username))
        if cursor.fetchone():
            cursor.close()
            conn.close()
            return jsonify({"error": "User already exists"}), 400

        password_hash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        cursor.execute(
            "INSERT INTO users (username, email, password_hash, created_at) VALUES (%s, %s, %s, %s)",
            (username, email, password_hash, datetime.datetime.now())
        )

        user_id = cursor.lastrowid
        token = generate_token(user_id)

        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({
            "message": "User registered successfully",
            "token": token,
            "user": {
                "id": user_id,
                "username": username,
                "email": email
            }
        }), 201

    except Exception as e:
        print(f"❌ Registration error: {e}")
        return jsonify({"error": "Registration failed"}), 500

@app.route('/login', methods=['POST'])
def login():
    try:
        data = request.get_json() or {}
        email = data.get('email', '').strip().lower()
        password = data.get('password', '')

        if not email or not password:
            return jsonify({"error": "Email and password are required"}), 400

        conn = get_db_connection()
        if not conn:
            return jsonify({"error": "Database connection failed"}), 500

        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM users WHERE email = %s", (email,))
        user = cursor.fetchone()

        if not user or not bcrypt.checkpw(password.encode('utf-8'), user['password_hash'].encode('utf-8')):
            cursor.close()
            conn.close()
            return jsonify({"error": "Invalid credentials"}), 401

        token = generate_token(user['id'])
        cursor.execute("UPDATE users SET last_login = %s WHERE id = %s", (datetime.datetime.now(), user['id']))

        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({
            "message": "Login successful",
            "token": token,
            "user": {
                "id": user['id'],
                "username": user['username'],
                "email": user['email']
            }
        })

    except Exception as e:
        print(f"❌ Login error: {e}")
        return jsonify({"error": "Login failed"}), 500

@app.route('/profile', methods=['GET'])
@token_required
def get_profile():
    try:
        user_id = request.user_id

        conn = get_db_connection()
        if not conn:
            return jsonify({"error": "Database connection failed"}), 500

        cursor = conn.cursor(dictionary=True)
        cursor.execute("""
            SELECT id, username, email, created_at, last_login 
            FROM users WHERE id = %s
        """, (user_id,))

        user = cursor.fetchone()
        cursor.close()
        conn.close()

        if not user:
            return jsonify({"error": "User not found"}), 404

        return jsonify({"user": user})

    except Exception as e:
        print(f"❌ Profile error: {e}")
        return jsonify({"error": "Failed to fetch profile"}), 500

@app.route('/profile', methods=['PUT'])
@token_required
def update_profile():
    try:
        user_id = request.user_id
        data = request.get_json() or {}
        username = data.get('username', '').strip()

        if not username or len(username) < 3:
            return jsonify({"error": "Username must be at least 3 characters"}), 400

        conn = get_db_connection()
        if not conn:
            return jsonify({"error": "Database connection failed"}), 500

        cursor = conn.cursor()
        cursor.execute("SELECT id FROM users WHERE username = %s AND id != %s", (username, user_id))
        if cursor.fetchone():
            cursor.close()
            conn.close()
            return jsonify({"error": "Username already taken"}), 400

        cursor.execute("UPDATE users SET username = %s WHERE id = %s", (username, user_id))

        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({"message": "Profile updated successfully"})

    except Exception as e:
        print(f"❌ Profile update error: {e}")
        return jsonify({"error": "Failed to update profile"}), 500

@app.route('/favorites', methods=['GET'])
@token_required
def get_favorites():
    try:
        user_id = request.user_id

        conn = get_db_connection()
        if not conn:
            return jsonify({"error": "Database connection failed"}), 500

        cursor = conn.cursor(dictionary=True)
        cursor.execute("""
            SELECT r.*, 
                   COALESCE(AVG(rt.rating), 0) as avg_rating,
                   COUNT(rt.id) as review_count,
                   f.created_at as favorited_at
            FROM user_favorites f
            JOIN recipes r ON f.recipe_id = r.id
            LEFT JOIN recipe_ratings rt ON r.id = rt.recipe_id
            WHERE f.user_id = %s
            GROUP BY r.id
            ORDER BY f.created_at DESC
        """, (user_id,))

        favorites = cursor.fetchall()
        for recipe in favorites:
            recipe['avg_rating'] = float(recipe['avg_rating']) if recipe['avg_rating'] else 0
            recipe['prep_time'] = int(recipe['prep_time']) if recipe['prep_time'] else 0
            recipe['cook_time'] = int(recipe['cook_time']) if recipe['cook_time'] else 0
            recipe['total_time'] = (recipe['prep_time'] or 0) + (recipe['cook_time'] or 0)

        cursor.close()
        conn.close()

        return jsonify(favorites)

    except Exception as e:
        print(f"❌ Favorites error: {e}")
        return jsonify({"error": "Failed to fetch favorites"}), 500

@app.route('/favorites/<int:recipe_id>', methods=['POST'])
@token_required
def add_favorite(recipe_id):
    try:
        user_id = request.user_id

        conn = get_db_connection()
        if not conn:
            return jsonify({"error": "Database connection failed"}), 500

        cursor = conn.cursor()
        cursor.execute("SELECT id FROM recipes WHERE id = %s", (recipe_id,))
        if not cursor.fetchone():
            cursor.close()
            conn.close()
            return jsonify({"error": "Recipe not found"}), 404

        cursor.execute("SELECT id FROM user_favorites WHERE user_id = %s AND recipe_id = %s", (user_id, recipe_id))
        if cursor.fetchone():
            cursor.close()
            conn.close()
            return jsonify({"error": "Recipe already in favorites"}), 400

        cursor.execute(
            "INSERT INTO user_favorites (user_id, recipe_id, created_at) VALUES (%s, %s, %s)",
            (user_id, recipe_id, datetime.datetime.now())
        )

        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({"message": "Recipe added to favorites"})

    except Exception as e:
        print(f"❌ Add favorite error: {e}")
        return jsonify({"error": "Failed to add favorite"}), 500

@app.route('/favorites/<int:recipe_id>', methods=['DELETE'])
@token_required
def remove_favorite(recipe_id):
    try:
        user_id = request.user_id

        conn = get_db_connection()
        if not conn:
            return jsonify({"error": "Database connection failed"}), 500

        cursor = conn.cursor()
        cursor.execute("DELETE FROM user_favorites WHERE user_id = %s AND recipe_id = %s", (user_id, recipe_id))

        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({"message": "Recipe removed from favorites"})

    except Exception as e:
        print(f"❌ Remove favorite error: {e}")
        return jsonify({"error": "Failed to remove favorite"}), 500

@app.route('/favorites/check/<int:recipe_id>', methods=['GET'])
@token_required
def check_favorite(recipe_id):
    try:
        user_id = request.user_id

        conn = get_db_connection()
        if not conn:
            return jsonify({"error": "Database connection failed"}), 500

        cursor = conn.cursor()
        cursor.execute("SELECT id FROM user_favorites WHERE user_id = %s AND recipe_id = %s", (user_id, recipe_id))
        is_favorited = cursor.fetchone() is not None

        cursor.close()
        conn.close()

        return jsonify({"is_favorited": is_favorited})

    except Exception as e:
        print(f"❌ Check favorite error: {e}")
        return jsonify({"error": "Failed to check favorite"}), 500

# Recipe Routes
@app.route('/search', methods=['GET'])
def search_recipe():
    try:
        query = request.args.get('q', '').strip().lower()
        category = request.args.get('category', '')
        difficulty = request.args.get('difficulty', '')
        max_time = request.args.get('max_time', '')
        tags = request.args.get('tags', '')

        conn = get_db_connection()
        if not conn:
            return jsonify({"error": "Database connection failed"}), 500

        cursor = conn.cursor(dictionary=True)

        # Use stored procedure for advanced search
        if tags:
            cursor.callproc('SearchRecipesAdvanced', [query or None, category or None, difficulty or None, int(max_time) if max_time else None, tags or None])
        else:
            # Basic search
            sql = """
                SELECT r.*, 
                       COALESCE(AVG(rt.rating), 0) as avg_rating,
                       COUNT(rt.id) as review_count,
                       COUNT(rv.id) as view_count,
                       n.calories, n.protein_g, n.carbs_g, n.fat_g, n.fiber_g
                FROM recipes r
                LEFT JOIN recipe_ratings rt ON r.id = rt.recipe_id
                LEFT JOIN recipe_views rv ON r.id = rv.recipe_id
                LEFT JOIN recipe_nutrition n ON r.id = n.recipe_id
                WHERE 1=1
            """
            
            params = []
            
            if query:
                sql += " AND (LOWER(r.name) LIKE %s OR LOWER(r.ingredients) LIKE %s OR LOWER(r.description) LIKE %s)"
                params.extend([f"%{query}%", f"%{query}%", f"%{query}%"])
            
            if category:
                sql += " AND r.category = %s"
                params.append(category)
                
            if difficulty:
                sql += " AND r.difficulty = %s"
                params.append(difficulty)
                
            if max_time:
                sql += " AND (r.prep_time + r.cook_time) <= %s"
                params.append(int(max_time))
            
            sql += " GROUP BY r.id ORDER BY r.name"
            cursor.execute(sql, params)

        recipes = []
        if tags:
            for result in cursor.stored_results():
                recipes = result.fetchall()
                break
        else:
            recipes = cursor.fetchall()

        cursor.close()
        conn.close()

        # Enhance recipe data
        for recipe in recipes:
            recipe['avg_rating'] = float(recipe['avg_rating']) if recipe['avg_rating'] else 0
            recipe['prep_time'] = int(recipe['prep_time']) if recipe['prep_time'] else 0
            recipe['cook_time'] = int(recipe['cook_time']) if recipe['cook_time'] else 0
            recipe['total_time'] = recipe['prep_time'] + recipe['cook_time']
            recipe['view_count'] = int(recipe['view_count']) if recipe['view_count'] else 0
            
            # Add nutrition info
            recipe['nutrition'] = {
                'calories': recipe.get('calories', estimate_calories(recipe)),
                'protein': f"{recipe.get('protein_g', 0)}g",
                'carbs': f"{recipe.get('carbs_g', 0)}g",
                'fat': f"{recipe.get('fat_g', 0)}g",
                'fiber': f"{recipe.get('fiber_g', 0)}g"
            }

        # Log search activity
        if query or category or difficulty or max_time:
            log_search_activity(query, category, difficulty, max_time, len(recipes))

        return jsonify(recipes)
    
    except Exception as e:
        print(f"❌ Search error: {e}")
        return jsonify({"error": "Failed to search recipes"}), 500

def estimate_calories(recipe):
    """Estimate calories based on recipe ingredients"""
    ingredients = recipe.get('ingredients', '').lower()
    if 'paneer' in ingredients or 'cheese' in ingredients:
        return 350
    elif 'chicken' in ingredients or 'meat' in ingredients:
        return 400
    elif 'rice' in ingredients:
        return 300
    elif 'dal' in ingredients or 'lentil' in ingredients:
        return 250
    elif 'vegetable' in ingredients:
        return 200
    else:
        return 280

def log_search_activity(query, category, difficulty, max_time, results_count):
    """Log search activity for analytics"""
    try:
        conn = get_db_connection()
        if not conn:
            return
        
        cursor = conn.cursor()
        session_id = get_session_id()
        
        search_query = f"q={query}&category={category}&difficulty={difficulty}&max_time={max_time}"
        
        cursor.execute("""
            INSERT INTO search_history (search_query, session_id, results_count)
            VALUES (%s, %s, %s)
        """, (search_query, session_id, results_count))
        
        conn.commit()
        cursor.close()
        conn.close()
    except Exception as e:
        print(f"❌ Failed to log search activity: {e}")

# Get recipe by ID
@app.route('/recipe/<int:recipe_id>', methods=['GET'])
def get_recipe(recipe_id):
    try:
        conn = get_db_connection()
        if not conn:
            return jsonify({"error": "Database connection failed"}), 500

        cursor = conn.cursor(dictionary=True)

        cursor.execute("""
            SELECT r.*, 
                   COALESCE(AVG(rt.rating), 0) as avg_rating,
                   COUNT(rt.id) as review_count,
                   COUNT(rv.id) as view_count,
                   n.calories, n.protein_g, n.carbs_g, n.fat_g, n.fiber_g
            FROM recipes r
            LEFT JOIN recipe_ratings rt ON r.id = rt.recipe_id
            LEFT JOIN recipe_views rv ON r.id = rv.recipe_id
            LEFT JOIN recipe_nutrition n ON r.id = n.recipe_id
            WHERE r.id = %s
            GROUP BY r.id
        """, (recipe_id,))
        
        recipe = cursor.fetchone()
        
        if not recipe:
            cursor.close()
            conn.close()
            return jsonify({"error": "Recipe not found"}), 404

        # Get recipe tags
        cursor.execute("""
            SELECT tag_name FROM recipe_tags WHERE recipe_id = %s
        """, (recipe_id,))
        tags = [row['tag_name'] for row in cursor.fetchall()]
        
        cursor.close()
        conn.close()

        # Enhance recipe data
        recipe['avg_rating'] = float(recipe['avg_rating']) if recipe['avg_rating'] else 0
        recipe['prep_time'] = int(recipe['prep_time']) if recipe['prep_time'] else 0
        recipe['cook_time'] = int(recipe['cook_time']) if recipe['cook_time'] else 0
        recipe['total_time'] = recipe['prep_time'] + recipe['cook_time']
        recipe['view_count'] = int(recipe['view_count']) if recipe['view_count'] else 0
        recipe['tags'] = tags
        
        # Add nutrition info
        recipe['nutrition'] = {
            'calories': recipe.get('calories', estimate_calories(recipe)),
            'protein': f"{recipe.get('protein_g', 0)}g",
            'carbs': f"{recipe.get('carbs_g', 0)}g",
            'fat': f"{recipe.get('fat_g', 0)}g",
            'fiber': f"{recipe.get('fiber_g', 0)}g"
        }

        # Log recipe view
        log_recipe_view(recipe_id)

        return jsonify(recipe)
    
    except Exception as e:
        print(f"❌ Database error: {e}")
        return jsonify({"error": "Failed to fetch recipe"}), 500

def log_recipe_view(recipe_id):
    """Log recipe view for popularity tracking"""
    try:
        conn = get_db_connection()
        if not conn:
            return
        
        cursor = conn.cursor()
        session_id = get_session_id()
        
        cursor.callproc('LogRecipeView', [recipe_id, session_id])
        
        conn.commit()
        cursor.close()
        conn.close()
    except Exception as e:
        print(f"❌ Failed to log recipe view: {e}")

# Get popular recipes
@app.route('/popular', methods=['GET'])
def get_popular_recipes():
    try:
        conn = get_db_connection()
        if not conn:
            return jsonify({"error": "Database connection failed"}), 500

        cursor = conn.cursor(dictionary=True)

        cursor.execute("""
            SELECT r.*, 
                   COALESCE(AVG(rt.rating), 0) as avg_rating,
                   COUNT(rt.id) as review_count,
                   COUNT(rv.id) as view_count
            FROM recipes r
            LEFT JOIN recipe_ratings rt ON r.id = rt.recipe_id
            LEFT JOIN recipe_views rv ON r.id = rv.recipe_id
            GROUP BY r.id
            ORDER BY view_count DESC, avg_rating DESC
            LIMIT 8
        """)
        
        recipes = cursor.fetchall()
        cursor.close()
        conn.close()

        for recipe in recipes:
            recipe['avg_rating'] = float(recipe['avg_rating']) if recipe['avg_rating'] else 0
            recipe['prep_time'] = int(recipe['prep_time']) if recipe['prep_time'] else 0
            recipe['cook_time'] = int(recipe['cook_time']) if recipe['cook_time'] else 0
            recipe['total_time'] = (recipe['prep_time'] or 0) + (recipe['cook_time'] or 0)
            recipe['view_count'] = int(recipe['view_count']) if recipe['view_count'] else 0

        return jsonify(recipes)
    
    except Exception as e:
        print(f"❌ Database error: {e}")
        return jsonify({"error": "Failed to fetch popular recipes"}), 500

# Get quick meals
@app.route('/quick-meals', methods=['GET'])
def get_quick_meals():
    try:
        conn = get_db_connection()
        if not conn:
            return jsonify({"error": "Database connection failed"}), 500

        cursor = conn.cursor(dictionary=True)

        cursor.execute("""
            SELECT r.*, 
                   COALESCE(AVG(rt.rating), 0) as avg_rating,
                   COUNT(rt.id) as review_count
            FROM recipes r
            LEFT JOIN recipe_ratings rt ON r.id = rt.recipe_id
            WHERE r.is_quick_meal = TRUE OR (r.prep_time + r.cook_time) <= 30
            GROUP BY r.id
            ORDER BY (r.prep_time + r.cook_time) ASC
            LIMIT 10
        """)
        
        recipes = cursor.fetchall()
        cursor.close()
        conn.close()

        for recipe in recipes:
            recipe['avg_rating'] = float(recipe['avg_rating']) if recipe['avg_rating'] else 0
            recipe['prep_time'] = int(recipe['prep_time']) if recipe['prep_time'] else 0
            recipe['cook_time'] = int(recipe['cook_time']) if recipe['cook_time'] else 0
            recipe['total_time'] = (recipe['prep_time'] or 0) + (recipe['cook_time'] or 0)

        return jsonify(recipes)
    
    except Exception as e:
        print(f"❌ Database error: {e}")
        return jsonify({"error": "Failed to fetch quick meals"}), 500

# Get featured recipes
@app.route('/featured', methods=['GET'])
def get_featured_recipes():
    try:
        conn = get_db_connection()
        if not conn:
            return jsonify({"error": "Database connection failed"}), 500

        cursor = conn.cursor(dictionary=True)

        cursor.execute("""
            SELECT r.*, 
                   COALESCE(AVG(rt.rating), 0) as avg_rating,
                   COUNT(rt.id) as review_count
            FROM recipes r
            LEFT JOIN recipe_ratings rt ON r.id = rt.recipe_id
            WHERE r.is_featured = TRUE
            GROUP BY r.id
            ORDER BY r.created_at DESC
            LIMIT 6
        """)
        
        recipes = cursor.fetchall()
        cursor.close()
        conn.close()

        for recipe in recipes:
            recipe['avg_rating'] = float(recipe['avg_rating']) if recipe['avg_rating'] else 0
            recipe['prep_time'] = int(recipe['prep_time']) if recipe['prep_time'] else 0
            recipe['cook_time'] = int(recipe['cook_time']) if recipe['cook_time'] else 0
            recipe['total_time'] = (recipe['prep_time'] or 0) + (recipe['cook_time'] or 0)

        return jsonify(recipes)
    
    except Exception as e:
        print(f"❌ Database error: {e}")
        return jsonify({"error": "Failed to fetch featured recipes"}), 500

# Get recipes by category
@app.route('/category/<category_name>', methods=['GET'])
def get_recipes_by_category(category_name):
    try:
        conn = get_db_connection()
        if not conn:
            return jsonify({"error": "Database connection failed"}), 500

        cursor = conn.cursor(dictionary=True)

        cursor.callproc('GetRecipesByCategory', [category_name])
        
        recipes = []
        for result in cursor.stored_results():
            recipes = result.fetchall()
            break
        
        cursor.close()
        conn.close()

        for recipe in recipes:
            recipe['avg_rating'] = float(recipe['avg_rating']) if recipe['avg_rating'] else 0
            recipe['prep_time'] = int(recipe['prep_time']) if recipe['prep_time'] else 0
            recipe['cook_time'] = int(recipe['cook_time']) if recipe['cook_time'] else 0
            recipe['total_time'] = (recipe['prep_time'] or 0) + (recipe['cook_time'] or 0)

        return jsonify(recipes)
    
    except Exception as e:
        print(f"❌ Database error: {e}")
        return jsonify({"error": "Failed to fetch category recipes"}), 500

# Get all categories
@app.route('/categories', methods=['GET'])
def get_categories():
    try:
        conn = get_db_connection()
        if not conn:
            return jsonify({"error": "Database connection failed"}), 500

        cursor = conn.cursor()

        cursor.execute("""
            SELECT DISTINCT category, COUNT(*) as recipe_count 
            FROM recipes 
            WHERE category IS NOT NULL 
            GROUP BY category 
            ORDER BY recipe_count DESC, category
        """)
        categories = [{'name': row[0], 'count': row[1]} for row in cursor.fetchall()]
        cursor.close()
        conn.close()

        return jsonify(categories)
    
    except Exception as e:
        print(f"❌ Database error: {e}")
        return jsonify({"error": "Failed to fetch categories"}), 500

# Get all tags
@app.route('/tags', methods=['GET'])
def get_tags():
    try:
        conn = get_db_connection()
        if not conn:
            return jsonify({"error": "Database connection failed"}), 500

        cursor = conn.cursor()

        cursor.execute("""
            SELECT DISTINCT tag_name, COUNT(*) as usage_count 
            FROM recipe_tags 
            GROUP BY tag_name 
            ORDER BY usage_count DESC, tag_name
            LIMIT 20
        """)
        tags = [{'name': row[0], 'count': row[1]} for row in cursor.fetchall()]
        cursor.close()
        conn.close()

        return jsonify(tags)
    
    except Exception as e:
        print(f"❌ Database error: {e}")
        return jsonify({"error": "Failed to fetch tags"}), 500

# Submit recipe rating
@app.route('/recipe/<int:recipe_id>/rate', methods=['POST'])
def rate_recipe(recipe_id):
    try:
        data = request.get_json()
        rating = data.get('rating')
        session_id = get_session_id()

        if not rating or not 1 <= int(rating) <= 5:
            return jsonify({"error": "Invalid rating"}), 400

        conn = get_db_connection()
        if not conn:
            return jsonify({"error": "Database connection failed"}), 500

        cursor = conn.cursor()

        # Check if user already rated this recipe
        cursor.execute("""
            SELECT id FROM recipe_ratings 
            WHERE recipe_id = %s AND session_id = %s
        """, (recipe_id, session_id))
        
        existing_rating = cursor.fetchone()

        if existing_rating:
            # Update existing rating
            cursor.execute("""
                UPDATE recipe_ratings 
                SET rating = %s, created_at = CURRENT_TIMESTAMP 
                WHERE id = %s
            """, (rating, existing_rating[0]))
        else:
            # Insert new rating
            cursor.execute("""
                INSERT INTO recipe_ratings (recipe_id, rating, session_id)
                VALUES (%s, %s, %s)
            """, (recipe_id, rating, session_id))

        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({"message": "Rating submitted successfully"})
    
    except Exception as e:
        print(f"❌ Rating error: {e}")
        return jsonify({"error": "Failed to submit rating"}), 500

# Get similar recipes
@app.route('/recipe/<int:recipe_id>/similar', methods=['GET'])
def get_similar_recipes(recipe_id):
    try:
        limit = request.args.get('limit', 4)
        
        conn = get_db_connection()
        if not conn:
            return jsonify({"error": "Database connection failed"}), 500

        cursor = conn.cursor(dictionary=True)
        cursor.callproc('GetSimilarRecipes', [recipe_id, int(limit)])
        
        similar_recipes = []
        for result in cursor.stored_results():
            similar_recipes = result.fetchall()
            break
        
        cursor.close()
        conn.close()

        for recipe in similar_recipes:
            recipe['avg_rating'] = float(recipe['avg_rating']) if recipe['avg_rating'] else 0
            recipe['prep_time'] = int(recipe['prep_time']) if recipe['prep_time'] else 0
            recipe['cook_time'] = int(recipe['cook_time']) if recipe['cook_time'] else 0
            recipe['total_time'] = (recipe['prep_time'] or 0) + (recipe['cook_time'] or 0)

        return jsonify(similar_recipes)
    
    except Exception as e:
        print(f"❌ Database error: {e}")
        return jsonify({"error": "Failed to fetch similar recipes"}), 500

# Get recipe statistics
@app.route('/stats', methods=['GET'])
def get_stats():
    try:
        conn = get_db_connection()
        if not conn:
            return jsonify({"error": "Database connection failed"}), 500

        cursor = conn.cursor(dictionary=True)

        # Get total recipes
        cursor.execute("SELECT COUNT(*) as total_recipes FROM recipes")
        total_recipes = cursor.fetchone()['total_recipes']

        # Get total categories
        cursor.execute("SELECT COUNT(DISTINCT category) as total_categories FROM recipes")
        total_categories = cursor.fetchone()['total_categories']

        # Get total tags
        cursor.execute("SELECT COUNT(DISTINCT tag_name) as total_tags FROM recipe_tags")
        total_tags = cursor.fetchone()['total_tags']

        # Get total views
        cursor.execute("SELECT COUNT(*) as total_views FROM recipe_views")
        total_views = cursor.fetchone()['total_views']

        # Get popular categories
        cursor.execute("""
            SELECT category, COUNT(*) as count 
            FROM recipes 
            WHERE category IS NOT NULL 
            GROUP BY category 
            ORDER BY count DESC 
            LIMIT 5
        """)
        popular_categories = cursor.fetchall()

        cursor.close()
        conn.close()

        return jsonify({
            "total_recipes": total_recipes,
            "total_categories": total_categories,
            "total_tags": total_tags,
            "total_views": total_views,
            "popular_categories": popular_categories
        })
    
    except Exception as e:
        print(f"❌ Database error: {e}")
        return jsonify({"error": "Failed to fetch statistics"}), 500

# Serve static files
@app.route('/')
def serve_index():
    return send_from_directory(os.path.dirname(__file__), 'recipe.html')

@app.route('/recipe.html')
def serve_recipe_html():
    return send_from_directory(os.path.dirname(__file__), 'recipe.html')

@app.route('/finder.html')
def serve_finder_html():
    return send_from_directory(os.path.dirname(__file__), 'finder.html')

@app.route('/recipe.css')
def serve_recipe_css():
    return send_from_directory(os.path.dirname(__file__), 'recipe.css')

@app.route('/finder.css')
def serve_finder_css():
    return send_from_directory(os.path.dirname(__file__), 'finder.css')

@app.route('/recipe.js')
def serve_recipe_js():
    return send_from_directory(os.path.dirname(__file__), 'recipe.js')

@app.route('/finder.js')
def serve_finder_js():
    return send_from_directory(os.path.dirname(__file__), 'finder.js')

# Route to serve image files
@app.route('/images/<path:filename>')
def serve_image(filename):
    try:
        images_dir = os.path.join(os.path.dirname(__file__), 'images')
        return send_from_directory(images_dir, filename)
    except FileNotFoundError:
        # Return a placeholder image if file not found
        return send_from_directory(images_dir, 'placeholder.jpg')

# Health check endpoint
@app.route('/health')
def health_check():
    try:
        conn = get_db_connection()
        if conn:
            conn.close()
            db_status = "connected"
        else:
            db_status = "disconnected"
    except:
        db_status = "error"

    return jsonify({
        "status": "healthy", 
        "message": "Recipe Finder API is running",
        "database": db_status,
        "timestamp": datetime.datetime.now().isoformat()
    })

# Error handlers
@app.errorhandler(404)
def not_found(error):
    return jsonify({"error": "Endpoint not found"}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({"error": "Internal server error"}), 500

if __name__ == '__main__':
    # Create images directory if it doesn't exist
    images_dir = os.path.join(os.path.dirname(__file__), 'images')
    if not os.path.exists(images_dir):
        os.makedirs(images_dir)
    
    print("🚀 Starting Enhanced Recipe Finder API server...")
    print("📍 Server running on: http://127.0.0.1:5000")
    print("🔐 Authentication endpoints:")
    print("   POST /register          - Register new user")
    print("   POST /login             - User login")
    print("   GET  /profile           - Get user profile (JWT)")
    print("   PUT  /profile           - Update profile (JWT)")
    print("   GET  /favorites         - List favorites (JWT)")
    print("   POST /favorites/<id>    - Add favorite (JWT)")
    print("   DELETE /favorites/<id>  - Remove favorite (JWT)")
    print("   GET  /favorites/check/<id> - Check favorite status (JWT)")
    print("📚 Available endpoints:")
    print("   GET  /search           - Search recipes with filters")
    print("   GET  /recipe/<id>      - Get recipe details")
    print("   GET  /popular          - Get popular recipes")
    print("   GET  /quick-meals      - Get quick meals")
    print("   GET  /featured         - Get featured recipes")
    print("   GET  /categories       - Get all categories")
    print("   GET  /tags             - Get popular tags")
    print("   GET  /category/<name>  - Get recipes by category")
    print("   GET  /stats            - Get application statistics")
    print("   POST /recipe/<id>/rate - Rate a recipe")
    print("   GET  /health           - Health check")
    
    app.run(debug=True, host='127.0.0.1', port=5000)