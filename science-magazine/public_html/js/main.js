// Основные функции JavaScript для сайта научного журнала

// Функция для валидации форм
function validateForm(formId) {
    const form = document.getElementById(formId);
    if (!form) return true;
    
    const requiredFields = form.querySelectorAll('[required]');
    let isValid = true;
    
    requiredFields.forEach(field => {
        if (!field.value.trim()) {
            field.classList.add('error');
            isValid = false;
        } else {
            field.classList.remove('error');
        }
    });
    
    return isValid;
}

// Функция для управления корзиной
function addToCart(articleId, articleTitle, price) {
    let cart = JSON.parse(localStorage.getItem('cart') || '[]');
    
    // Проверяем, есть ли уже такая статья в корзине
    const existingItem = cart.find(item => item.id === articleId);
    
    if (existingItem) {
        existingItem.quantity += 1;
    } else {
        cart.push({
            id: articleId,
            title: articleTitle,
            price: price,
            quantity: 1
        });
    }
    
    localStorage.setItem('cart', JSON.stringify(cart));
    updateCartCounter();
    
    // Показываем уведомление
    showNotification('Статья добавлена в корзину');
}

// Функция для обновления счетчика товаров в корзине
function updateCartCounter() {
    const cart = JSON.parse(localStorage.getItem('cart') || '[]');
    const counter = document.getElementById('cart-counter');
    
    if (counter) {
        const totalItems = cart.reduce((sum, item) => sum + item.quantity, 0);
        counter.textContent = totalItems;
        
        if (totalItems > 0) {
            counter.style.display = 'inline-block';
        } else {
            counter.style.display = 'none';
        }
    }
}

// Функция для отображения уведомлений
function showNotification(message) {
    const notification = document.createElement('div');
    notification.className = 'notification';
    notification.textContent = message;
    
    document.body.appendChild(notification);
    
    // Показываем уведомление
    setTimeout(() => {
        notification.classList.add('show');
    }, 10);
    
    // Скрываем и удаляем уведомление через 3 секунды
    setTimeout(() => {
        notification.classList.remove('show');
        setTimeout(() => {
            document.body.removeChild(notification);
        }, 300);
    }, 3000);
}

// Check if user is logged in and get their role
function checkUserRole() {
    // Get the session cookie
    const cookies = document.cookie.split(';');
    let sessionCookie = '';
    
    for (let i = 0; i < cookies.length; i++) {
        const cookie = cookies[i].trim();
        if (cookie.startsWith('session=')) {
            sessionCookie = cookie.substring('session='.length);
            break;
        }
    }
    
    if (sessionCookie) {
        const [userId, userRole] = sessionCookie.split(':');
        
        // If user is admin or editor, show the admin panel link
        if (userRole === 'admin' || userRole === 'editor') {
            document.getElementById('admin-link-container').innerHTML = 
                '<a href="/cgi-bin/admin.pl">Панель администратора</a>';
        }
        
        // Change the auth link to personal profile
        document.getElementById('auth-link').textContent = 'Личный кабинет';
        document.getElementById('auth-link').href = '/cgi-bin/auth.pl?action=profile';
    }
}

// Run when the page loads


// Инициализация при загрузке страницы
document.addEventListener('DOMContentLoaded', function() {
    // Обновляем счетчик корзины
    updateCartCounter();
    checkUserRole();
    
    // Добавляем обработчики событий для форм
    const forms = document.querySelectorAll('form[data-validate="true"]');
    forms.forEach(form => {
        form.addEventListener('submit', function(event) {
            if (!validateForm(form.id)) {
                event.preventDefault();
                showNotification('Пожалуйста, заполните все обязательные поля');
            }
        });
    });
}); 