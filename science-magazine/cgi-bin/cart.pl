#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
use Encode qw(decode encode);
use JSON;
use DB_File;
use POSIX qw(strftime);

# Подключаем модуль для работы с БД
require "./db_utils.pl";
db_utils->import(qw(
    init_database
    get_article_by_id
    get_user_by_id
    create_order
    add_order_detail
    encode_utf8
    decode_utf8
));

# Инициализируем базу данных
init_database();

# Включаем вывод ошибок в браузер
BEGIN {
    $ENV{PERL_CGI_STDERR_TO_BROWSER} = 1;
}

my $q = CGI->new;
my $action = $q->param('action') || 'view';

# Получаем данные сессии из cookie
my $session_cookie = $q->cookie('session');
my ($user_id, $user_role) = split(/:/, $session_cookie) if $session_cookie;

# Обработка действий
if ($action eq 'view') {
    show_cart();
} elsif ($action eq 'checkout') {
    process_checkout();
} elsif ($action eq 'add') {
    add_to_cart();
} elsif ($action eq 'remove') {
    remove_from_cart();
} elsif ($action eq 'update') {
    update_cart();
} elsif ($action eq 'clear') {
    clear_cart();
} elsif ($action eq 'confirmation') {
    show_confirmation();
} else {
    show_cart();
}

