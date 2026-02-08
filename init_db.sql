-- Database creation removed to use default 'railway' database provided by host
-- CREATE DATABASE IF NOT EXISTS recipe_finder;
-- USE recipe_finder;

-- Enhanced recipes table without user dependencies
CREATE TABLE IF NOT EXISTS recipes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    ingredients TEXT NOT NULL,
    instructions TEXT NOT NULL,
    image_url VARCHAR(500),
    category VARCHAR(50),
    difficulty ENUM('Easy', 'Medium', 'Hard') DEFAULT 'Medium',
    prep_time INT,
    cook_time INT,
    servings INT DEFAULT 2,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    tags VARCHAR(500),
    cuisine_type VARCHAR(50),
    is_featured BOOLEAN DEFAULT FALSE,
    is_quick_meal BOOLEAN DEFAULT FALSE,
    INDEX name_index (name),
    INDEX category_index (category),
    INDEX difficulty_index (difficulty),
    INDEX prep_time_index (prep_time),
    INDEX featured_index (is_featured)
);

-- Recipe ratings without user dependency (using session/browser tracking)
CREATE TABLE IF NOT EXISTS recipe_ratings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    recipe_id INT,
    rating TINYINT CHECK (rating BETWEEN 1 AND 5),
    session_id VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (recipe_id) REFERENCES recipes(id),
    INDEX recipe_rating_index (recipe_id),
    INDEX session_index (session_id)
);

-- Recipe views tracking for popularity
CREATE TABLE IF NOT EXISTS recipe_views (
    id INT AUTO_INCREMENT PRIMARY KEY,
    recipe_id INT,
    session_id VARCHAR(100),
    viewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (recipe_id) REFERENCES recipes(id),
    INDEX recipe_views_index (recipe_id),
    INDEX view_date_index (viewed_at)
);

-- Search history for recommendations
CREATE TABLE IF NOT EXISTS search_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    search_query VARCHAR(255),
    session_id VARCHAR(100),
    results_count INT,
    searched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX search_query_index (search_query),
    INDEX search_date_index (searched_at)
);

-- Recipe tags for better categorization
CREATE TABLE IF NOT EXISTS recipe_tags (
    id INT AUTO_INCREMENT PRIMARY KEY,
    recipe_id INT,
    tag_name VARCHAR(50),
    FOREIGN KEY (recipe_id) REFERENCES recipes(id),
    INDEX tag_index (tag_name),
    UNIQUE KEY unique_recipe_tag (recipe_id, tag_name)
);

-- Nutrition information table
CREATE TABLE IF NOT EXISTS recipe_nutrition (
    id INT AUTO_INCREMENT PRIMARY KEY,
    recipe_id INT,
    calories INT,
    protein_g DECIMAL(5,2),
    carbs_g DECIMAL(5,2),
    fat_g DECIMAL(5,2),
    fiber_g DECIMAL(5,2),
    FOREIGN KEY (recipe_id) REFERENCES recipes(id),
    UNIQUE KEY unique_recipe_nutrition (recipe_id)
);

-- Insert sample recipes with enhanced data
INSERT INTO recipes (name, description, ingredients, instructions, image_url, category, difficulty, prep_time, cook_time, servings, tags, cuisine_type, is_featured, is_quick_meal) VALUES 
('Dal Tadka', 'A comforting lentil dish tempered with aromatic spices', 'Toor dal (1 cup), Cumin seeds (1 tsp), Garlic (4 cloves), Onion (1, chopped), Tomato (1, chopped), Turmeric (½ tsp), Ghee (2 tbsp), Coriander (for garnish), Salt (to taste)',
'1. Wash and pressure cook dal with turmeric and 2 cups of water until soft. 
2. Heat ghee in a pan, add cumin and let it splutter. 
3. Add garlic, onions, and sauté until golden. 
4. Add tomatoes and cook until mushy. 
5. Add cooked dal, salt, simmer for 10 minutes. 
6. Garnish with coriander and serve hot with rice.',
'daltadka.jpg', 'Main Course', 'Easy', 10, 20, 4, 'vegetarian,healthy,protein-rich', 'Indian', TRUE, FALSE),

('Paneer Butter Masala', 'Creamy and rich cottage cheese in tomato gravy', 'Paneer (200g, cubed), Butter (2 tbsp), Tomato puree (1 cup), Cream (¼ cup), Onion (1, chopped), Ginger garlic paste (1 tsp), Garam masala (1 tsp), Red chili powder (½ tsp), Salt (to taste)',
'1. Heat butter, sauté onion and ginger-garlic paste. 
2. Add tomato puree, chili powder, garam masala, and cook until oil separates. 
3. Add paneer cubes and cream, simmer for 5 minutes. 
4. Serve with naan or rice.',
'paneerbuttermasala.jpg', 'Main Course', 'Medium', 15, 25, 3, 'vegetarian,rich,creamy', 'Indian', TRUE, FALSE),

('Masala Dosa', 'Crispy rice crepe filled with spiced potatoes', 'Dosa batter, Potato (3), Onion (1), Mustard seeds (½ tsp), Curry leaves (few), Turmeric (¼ tsp), Oil (2 tbsp)',
'1. Make potato filling by sautéing onion, mustard seeds, curry leaves, and mashed potatoes. 
2. Spread dosa batter on pan, add filling, and fold. 
3. Serve with chutney and sambhar.',
'masaladosa.png', 'Breakfast', 'Medium', 20, 15, 2, 'breakfast,south-indian,crispy', 'South Indian', TRUE, TRUE),

