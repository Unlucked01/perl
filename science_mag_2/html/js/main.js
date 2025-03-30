// Main JavaScript for Scientific Journal Website

// Wait for DOM to be fully loaded
document.addEventListener('DOMContentLoaded', function() {
    initCartButtons();
    initSearchForm();
});

// Initialize add to cart buttons
function initCartButtons() {
    const cartButtons = document.querySelectorAll('.btn-primary[href="#"]');
    
    cartButtons.forEach(button => {
        button.addEventListener('click', function(e) {
            e.preventDefault();
            
            // Get the parent card to extract product info
            const card = this.closest('.card');
            if (!card) return;
            
            const title = card.querySelector('.card-title').textContent;
            const imgSrc = card.querySelector('img') ? card.querySelector('img').src : '';
            
            // Extract issue ID from nearby link if available
            const detailsLink = card.querySelector('a[href^="issue.html"]');
            const issueId = detailsLink ? new URL(detailsLink.href).searchParams.get('id') : null;
            
            if (issueId) {
                addToCart(issueId, title, imgSrc);
                showNotification(`"${title}" добавлен в корзину`);
            }
        });
    });
}

// Add item to cart
function addToCart(id, title, image) {
    let cart = JSON.parse(localStorage.getItem('cart')) || [];
    
    // Check if item already exists in cart
    const existingItemIndex = cart.findIndex(item => item.id === id);
    
    if (existingItemIndex >= 0) {
        cart[existingItemIndex].quantity += 1;
    } else {
        cart.push({
            id: id,
            title: title,
            image: image,
            price: 500, // Default price, would be fetched from server in real app
            quantity: 1
        });
    }
    
    // Save cart back to localStorage
    localStorage.setItem('cart', JSON.stringify(cart));
    
    // Update cart counter if it exists
    updateCartCounter();
}

// Update cart item counter in navbar
function updateCartCounter() {
    const cart = JSON.parse(localStorage.getItem('cart')) || [];
    const totalItems = cart.reduce((total, item) => total + item.quantity, 0);
    
    // Create or update cart counter badge
    let cartLink = document.querySelector('a[href="cart.html"]');
    if (cartLink) {
        let badge = cartLink.querySelector('.badge');
        
        if (!badge && totalItems > 0) {
            badge = document.createElement('span');
            badge.className = 'badge bg-danger ms-1';
            cartLink.appendChild(badge);
        }
        
        if (badge) {
            if (totalItems > 0) {
                badge.textContent = totalItems;
                badge.style.display = 'inline-block';
            } else {
                badge.style.display = 'none';
            }
        }
    }
}

// Show notification message
function showNotification(message) {
    // Create notification element
    const notification = document.createElement('div');
    notification.className = 'alert alert-success notification';
    notification.style.position = 'fixed';
    notification.style.top = '20px';
    notification.style.right = '20px';
    notification.style.zIndex = '1000';
    notification.style.maxWidth = '300px';
    notification.style.opacity = '0';
    notification.style.transition = 'opacity 0.3s ease';
    notification.textContent = message;
    
    // Add to DOM
    document.body.appendChild(notification);
    
    // Animate in
    setTimeout(() => {
        notification.style.opacity = '1';
    }, 10);
    
    // Remove after 3 seconds
    setTimeout(() => {
        notification.style.opacity = '0';
        
        // Remove from DOM after fade out
        setTimeout(() => {
            notification.remove();
        }, 300);
    }, 3000);
}

// Initialize search form
function initSearchForm() {
    const searchForm = document.querySelector('.search-form');
    if (searchForm) {
        searchForm.addEventListener('submit', function(e) {
            e.preventDefault();
            const query = this.querySelector('input[name="query"]').value.trim();
            
            if (query.length > 0) {
                window.location.href = `search.html?query=${encodeURIComponent(query)}`;
            }
        });
    }
} 