# Функция для отображения корзины
sub show_cart {
    my $error = $q->param('error') || '';
    my $success = $q->param('success') || '';
    
    binmode(STDOUT, ":utf8");
    print "Content-Type: text/html; charset=utf-8\n\n";

    print <<HTML;
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Корзина - Научный журнал</title>
    <link rel="stylesheet" href="/css/style.css">
    <style>
        .alert {
            padding: 15px;
            margin-bottom: 20px;
            border: 1px solid transparent;
            border-radius: 4px;
        }
        .alert-error {
            color: #721c24;
            background-color: #f8d7da;
            border-color: #f5c6cb;
        }
        .alert-success {
            color: #155724;
            background-color: #d4edda;
            border-color: #c3e6cb;
        }
        
        .cart-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 1rem;
        }
        
        .cart-table th, .cart-table td {
            padding: 0.75rem;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        
        .cart-table th {
            background-color: #f5f5f5;
        }
        
        .cart-summary {
            display: flex;
            justify-content: flex-end;
            margin-top: 1rem;
            padding-top: 1rem;
            border-top: 1px solid #ddd;
        }
        
        .cart-total {
            font-size: 1.2rem;
            font-weight: bold;
        }
        
        .cart-actions {
            display: flex;
            justify-content: space-between;
            margin-top: 1rem;
        }
        
        .quantity-input {
            width: 60px;
            text-align: center;
        }
        
        .empty-cart {
            text-align: center;
            padding: 2rem;
            color: #666;
        }
    </style>
</head>
<body>
    <header class="header">
        <div class="container header-content">
            <div class="logo">
                <a href="/">Научный журнал</a>
            </div>
            <nav class="nav">
                <a href="/">Главная</a>
                <a href="/cgi-bin/issues.pl">Выпуски</a>
                <a href="/about.html">О журнале</a>
                <a href="/cgi-bin/cart.pl" class="active">Корзина <span id="cart-counter" style="display: none;">0</span></a>
HTML

    if ($user_id) {
        print qq(<a href="/cgi-bin/auth.pl?action=profile">Личный кабинет</a>);
    } else {
        print qq(<a href="/cgi-bin/auth.pl">Вход</a>);
    }

    print <<HTML;
            </nav>
        </div>
    </header>
    
    <main class="main">
        <div class="container">
            <h1 class="mb-4">Корзина</h1>
            
HTML

    if ($error) {
        print qq(<div class="alert alert-error">$error</div>);
    }
    
    if ($success) {
        print qq(<div class="alert alert-success">$success</div>);
    }

    print <<HTML;
            <div id="cart-content">
                <!-- Содержимое корзины будет загружено с помощью JavaScript -->
            </div>
            
            <div id="checkout-form" style="display: none;">
                <div class="card">
                    <h2 class="card-title">Оформление заказа</h2>
                    
HTML

    # Если пользователь не авторизован, показываем сообщение о необходимости входа
    unless ($user_id) {
        print <<HTML;
                    <div class="alert alert-error">
                        Для оформления заказа необходимо <a href="/cgi-bin/auth.pl">войти в систему</a> или <a href="/cgi-bin/auth.pl?action=register_form">зарегистрироваться</a>.
                    </div>
HTML
    } else {
        # Получаем данные пользователя
        my $user = get_user_by_id($user_id);
        
        print <<HTML;
                    <form action="/cgi-bin/cart.pl" method="post">
                        <input type="hidden" name="action" value="checkout">
                        <input type="hidden" name="cart_data" id="cart-data">
                        
                        <div class="form-group">
                            <label for="payment_method">Способ оплаты:</label>
                            <select id="payment_method" name="payment_method" class="form-control">
                                <option value="card">Банковская карта</option>
                                <option value="bank_transfer">Банковский перевод</option>
                                <option value="electronic_wallet">Электронный кошелек</option>
                            </select>
                        </div>
                        
                        <div id="order-summary">
                            <!-- Сводка заказа будет загружена с помощью JavaScript -->
                        </div>
                        
                        <div class="form-group">
                            <button type="submit" class="btn">Оформить заказ</button>
                            <button type="button" class="btn btn-secondary" onclick="hideCheckoutForm()">Отмена</button>
                        </div>
                    </form>
HTML
    }

    print <<HTML;
                </div>
            </div>
        </div>
    </main>
    
    <footer class="footer">
        <div class="container footer-content">
            <div class="footer-section">
                <h3 class="footer-title">О журнале</h3>
                <p>Научный журнал публикует оригинальные исследования в различных областях науки.</p>
            </div>
            <div class="footer-section">
                <h3 class="footer-title">Контакты</h3>
                <p>Email: "info\@scientific-journal.com"</p>
                <p>Телефон: +7 (123) 456-78-90</p>
            </div>
            <div class="footer-section">
                <h3 class="footer-title">Ссылки</h3>
                <p><a href="/about.html">О журнале</a></p>
                <p><a href="/cgi-bin/issues.pl">Архив выпусков</a></p>
HTML

    if ($user_id) {
        print qq(<p><a href="/cgi-bin/auth.pl?action=profile">Личный кабинет</a></p>);
    } else {
        print qq(<p><a href="/cgi-bin/auth.pl?action=register_form">Регистрация</a></p>);
    }

    print <<HTML;
            </div>
        </div>
        <div class="container text-center mt-3">
            <p>&copy; 2025 Научный журнал. Все права защищены.</p>
        </div>
    </footer>
    
    <script>
    function updateCartCounter() {
        var cartCounter = document.getElementById('cart-counter');
        var cart = JSON.parse(localStorage.getItem('cart') || '[]');
        
        if (cart.length > 0) {
            cartCounter.textContent = cart.length;
            cartCounter.style.display = 'inline';
        } else {
            cartCounter.style.display = 'none';
        }
    }
    
    function loadCart() {
        var cartContent = document.getElementById('cart-content');
        var cart = JSON.parse(localStorage.getItem('cart') || '[]');
        
        if (cart.length === 0) {
            cartContent.innerHTML = '<div class="empty-cart">Ваша корзина пуста</div>';
            return;
        }
        
        var totalPrice = 0;
        var html = '<div class="card">' +
                   '<table class="cart-table">' +
                   '<thead>' +
                   '<tr>' +
                   '<th>Название</th>' +
                   '<th>Цена</th>' +
                   '<th>Количество</th>' +
                   '<th>Сумма</th>' +
                   '<th>Действия</th>' +
                   '</tr>' +
                   '</thead>' +
                   '<tbody>';
        
        for (var i = 0; i < cart.length; i++) {
            var item = cart[i];
            var itemTotal = item.price * item.quantity;
            totalPrice += itemTotal;
            
            html += '<tr>' +
                    '<td>' + item.title + '</td>' +
                    '<td>' + item.price + ' руб.</td>' +
                    '<td>' +
                    '<input type="number" min="1" value="' + item.quantity + '" class="quantity-input" ' +
                    'onchange="updateQuantity(' + i + ', this.value)">' +
                    '</td>' +
                    '<td>' + itemTotal + ' руб.</td>' +
                    '<td>' +
                    '<button class="btn btn-small" onclick="removeFromCart(' + i + ')">Удалить</button>' +
                    '</td>' +
                    '</tr>';
        }
        
        html += '</tbody>' +
                '</table>' +
                '<div class="cart-summary">' +
                '<div class="cart-total">Итого: ' + totalPrice + ' руб.</div>' +
                '</div>' +
                '<div class="cart-actions">' +
                '<button class="btn btn-secondary" onclick="clearCart()">Очистить корзину</button>' +
                '<button class="btn" onclick="showCheckoutForm()">Оформить заказ</button>' +
                '</div>' +
                '</div>';
        
        cartContent.innerHTML = html;
    }
    
    function showCheckoutForm() {
        document.getElementById('cart-content').style.display = 'none';
        document.getElementById('checkout-form').style.display = 'block';
        renderOrderSummary();
    }
    
    function hideCheckoutForm() {
        document.getElementById('cart-content').style.display = 'block';
        document.getElementById('checkout-form').style.display = 'none';
    }
    
    function updateQuantity(index, quantity) {
        var cart = JSON.parse(localStorage.getItem('cart') || '[]');
        cart[index].quantity = parseInt(quantity);
        localStorage.setItem('cart', JSON.stringify(cart));
        loadCart();
        updateCartCounter();
    }
    
    function removeFromCart(index) {
        var cart = JSON.parse(localStorage.getItem('cart') || '[]');
        cart.splice(index, 1);
        localStorage.setItem('cart', JSON.stringify(cart));
        loadCart();
        updateCartCounter();
    }
    
    function clearCart() {
        localStorage.setItem('cart', '[]');
        loadCart();
        updateCartCounter();
    }
    
    function renderOrderSummary() {
        var orderSummary = document.getElementById('order-summary');
        var cart = JSON.parse(localStorage.getItem('cart') || '[]');
        var totalPrice = 0;
        
        var orderHtml = 
            '<h3>Ваш заказ</h3>' +
            '<table class="cart-table">' +
            '<thead>' +
            '<tr>' +
            '<th>Название</th>' +
            '<th>Цена</th>' +
            '<th>Количество</th>' +
            '<th>Сумма</th>' +
            '</tr>' +
            '</thead>' +
            '<tbody>';
        
        for (var i = 0; i < cart.length; i++) {
            var item = cart[i];
            var itemTotal = item.price * item.quantity;
            totalPrice += itemTotal;
            
            orderHtml += 
                '<tr>' +
                '<td>' + item.title + '</td>' +
                '<td>' + item.price + ' руб.</td>' +
                '<td>' + item.quantity + '</td>' +
                '<td>' + itemTotal + ' руб.</td>' +
                '</tr>';
        }
        
        orderHtml += 
            '</tbody>' +
            '</table>' +
            '<div class="cart-summary">' +
            '<div class="cart-total">Итого: ' + totalPrice + ' руб.</div>' +
            '</div>';
        
        orderSummary.innerHTML = orderHtml;
        
        // Сохраняем данные корзины в скрытое поле формы
        document.getElementById('cart-data').value = JSON.stringify(cart);
    }
    
    // Загружаем корзину и обновляем счетчик при загрузке страницы
    document.addEventListener('DOMContentLoaded', function() {
        loadCart();
        updateCartCounter();
    });
    </script>
</body>
</html>
HTML
}