('Veg Biryani', 'Fragrant rice cooked with mixed vegetables and spices', 'Basmati rice (1 cup), Mixed vegetables (1 cup), Onion (1), Tomato (1), Biryani masala (1 tbsp), Curd (2 tbsp), Oil, Mint, Coriander',
'1. Fry onions and add vegetables, tomato, and masala. 
2. Add rice and curd, cook with 2 cups of water. 
3. Garnish with mint and coriander.',
'vegbiryani.jpg', 'Main Course', 'Hard', 30, 40, 4, 'rice,festive,flavorful', 'Indian', TRUE, FALSE),

('Rajma Chawal', 'Kidney beans in spicy gravy served with rice', 'Kidney beans (1 cup), Onion (1), Tomato (2), Ginger garlic paste (1 tsp), Garam masala (1 tsp), Salt, Oil',
'1. Soak rajma overnight, pressure cook until soft. 
2. Make gravy with onion, tomato, and masala. 
3. Add rajma, cook for 15 mins, and serve with rice.',
'rajmachawal.jpg', 'Main Course', 'Easy', 15, 30, 3, 'comfort-food,protein,healthy', 'North Indian', FALSE, FALSE),

('Aloo Paratha', 'Whole wheat flatbread stuffed with spiced potatoes', 'Wheat flour (2 cups), Potato (2, boiled), Onion (1, chopped), Green chili, Coriander, Salt, Butter',
'1. Make dough with flour and water. 
2. Mix mashed potato, onion, chili, salt, coriander for filling. 
3. Roll paratha, stuff filling, cook on tawa with butter.',
'alooparatha.jpg', 'Breakfast', 'Easy', 20, 15, 2, 'breakfast,stuffed,wholesome', 'North Indian', FALSE, TRUE),

('Pav Bhaji', 'Spicy vegetable mash served with buttered bread', 'Potato (2), Tomato (2), Onion (1), Capsicum (1), Pav bhaji masala (2 tbsp), Butter (2 tbsp)',
'1. Boil and mash vegetables. 
2. Sauté onion and tomato with masala. 
3. Mix mashed veggies and butter, cook for 10 mins. 
4. Serve with butter-toasted pav.',
'pavbhaji.jpg', 'Snack', 'Medium', 20, 20, 2, 'street-food,spicy,quick', 'Maharashtrian', TRUE, TRUE),

('Palak Paneer', 'Cottage cheese in spinach gravy', 'Paneer (200g), Spinach (2 cups), Onion (1), Tomato (1), Garlic (3 cloves), Cream (2 tbsp), Spices',
'1. Blanch spinach and blend. 
2. Sauté onion, tomato, garlic, and add puree. 
3. Mix paneer cubes and simmer 5 minutes.',
'palakpaneer.jpg', 'Main Course', 'Easy', 15, 20, 3, 'healthy,green,protein', 'North Indian', FALSE, TRUE),

('Veg Manchurian', 'Vegetable balls in spicy Indo-Chinese sauce', 'Cabbage, Carrot, Flour, Soy sauce, Vinegar, Garlic, Ginger, Corn flour',
'1. Make balls with vegetables and fry. 
2. Prepare sauce using soy, vinegar, and garlic. 
3. Mix balls in sauce and serve hot.',
'vegmanchurian.jpg', 'Starter', 'Medium', 25, 15, 2, 'indochinese,starter,crispy', 'Indo-Chinese', FALSE, FALSE),

('Fried Rice', 'Quick and flavorful rice with vegetables', 'Rice (2 cups), Carrot, Beans, Capsicum, Soy sauce (2 tbsp), Vinegar (1 tbsp), Garlic (1 tsp)',
'1. Boil rice and let it cool. 
2. Sauté garlic and vegetables. 
3. Add rice, soy sauce, vinegar, toss well.',
'friedrice.jpg', 'Main Course', 'Easy', 10, 15, 2, 'quick,chinese,simple', 'Chinese', FALSE, TRUE),

('Gulab Jamun', 'Sweet milk dumplings in sugar syrup', 'Khoya (1 cup), Maida (2 tbsp), Sugar (1 cup), Cardamom (2), Oil',
'1. Mix khoya and maida, make soft balls. 
2. Fry in oil until brown. 
3. Soak in sugar syrup for 30 mins.',
'gulabjamun.jpg', 'Dessert', 'Medium', 30, 30, 6, 'sweet,festive,dessert', 'Indian', TRUE, FALSE),

('Pani Puri', 'Crispy puris filled with tangy water and fillings', 'Puri, Boiled potato, Chickpeas, Tamarind water, Mint chutney, Onion',
'1. Fill puris with potato and chickpeas. 
2. Add spicy tangy water and enjoy.',
'panipuri.jpg', 'Snack', 'Easy', 20, 10, 1, 'street-food,tangy,fun', 'Indian', FALSE, TRUE),

('Dhokla', 'Steamed savory gram flour cakes', 'Gram flour (1 cup), Curd (½ cup), Eno (1 tsp), Mustard seeds, Curry leaves',
'1. Mix batter with curd and eno. 
2. Steam for 15 mins. 
3. Temper with mustard seeds and curry leaves.',
'dhokla.png', 'Snack', 'Medium', 15, 20, 4, 'steamed,healthy,guajarati', 'Gujarati', FALSE, TRUE),

('Rasgulla', 'Soft cottage cheese balls in light syrup', 'Milk (1 liter), Lemon juice, Sugar (1 cup), Cardamom',
'1. Make chenna from milk and shape into balls. 
2. Boil in sugar syrup for 20 mins.',
'rasgulla.png', 'Dessert', 'Hard', 40, 30, 8, 'sweet,bengali,soft', 'Bengali', TRUE, FALSE);

