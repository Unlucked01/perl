#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DB_File;
use Time::HiRes qw(gettimeofday);


my $cgi = CGI->new;

# Define paths
my $db_path = "/usr/local/apache2/data/users.db";
my $sessions_path = "/usr/local/apache2/data/sessions.db";
my $issues_path = "/usr/local/apache2/data/issues.db";
my $orders_path = "/usr/local/apache2/data/orders.db";

# Check if user is logged in
my $session_cookie = $cgi->cookie('session') || '';
my ($user_email, $user_name, $user_role) = check_session($session_cookie);

# Redirect to login if not logged in
if (!$user_email) {
    print $cgi->redirect(-uri => '/cgi-bin/login.pl');
    exit;
}

# Process checkout form
if ($cgi->param('submit')) {
    my $name = $cgi->param('name') || '';
    my $email = $cgi->param('email') || '';
    my $phone = $cgi->param('phone') || '';
    my $payment_method = $cgi->param('payment_method') || '';
    my $cart_json = $cgi->param('cart') || '[]';
    my $order_total = $cgi->param('total') || 0;
    
    # Debug log
    open my $log, '>>', '/tmp/checkout_debug.log';
    print $log "Received data: name=$name, email=$email, cart=$cart_json, total=$order_total\n";
    print $log "Session user email: $user_email\n";
    close $log;
    
    # If email is empty, use the email from session
    if (!$email && $user_email) {
        $email = $user_email;
    }
    
    # Simple validation
    if ($name && $email && $phone && $payment_method && $cart_json ne '[]' && $order_total > 0) {
        # Generate order ID
        my $order_id = generate_order_id();
        
        # Store order in the database
        my %orders;
        if (tie %orders, 'DB_File', $orders_path, O_CREAT|O_RDWR, 0644, $DB_HASH) {
            # Order format: email:::date:::amount:::status (to match init_db.pl format)
            my $order_status = 'Оплачен';
            
            # Format date as DD.MM.YYYY instead of timestamp
            my ($sec, $min, $hour, $day, $month, $year) = localtime(time());
            $year += 1900;
            $month += 1; # Convert 0-11 to 1-12
            my $formatted_date = sprintf("%02d.%02d.%04d", $day, $month, $year);
            
            # Pre-process the email to ensure it's a valid string
            my $clean_email = $email;
            $clean_email =~ s/^\s+|\s+$//g;  # Trim whitespace
            
            # Construct the order data string with explicit local variables
            my $order_data = $clean_email . ":::" . $formatted_date . ":::" . $order_total . ":::" . $order_status;
            
            $orders{$order_id} = $order_data;
            untie %orders;
            
            # Redirect to success page
            print $cgi->redirect(-uri => "/cgi-bin/profile.pl?action=order_success&id=$order_id");
            exit;
        }
    } else {
        # Debug log for validation failure
        open my $log, '>>', '/tmp/checkout_debug.log';
        print $log "Validation failed: name=$name, email=$email, phone=$phone, payment=$payment_method, cart=$cart_json, total=$order_total\n";
        close $log;
    }
}

print $cgi->header(-type => 'text/html', -charset => 'UTF-8');
print_checkout_form();

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

# Function to generate order ID
sub generate_order_id {
    my ($seconds, $microseconds) = gettimeofday();
    my $random = int(rand(1000));
    return sprintf("ORD-%d%03d", $seconds % 1000000, $random);
}