# Функция для обработки оформления заказа
sub process_checkout {
    # Проверяем, авторизован ли пользователь
    unless ($user_id) {
        print $q->redirect(-uri => "/cgi-bin/cart.pl?error=Для оформления заказа необходимо войти в систему");
        return;
    }
    
    # Получаем данные пользователя
    my $user = get_user_by_id($user_id);
    
    # Если это GET-запрос, показываем форму оформления заказа
    if ($q->request_method() eq 'GET') {
        # Перенаправляем на страницу корзины
        print $q->redirect(-uri => "/cgi-bin/cart.pl");
    } else {
        # Если это POST-запрос, обрабатываем форму оформления заказа
        process_checkout_form();
    }
}

# Функция для обработки формы оформления заказа
sub process_checkout_form {
    my $cart_data = $q->param('cart_data');
    my $payment_method = $q->param('payment_method') || 'card';
    
    # Проверяем наличие данных корзины
    unless ($cart_data) {
        print $q->redirect(-uri => "/cgi-bin/cart.pl?error=Корзина пуста");
        return;
    }
    
    # Декодируем JSON с данными корзины
    my $cart = eval { decode_json($cart_data) };
    if ($@) {
        print $q->redirect(-uri => "/cgi-bin/cart.pl?error=Ошибка в данных корзины");
        return;
    }
    
    # Проверяем, что корзина не пуста
    unless (@$cart) {
        print $q->redirect(-uri => "/cgi-bin/cart.pl?error=Корзина пуста");
        return;
    }
    
    # Рассчитываем общую сумму заказа
    my $total = 0;
    foreach my $item (@$cart) {
        my $item_total = $item->{price} * $item->{quantity};
        $total += $item_total;
    }
    
    # Генерируем номер квитанции
    my $receipt_number = sprintf("REC-%s-%06d", strftime("%Y%m%d", localtime), int(rand(1000000)));
    
    # Создаем заказ в базе данных
    my $order_id = create_order(
        $user_id,
        $total,
        'new',
        $payment_method,
        $receipt_number
    );
    
    # Добавляем детали заказа
    foreach my $item (@$cart) {
        add_order_detail(
            $order_id,
            $item->{id},
            $item->{quantity},
            $item->{price}
        );
    }
    
    # Перенаправляем на страницу подтверждения заказа
    print $q->redirect(-uri => "/cgi-bin/cart.pl?action=confirmation&order_id=$order_id");
}