-- Insert nutrition information
INSERT INTO recipe_nutrition (recipe_id, calories, protein_g, carbs_g, fat_g, fiber_g) VALUES
(1, 280, 12.5, 45.2, 8.3, 6.7),
(2, 420, 18.2, 25.8, 28.5, 3.2),
(3, 320, 8.7, 58.9, 9.2, 4.8),
(4, 380, 9.3, 68.4, 12.1, 7.2),
(5, 350, 15.2, 55.8, 9.8, 12.5),
(6, 290, 9.8, 48.5, 7.9, 5.3),
(7, 320, 11.2, 45.6, 12.8, 8.4),
(8, 280, 16.8, 22.4, 15.6, 6.9),
(9, 240, 6.8, 28.9, 11.2, 4.2),
(10, 310, 8.5, 58.3, 6.8, 5.7),
(11, 380, 8.2, 65.8, 12.4, 2.1),
(12, 180, 4.2, 35.6, 3.8, 3.5),
(13, 220, 12.8, 32.5, 5.9, 4.8),
(14, 280, 15.2, 42.8, 8.4, 0.8);

-- Insert recipe tags
INSERT INTO recipe_tags (recipe_id, tag_name) VALUES
(1, 'vegetarian'), (1, 'healthy'), (1, 'protein-rich'),
(2, 'vegetarian'), (2, 'rich'), (2, 'creamy'),
(3, 'breakfast'), (3, 'south-indian'), (3, 'crispy'),
(4, 'rice'), (4, 'festive'), (4, 'flavorful'),
(5, 'comfort-food'), (5, 'protein'), (5, 'healthy'),
(6, 'breakfast'), (6, 'stuffed'), (6, 'wholesome'),
(7, 'street-food'), (7, 'spicy'), (7, 'quick'),
(8, 'healthy'), (8, 'green'), (8, 'protein'),
(9, 'indochinese'), (9, 'starter'), (9, 'crispy'),
(10, 'quick'), (10, 'chinese'), (10, 'simple'),
(11, 'sweet'), (11, 'festive'), (11, 'dessert'),
(12, 'street-food'), (12, 'tangy'), (12, 'fun'),
(13, 'steamed'), (13, 'healthy'), (13, 'gujarati'),
(14, 'sweet'), (14, 'bengali'), (14, 'soft');

-- Create views for enhanced functionality
CREATE VIEW recipe_popularity AS
SELECT 
    r.id,
    r.name,
    r.category,
    r.difficulty,
    (r.prep_time + r.cook_time) as total_time,
    COALESCE(AVG(rt.rating), 0) as avg_rating,
    COUNT(rt.id) as rating_count,
    COUNT(rv.id) as view_count,
    r.is_featured,
    r.is_quick_meal
FROM recipes r
LEFT JOIN recipe_ratings rt ON r.id = rt.recipe_id
LEFT JOIN recipe_views rv ON r.id = rv.recipe_id
GROUP BY r.id;

CREATE VIEW quick_meals AS
SELECT *
FROM recipes 
WHERE is_quick_meal = TRUE OR (prep_time + cook_time) <= 30
ORDER BY (prep_time + cook_time) ASC;

CREATE VIEW featured_recipes AS
SELECT *
FROM recipes 
WHERE is_featured = TRUE
ORDER BY created_at DESC;

-- Create stored procedures for better performance
DELIMITER //
CREATE PROCEDURE GetRecipesByCategory(IN category_name VARCHAR(50))
BEGIN
    SELECT r.*, 
           COALESCE(AVG(rt.rating), 0) as avg_rating,
           COUNT(rt.id) as rating_count
    FROM recipes r
    LEFT JOIN recipe_ratings rt ON r.id = rt.recipe_id
    WHERE r.category = category_name
    GROUP BY r.id
    ORDER BY avg_rating DESC, r.name;
END //

CREATE PROCEDURE SearchRecipesAdvanced(
    IN search_query VARCHAR(255),
    IN category_filter VARCHAR(50),
    IN difficulty_filter VARCHAR(20),
    IN max_time INT,
    IN tags_list VARCHAR(500)
)
BEGIN
    SELECT DISTINCT r.*,
           COALESCE(AVG(rt.rating), 0) as avg_rating,
           COUNT(rt.id) as rating_count
    FROM recipes r
    LEFT JOIN recipe_ratings rt ON r.id = rt.recipe_id
    LEFT JOIN recipe_tags rtg ON r.id = rtg.recipe_id
    WHERE (search_query IS NULL OR r.name LIKE CONCAT('%', search_query, '%') OR r.ingredients LIKE CONCAT('%', search_query, '%'))
      AND (category_filter IS NULL OR r.category = category_filter)
      AND (difficulty_filter IS NULL OR r.difficulty = difficulty_filter)
      AND (max_time IS NULL OR (r.prep_time + r.cook_time) <= max_time)
      AND (tags_list IS NULL OR FIND_IN_SET(rtg.tag_name, tags_list))
    GROUP BY r.id
    ORDER BY avg_rating DESC, r.name;
END //

CREATE PROCEDURE LogRecipeView(IN recipe_id INT, IN session_id VARCHAR(100))
BEGIN
    INSERT INTO recipe_views (recipe_id, session_id) VALUES (recipe_id, session_id);
END //