# Function to display checkout form
sub print_checkout_form {
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
                <a class="navbar-brand" href="/cgi-bin/index.pl">Научный журнал</a>
                <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav" aria-controls="navbarNav" aria-expanded="false" aria-label="Toggle navigation">
                    <span class="navbar-toggler-icon"></span>
                </button>
                <div class="collapse navbar-collapse" id="navbarNav">
                    <ul class="navbar-nav me-auto">
                        <li class="nav-item">
                            <a class="nav-link" href="/cgi-bin/index.pl">Главная</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="/cgi-bin/issues.pl">Выпуски</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="/about.html">О журнале</a>
                        </li>
HTML

    # Show admin link if user is admin or editor
    if ($user_role eq 'admin' || $user_role eq 'editor') {
        print <<HTML;
                        <li class="nav-item">
                            <a class="nav-link" href="/cgi-bin/admin.pl">Админ-панель</a>
                        </li>
HTML
    }

    print <<HTML;
                    </ul>
                    <div class="d-flex">
                        <a href="/cart.html" class="btn btn-outline-light me-2">
                            <i class="bi bi-cart"></i> Корзина
                        </a>
HTML

    # Display user profile dropdown if logged in
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
    }

    print <<HTML;
                    </div>
                </div>
            </div>
        </nav>
    </header>

    <main class="container my-4">
        <h1 class="mb-4">Оформление заказа</h1>
        
        <div class="row">
            <div class="col-md-8">
                <div class="card mb-4">
                    <div class="card-header bg-primary text-white">
                        <h5 class="card-title mb-0">Данные для оформления</h5>
                    </div>
                    <div class="card-body">
                        <form action="/cgi-bin/checkout.pl" method="post" id="checkoutForm">
                            <input type="hidden" name="cart" id="cartItemsInput">
                            <input type="hidden" name="total" id="totalInput">
                            
                            <div class="mb-3">
                                <label for="name" class="form-label">ФИО</label>
                                <input type="text" class="form-control" id="name" name="name" value="$user_name" required>
                            </div>
                            
                            <div class="mb-3">
                                <label for="email" class="form-label">Email</label>
                                <input type="email" class="form-control" id="email" name="email" value="$user_email" required>
                            </div>
                            
                            <div class="mb-3">
                                <label for="phone" class="form-label">Телефон</label>
                                <input type="tel" class="form-control" id="phone" name="phone" required>
                            </div>
                            
                            <div class="mb-3">
                                <label class="form-label">Способ оплаты</label>
                                <div class="form-check">
                                    <input class="form-check-input" type="radio" name="payment_method" id="card" value="card" checked>
                                    <label class="form-check-label" for="card">
                                        Банковская карта
                                    </label>
                                </div>
                                <div class="form-check">
                                    <input class="form-check-input" type="radio" name="payment_method" id="invoice" value="invoice">
                                    <label class="form-check-label" for="invoice">
                                        Счет для юридических лиц
                                    </label>
                                </div>
                            </div>
                            
                            <div class="d-grid gap-2 mt-4">
                                <button type="submit" name="submit" value="1" class="btn btn-primary" id="orderButton">
                                    Оформить заказ
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
            
            <div class="col-md-4">
                <div class="card mb-4">
                    <div class="card-header bg-primary text-white">
                        <h5 class="card-title mb-0">Ваш заказ</h5>
                    </div>
                    <div class="card-body">
                        <div id="cartItemsList">
                            <!-- Cart items will be loaded here via JavaScript -->
                        </div>
                        <hr>
                        <div class="d-flex justify-content-between fw-bold">
                            <span>Итого:</span>
                            <span id="totalAmount">0 ₽</span>
                        </div>
                    </div>
                </div>
                
                <div class="card">
                    <div class="card-header bg-secondary text-white">
                        <h5 class="card-title mb-0">Информация</h5>
                    </div>
                    <div class="card-body">
                        <p class="mb-2"><i class="bi bi-info-circle"></i> После оформления заказа вы получите доступ к загрузке выпусков журнала в личном кабинете.</p>
                        <p class="mb-0"><i class="bi bi-shield-check"></i> Ваши данные защищены и не будут переданы третьим лицам.</p>
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
    <script>
    document.addEventListener('DOMContentLoaded', function() {
        // Load cart items from localStorage
        let cart = [];
        try {
            const cartData = localStorage.getItem('cart');
            console.log('Cart data from localStorage:', cartData);
            if (cartData) {
                cart = JSON.parse(cartData);
            }
        } catch (e) {
            console.error('Error parsing cart data:', e);
            cart = [];
        }
        
        const cartItemsList = document.getElementById('cartItemsList');
        const cartItemsInput = document.getElementById('cartItemsInput');
        const totalInput = document.getElementById('totalInput');
        const totalAmount = document.getElementById('totalAmount');
        const orderButton = document.getElementById('orderButton');
        
        // Display cart items
        let total = 0;
        
        if (!cart || cart.length === 0) {
            cartItemsList.innerHTML = '<div class="alert alert-info">Ваша корзина пуста</div>' +
                '<div class="text-center mt-3">' +
                '<a href="/cgi-bin/issues.pl" class="btn btn-outline-primary">Перейти к выпускам</a>' +
                '</div>';
            orderButton.disabled = true;
        } else {
            let itemsHtml = '';
            
            cart.forEach(function(item, index) {
                // Ensure item has all required properties
                if (!item.price) {
                    console.error("Item missing price:", item);
                    return;
                }
                
                if (!item.title) {
                    console.error("Item missing title:", item);
                    return;
                }
                
                const itemPrice = parseFloat(item.price) || 0;
                const itemQty = parseInt(item.quantity) || 1;
                const itemTotal = itemPrice * itemQty;
                total += itemTotal;
                
                itemsHtml += '<div class="mb-3"><div class="d-flex justify-content-between"><div>' +
                    '<h6 class="mb-0">' + item.title + '</h6>' +
                    '<small class="text-muted">' + itemQty + ' x ' + itemPrice + ' ₽</small>' +
                    '</div>' +
                    '<div class="d-flex align-items-center">' +
                    '<span class="me-2">' + itemTotal + ' ₽</span>' +
                    '<button type="button" class="btn btn-sm btn-outline-danger remove-item" data-index="' + index + '">' +
                    '<i class="bi bi-x"></i>' +
                    '</button>' +
                    '</div></div></div>';
            });
            
            cartItemsList.innerHTML = itemsHtml;
            
            // Add event listeners for remove buttons
            document.querySelectorAll('.remove-item').forEach(function(button) {
                button.addEventListener('click', function() {
                    const index = parseInt(this.getAttribute('data-index'));
                    removeCartItem(index);
                });
            });
        }
        
        // Function to remove item from cart
        function removeCartItem(index) {
            cart.splice(index, 1);
            localStorage.setItem('cart', JSON.stringify(cart));
            
            // Reload page to refresh cart display
            window.location.reload();
        }
        
        // Update total
        totalAmount.textContent = total + ' ₽';
        totalInput.value = total;
        
        // Set cart items to hidden input
        cartItemsInput.value = JSON.stringify(cart);
        
        // Add form submission handler
        document.getElementById('checkoutForm').addEventListener('submit', function(e) {
            // Make sure cart has items and total is positive
            if (!cart || cart.length === 0 || total <= 0) {
                e.preventDefault();
                alert('Ваша корзина пуста. Пожалуйста, добавьте товары в корзину.');
                return false;
            }
            
            // Make sure form inputs are valid
            const name = document.getElementById('name').value;
            const email = document.getElementById('email').value;
            const phone = document.getElementById('phone').value;
            
            if (!name || !email || !phone) {
                e.preventDefault();
                alert('Пожалуйста, заполните все обязательные поля.');
                return false;
            }
            
            // Ensure cart data is set correctly
            cartItemsInput.value = JSON.stringify(cart);
            totalInput.value = total;
            
            console.log('Form submission - Cart:', cartItemsInput.value);
            console.log('Form submission - Total:', totalInput.value);
            
            // Clear cart after successful submission
            localStorage.setItem('cart', '[]');
            return true;
        });
    });
    </script>
</body>
</html>
HTML
} 