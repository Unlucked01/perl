#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
use Encode qw(decode encode);
use Digest::MD5 qw(md5_hex);
use POSIX qw(strftime);
use DB_File;

# Подключаем модуль для работы с БД
require "./db_utils.pl";
db_utils->import(qw(
    init_database
    get_user_by_login
    get_user_by_id
    get_next_id
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
my $action = $q->param('action') || 'login_form';

# Получаем данные сессии из cookie
my $session_cookie = $q->cookie('session');
my ($user_id, $user_role) = split(/:/, $session_cookie) if $session_cookie;

# Обработка действий
if ($action eq 'login_form') {
    show_login_form();
} elsif ($action eq 'login') {
    process_login();
} elsif ($action eq 'register_form') {
    show_register_form();
} elsif ($action eq 'register') {
    process_registration();
} elsif ($action eq 'logout') {
    process_logout();
} elsif ($action eq 'profile') {
    show_profile();
} else {
    show_login_form();
}

# Функция для отображения формы входа
sub show_login_form {
    my $error = $q->param('error') || '';
    my $success = $q->param('success') || '';
    
    # Декодируем сообщения
    $error = decode('utf-8', $error) if $error;
    $success = decode('utf-8', $success) if $success;
    
    binmode(STDOUT, ":utf8");
    print "Content-Type: text/html; charset=utf-8\n\n";
    
    print <<HTML;
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Вход в систему - Научный журнал</title>
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
                <a href="/cgi-bin/cart.pl">Корзина <span id="cart-counter" style="display: none;">0</span></a>
                <a href="/cgi-bin/auth.pl" class="active">Вход</a>
            </nav>
        </div>
    </header>
    
    <main class="main">
        <div class="container">
            <div class="card" style="max-width: 500px; margin: 0 auto;">
                <h1 class="card-title">Вход в систему</h1>
                
HTML

    if ($error) {
        print qq(<div class="alert alert-error">$error</div>);
    }
    
    if ($success) {
        print qq(<div class="alert alert-success">$success</div>);
    }

    print <<HTML;
                <form action="/cgi-bin/auth.pl" method="post">
                    <input type="hidden" name="action" value="login">
                    
                    <div class="form-group">
                        <label for="login">Логин:</label>
                        <input type="text" id="login" name="login" required class="form-control">
                    </div>
                    
                    <div class="form-group">
                        <label for="password">Пароль:</label>
                        <input type="password" id="password" name="password" required class="form-control">
                    </div>
                    
                    <div class="form-group">
                        <button type="submit" class="btn">Войти</button>
                    </div>
                </form>
                
                <div class="mt-3">
                    <p>Еще нет аккаунта? <a href="/cgi-bin/auth.pl?action=register_form">Зарегистрироваться</a></p>
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
                <p><a href="/cgi-bin/auth.pl?action=register_form">Регистрация</a></p>
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
    
    // Обновляем счетчик корзины при загрузке страницы
    document.addEventListener('DOMContentLoaded', function() {
        updateCartCounter();
    });
    </script>
</body>
</html>
HTML
}

# Функция для обработки входа
sub process_login {
    my $login = $q->param('login');
    my $password = $q->param('password');
    
    # Проверяем, что логин и пароль указаны
    unless ($login && $password) {
        my $error_msg = "Необходимо указать логин и пароль";
        $error_msg = encode('utf-8', $error_msg);
        print $q->redirect(-uri => "/cgi-bin/auth.pl?error=$error_msg");
        return;
    }
    
    # Получаем данные пользователя
    my $user = get_user_by_login($login);
    
    # Проверяем, что пользователь существует и пароль верный
    unless ($user && $user->{password} eq md5_hex($password)) {
        my $error_msg = "Неверный логин или пароль";
        $error_msg = encode('utf-8', $error_msg);
        print $q->redirect(-uri => "/cgi-bin/auth.pl?error=$error_msg");
        return;
    }
    
    # Создаем cookie с данными сессии
    my $cookie = $q->cookie(
        -name => 'session',
        -value => "$user->{id}:$user->{role}",
        -expires => '+1d'
    );
    
    # Перенаправляем на главную страницу
    print $q->redirect(
        -uri => '/',
        -cookie => $cookie
    );
}

# Функция для отображения формы регистрации
sub show_register_form {
    my $error = $q->param('error') || '';
    
    binmode(STDOUT, ":utf8");
    print "Content-Type: text/html; charset=utf-8\n\n";
    
    print <<HTML;
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Регистрация - Научный журнал</title>
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
                <a href="/cgi-bin/cart.pl">Корзина <span id="cart-counter" style="display: none;">0</span></a>
                <a href="/cgi-bin/auth.pl" class="active">Вход</a>
            </nav>
        </div>
    </header>
    
    <main class="main">
        <div class="container">
            <div class="card" style="max-width: 600px; margin: 0 auto;">
                <h1 class="card-title">Регистрация</h1>
                
HTML

    if ($error) {
        print qq(<div class="alert alert-error">$error</div>);
    }

    print <<HTML;
                <form action="/cgi-bin/auth.pl" method="post">
                    <input type="hidden" name="action" value="register">
                    
                    <div class="form-group">
                        <label for="login">Логин:</label>
                        <input type="text" id="login" name="login" required class="form-control">
                    </div>
                    
                    <div class="form-group">
                        <label for="password">Пароль:</label>
                        <input type="password" id="password" name="password" required class="form-control">
                    </div>
                    
                    <div class="form-group">
                        <label for="confirm_password">Подтверждение пароля:</label>
                        <input type="password" id="confirm_password" name="confirm_password" required class="form-control">
                    </div>
                    
                    <div class="form-group">
                        <label for="email">Email:</label>
                        <input type="email" id="email" name="email" required class="form-control">
                    </div>
                    
                    <div class="form-group">
                        <label for="full_name">ФИО:</label>
                        <input type="text" id="full_name" name="full_name" required class="form-control">
                    </div>
                    
                    <div class="form-group">
                        <button type="submit" class="btn">Зарегистрироваться</button>
                    </div>
                </form>
                
                <div class="mt-3">
                    <p>Уже есть аккаунт? <a href="/cgi-bin/auth.pl">Войти</a></p>
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
                <p><a href="/cgi-bin/auth.pl">Вход</a></p>
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
    
    // Обновляем счетчик корзины при загрузке страницы
    document.addEventListener('DOMContentLoaded', function() {
        updateCartCounter();
    });
    </script>
</body>
</html>
HTML
}

# Функция для обработки регистрации
sub process_registration {
    my $login = $q->param('login');
    my $password = $q->param('password');
    my $confirm_password = $q->param('confirm_password');
    my $email = $q->param('email');
    my $full_name = $q->param('full_name');
    
    # Проверяем, что все поля заполнены
    unless ($login && $password && $confirm_password && $email && $full_name) {
        print $q->redirect(-uri => "/cgi-bin/auth.pl?action=register_form&error=Все поля обязательны для заполнения");
        return;
    }
    
    # Проверяем, что пароли совпадают
    unless ($password eq $confirm_password) {
        my $error_msg = "Пароли не совпадают";
        $error_msg = encode('utf-8', $error_msg);
        print $q->redirect(-uri => "/cgi-bin/auth.pl?action=register_form&error=$error_msg");
        return;
    }
    
    # Проверяем, что логин не занят
    my $existing_user = get_user_by_login($login);
    if ($existing_user) {
        my $error_msg = "Логин уже занят";
        $error_msg = encode('utf-8', $error_msg);
        print $q->redirect(-uri => "/cgi-bin/auth.pl?action=register_form&error=$error_msg");
        return;
    }
    
    # Получаем следующий ID пользователя
    my $user_id = get_next_id($db_utils::USERS_DB);
    
    # Хешируем пароль
    my $hashed_password = md5_hex($password);
    
    # Создаем запись о пользователе
    my %users;
    tie %users, 'DB_File', $db_utils::USERS_DB, O_RDWR, 0666, $DB_HASH
        or die "Не удалось открыть базу данных пользователей: $!";
    
    # Формируем данные пользователя
    my $user_data = encode_utf8(join('|', (
        $login,
        $hashed_password,
        $full_name,
        $email,
        "+7 (000) 000-00-00", # телефон (пустой)
        "Не указан", # адрес (пустой)
        'user', # роль по умолчанию
        strftime("%Y-%m-%d", localtime) # дата регистрации
    )));
    
    $users{$user_id} = $user_data;
    untie %users;
    
    # Перенаправляем на страницу входа с сообщением об успешной регистрации
    my $success_msg = "Регистрация успешно завершена. Теперь вы можете войти в систему.";
    $success_msg = encode('utf-8', $success_msg);
    print $q->redirect(-uri => "/cgi-bin/auth.pl?success=$success_msg");
}

# Функция для выхода из системы
sub process_logout {
    # Создаем cookie с пустым значением и истекшим сроком действия
    my $cookie = $q->cookie(
        -name => 'session',
        -value => '',
        -expires => '-1d'
    );
    
    # Перенаправляем на главную страницу
    print $q->redirect(
        -uri => '/',
        -cookie => $cookie
    );
}

# Функция для отображения профиля пользователя
sub show_profile {
    # Проверяем, авторизован ли пользователь
    unless ($user_id) {
        print $q->redirect(-uri => "/cgi-bin/auth.pl?error=Для доступа к профилю необходимо войти в систему");
        return;
    }
    
    # Получаем данные пользователя
    my $user = get_user_by_id($user_id);
    
    binmode(STDOUT, ":utf8");
    print "Content-Type: text/html; charset=utf-8\n\n";
    
    print <<HTML;
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Личный кабинет - Научный журнал</title>
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
                <a href="/cgi-bin/auth.pl?action=profile" class="active">Личный кабинет</a>
            </nav>
        </div>
    </header>
    
    <main class="main">
        <div class="container">
            <h1 class="mb-4">Личный кабинет</h1>
            
            <div class="card mb-4">
                <h2 class="card-title">Информация о пользователе</h2>
                <p><strong>Логин:</strong> $user->{login}</p>
                <p><strong>Email:</strong> $user->{email}</p>
                <p><strong>ФИО:</strong> $user->{full_name}</p>
                <p><strong>Роль:</strong> $user->{role}</p>
                <p><strong>Дата регистрации:</strong> $user->{registration_date}</p>
            </div>
            
            <div class="card mb-4">
                <h2 class="card-title">Действия</h2>
                <a href="/cgi-bin/auth.pl?action=logout" class="btn">Выйти из системы</a>
            </div>
HTML

    # Если пользователь - редактор или администратор, показываем дополнительные опции
    if ($user_role eq 'editor' || $user_role eq 'admin') {
        print <<HTML;
            <div class="card mb-4">
                <h2 class="card-title">Управление статьями</h2>
                <p>Здесь вы можете управлять статьями и выпусками журнала.</p>
                <a href="/cgi-bin/admin.pl?action=articles" class="btn">Управление статьями</a>
                <a href="/cgi-bin/admin.pl?action=issues" class="btn">Управление выпусками</a>
            </div>
HTML
    }

    # Если пользователь - администратор, показываем панель администратора
    if ($user_role eq 'admin') {
        print <<HTML;
            <div class="card mb-4">
                <h2 class="card-title">Панель администратора</h2>
                <p>Здесь вы можете управлять пользователями и просматривать статистику.</p>
                <a href="/cgi-bin/admin.pl?action=users" class="btn">Управление пользователями</a>
                <a href="/cgi-bin/admin.pl?action=stats" class="btn">Статистика продаж</a>
            </div>
HTML
    }

    print <<HTML;
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
                <p><a href="/cgi-bin/auth.pl?action=logout">Выйти</a></p>
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
    
    // Обновляем счетчик корзины при загрузке страницы
    document.addEventListener('DOMContentLoaded', function() {
        updateCartCounter();
    });
    </script>
</body>
</html>
HTML
} 