CREATE PROCEDURE GetSimilarRecipes(IN recipe_id INT, IN limit_count INT)
BEGIN
    SELECT r2.*, 
           COALESCE(AVG(rt.rating), 0) as avg_rating
    FROM recipes r1
    JOIN recipes r2 ON r1.category = r2.category AND r1.id != r2.id
    LEFT JOIN recipe_ratings rt ON r2.id = rt.recipe_id
    WHERE r1.id = recipe_id
    GROUP BY r2.id
    ORDER BY COUNT(rt.id) DESC, avg_rating DESC
    LIMIT limit_count;
END //

DELIMITER ;

-- Insert 30+ new sample recipes with simple image names
INSERT INTO recipes (name, description, ingredients, instructions, image_url, category, difficulty, prep_time, cook_time, servings, tags, cuisine_type, is_featured, is_quick_meal) VALUES 

('Chicken Tikka Masala', 'Grilled chicken chunks in rich creamy tomato sauce', 'Chicken (500g), Yogurt (1 cup), Cream (½ cup), Tomato puree (1 cup), Ginger garlic paste (2 tsp), Garam masala (1 tsp), Kasuri methi (1 tbsp), Butter (2 tbsp), Salt, Lemon juice',
'1. Marinate chicken in yogurt and spices for 2 hours.
2. Grill chicken until cooked.
3. Prepare gravy with tomato puree, cream and spices.
4. Add grilled chicken and simmer for 10 minutes.
5. Garnish with cream and coriander.',
'chickentikka.jpg', 'Main Course', 'Medium', 30, 25, 4, 'non-vegetarian,creamy,spicy', 'Indian', TRUE, FALSE),

('Vegetable Fried Rice', 'Quick and easy rice stir-fried with fresh vegetables', 'Basmati rice (2 cups), Carrot (1), Capsicum (1), Beans (10), Spring onions (4), Soy sauce (2 tbsp), Vinegar (1 tbsp), Garlic (1 tbsp), Oil (2 tbsp), Salt, Pepper',
'1. Cook rice and let it cool.
2. Heat oil, sauté garlic and vegetables.
3. Add rice, soy sauce, vinegar and toss well.
4. Season with salt and pepper.
5. Garnish with spring onions.',
'friedrice.jpg', 'Main Course', 'Easy', 15, 10, 3, 'vegetarian,quick,chinese', 'Chinese', FALSE, TRUE),

('Butter Naan', 'Soft and fluffy leavened bread brushed with butter', 'Maida (2 cups), Yogurt (¼ cup), Yeast (1 tsp), Sugar (1 tsp), Salt, Butter (2 tbsp), Milk (¼ cup)',
'1. Activate yeast in warm milk with sugar.
2. Knead dough with all ingredients.
3. Let it rise for 2 hours.
4. Roll and cook on hot tawa.
5. Brush with butter and serve hot.',
'naan.jpg', 'Bread', 'Medium', 20, 10, 4, 'bread,buttery,soft', 'Indian', FALSE, TRUE),

('Mango Lassi', 'Refreshing yogurt-based mango drink', 'Ripe mango (2), Yogurt (2 cups), Milk (½ cup), Sugar (4 tbsp), Cardamom powder (½ tsp), Ice cubes, Saffron strands',
'1. Blend mango pulp with yogurt and milk.
2. Add sugar and cardamom powder.
3. Blend until smooth and frothy.
4. Serve chilled with ice cubes.
5. Garnish with saffron.',
'mangolassi.jpg', 'Beverage', 'Easy', 5, 0, 2, 'drink,sweet,refreshing', 'Indian', FALSE, TRUE),

('Egg Curry', 'Hard-boiled eggs in spicy onion-tomato gravy', 'Eggs (6), Onion (2), Tomato (2), Ginger garlic paste (1 tbsp), Turmeric (½ tsp), Red chili powder (1 tsp), Garam masala (1 tsp), Oil (3 tbsp), Coriander leaves',
'1. Boil eggs and peel them.
2. Sauté onions until golden brown.
3. Add tomatoes and cook until soft.
4. Add spices and cook until oil separates.
5. Add eggs and simmer for 5 minutes.',
'eggcurry.jpg', 'Main Course', 'Easy', 15, 20, 3, 'non-vegetarian,spicy,protein', 'Indian', FALSE, TRUE),

('Vegetable Soup', 'Healthy mixed vegetable clear soup', 'Carrot (1), Beans (10), Cabbage (¼), Cauliflower (5 florets), Peas (¼ cup), Corn (¼ cup), Vegetable stock (4 cups), Salt, Pepper, Spring onions',
'1. Chop all vegetables finely.
2. Boil vegetable stock.
3. Add vegetables and cook until tender.
4. Season with salt and pepper.
5. Garnish with spring onions.',
'vegetablesoup.jpg', 'Starter', 'Easy', 10, 15, 2, 'vegetarian,healthy,light', 'Continental', FALSE, TRUE),

('Fish Fry', 'Crispy marinated fish shallow fried to perfection', 'Fish fillets (4), Red chili powder (1 tsp), Turmeric (½ tsp), Lemon juice (2 tbsp), Rice flour (2 tbsp), Salt, Oil for frying',
'1. Marinate fish with spices and lemon juice.
2. Coat with rice flour.
3. Shallow fry until golden brown.
4. Flip and cook both sides.
5. Serve hot with lemon wedges.',
'fishfry.jpg', 'Starter', 'Easy', 10, 15, 2, 'non-vegetarian,crispy,seafood', 'Indian', FALSE, TRUE),

