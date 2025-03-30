#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DB_File;

my $cgi = CGI->new;
print $cgi->header('text/html');

# Define paths
my $db_path = "/usr/local/apache2/data/users.db";
my $sessions_path = "/usr/local/apache2/data/sessions.db";
my $orders_path = "/usr/local/apache2/data/orders.db";

# Check if user is logged in
my $session_cookie = $cgi->cookie('session') || '';
my ($user_email, $user_name, $user_role) = check_session($session_cookie);

# Handle actions
my $action = $cgi->param('action') || '';

if ($action eq 'process_order') {
    process_order();
} else {
    display_checkout_form();
}

# Function to check session
sub check_session {
    my $session_id = shift;
    
    if (!$session_id) {
        return ('', '', '');
    }
    
    my %sessions;
    if (tie %sessions, 'DB_File', $sessions_path, O_RDONLY, 0644, $DB_HASH) {
        if (exists $sessions{$session_id}) {
            my ($email, $role, $expiry) = split(':::', $sessions{$session_id});
            
            # Check if session is expired
            if ($expiry > time()) {
                # Get user name
                my %users;
                if (tie %users, 'DB_File', $db_path, O_RDONLY, 0644, $DB_HASH) {
                    my ($password, $name, $stored_role) = split(':::', $users{$email});
                    untie %users;
                    
                    untie %sessions;
                    return ($email, $name, $role);
                }
            }
        }
        untie %sessions;
    }
    
    return ('', '', '');
}

