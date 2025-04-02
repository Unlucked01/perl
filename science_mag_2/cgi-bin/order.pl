#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DB_File;

my $cgi = CGI->new;
print $cgi->header(-type => 'text/html', -charset => 'UTF-8');

# Define paths
my $db_path = "/usr/local/apache2/data/users.db";
my $sessions_path = "/usr/local/apache2/data/sessions.db";
my $orders_path = "/usr/local/apache2/data/orders.db";

# Check if user is logged in
my $session_cookie = $cgi->cookie('session') || '';
my ($user_email, $user_name, $user_role) = check_session($session_cookie);

# Get order ID from URL parameter
my $order_id = $cgi->param('id') || '';

# Redirect to login if not logged in
if (!$user_email) {
    print $cgi->redirect(-uri => '/cgi-bin/login.pl');
    exit;
}

# Get order details
my %orders;
my $order_data = '';
if (tie %orders, 'DB_File', $orders_path, O_RDONLY, 0644, $DB_HASH) {
    if (exists $orders{$order_id}) {
        $order_data = $orders{$order_id};
    }
    untie %orders;
}

# If order not found or doesn't belong to user
if (!$order_data) {
    print <<HTML;
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Заказ не найден | Научный журнал</title>
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
                    </div>
                </div>
            </div>
        </nav>
    </header>

    <main class="container my-4">
        <div class="row justify-content-center">
            <div class="col-md-8">
                <div class="card">
                    <div class="card-body text-center">
                        <div class="mb-4">
                            <i class="bi bi-exclamation-circle-fill text-warning" style="font-size: 5rem;"></i>
                        </div>
                        <h1 class="card-title mb-4">Заказ не найден</h1>
                        <p class="card-text">Заказ с номером <strong>$order_id</strong> не найден или у вас нет доступа к его просмотру.</p>
                        
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
</body>
</html>
HTML
    exit;
}

# Parse order data
my ($order_email, $order_date, $order_amount, $order_status) = split(':::', $order_data);

# Check if order belongs to current user or if user is admin
if ($order_email ne $user_email && $user_role ne 'admin') {
    print <<HTML;
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Доступ запрещен | Научный журнал</title>
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
                    </div>
                </div>
            </div>
        </nav>
    </header>

    <main class="container my-4">
        <div class="row justify-content-center">
            <div class="col-md-8">
                <div class="card">
                    <div class="card-body text-center">
                        <div class="mb-4">
                            <i class="bi bi-shield-lock-fill text-danger" style="font-size: 5rem;"></i>
                        </div>
                        <h1 class="card-title mb-4">Доступ запрещен</h1>
                        <p class="card-text">У вас нет доступа к просмотру этого заказа.</p>
                        
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
</body>
</html>
HTML
    exit;
}

# Display order details
print <<HTML;
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Детали заказа | Научный журнал</title>
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
                    </div>
                </div>
            </div>
        </nav>
    </header>

    <main class="container my-4">
        <nav aria-label="breadcrumb" class="mb-4">
            <ol class="breadcrumb">
                <li class="breadcrumb-item"><a href="/index.html">Главная</a></li>
                <li class="breadcrumb-item"><a href="/cgi-bin/profile.pl">Личный кабинет</a></li>
                <li class="breadcrumb-item active" aria-current="page">Детали заказа</li>
            </ol>
        </nav>

        <div class="row">
            <div class="col-md-8">
                <div class="card">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h5 class="card-title mb-0">Детали заказа</h5>
                        <span class="badge bg-primary">$order_status</span>
HTML

# Add admin badge if applicable
if ($user_role eq 'admin') {
    print '<span class="badge bg-danger ms-2">Администратор</span>';
}

print <<HTML;
                    </div>
                    <div class="card-body">
                        <div class="mb-3">
                            <h6>Информация о заказе</h6>
                            <div class="row">
                                <div class="col-md-6">
                                    <p><strong>Номер заказа:</strong> $order_id</p>
                                    <p><strong>Дата оформления:</strong> $order_date</p>
                                </div>
                                <div class="col-md-6">
                                    <p><strong>Сумма заказа:</strong> $order_amount ₽</p>
                                    <p><strong>Статус:</strong> $order_status</p>
                                </div>
                            </div>
                        </div>
                        
                        <!-- Admin-specific information -->
HTML

# Show admin message if user is an admin and not the order owner
if ($user_role eq 'admin' && $order_email ne $user_email) {
    print <<HTML;
                        <div class="alert alert-info">
                            <strong>Администратор:</strong> Вы просматриваете заказ пользователя $order_email
                        </div>
HTML
}

print <<HTML;
                        <div class="mb-3">
                            <h6>Контактная информация</h6>
                            <p><strong>Email:</strong> $order_email</p>
                        </div>
                    </div>
                </div>

                <div class="card mb-4">
                    <div class="card-header">
                        <h5 class="mb-0">Товары в заказе</h5>
                    </div>
                    <div class="card-body">
                        <div class="table-responsive">
                            <table class="table">
                                <thead>
                                    <tr>
                                        <th>Товар</th>
                                        <th>Цена</th>
                                        <th>Количество</th>
                                        <th>Итого</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr>
                                        <td>Электронная версия выпуска</td>
                                        <td>$order_amount ₽</td>
                                        <td>1</td>
                                        <td>$order_amount ₽</td>
                                    </tr>
                                </tbody>
                                <tfoot>
                                    <tr>
                                        <td colspan="3" class="text-end"><strong>Итого к оплате:</strong></td>
                                        <td><strong>$order_amount ₽</strong></td>
                                    </tr>
                                </tfoot>
                            </table>
                        </div>
                    </div>
                </div>
            </div>

            <div class="col-md-4">
                <div class="card mb-4">
                    <div class="card-header">
                        <h5 class="mb-0">Действия</h5>
                    </div>
                    <div class="card-body">
                        <div class="d-grid gap-2">
                            <a href="/cgi-bin/profile.pl" class="btn btn-outline-primary">
                                <i class="bi bi-arrow-left"></i> Вернуться в личный кабинет
                            </a>
                            <a href="/index.html" class="btn btn-outline-secondary">
                                <i class="bi bi-house"></i> На главную
                            </a>
                        </div>
                    </div>
                </div>

                <div class="card">
                    <div class="card-header">
                        <h5 class="mb-0">Поддержка</h5>
                    </div>
                    <div class="card-body">
                        <p>Если у вас возникли вопросы по заказу, свяжитесь с нами:</p>
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
</body>
</html>
HTML

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

sub check_session {
    my $session_id = shift;
    
    if (!$session_id) {
        return ('', '', '');
    }
    
    # Get session data from database
    my %sessions;
    if (tie %sessions, 'DB_File', $sessions_path, O_RDONLY, 0644, $DB_HASH) {
        if (exists $sessions{$session_id}) {
            my ($email, $role, $expiry) = split(':::', $sessions{$session_id});
            
            # Check if session is expired
            if ($expiry > time()) {
                # Get user data from users database
                my %users;
                if (tie %users, 'DB_File', $db_path, O_RDONLY, 0644, $DB_HASH) {
                    if (exists $users{$email}) {
                        my ($password, $name, $role) = split(':::', $users{$email});
                        untie %users;
                        untie %sessions;
                        return ($email, $name, $role);
                    }
                    untie %users;
                }
            }
        }
        untie %sessions;
    }
    
    return ('', '', '');
}