('Mushroom Masala', 'Button mushrooms in rich onion-tomato gravy', 'Mushrooms (200g), Onion (1), Tomato (1), Ginger garlic paste (1 tsp), Cream (2 tbsp), Cashew paste (2 tbsp), Garam masala (1 tsp), Oil (2 tbsp)',
'1. Clean and slice mushrooms.
2. Sauté onions until golden.
3. Add tomatoes and cook until soft.
4. Add mushrooms and cook for 5 minutes.
5. Add cream and cashew paste, simmer.',
'mushroommasala.jpg', 'Main Course', 'Medium', 15, 20, 2, 'vegetarian,creamy,rich', 'Indian', FALSE, TRUE),

('Chicken Biryani', 'Fragrant rice layered with spiced chicken', 'Basmati rice (2 cups), Chicken (500g), Onion (2), Yogurt (½ cup), Biryani masala (2 tbsp), Saffron, Mint leaves, Ghee (3 tbsp)',
'1. Marinate chicken with yogurt and spices.
2. Parboil rice with whole spices.
3. Layer rice and chicken in handi.
4. Cook on dum for 20 minutes.
5. Serve hot with raita.',
'chickenbiryani.jpg', 'Main Course', 'Hard', 40, 30, 4, 'non-vegetarian,rice,festive', 'Indian', TRUE, FALSE),

('Aloo Gobi', 'Classic potato and cauliflower dry curry', 'Potato (2), Cauliflower (1), Onion (1), Tomato (1), Turmeric (½ tsp), Red chili powder (1 tsp), Coriander powder (1 tsp), Oil (3 tbsp), Coriander leaves',
'1. Cut potatoes and cauliflower.
2. Heat oil, sauté onions until golden.
3. Add tomatoes and spices.
4. Add vegetables and cook covered.
5. Garnish with coriander leaves.',
'aloogobi.jpg', 'Main Course', 'Easy', 15, 20, 3, 'vegetarian,dry,classic', 'Indian', FALSE, TRUE),

('Tomato Soup', 'Creamy and comforting tomato soup', 'Tomatoes (6), Onion (1), Garlic (3 cloves), Vegetable stock (2 cups), Cream (2 tbsp), Sugar (1 tsp), Salt, Pepper, Basil leaves',
'1. Blanch and peel tomatoes.
2. Sauté onion and garlic.
3. Add tomatoes and cook until soft.
4. Blend and strain the mixture.
5. Add cream and seasonings.',
'tomatosoup.jpg', 'Starter', 'Easy', 10, 15, 2, 'vegetarian,creamy,comfort', 'Continental', FALSE, TRUE),

('Chicken Curry', 'Classic Indian chicken curry', 'Chicken (500g), Onion (2), Tomato (2), Ginger garlic paste (1 tbsp), Yogurt (2 tbsp), Garam masala (1 tsp), Oil (3 tbsp), Coriander leaves',
'1. Heat oil, sauté onions until brown.
2. Add ginger-garlic paste and cook.
3. Add tomatoes and cook until soft.
4. Add chicken and cook for 15 minutes.
5. Add yogurt and simmer for 10 minutes.',
'chickencurry.jpg', 'Main Course', 'Medium', 20, 25, 4, 'non-vegetarian,spicy,classic', 'Indian', FALSE, FALSE),

('Vegetable Pulao', 'Fragrant rice cooked with mixed vegetables', 'Basmati rice (2 cups), Mixed vegetables (1 cup), Onion (1), Ghee (2 tbsp), Cumin seeds (1 tsp), Bay leaf (1), Cardamom (2), Salt',
'1. Wash and soak rice for 30 minutes.
2. Heat ghee, temper with whole spices.
3. Add onions and vegetables, sauté.
4. Add rice and water, cook until done.
5. Fluff with fork and serve.',
'vegetablepulao.jpg', 'Main Course', 'Easy', 15, 20, 3, 'vegetarian,rice,light', 'Indian', FALSE, TRUE),

('Matar Paneer', 'Peas and cottage cheese in tomato gravy', 'Paneer (200g), Peas (1 cup), Onion (1), Tomato (2), Ginger (1 inch), Cream (2 tbsp), Garam masala (1 tsp), Oil (2 tbsp)',
'1. Sauté onion and ginger until golden.
2. Add tomatoes and cook until soft.
3. Add peas and cook for 5 minutes.
4. Add paneer cubes and cream.
5. Simmer for 5 minutes and serve.',
'matarpaneer.jpg', 'Main Course', 'Medium', 15, 20, 3, 'vegetarian,protein,creamy', 'Indian', FALSE, TRUE),

('Chicken Soup', 'Hearty and comforting chicken soup', 'Chicken (200g), Carrot (1), Celery (2 stalks), Onion (1), Garlic (2 cloves), Chicken stock (4 cups), Salt, Pepper, Parsley',
'1. Boil chicken until cooked, shred it.
2. Sauté vegetables in butter.
3. Add chicken stock and bring to boil.
4. Add shredded chicken.
5. Season with salt and pepper.',
'chickensoup.jpg', 'Starter', 'Easy', 15, 25, 2, 'non-vegetarian,healthy,comfort', 'Continental', FALSE, TRUE),

('Baingan Bharta', 'Smoky roasted eggplant mash', 'Eggplant (1 large), Onion (1), Tomato (1), Green chili (2), Garlic (3 cloves), Mustard oil (2 tbsp), Coriander leaves',
'1. Roast eggplant until charred and soft.
2. Peel and mash the pulp.
3. Heat oil, sauté onions and garlic.
4. Add tomatoes and cook until soft.
5. Add mashed eggplant and mix well.',
'bainganbharta.jpg', 'Main Course', 'Easy', 10, 20, 2, 'vegetarian,smoky,healthy', 'Indian', FALSE, TRUE),