# Функция для отображения страницы подтверждения заказа
sub show_confirmation {
    my $order_id = $q->param('order_id');
    
    binmode(STDOUT, ":utf8");
    print "Content-Type: text/html; charset=utf-8\n\n";
    
    print <<HTML;
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Заказ оформлен - Научный журнал</title>
    <link rel="stylesheet" href="/css/style.css">
</head>
<body>
    <header class="header">
        <div class="container header-content">
            <div class="logo">
                <a href="/">Научный журнал</a>
            </div>
            <nav class="nav">
                <a href="/">Главная</a>
                <a href="/cgi-bin/issues.pl">Выпуски</a>
                <a href="/about.html">О журнале</a>
                <a href="/cgi-bin/cart.pl">Корзина <span id="cart-counter" style="display: none;">0</span></a>
HTML

    if ($user_id) {
        print qq(<a href="/cgi-bin/auth.pl?action=profile">Личный кабинет</a>);
    } else {
        print qq(<a href="/cgi-bin/auth.pl">Вход</a>);
    }

    print <<HTML;
            </nav>
        </div>
    </header>
    
    <main class="main">
        <div class="container">
            <div class="card text-center">
                <h1 class="card-title">Заказ успешно оформлен!</h1>
                <p>Ваш заказ №$order_id успешно оформлен и принят в обработку.</p>
                <p>Вы можете отслеживать статус заказа в <a href="/cgi-bin/auth.pl?action=profile">личном кабинете</a>.</p>
                <div class="mt-3">
                    <a href="/" class="btn">Вернуться на главную</a>
                </div>
            </div>
        </div>
    </main>
    
    <footer class="footer">
        <div class="container footer-content">
            <div class="footer-section">
                <h3 class="footer-title">О журнале</h3>
                <p>Научный журнал публикует оригинальные исследования в различных областях науки.</p>
            </div>
            <div class="footer-section">
                <h3 class="footer-title">Контакты</h3>
                <p>Email: "info\@scientific-journal.com"</p>
                <p>Телефон: +7 (123) 456-78-90</p>
            </div>
            <div class="footer-section">
                <h3 class="footer-title">Ссылки</h3>
                <p><a href="/about.html">О журнале</a></p>
                <p><a href="/cgi-bin/issues.pl">Архив выпусков</a></p>
HTML

    if ($user_id) {
        print qq(<p><a href="/cgi-bin/auth.pl?action=profile">Личный кабинет</a></p>);
    } else {
        print qq(<p><a href="/cgi-bin/auth.pl?action=register_form">Регистрация</a></p>);
    }

    print <<HTML;
            </div>
        </div>
        <div class="container text-center mt-3">
            <p>&copy; 2025 Научный журнал. Все права защищены.</p>
        </div>
    </footer>
    
    <script>
    // Очищаем корзину после успешного оформления заказа
    localStorage.setItem('cart', '[]');
    
    function updateCartCounter() {
        var cartCounter = document.getElementById('cart-counter');
        var cart = JSON.parse(localStorage.getItem('cart') || '[]');
        
        if (cart.length > 0) {
            cartCounter.textContent = cart.length;
            cartCounter.style.display = 'inline';
        } else {
            cartCounter.style.display = 'none';
        }
    }
    
    // Обновляем счетчик корзины при загрузке страницы
    document.addEventListener('DOMContentLoaded', function() {
        updateCartCounter();
    });
    </script>
</body>
</html>
HTML
}