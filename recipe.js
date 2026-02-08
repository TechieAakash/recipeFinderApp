// Recipe App JavaScript with Authentication
class RecipeApp {
    constructor() {
        this.recipes = [];
        this.categories = [];
        this.tags = [];
        this.currentView = 'grid';
        this.currentTab = 'all-recipes';
        this.currentFilters = {
            query: '',
            category: '',
            difficulty: '',
            max_time: '',
            sort: 'name'
        };
        this.sessionId = this.generateSessionId();
        this.token = localStorage.getItem('recipeToken');
        this.user = JSON.parse(localStorage.getItem('recipeUser') || 'null');

        this.init();
    }

    generateSessionId() {
        return 'session_' + Math.random().toString(36).substr(2, 9) + Date.now().toString(36);
    }

    init() {
        this.bindEvents();
        this.checkAuthState();
        this.loadInitialData();
        this.updateStats();
    }

    bindEvents() {
        // Search functionality
        document.getElementById('searchButton').addEventListener('click', () => this.searchRecipes());
        document.getElementById('searchInput').addEventListener('keypress', (e) => {
            if (e.key === 'Enter') this.searchRecipes();
        });

        // Show all recipes
        document.getElementById('showAllButton').addEventListener('click', () => this.showAllRecipes());

        // Filter changes
        document.getElementById('categoryFilter').addEventListener('change', () => this.applyFilters());
        document.getElementById('difficultyFilter').addEventListener('change', () => this.applyFilters());
        document.getElementById('timeFilter').addEventListener('change', () => this.applyFilters());
        document.getElementById('sortFilter').addEventListener('change', () => this.applyFilters());

        // Tab navigation
        document.querySelectorAll('.tab-link').forEach(tab => {
            tab.addEventListener('click', (e) => this.switchTab(e.target.dataset.tab));
        });

        // View toggle
        document.querySelectorAll('.view-btn').forEach(btn => {
            btn.addEventListener('click', (e) => this.toggleView(e.target.dataset.view));
        });

        // Advanced filters toggle
        document.querySelector('.filter-toggle').addEventListener('click', () => this.toggleFilters());

        // Modal close
        document.querySelectorAll('.close').forEach(closeBtn => {
            closeBtn.addEventListener('click', (e) => {
                const modal = e.target.closest('.modal');
                this.closeModal(modal);
            });
        });

        // Modal background close
        document.querySelectorAll('.modal').forEach(modal => {
            modal.addEventListener('click', (e) => {
                if (e.target === modal) this.closeModal(modal);
            });
        });

        // Quick category clicks
        document.addEventListener('click', (e) => {
            if (e.target.classList.contains('category-tag')) {
                const category = e.target.dataset.category;
                this.filterByCategory(category);
            }
        });

        // Category card clicks
        document.addEventListener('click', (e) => {
            if (e.target.classList.contains('view-category')) {
                const category = e.target.dataset.category;
                this.switchTab('all-recipes');
                this.filterByCategory(category);
            }
        });

        // Auth events
        this.bindAuthEvents();
    }

    bindAuthEvents() {
        // Auth buttons
        document.getElementById('loginButton').addEventListener('click', () => this.showLoginModal());
        document.getElementById('registerButton').addEventListener('click', () => this.showRegisterModal());
        document.getElementById('profileButton').addEventListener('click', () => this.showProfileModal());
        document.getElementById('favoritesButton').addEventListener('click', () => this.showFavoritesTab());
        
        // Auth modal switches
        document.getElementById('showRegister').addEventListener('click', (e) => {
            e.preventDefault();
            this.showRegisterModal();
        });
        
        document.getElementById('showLogin').addEventListener('click', (e) => {
            e.preventDefault();
            this.showLoginModal();
        });

        // Auth forms
        document.getElementById('loginForm').addEventListener('submit', (e) => this.handleLogin(e));
        document.getElementById('registerForm').addEventListener('submit', (e) => this.handleRegister(e));
        document.getElementById('profileForm').addEventListener('submit', (e) => this.handleProfileUpdate(e));

        // Profile actions
        document.getElementById('editProfile').addEventListener('click', () => this.editProfile());
        document.getElementById('cancelEdit').addEventListener('click', () => this.cancelEdit());
        
        // Logout buttons
        document.getElementById('logoutButton').addEventListener('click', () => this.handleLogout());
        document.getElementById('logoutDropdown').addEventListener('click', (e) => {
            e.preventDefault();
            this.handleLogout();
        });

        // User menu
        document.getElementById('userAvatar').addEventListener('click', () => this.toggleUserDropdown());
        
        // Favorites tab auth
        document.getElementById('loginFromFavorites').addEventListener('click', () => this.showLoginModal());
        
        // Close dropdown when clicking outside
        document.addEventListener('click', (e) => {
            if (!e.target.closest('.user-menu')) {
                document.getElementById('userDropdown').classList.remove('show');
            }
        });
    }