('Chicken Roll', 'Spiced chicken wrapped in paratha', 'Chicken (300g), Paratha (4), Onion (1), Capsicum (1), Mayonnaise (2 tbsp), Chili sauce (1 tbsp), Salt, Pepper',
'1. Cook chicken with spices and shred.
2. Sauté onions and capsicum.
3. Mix with chicken and sauces.
4. Warm parathas and fill with mixture.
5. Roll tightly and serve.',
'chickenroll.jpg', 'Snack', 'Medium', 20, 15, 2, 'non-vegetarian,streetfood,quick', 'Indian', FALSE, TRUE),

('Vegetable Cutlet', 'Crispy fried vegetable patties', 'Potato (3), Mixed vegetables (1 cup), Bread crumbs (1 cup), Green chili (2), Coriander leaves, Salt, Oil for frying',
'1. Boil and mash potatoes.
2. Mix with chopped vegetables.
3. Shape into cutlets and coat with breadcrumbs.
4. Shallow fry until golden brown.
5. Serve with chutney.',
'vegetablecutlet.jpg', 'Snack', 'Easy', 20, 10, 4, 'vegetarian,crispy,tea-time', 'Indian', FALSE, TRUE),

('Mutton Curry', 'Rich and flavorful goat meat curry', 'Mutton (500g), Onion (2), Tomato (2), Ginger garlic paste (2 tbsp), Yogurt (¼ cup), Spices, Oil (3 tbsp), Coriander leaves',
'1. Marinate mutton with yogurt and spices.
2. Sauté onions until golden brown.
3. Add ginger-garlic paste and tomatoes.
4. Add mutton and pressure cook until tender.
5. Garnish with coriander leaves.',
'muttoncurry.jpg', 'Main Course', 'Hard', 30, 40, 4, 'non-vegetarian,rich,spicy', 'Indian', TRUE, FALSE),

('Corn Salad', 'Fresh and healthy corn vegetable salad', 'Sweet corn (1 cup), Cucumber (1), Tomato (1), Onion (1), Lemon juice (2 tbsp), Salt, Pepper, Mint leaves',
'1. Boil sweet corn until tender.
2. Chop all vegetables finely.
3. Mix everything in a bowl.
4. Add lemon juice and seasonings.
5. Chill for 30 minutes before serving.',
'cornsalad.jpg', 'Salad', 'Easy', 10, 5, 2, 'vegetarian,healthy,fresh', 'Continental', FALSE, TRUE),

('Chicken Kebab', 'Juicy and flavorful grilled chicken kebabs', 'Chicken mince (500g), Onion (1), Green chili (2), Ginger garlic paste (1 tbsp), Bread slices (2), Spices, Oil for grilling',
'1. Soak bread in water and squeeze.
2. Mix all ingredients thoroughly.
3. Shape into kebabs and refrigerate.
4. Grill or shallow fry until cooked.
5. Serve with mint chutney.',
'chickenkebab.jpg', 'Starter', 'Medium', 20, 15, 4, 'non-vegetarian,grilled,party', 'Indian', FALSE, FALSE),

('Vegetable Noodles', 'Stir-fried noodles with colorful vegetables', 'Noodles (200g), Carrot (1), Capsicum (1), Cabbage (¼), Spring onions (3), Soy sauce (2 tbsp), Vinegar (1 tbsp), Oil (2 tbsp)',
'1. Boil noodles as per package instructions.
2. Heat oil, sauté vegetables.
3. Add noodles and toss well.
4. Add sauces and mix thoroughly.
5. Garnish with spring onions.',
'vegetablenoodles.jpg', 'Main Course', 'Easy', 15, 10, 2, 'vegetarian,chinese,quick', 'Chinese', FALSE, TRUE),

('Egg Fried Rice', 'Quick egg fried rice with vegetables', 'Rice (2 cups), Eggs (3), Carrot (1), Beans (10), Spring onions (3), Soy sauce (2 tbsp), Oil (2 tbsp), Salt, Pepper',
'1. Cook rice and let it cool.
2. Scramble eggs and set aside.
3. Sauté vegetables until crisp.
4. Add rice, eggs and sauces.
5. Toss everything together.',
'eggfriedrice.jpg', 'Main Course', 'Easy', 10, 15, 2, 'non-vegetarian,quick,protein', 'Chinese', FALSE, TRUE),

('Chicken Momos', 'Steamed Tibetan dumplings with chicken filling', 'Chicken mince (300g), Cabbage (¼), Onion (1), Ginger garlic paste (1 tsp), Momo wrappers (20), Soy sauce, Vinegar',
'1. Mix chicken with vegetables and spices.
2. Fill wrappers with mixture.
3. Steam for 10-12 minutes.
4. Serve with spicy sauce.
5. Can be pan-fried for variation.',
'chickenmomos.jpg', 'Snack', 'Medium', 30, 15, 4, 'non-vegetarian,steamed,asian', 'Tibetan', FALSE, FALSE),

('Fruit Salad', 'Fresh mixed fruits with honey dressing', 'Apple (1), Banana (1), Orange (1), Grapes (1 cup), Pomegranate (½), Honey (2 tbsp), Lemon juice (1 tbsp), Mint leaves',
'1. Chop all fruits into bite-sized pieces.
2. Mix gently in a large bowl.
3. Add honey and lemon juice.
4. Chill for 30 minutes.
5. Garnish with mint leaves.',
'fruitsalad.jpg', 'Dessert', 'Easy', 15, 0, 2, 'vegetarian,fresh,healthy', 'Continental', FALSE, TRUE),