# Function to display checkout form
sub display_checkout_form {
    # Redirect to login if not logged in
    if (!$user_email) {
        print <<HTML;
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="refresh" content="3; url=/cgi-bin/login.pl">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Оформление заказа | Научный журнал</title>
    <link href="/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
    <div class="container">
        <div class="row justify-content-center mt-5">
            <div class="col-md-6">
                <div class="alert alert-warning">
                    <h4 class="alert-heading">Требуется авторизация</h4>
                    <p>Для оформления заказа необходимо войти в систему. Перенаправление на страницу входа...</p>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
HTML
        return;
    }
    
    print <<HTML;
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Оформление заказа | Научный журнал</title>
    <link href="/css/bootstrap.min.css" rel="stylesheet">
    <link href="/css/bootstrap-icons.css" rel="stylesheet">
    <link href="/css/styles.css" rel="stylesheet">
</head>
<body>
    <header>
        <nav class="navbar navbar-expand-lg navbar-dark bg-primary">
            <div class="container">
                <a class="navbar-brand" href="/index.html">Научный журнал</a>
                <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav" aria-controls="navbarNav" aria-expanded="false" aria-label="Toggle navigation">
                    <span class="navbar-toggler-icon"></span>
                </button>
                <div class="collapse navbar-collapse" id="navbarNav">
                    <ul class="navbar-nav me-auto">
                        <li class="nav-item">
                            <a class="nav-link" href="/index.html">Главная</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="/issues.html">Выпуски</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="/about.html">О журнале</a>
                        </li>
                    </ul>
                    <div class="d-flex">
                        <a href="/cart.html" class="btn btn-outline-light me-2">
                            <i class="bi bi-cart"></i> Корзина
                        </a>
HTML

    if ($user_email) {
        print <<HTML;
                        <div class="dropdown">
                            <button class="btn btn-light dropdown-toggle" type="button" id="profileDropdown" data-bs-toggle="dropdown" aria-expanded="false">
                                $user_name
                            </button>
                            <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="profileDropdown">
                                <li><a class="dropdown-item" href="/cgi-bin/profile.pl">Личный кабинет</a></li>
                                <li><hr class="dropdown-divider"></li>
                                <li><a class="dropdown-item" href="/cgi-bin/profile.pl?action=logout">Выйти</a></li>
                            </ul>
                        </div>
HTML
    } else {
        print <<HTML;
                        <a href="/cgi-bin/login.pl" class="btn btn-outline-light">Войти</a>
HTML
    }

    print <<HTML;
                    </div>
                </div>
            </div>
        </nav>
    </header>

    <main class="container my-4">
        <nav aria-label="breadcrumb" class="mb-4">
            <ol class="breadcrumb">
                <li class="breadcrumb-item"><a href="/index.html">Главная</a></li>
                <li class="breadcrumb-item"><a href="/cart.html">Корзина</a></li>
                <li class="breadcrumb-item active" aria-current="page">Оформление заказа</li>
            </ol>
        </nav>
        
        <h1 class="mb-4">Оформление заказа</h1>
        
        <div class="row">
            <div class="col-lg-7">
                <div class="card mb-4">
                    <div class="card-header">
                        <h5 class="mb-0">Контактная информация</h5>
                    </div>
                    <div class="card-body">
                        <form id="checkoutForm" method="post" action="/cgi-bin/checkout.pl">
                            <input type="hidden" name="action" value="process_order">
                            
                            <div class="row mb-3">
                                <div class="col-md-6">
                                    <label for="firstName" class="form-label">Имя</label>
                                    <input type="text" class="form-control" id="firstName" name="first_name" value="$user_name" required>
                                </div>
                                <div class="col-md-6">
                                    <label for="lastName" class="form-label">Фамилия</label>
                                    <input type="text" class="form-control" id="lastName" name="last_name" required>
                                </div>
                            </div>
                            
                            <div class="mb-3">
                                <label for="email" class="form-label">Email</label>
                                <input type="email" class="form-control" id="email" name="email" value="$user_email" required>
                            </div>
                            
                            <div class="mb-3">
                                <label for="phone" class="form-label">Телефон</label>
                                <input type="tel" class="form-control" id="phone" name="phone" placeholder="+7 (XXX) XXX-XX-XX" required>
                            </div>
                            
                            <hr class="my-4">
                            
                            <h5>Способ оплаты</h5>
                            <div class="my-3">
                                <div class="form-check">
                                    <input id="credit" name="payment_method" type="radio" class="form-check-input" value="credit_card" checked required>
                                    <label class="form-check-label" for="credit">Банковская карта</label>
                                </div>
                                <div class="form-check">
                                    <input id="electronic" name="payment_method" type="radio" class="form-check-input" value="electronic">
                                    <label class="form-check-label" for="electronic">Электронный платеж</label>
                                </div>
                                <div class="form-check">
                                    <input id="invoice" name="payment_method" type="radio" class="form-check-input" value="invoice">
                                    <label class="form-check-label" for="invoice">Счет на организацию</label>
                                </div>
                            </div>
                            
                            <div id="creditCardFields">
                                <div class="row mb-3">
                                    <div class="col-md-6">
                                        <label for="cardName" class="form-label">Имя на карте</label>
                                        <input type="text" class="form-control" id="cardName" name="card_name">
                                    </div>
                                    <div class="col-md-6">
                                        <label for="cardNumber" class="form-label">Номер карты</label>
                                        <input type="text" class="form-control" id="cardNumber" name="card_number" placeholder="XXXX XXXX XXXX XXXX">
                                    </div>
                                </div>
                                <div class="row">
                                    <div class="col-md-6">
                                        <label for="expiration" class="form-label">Срок действия</label>
                                        <input type="text" class="form-control" id="expiration" name="expiration" placeholder="MM/ГГ">
                                    </div>
                                    <div class="col-md-6">
                                        <label for="cvv" class="form-label">CVV</label>
                                        <input type="text" class="form-control" id="cvv" name="cvv" placeholder="XXX">
                                    </div>
                                </div>
                            </div>
                            
                            <div id="invoiceFields" style="display: none;">
                                <div class="mb-3">
                                    <label for="companyName" class="form-label">Название организации</label>
                                    <input type="text" class="form-control" id="companyName" name="company_name">
                                </div>
                                <div class="mb-3">
                                    <label for="inn" class="form-label">ИНН</label>
                                    <input type="text" class="form-control" id="inn" name="inn">
                                </div>
                                <div class="mb-3">
                                    <label for="address" class="form-label">Юридический адрес</label>
                                    <textarea class="form-control" id="address" name="address" rows="3"></textarea>
                                </div>
                            </div>
                            
                            <hr class="my-4">
                            
                            <div class="mb-3 form-check">
                                <input type="checkbox" class="form-check-input" id="termsAgreement" name="terms_agreement" required>
                                <label class="form-check-label" for="termsAgreement">Я согласен с условиями оплаты и доставки</label>
                            </div>
                            
                            <hr class="my-4">
                            
                            <button class="btn btn-primary btn-lg w-100" type="submit">Оформить заказ</button>
                        </form>
                    </div>
                </div>
            </div>
            
            <div class="col-lg-5">
                <div class="card mb-4">
                    <div class="card-header">
                        <h5 class="mb-0">Ваш заказ</h5>
                    </div>
                    <div class="card-body">
                        <div id="orderSummary">
                            <!-- Order items will be loaded here by JavaScript -->
                        </div>
                        
                        <div class="spinner-border text-primary" role="status" id="loadingOrder">
                            <span class="visually-hidden">Загрузка...</span>
                        </div>
                        
                        <hr class="my-4">
                        
                        <div class="d-flex justify-content-between mb-3">
                            <span>Товаров в корзине:</span>
                            <span id="totalItems">0</span>
                        </div>
                        <div class="d-flex justify-content-between mb-3">
                            <span>Стоимость:</span>
                            <span id="subtotal">0 ₽</span>
                        </div>
                        <hr>
                        <div class="d-flex justify-content-between mb-3 fw-bold">
                            <span>Итого к оплате:</span>
                            <span id="totalPrice">0 ₽</span>
                        </div>
                    </div>
                </div>
                
                <div class="card mb-4">
                    <div class="card-header">
                        <h5 class="mb-0">Информация</h5>
                    </div>
                    <div class="card-body">
                        <p><i class="bi bi-info-circle"></i> После оплаты заказа вы получите доступ к электронным версиям выпусков в личном кабинете.</p>
                        <p><i class="bi bi-shield-check"></i> Оплата производится через защищенное соединение.</p>
                        <p><i class="bi bi-question-circle"></i> Если у вас возникли вопросы, свяжитесь с нами:</p>
                        <p><i class="bi bi-envelope"></i> orders\@science-journal.ru<br>
                        <i class="bi bi-telephone"></i> +7 (495) 123-45-67</p>
                    </div>
                </div>
            </div>
        </div>
    </main>

    <footer class="bg-dark text-white py-4 mt-4">
        <div class="container">
            <div class="row">
                <div class="col-md-6">
                    <h5>Научный журнал</h5>
                    <p>© 2025 Все права защищены</p>
                </div>
            </div>
        </div>
    </footer>

    <script src="/js/bootstrap.bundle.min.js"></script>
    <script src="/js/main.js"></script>
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            // Show/hide payment fields based on selection
            const paymentMethods = document.querySelectorAll('input[name="payment_method"]');
            const creditCardFields = document.getElementById('creditCardFields');
            const invoiceFields = document.getElementById('invoiceFields');
            
            paymentMethods.forEach(method => {
                method.addEventListener('change', function() {
                    if (this.value === 'credit_card') {
                        creditCardFields.style.display = 'block';
                        invoiceFields.style.display = 'none';
                    } else if (this.value === 'invoice') {
                        creditCardFields.style.display = 'none';
                        invoiceFields.style.display = 'block';
                    } else {
                        creditCardFields.style.display = 'none';
                        invoiceFields.style.display = 'none';
                    }
                });
            });
            
            // Load cart items for order summary
            const orderSummary = document.getElementById('orderSummary');
            const loadingOrder = document.getElementById('loadingOrder');
            const totalItemsEl = document.getElementById('totalItems');
            const subtotalEl = document.getElementById('subtotal');
            const totalPriceEl = document.getElementById('totalPrice');
            
            function loadCart() {
                const cart = JSON.parse(localStorage.getItem('cart')) || [];
                
                if (cart.length === 0) {
                    orderSummary.innerHTML = '<div class="alert alert-warning">Ваша корзина пуста.</div>';
                } else {
                    let html = '<ul class="list-group list-group-flush">';
                    let totalItems = 0;
                    let subtotal = 0;
                    
                    cart.forEach(item => {
                        const itemTotal = item.price * item.quantity;
                        subtotal += itemTotal;
                        totalItems += item.quantity;
                        
                        html += `
                            <li class="list-group-item px-0">
                                <div class="row align-items-center">
                                    <div class="col-2">
                                        <img src="${item.image}" class="img-fluid rounded" alt="${item.title}">
                                    </div>
                                    <div class="col-7">
                                        <h6 class="mb-0">${item.title}</h6>
                                        <small class="text-muted">Количество: ${item.quantity}</small>
                                    </div>
                                    <div class="col-3 text-end">
                                        <span class="fw-bold">${itemTotal} ₽</span>
                                    </div>
                                </div>
                            </li>
                        `;
                    });
                    
                    html += '</ul>';
                    orderSummary.innerHTML = html;
                    
                    totalItemsEl.textContent = totalItems;
                    subtotalEl.textContent = subtotal + ' ₽';
                    totalPriceEl.textContent = subtotal + ' ₽';
                }
                
                loadingOrder.style.display = 'none';
            }
            
            // Load cart on page load
            loadCart();
            
            // Form validation
            const checkoutForm = document.getElementById('checkoutForm');
            
            checkoutForm.addEventListener('submit', function(e) {
                e.preventDefault();
                
                // Simple validation
                let valid = true;
                
                // Check if cart is empty
                const cart = JSON.parse(localStorage.getItem('cart')) || [];
                if (cart.length === 0) {
                    alert('Ваша корзина пуста. Добавьте товары в корзину, прежде чем оформить заказ.');
                    valid = false;
                }
                
                if (valid) {
                    // Submit form
                    this.submit();
                }
            });
        });
    </script>