    checkAuthState() {
        if (this.token && this.user) {
            this.showUserMenu();
            this.verifyToken();
        } else {
            this.showAuthButtons();
        }
    }

    async verifyToken() {
        try {
            await this.fetchAPI('/profile');
            // Token is valid
        } catch (error) {
            // Token is invalid
            this.handleLogout();
        }
    }

    showAuthButtons() {
        document.getElementById('authButtons').style.display = 'flex';
        document.getElementById('userMenu').style.display = 'none';
        document.getElementById('favoritesContent').style.display = 'none';
        document.getElementById('favoritesAuthRequired').style.display = 'block';
    }

    showUserMenu() {
        document.getElementById('authButtons').style.display = 'none';
        document.getElementById('userMenu').style.display = 'flex';
        document.getElementById('usernameDisplay').textContent = this.user.username;
        
        // Show favorites content if on favorites tab
        if (this.currentTab === 'favorites') {
            document.getElementById('favoritesAuthRequired').style.display = 'none';
            document.getElementById('favoritesContent').style.display = 'block';
            this.loadFavorites();
        }
    }

    toggleUserDropdown() {
        document.getElementById('userDropdown').classList.toggle('show');
    }

    showLoginModal() {
        this.closeAllModals();
        document.getElementById('loginModal').style.display = 'block';
        this.clearAuthErrors();
    }

    showRegisterModal() {
        this.closeAllModals();
        document.getElementById('registerModal').style.display = 'block';
        this.clearAuthErrors();
    }

    showProfileModal() {
        this.closeAllModals();
        this.loadProfile();
        document.getElementById('profileModal').style.display = 'block';
        this.toggleUserDropdown();
    }

    closeAllModals() {
        document.querySelectorAll('.modal').forEach(modal => {
            modal.style.display = 'none';
        });
    }

    closeModal(modal) {
        if (modal) {
            modal.style.display = 'none';
        }
    }

    clearAuthErrors() {
        document.querySelectorAll('.error-message').forEach(el => {
            el.classList.remove('show');
        });
    }

    showError(elementId, message) {
        const element = document.getElementById(elementId);
        element.textContent = message;
        element.classList.add('show');
    }