('Chicken Sandwich', 'Grilled chicken sandwich with vegetables', 'Chicken slices (200g), Bread slices (8), Lettuce (4 leaves), Tomato (1), Mayonnaise (3 tbsp), Butter (2 tbsp), Salt, Pepper',
'1. Grill or roast chicken slices.
2. Apply butter to bread slices.
3. Layer with lettuce, tomato, chicken.
4. Spread mayonnaise and season.
5. Grill until golden brown.',
'chickensandwich.jpg', 'Snack', 'Easy', 15, 10, 2, 'non-vegetarian,quick,healthy', 'Continental', FALSE, TRUE),

('Vegetable Burger', 'Crispy vegetable patty in burger bun', 'Burger buns (4), Potato (2), Peas (¼ cup), Carrot (1), Bread crumbs (½ cup), Cheese slices (4), Mayonnaise, Lettuce',
'1. Boil and mash potatoes with vegetables.
2. Make patties and shallow fry.
3. Toast burger buns.
4. Assemble with patty, cheese, vegetables.
5. Serve with sauces.',
'vegetableburger.jpg', 'Snack', 'Easy', 20, 10, 2, 'vegetarian,fastfood,crispy', 'Continental', FALSE, TRUE),

('Chocolate Shake', 'Rich and creamy chocolate milkshake', 'Milk (2 cups), Chocolate ice cream (2 scoops), Chocolate syrup (3 tbsp), Sugar (2 tbsp), Ice cubes, Whipped cream',
'1. Chill milk in refrigerator.
2. Blend milk with ice cream and chocolate syrup.
3. Add sugar and blend until frothy.
4. Pour into glasses.
5. Top with whipped cream and chocolate drizzle.',
'chocolateshake.jpg', 'Beverage', 'Easy', 5, 0, 2, 'drink,sweet,refreshing', 'Continental', FALSE, TRUE),

('Chicken Wings', 'Crispy baked chicken wings with spices', 'Chicken wings (10), Soy sauce (2 tbsp), Honey (1 tbsp), Garlic powder (1 tsp), Paprika (1 tsp), Oil (1 tbsp), Salt, Pepper',
'1. Marinate wings with all ingredients.
2. Preheat oven to 200°C.
3. Arrange wings on baking tray.
4. Bake for 25-30 minutes until crispy.
5. Serve with dip.',
'chickenwings.jpg', 'Starter', 'Easy', 10, 30, 2, 'non-vegetarian,crispy,party', 'American', FALSE, FALSE),

('Vegetable Pizza', 'Homemade pizza with fresh vegetables', 'Pizza base (1), Pizza sauce (3 tbsp), Mozzarella cheese (1 cup), Capsicum (1), Onion (1), Tomato (1), Olives, Oregano',
'1. Spread pizza sauce on base.
2. Add grated cheese generously.
3. Arrange vegetable toppings.
4. Bake at 200°C for 15 minutes.
5. Sprinkle oregano and serve.',
'vegetablepizza.jpg', 'Snack', 'Medium', 20, 15, 2, 'vegetarian,italian,cheesy', 'Italian', FALSE, FALSE),

('Chicken Pizza', 'Delicious chicken topping pizza', 'Pizza base (1), Chicken chunks (1 cup), Pizza sauce (3 tbsp), Cheese (1 cup), Onion (1), Capsicum (1), Olives, Oregano',
'1. Cook chicken with pizza seasoning.
2. Spread sauce on pizza base.
3. Add cheese, chicken and vegetables.
4. Bake at 200°C for 15-20 minutes.
5. Cut and serve hot.',
'chickenpizza.jpg', 'Snack', 'Medium', 25, 15, 2, 'non-vegetarian,cheesy,italian', 'Italian', FALSE, FALSE),

('Fruit Smoothie', 'Healthy and refreshing mixed fruit smoothie', 'Banana (1), Strawberries (½ cup), Yogurt (1 cup), Honey (2 tbsp), Milk (½ cup), Ice cubes, Chia seeds',
'1. Chop all fruits into small pieces.
2. Blend with yogurt and milk.
3. Add honey and ice cubes.
4. Blend until smooth and creamy.
5. Top with chia seeds and serve.',
'fruitsmoothie.jpg', 'Beverage', 'Easy', 5, 0, 2, 'drink,healthy,refreshing', 'Continental', FALSE, TRUE),

('Chicken Salad', 'Healthy grilled chicken salad', 'Chicken breast (200g), Lettuce (1 cup), Cucumber (1), Tomato (1), Olive oil (2 tbsp), Lemon juice (1 tbsp), Salt, Pepper',
'1. Grill chicken breast until cooked.
2. Chop all vegetables finely.
3. Slice chicken into strips.
4. Mix everything in a bowl.
5. Add dressing and toss well.',
'chickensalad.jpg', 'Salad', 'Easy', 15, 10, 2, 'non-vegetarian,healthy,protein', 'Continental', FALSE, TRUE),

('Vegetable Spring Rolls', 'Crispy fried rolls with vegetable filling', 'Spring roll wrappers (10), Cabbage (¼), Carrot (1), Beans (10), Soy sauce (1 tbsp), Salt, Pepper, Oil for frying',
'1. Shred all vegetables finely.
2. Sauté vegetables with soy sauce.
3. Cool the filling completely.
4. Wrap in spring roll sheets.
5. Deep fry until golden brown.',
'springrolls.jpg', 'Snack', 'Medium', 25, 15, 4, 'vegetarian,crispy,chinese', 'Chinese', FALSE, FALSE);