</body>
</html>
HTML
}

# Function to process order
sub process_order {
    
    print <<HTML;
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Заказ оформлен | Научный журнал</title>
    <link href="/css/bootstrap.min.css" rel="stylesheet">
    <link href="/css/bootstrap-icons.css" rel="stylesheet">
    <link href="/css/styles.css" rel="stylesheet">
</head>
<body>
    <header>
        <nav class="navbar navbar-expand-lg navbar-dark bg-primary">
            <div class="container">
                <a class="navbar-brand" href="/index.html">Научный журнал</a>
                <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav" aria-controls="navbarNav" aria-expanded="false" aria-label="Toggle navigation">
                    <span class="navbar-toggler-icon"></span>
                </button>
                <div class="collapse navbar-collapse" id="navbarNav">
                    <ul class="navbar-nav me-auto">
                        <li class="nav-item">
                            <a class="nav-link" href="/index.html">Главная</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="/issues.html">Выпуски</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="/about.html">О журнале</a>
                        </li>
                    </ul>
                    <div class="d-flex">
                        <a href="/cart.html" class="btn btn-outline-light me-2">
                            <i class="bi bi-cart"></i> Корзина
                        </a>
HTML

    if ($user_email) {
        print <<HTML;
                        <div class="dropdown">
                            <button class="btn btn-light dropdown-toggle" type="button" id="profileDropdown" data-bs-toggle="dropdown" aria-expanded="false">
                                $user_name
                            </button>
                            <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="profileDropdown">
                                <li><a class="dropdown-item" href="/cgi-bin/profile.pl">Личный кабинет</a></li>
                                <li><hr class="dropdown-divider"></li>
                                <li><a class="dropdown-item" href="/cgi-bin/profile.pl?action=logout">Выйти</a></li>
                            </ul>
                        </div>
HTML
    } else {
        print <<HTML;
                        <a href="/cgi-bin/login.pl" class="btn btn-outline-light">Войти</a>
HTML
    }

    print <<HTML;
                    </div>
                </div>
            </div>
        </nav>
    </header>

    <main class="container my-4">
        <div class="row justify-content-center">
            <div class="col-md-8">
                <div class="card text-center">
                    <div class="card-body py-5">
                        <div class="mb-4">
                            <i class="bi bi-check-circle-fill text-success" style="font-size: 5rem;"></i>
                        </div>
                        <h1 class="card-title mb-4">Заказ успешно оформлен!</h1>
                        <p class="card-text lead">Благодарим вас за покупку. Номер вашего заказа: <strong>ORD-003</strong></p>
                        <p class="card-text">Вы получите подтверждение заказа на указанный email. Доступ к электронным версиям выпусков будет открыт в вашем личном кабинете.</p>
                        
                        <div class="d-grid gap-2 d-md-flex justify-content-md-center mt-4">
                            <a href="/cgi-bin/profile.pl" class="btn btn-primary">
                                <i class="bi bi-person"></i> Перейти в личный кабинет
                            </a>
                            <a href="/index.html" class="btn btn-outline-secondary">
                                <i class="bi bi-house"></i> Вернуться на главную
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </main>

    <footer class="bg-dark text-white py-4 mt-4">
        <div class="container">
            <div class="row">
                <div class="col-md-6">
                    <h5>Научный журнал</h5>
                    <p>© 2025 Все права защищены</p>
                </div>
            </div>
        </div>
    </footer>

    <script src="/js/bootstrap.bundle.min.js"></script>
    <script src="/js/main.js"></script>
    <script>
        // Clear the cart after successful order
        localStorage.setItem('cart', JSON.stringify([]));
        
        // Update cart counter
        document.addEventListener('DOMContentLoaded', function() {
            updateCartCounter();
        });
    </script>
</body>
</html>
HTML
} 