    async handleLogin(e) {
        e.preventDefault();
        
        const email = document.getElementById('loginEmail').value;
        const password = document.getElementById('loginPassword').value;
        
        this.clearAuthErrors();

        try {
            const data = await this.fetchAPI('/login', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ email, password })
            });

            this.token = data.token;
            this.user = data.user;
            
            localStorage.setItem('recipeToken', this.token);
            localStorage.setItem('recipeUser', JSON.stringify(this.user));
            
            this.showUserMenu();
            this.closeAllModals();
            this.showSuccess('Login successful!');
            
            // Reload favorites if on favorites tab
            if (this.currentTab === 'favorites') {
                this.loadFavorites();
            }

        } catch (error) {
            this.showError('loginPasswordError', error.message || 'Login failed');
        }
    }

    async handleRegister(e) {
        e.preventDefault();
        
        const username = document.getElementById('registerUsername').value;
        const email = document.getElementById('registerEmail').value;
        const password = document.getElementById('registerPassword').value;
        
        this.clearAuthErrors();

        try {
            const data = await this.fetchAPI('/register', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ username, email, password })
            });

            this.token = data.token;
            this.user = data.user;
            
            localStorage.setItem('recipeToken', this.token);
            localStorage.setItem('recipeUser', JSON.stringify(this.user));
            
            this.showUserMenu();
            this.closeAllModals();
            this.showSuccess('Registration successful! Welcome to Recipe Finder!');

        } catch (error) {
            this.showError('registerPasswordError', error.message || 'Registration failed');
        }
    }

    async handleProfileUpdate(e) {
        e.preventDefault();
        
        const username = document.getElementById('profileUsername').value;
        
        try {
            await this.fetchAPI('/profile', {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${this.token}`
                },
                body: JSON.stringify({ username })
            });

            this.user.username = username;
            localStorage.setItem('recipeUser', JSON.stringify(this.user));
            
            document.getElementById('usernameDisplay').textContent = username;
            this.cancelEdit();
            this.showSuccess('Profile updated successfully!');

        } catch (error) {
            this.showError('profileUsernameError', error.message || 'Profile update failed');
        }
    }

    handleLogout() {
        this.token = null;
        this.user = null;
        localStorage.removeItem('recipeToken');
        localStorage.removeItem('recipeUser');
        
        this.showAuthButtons();
        this.closeAllModals();
        this.showSuccess('Logged out successfully');
        
        // If on favorites tab, switch to all recipes
        if (this.currentTab === 'favorites') {
            this.switchTab('all-recipes');
        }
    }

    async loadProfile() {
        try {
            const data = await this.fetchAPI('/profile');
            this.displayProfile(data.user);
        } catch (error) {
            this.showError('Failed to load profile');
        }
    }

    displayProfile(user) {
        const profileInfo = document.getElementById('profileInfo');
        profileInfo.innerHTML = `
            <div class="profile-avatar">
                <i class="fas fa-user"></i>
            </div>
            <div class="profile-info">
                <h3>${user.username}</h3>
                <p>${user.email}</p>
                <p><small>Member since ${new Date(user.created_at).toLocaleDateString()}</small></p>
                ${user.last_login ? `<p><small>Last login: ${new Date(user.last_login).toLocaleDateString()}</small></p>` : ''}
            </div>
        `;
        
        document.getElementById('profileUsername').value = user.username;
    }

    editProfile() {
        document.getElementById('profileInfo').style.display = 'none';
        document.getElementById('profileForm').style.display = 'block';
        document.getElementById('editProfile').style.display = 'none';
    }

    cancelEdit() {
        document.getElementById('profileInfo').style.display = 'block';
        document.getElementById('profileForm').style.display = 'none';
        document.getElementById('editProfile').style.display = 'block';
        this.clearAuthErrors();
    }

    showFavoritesTab() {
        this.switchTab('favorites');
        this.toggleUserDropdown();
    }

    async loadFavorites() {
        if (!this.token) return;

        try {
            const favorites = await this.fetchAPI('/favorites');
            this.displayRecipes(favorites, 'favoritesContent');
        } catch (error) {
            document.getElementById('favoritesContent').innerHTML = 
                '<div class="error">Failed to load favorites</div>';
        }
    }

    async toggleFavorite(recipeId, isFavorited) {
        if (!this.token) {
            this.showLoginModal();
            return;
        }

        try {
            if (isFavorited) {
                await this.fetchAPI(`/favorites/${recipeId}`, {
                    method: 'DELETE',
                    headers: {
                        'Authorization': `Bearer ${this.token}`
                    }
                });
            } else {
                await this.fetchAPI(`/favorites/${recipeId}`, {
                    method: 'POST',
                    headers: {
                        'Authorization': `Bearer ${this.token}`
                    }
                });
            }

            // Update UI
            const favoriteBtn = document.querySelector(`[data-recipe-id="${recipeId}"] .favorite-btn`);
            if (favoriteBtn) {
                favoriteBtn.classList.toggle('favorited', !isFavorited);
                favoriteBtn.innerHTML = !isFavorited ? 
                    '<i class="fas fa-heart"></i> Favorited' : 
                    '<i class="far fa-heart"></i> Add to Favorites';
            }

            // Reload favorites if on favorites tab
            if (this.currentTab === 'favorites') {
                this.loadFavorites();
            }

        } catch (error) {
            this.showError('Failed to update favorites');
        }
    }

    async checkFavoriteStatus(recipeId) {
        if (!this.token) return false;

        try {
            const data = await this.fetchAPI(`/favorites/check/${recipeId}`);
            return data.is_favorited;
        } catch (error) {
            return false;
        }
    }

    async loadInitialData() {
        try {
            await Promise.all([
                this.loadCategories(),
                this.loadAllRecipes(),
                this.loadPopularRecipes(),
                this.loadQuickMeals(),
                this.loadTags(),
                this.loadFeaturedRecipes()
            ]);
        } catch (error) {
            console.error('Error loading initial data:', error);
            this.showError('Failed to load initial data');
        }
    }

    async fetchAPI(endpoint, options = {}) {
        try {
            const config = {
                headers: {
                    'X-Session-ID': this.sessionId,
                    ...options.headers
                },
                ...options
            };

            // Add authorization header if token exists
            if (this.token && !config.headers['Authorization']) {
                config.headers['Authorization'] = `Bearer ${this.token}`;
            }

            const response = await fetch(`${endpoint}`, config);
            
            if (!response.ok) {
                const errorData = await response.json().catch(() => ({}));
                throw new Error(errorData.error || `HTTP error! status: ${response.status}`);
            }
            
            return await response.json();
        } catch (error) {
            console.error(`API Error (${endpoint}):`, error);
            throw error;
        }
    }

    async loadAllRecipes() {
        try {
            this.recipes = await this.fetchAPI('/search');
            this.displayRecipes(this.recipes, 'results');
            this.updateResultsCount(this.recipes.length);
        } catch (error) {
            this.showError('Failed to load recipes');
        }
    }

    async loadCategories() {
        try {
            const categoriesData = await this.fetchAPI('/categories');
            this.categories = categoriesData;
            this.populateCategoryFilters();
            this.displayCategories();
        } catch (error) {
            this.showError('Failed to load categories');
        }
    }

    async loadTags() {
        try {
            this.tags = await this.fetchAPI('/tags');
        } catch (error) {
            console.error('Failed to load tags:', error);
        }
    }

    async loadPopularRecipes() {
        try {
            const recipes = await this.fetchAPI('/popular');
            this.displayRecipes(recipes, 'popularResults');
        } catch (error) {
            document.getElementById('popularResults').innerHTML = 
                '<div class="error">Failed to load popular recipes</div>';
        }
    }

    async loadQuickMeals() {
        try {
            const recipes = await this.fetchAPI('/quick-meals');
            this.displayRecipes(recipes, 'quickMealsResults');
        } catch (error) {
            document.getElementById('quickMealsResults').innerHTML = 
                '<div class="error">Failed to load quick meals</div>';
        }
    }

    async loadFeaturedRecipes() {
        try {
            const recipes = await this.fetchAPI('/featured');
            // You can display featured recipes in a special section if needed
            console.log('Featured recipes loaded:', recipes);
        } catch (error) {
            console.error('Failed to load featured recipes:', error);
        }
    }

    populateCategoryFilters() {
        const categoryFilter = document.getElementById('categoryFilter');
        const quickCategories = document.getElementById('quickCategories');

        // Clear existing options except the first one
        while (categoryFilter.children.length > 1) {
            categoryFilter.removeChild(categoryFilter.lastChild);
        }
        quickCategories.innerHTML = '';

        this.categories.forEach(category => {
            // Handle both string and object formats
            const categoryName = typeof category === 'object' ? category.name : category;
            const recipeCount = typeof category === 'object' ? category.count : '';

            // Add to filter dropdown
            const option = document.createElement('option');
            option.value = categoryName;
            option.textContent = recipeCount ? `${categoryName} (${recipeCount})` : categoryName;
            categoryFilter.appendChild(option);

            // Add to quick categories
            const tag = document.createElement('span');
            tag.className = 'category-tag';
            tag.dataset.category = categoryName;
            tag.textContent = categoryName;
            if (recipeCount) {
                tag.innerHTML = `${categoryName} <small>(${recipeCount})</small>`;
            }
            quickCategories.appendChild(tag);
        });
    }

    displayCategories() {
        const categoriesList = document.getElementById('categoriesList');
        categoriesList.innerHTML = '';

        this.categories.forEach(category => {
            const categoryName = typeof category === 'object' ? category.name : category;
            const recipeCount = typeof category === 'object' ? category.count : '';

            const categoryCard = document.createElement('div');
            categoryCard.className = 'category-card';
            categoryCard.innerHTML = `
                <div class="category-icon">
                    <i class="fas fa-utensils"></i>
                </div>
                <h4>${categoryName}</h4>
                ${recipeCount ? `<p class="recipe-count">${recipeCount} recipes</p>` : ''}
                <button class="btn-secondary view-category" data-category="${categoryName}">
                    View Recipes
                </button>
            `;

            categoriesList.appendChild(categoryCard);
        });
    }

    displayRecipes(recipes, containerId) {
        const container = document.getElementById(containerId);
        
        if (!recipes || recipes.length === 0) {
            container.innerHTML = '<div class="no-results">No recipes found</div>';
            return;
        }

        // Create recipe cards
        const recipeCards = [];
        for (const recipe of recipes) {
            const card = this.createRecipeCard(recipe);
            recipeCards.push(card);
        }
        container.innerHTML = recipeCards.join('');
        
        // Add event listeners
        container.querySelectorAll('.recipe-card').forEach(card => {
            card.addEventListener('click', (e) => {
                if (!e.target.closest('.recipe-actions')) {
                    this.showRecipeDetails(card.dataset.recipeId);
                }
            });
        });

        // Add favorite button events
        container.querySelectorAll('.favorite-btn').forEach(async (btn) => {
            const recipeId = btn.dataset.recipeId;
            const isFavorited = await this.checkFavoriteStatus(recipeId);
            
            if (isFavorited) {
                btn.classList.add('favorited');
                btn.innerHTML = '<i class="fas fa-heart"></i> Favorited';
            }
            
            btn.addEventListener('click', async (e) => {
                e.stopPropagation();
                await this.toggleFavorite(recipeId, isFavorited);
            });
        });

        // Add view recipe button events
        container.querySelectorAll('.view-recipe').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.stopPropagation();
                const recipeId = e.target.closest('.recipe-card').dataset.recipeId;
                this.showRecipeDetails(recipeId);
            });
        });
    }

    createRecipeCard(recipe) {
        const totalTime = (recipe.prep_time || 0) + (recipe.cook_time || 0);
        const rating = recipe.avg_rating || 0;
        const reviewCount = recipe.review_count || 0;

        return `
            <div class="recipe-card" data-recipe-id="${recipe.id}">
                <div class="recipe-image">
                    ${recipe.image_url ? 
                        `<img src="/images/${recipe.image_url}" alt="${recipe.name}" onerror="this.src='https://via.placeholder.com/300x200/4CAF50/white?text=No+Image'">` :
                        `<div class="no-image">No Image</div>`
                    }
                    <div class="recipe-badge ${recipe.difficulty?.toLowerCase() || 'medium'}">
                        ${recipe.difficulty || 'Medium'}
                    </div>
                </div>
                <div class="recipe-info">
                    <h4 class="recipe-title">${recipe.name}</h4>
                    <p class="recipe-description">${recipe.description || 'A delicious recipe waiting to be tried!'}</p>
                    
                    <div class="recipe-meta">
                        <span class="time">
                            <i class="fas fa-clock"></i> ${totalTime} mins
                        </span>
                        <span class="rating">
                            <i class="fas fa-star"></i> ${rating.toFixed(1)} (${reviewCount})
                        </span>
                    </div>

                    <div class="recipe-category">
                        <i class="fas fa-tag"></i> ${recipe.category || 'Uncategorized'}
                    </div>

                    ${recipe.nutrition ? `
                        <div class="nutrition-preview">
                            <span class="calories">
                                <i class="fas fa-fire"></i> ${recipe.nutrition.calories} cal
                            </span>
                        </div>
                    ` : ''}

                    <div class="recipe-actions">
                        <button class="btn-primary view-recipe">
                            View Recipe
                        </button>
                        <button class="favorite-btn" data-recipe-id="${recipe.id}">
                            <i class="far fa-heart"></i> Add to Favorites
                        </button>
                    </div>
                </div>
            </div>
        `;
    }

    async searchRecipes() {
        const query = document.getElementById('searchInput').value.trim();
        this.currentFilters.query = query;
        await this.applyFilters();
    }

    async applyFilters() {
        const category = document.getElementById('categoryFilter').value;
        const difficulty = document.getElementById('difficultyFilter').value;
        const max_time = document.getElementById('timeFilter').value;
        const sort = document.getElementById('sortFilter').value;

        this.currentFilters = { ...this.currentFilters, category, difficulty, max_time, sort };

        try {
            const params = new URLSearchParams();
            if (this.currentFilters.query) params.append('q', this.currentFilters.query);
            if (category) params.append('category', category);
            if (difficulty) params.append('difficulty', difficulty);
            if (max_time) params.append('max_time', max_time);

            const recipes = await this.fetchAPI(`/search?${params.toString()}`);
            
            // Apply sorting
            const sortedRecipes = this.sortRecipes(recipes, sort);
            this.displayRecipes(sortedRecipes, 'results');
            this.updateResultsCount(sortedRecipes.length);
        } catch (error) {
            this.showError('Failed to apply filters');
        }
    }

    sortRecipes(recipes, sortBy) {
        return [...recipes].sort((a, b) => {
            switch (sortBy) {
                case 'time':
                    return (a.prep_time + a.cook_time) - (b.prep_time + b.cook_time);
                case 'rating':
                    return (b.avg_rating || 0) - (a.avg_rating || 0);
                case 'difficulty':
                    const difficultyOrder = { 'Easy': 1, 'Medium': 2, 'Hard': 3 };
                    return (difficultyOrder[a.difficulty] || 0) - (difficultyOrder[b.difficulty] || 0);
                default: // name
                    return a.name.localeCompare(b.name);
            }
        });
    }

    filterByCategory(category) {
        document.getElementById('categoryFilter').value = category;
        this.currentFilters.category = category;
        this.applyFilters();
    }

    showAllRecipes() {
        document.getElementById('searchInput').value = '';
        document.getElementById('categoryFilter').value = '';
        document.getElementById('difficultyFilter').value = '';
        document.getElementById('timeFilter').value = '';
        document.getElementById('sortFilter').value = 'name';
        
        this.currentFilters = {
            query: '',
            category: '',
            difficulty: '',
            max_time: '',
            sort: 'name'
        };

        this.loadAllRecipes();
    }

    async showRecipeDetails(recipeId) {
        try {
            const recipe = await this.fetchAPI(`/recipe/${recipeId}`);
            this.displayRecipeModal(recipe);
        } catch (error) {
            this.showError('Failed to load recipe details');
        }
    }

    displayRecipeModal(recipe) {
        const modalContent = document.getElementById('recipeModalContent');
        const totalTime = (recipe.prep_time || 0) + (recipe.cook_time || 0);

        modalContent.innerHTML = `
            <div class="recipe-detail">
                <div class="recipe-detail-header">
                    <h2>${recipe.name}</h2>
                    <div class="recipe-meta-large">
                        <span class="category-badge">${recipe.category || 'Uncategorized'}</span>
                        <span class="difficulty-badge ${recipe.difficulty?.toLowerCase() || 'medium'}">
                            ${recipe.difficulty || 'Medium'}
                        </span>
                        <span class="rating-large">
                            <i class="fas fa-star"></i> ${(recipe.avg_rating || 0).toFixed(1)}
                            <small>(${recipe.review_count || 0} reviews)</small>
                        </span>
                    </div>
                </div>

                <div class="recipe-detail-content">
                    <div class="recipe-image-large">
                        ${recipe.image_url ? 
                            `<img src="/images/${recipe.image_url}" alt="${recipe.name}" onerror="this.src='https://via.placeholder.com/500x300/4CAF50/white?text=No+Image'">` :
                            `<div class="no-image-large">No Image Available</div>`
                        }
                    </div>

                    <div class="recipe-info-large">
                        <div class="time-info">
                            <div class="time-item">
                                <i class="fas fa-clock"></i>
                                <div>
                                    <strong>Prep Time</strong>
                                    <span>${recipe.prep_time || 0} minutes</span>
                                </div>
                            </div>
                            <div class="time-item">
                                <i class="fas fa-fire"></i>
                                <div>
                                    <strong>Cook Time</strong>
                                    <span>${recipe.cook_time || 0} minutes</span>
                                </div>
                            </div>
                            <div class="time-item total">
                                <i class="fas fa-stopwatch"></i>
                                <div>
                                    <strong>Total Time</strong>
                                    <span>${totalTime} minutes</span>
                                </div>
                            </div>
                        </div>

                        ${recipe.description ? `
                            <div class="description-section">
                                <h3>Description</h3>
                                <p>${recipe.description}</p>
                            </div>
                        ` : ''}

                        <div class="ingredients-section">
                            <h3>Ingredients</h3>
                            <div class="ingredients-list">
                                ${this.formatIngredients(recipe.ingredients)}
                            </div>
                        </div>

                        <div class="instructions-section">
                            <h3>Instructions</h3>
                            <div class="instructions-list">
                                ${this.formatInstructions(recipe.instructions)}
                            </div>
                        </div>

                        ${recipe.nutrition ? `
                            <div class="nutrition-section">
                                <h3>Nutrition Information</h3>
                                <div class="nutrition-facts">
                                    <div class="nutrition-item">
                                        <span>Calories</span>
                                        <strong>${recipe.nutrition.calories || 'N/A'}</strong>
                                    </div>
                                    <div class="nutrition-item">
                                        <span>Protein</span>
                                        <strong>${recipe.nutrition.protein || 'N/A'}</strong>
                                    </div>
                                    <div class="nutrition-item">
                                        <span>Carbs</span>
                                        <strong>${recipe.nutrition.carbs || 'N/A'}</strong>
                                    </div>
                                    <div class="nutrition-item">
                                        <span>Fat</span>
                                        <strong>${recipe.nutrition.fat || 'N/A'}</strong>
                                    </div>
                                    ${recipe.nutrition.fiber ? `
                                        <div class="nutrition-item">
                                            <span>Fiber</span>
                                            <strong>${recipe.nutrition.fiber}</strong>
                                        </div>
                                    ` : ''}
                                </div>
                            </div>
                        ` : ''}

                        ${recipe.tags && recipe.tags.length > 0 ? `
                            <div class="tags-section">
                                <h3>Tags</h3>
                                <div class="recipe-tags">
                                    ${recipe.tags.map(tag => `<span class="recipe-tag">${tag}</span>`).join('')}
                                </div>
                            </div>
                        ` : ''}

                        <div class="recipe-actions-modal">
                            <button class="favorite-btn-large" data-recipe-id="${recipe.id}">
                                <i class="far fa-heart"></i> Add to Favorites
                            </button>
                        </div>

                        <div class="rating-section">
                            <h3>Rate this Recipe</h3>
                            <div class="rating-stars">
                                ${[1, 2, 3, 4, 5].map(star => `
                                    <span class="star" data-rating="${star}">
                                        <i class="far fa-star"></i>
                                    </span>
                                `).join('')}
                            </div>
                            <button class="btn-primary submit-rating" data-recipe-id="${recipe.id}">
                                Submit Rating
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        `;

        // Initialize favorite button in modal
        this.initializeFavoriteButton(recipe.id);
        this.initializeRatingStars(recipe.id);
        this.openModal(document.getElementById('recipeModal'));
    }

    async initializeFavoriteButton(recipeId) {
        const favoriteBtn = document.querySelector('.favorite-btn-large');
        if (!favoriteBtn) return;

        const isFavorited = await this.checkFavoriteStatus(recipeId);
        
        if (isFavorited) {
            favoriteBtn.classList.add('favorited');
            favoriteBtn.innerHTML = '<i class="fas fa-heart"></i> Favorited';
        }
        
        favoriteBtn.addEventListener('click', async () => {
            await this.toggleFavorite(recipeId, isFavorited);
        });
    }

    initializeRatingStars(recipeId) {
        const stars = document.querySelectorAll('.star');
        let selectedRating = 0;

        stars.forEach(star => {
            star.addEventListener('click', () => {
                selectedRating = parseInt(star.dataset.rating);
                
                // Update star display
                stars.forEach((s, index) => {
                    const icon = s.querySelector('i');
                    if (index < selectedRating) {
                        icon.className = 'fas fa-star';
                        s.classList.add('active');
                    } else {
                        icon.className = 'far fa-star';
                        s.classList.remove('active');
                    }
                });
            });

            star.addEventListener('mouseenter', () => {
                const rating = parseInt(star.dataset.rating);
                stars.forEach((s, index) => {
                    const icon = s.querySelector('i');
                    if (index < rating) {
                        icon.className = 'fas fa-star';
                    } else {
                        icon.className = 'far fa-star';
                    }
                });
            });

            star.addEventListener('mouseleave', () => {
                stars.forEach((s, index) => {
                    const icon = s.querySelector('i');
                    if (index < selectedRating) {
                        icon.className = 'fas fa-star';
                    } else {
                        icon.className = 'far fa-star';
                    }
                });
            });
        });

        // Submit rating button
        document.querySelector('.submit-rating').addEventListener('click', async () => {
            if (selectedRating === 0) {
                alert('Please select a rating before submitting.');
                return;
            }

            try {
                await this.submitRating(recipeId, selectedRating);
                alert('Thank you for your rating!');
                this.closeModal(document.getElementById('recipeModal'));
            } catch (error) {
                this.showError('Failed to submit rating');
            }
        });
    }

    async submitRating(recipeId, rating) {
        try {
            await this.fetchAPI(`/recipe/${recipeId}/rate`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                'Authorization': `Bearer ${this.token}`
                },
                body: JSON.stringify({ rating })
            });
        } catch (error) {
            throw new Error('Failed to submit rating');
        }
    }

    formatIngredients(ingredients) {
        if (!ingredients) return '<p>No ingredients listed.</p>';
        
        // Split by commas or new lines and create list items
        const items = ingredients.split(/[,|\n]/).filter(item => item.trim());
        
        if (items.length === 0) return '<p>No ingredients listed.</p>';
        
        return items.map(item => `
            <div class="ingredient-item">
                <i class="fas fa-check-circle"></i>
                <span>${item.trim()}</span>
            </div>
        `).join('');
    }

    formatInstructions(instructions) {
        if (!instructions) return '<p>No instructions available.</p>';
        
        // Split by numbers, periods, or new lines
        const steps = instructions.split(/(?:\d+\.|\n)/).filter(step => step.trim());
        
        if (steps.length === 0) return '<p>No instructions available.</p>';
        
        return steps.map((step, index) => `
            <div class="instruction-step">
                <div class="step-number">${index + 1}</div>
                <div class="step-content">${step.trim()}</div>
            </div>
        `).join('');
    }

    switchTab(tabName) {
        // Update tabs
        document.querySelectorAll('.tab-link').forEach(tab => {
            tab.classList.toggle('active', tab.dataset.tab === tabName);
        });

        // Update tab content
        document.querySelectorAll('.tab-content').forEach(content => {
            content.classList.toggle('active', content.id === tabName);
        });

        this.currentTab = tabName;

        // Load data for specific tabs
        if (tabName === 'categories' && this.categories.length === 0) {
            this.loadCategories();
        } else if (tabName === 'favorites') {
            if (this.token) {
                document.getElementById('favoritesAuthRequired').style.display = 'none';
                document.getElementById('favoritesContent').style.display = 'block';
                this.loadFavorites();
            } else {
                document.getElementById('favoritesAuthRequired').style.display = 'block';
                document.getElementById('favoritesContent').style.display = 'none';
            }
        }
    }

    toggleView(view) {
        this.currentView = view;
        const containers = document.querySelectorAll('.results-container');
        
        containers.forEach(container => {
            container.classList.remove('grid-view', 'list-view');
            container.classList.add(`${view}-view`);
        });

        document.querySelectorAll('.view-btn').forEach(btn => {
            btn.classList.toggle('active', btn.dataset.view === view);
        });
    }

    toggleFilters() {
        const filtersContent = document.querySelector('.filters-content');
        const toggleIcon = document.querySelector('.filter-toggle .fa-chevron-down');
        
        filtersContent.classList.toggle('active');
        toggleIcon.classList.toggle('fa-chevron-up');
        toggleIcon.classList.toggle('fa-chevron-down');
    }

    openModal(modal) {
        if (modal) {
            modal.style.display = 'block';
            document.body.style.overflow = 'hidden';
        }
    }

    updateResultsCount(count) {
        document.getElementById('resultsCount').textContent = `${count} recipe${count !== 1 ? 's' : ''} found`;
    }

    async updateStats() {
        try {
            const stats = await this.fetchAPI('/stats');
            
            document.getElementById('recipeCount').textContent = `${stats.total_recipes} Recipes`;
            document.getElementById('categoryCount').textContent = `${stats.total_categories} Categories`;
            document.getElementById('totalRecipes').textContent = `${stats.total_recipes} Recipes Available`;
            
            // Update API status
            document.getElementById('apiStatus').className = 'status-online';
            document.getElementById('apiStatus').textContent = '● API Online';
        } catch (error) {
            document.getElementById('apiStatus').className = 'status-offline';
            document.getElementById('apiStatus').textContent = '● API Offline';
        }
    }

    showSuccess(message) {
        // Create temporary success message
        const successDiv = document.createElement('div');
        successDiv.className = 'success-message show';
        successDiv.innerHTML = `
            <i class="fas fa-check-circle"></i>
            <span>${message}</span>
        `;
        
        document.body.appendChild(successDiv);
        
        setTimeout(() => {
            if (successDiv.parentNode) {
                successDiv.parentNode.removeChild(successDiv);
            }
        }, 3000);
    }

    showError(message) {
        // Create a temporary error notification
        const errorDiv = document.createElement('div');
        errorDiv.className = 'error-notification';
        errorDiv.innerHTML = `
            <i class="fas fa-exclamation-circle"></i>
            <span>${message}</span>
        `;
        
        document.body.appendChild(errorDiv);
        
        // Remove after 3 seconds
        setTimeout(() => {
            if (errorDiv.parentNode) {
                errorDiv.parentNode.removeChild(errorDiv);
            }
        }, 3000);
    }
}

// Initialize the application when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    new RecipeApp();
});

// Health check function
async function checkAPIHealth() {
    try {
        const response = await fetch('http://127.0.0.1:5000/health');
        const data = await response.json();
        console.log('API Health:', data);
        return true;
    } catch (error) {
        console.error('API Health Check Failed:', error);
        return false;
    }
}

setInterval(checkAPIHealth, 30000); // Check every 30 seconds