-- Insert nutrition information for new recipes
INSERT INTO recipe_nutrition (recipe_id, calories, protein_g, carbs_g, fat_g, fiber_g) VALUES
(15, 320, 25.5, 12.8, 18.2, 3.2),
(16, 280, 8.2, 52.3, 6.8, 4.5),
(17, 220, 7.5, 38.9, 4.2, 2.8),
(18, 180, 6.8, 28.4, 5.1, 3.7),
(19, 290, 22.8, 15.6, 16.3, 4.2),
(20, 350, 28.5, 18.9, 19.2, 5.1),
(21, 190, 8.2, 32.8, 4.8, 6.2),
(22, 320, 26.8, 12.4, 18.9, 2.8),
(23, 380, 18.5, 45.2, 14.8, 5.3),
(24, 310, 12.8, 48.6, 8.2, 4.1),
(25, 280, 15.2, 35.8, 9.6, 3.7),
(26, 420, 22.8, 52.3, 14.2, 6.8),
(27, 180, 4.2, 38.5, 2.1, 5.2),
(28, 320, 18.5, 42.8, 9.8, 3.2),
(29, 290, 8.9, 45.6, 8.5, 4.8),
(30, 380, 12.5, 58.9, 12.8, 5.1),
(31, 420, 25.8, 35.2, 20.5, 3.8),
(32, 320, 15.8, 42.6, 12.4, 4.2),
(33, 350, 18.9, 45.8, 14.2, 5.1),
(34, 280, 22.8, 12.5, 16.8, 3.2),
(35, 320, 25.6, 18.9, 18.2, 4.1),
(36, 290, 12.8, 38.5, 9.6, 4.8),
(37, 380, 28.5, 22.4, 20.8, 3.5),
(38, 420, 18.9, 52.6, 16.2, 5.8),
(39, 180, 6.2, 32.8, 4.1, 6.2),
(40, 320, 25.8, 18.5, 18.9, 4.5),
(41, 280, 8.5, 45.2, 8.9, 5.2),
(42, 350, 12.8, 52.8, 12.5, 6.1),
(43, 290, 6.8, 58.9, 8.2, 7.2),
(44, 320, 22.8, 28.5, 16.8, 4.8);

-- Insert tags for new recipes
INSERT INTO recipe_tags (recipe_id, tag_name) VALUES
(15, 'non-vegetarian'), (15, 'creamy'), (15, 'spicy'),
(16, 'vegetarian'), (16, 'quick'), (16, 'chinese'),
(17, 'bread'), (17, 'buttery'), (17, 'soft'),
(18, 'drink'), (18, 'sweet'), (18, 'refreshing'),
(19, 'non-vegetarian'), (19, 'spicy'), (19, 'protein'),
(20, 'vegetarian'), (20, 'healthy'), (20, 'light'),
(21, 'non-vegetarian'), (21, 'crispy'), (21, 'seafood'),
(22, 'vegetarian'), (22, 'creamy'), (22, 'rich'),
(23, 'non-vegetarian'), (23, 'rice'), (23, 'festive'),
(24, 'vegetarian'), (24, 'dry'), (24, 'classic'),
(25, 'vegetarian'), (25, 'creamy'), (25, 'comfort'),
(26, 'non-vegetarian'), (26, 'spicy'), (26, 'classic'),
(27, 'vegetarian'), (27, 'rice'), (27, 'light'),
(28, 'vegetarian'), (28, 'protein'), (28, 'creamy'),
(29, 'non-vegetarian'), (29, 'healthy'), (29, 'comfort'),
(30, 'vegetarian'), (30, 'smoky'), (30, 'healthy'),
(31, 'non-vegetarian'), (31, 'streetfood'), (31, 'quick'),
(32, 'vegetarian'), (32, 'crispy'), (32, 'tea-time'),
(33, 'non-vegetarian'), (33, 'rich'), (33, 'spicy'),
(34, 'vegetarian'), (34, 'healthy'), (34, 'fresh'),
(35, 'non-vegetarian'), (35, 'grilled'), (35, 'party'),
(36, 'vegetarian'), (36, 'chinese'), (36, 'quick'),
(37, 'non-vegetarian'), (37, 'quick'), (37, 'protein'),
(38, 'non-vegetarian'), (38, 'steamed'), (38, 'asian'),
(39, 'vegetarian'), (39, 'fresh'), (39, 'healthy'),
(40, 'non-vegetarian'), (40, 'quick'), (40, 'healthy'),
(41, 'vegetarian'), (41, 'fastfood'), (41, 'crispy'),
(42, 'drink'), (42, 'sweet'), (42, 'refreshing'),
(43, 'non-vegetarian'), (43, 'crispy'), (43, 'party'),
(44, 'vegetarian'), (44, 'italian'), (44, 'cheesy');

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    is_active BOOLEAN DEFAULT TRUE
);

-- User favorites table
CREATE TABLE IF NOT EXISTS user_favorites (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    recipe_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_recipe (user_id, recipe_id)
);

-- Add indexes for better performance
CREATE INDEX idx_user_favorites_user ON user_favorites(user_id);
CREATE INDEX idx_user_favorites_recipe ON user_favorites(recipe_id);
CREATE INDEX idx_users_email ON users(email);
