#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DB_File;

my $cgi = CGI->new;

# Define paths
my $db_path = "/usr/local/apache2/data/users.db";
my $sessions_path = "/usr/local/apache2/data/sessions.db";
my $issues_path = "/usr/local/apache2/data/issues.db";

my $issue_id = $cgi->param('id');
my $session_cookie = $cgi->cookie('session') || '';
my ($user_email, $user_name, $user_role) = check_session($session_cookie);

if (!$user_email) {
    print $cgi->redirect(-uri => '/cgi-bin/login.pl');
    exit;
}

print $cgi->header(-type => 'text/html', -charset => 'UTF-8');

if (!$issue_id) {
    print_error("Идентификатор выпуска не указан");
    exit;
}

unless (-e $issues_path) {
    print_error("База данных выпусков не найдена");
    exit;
}

my %issues;
if (tie %issues, 'DB_File', $issues_path, O_RDONLY, 0644, $DB_HASH) {
    if (exists $issues{$issue_id}) {
        my ($number, $date, $title, $description, $articles, $price) = split(/:::/, $issues{$issue_id});
        untie %issues;
        
        print_issue_details($issue_id, $number, $date, $title, $description, $articles, $price);
    } else {
        untie %issues;
        print_error("Выпуск не найден");
    }
} else {
    print_error("Ошибка при открытии базы данных выпусков");
}

sub check_session {
    my $session_id = shift;
    
    if (!$session_id) {
        return ('', '', '');
    }
    
    my %sessions;
    if (tie %sessions, 'DB_File', $sessions_path, O_RDONLY, 0644, $DB_HASH) {
        if (exists $sessions{$session_id}) {
            my ($email, $role, $expiry) = split(':::', $sessions{$session_id});
            
            if ($expiry > time()) {
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

sub print_issue_details {
    my ($issue_id, $number, $date, $title, $description, $articles, $price) = @_;

    print <<HTML;
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$title | Научный журнал</title>
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
                            <a class="nav-link active" href="/cgi-bin/issues.pl">Выпуски</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="/about.html">О журнале</a>
                        </li>
HTML

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
        <div class="row">
            <div class="col-lg-8">
                <nav aria-label="breadcrumb">
                    <ol class="breadcrumb">
                        <li class="breadcrumb-item"><a href="/cgi-bin/index.pl">Главная</a></li>
                        <li class="breadcrumb-item"><a href="/cgi-bin/issues.pl">Выпуски</a></li>
                        <li class="breadcrumb-item active" aria-current="page">$title</li>
                    </ol>
                </nav>
                
                <div class="card mb-4">
                    <div class="card-body">
                        <h1 class="card-title">$title</h1>
                        <h5 class="card-subtitle mb-3 text-muted">Выпуск $number от $date</h5>
                        <p class="card-text">$description</p>
                        <hr>
                        <h4>Содержание выпуска:</h4>
                        <ul class="list-group list-group-flush">
HTML

    my @article_ids = split(/,/, $articles);
    foreach my $i (0..$#article_ids) {
        my $article_num = $i + 1;
        print <<HTML;
                            <li class="list-group-item d-flex justify-content-between align-items-center">
                                <span>$article_num. Статья $article_ids[$i]</span>
                                <span class="badge bg-primary rounded-pill">PDF</span>
                            </li>
HTML
    }

    print <<HTML;
                        </ul>
                    </div>
                    <div class="card-footer">
                        <div class="d-flex justify-content-between align-items-center">
                            <div>
                                <p class="my-0"><strong>Цена:</strong> $price ₽</p>
                            </div>
                            <div>
                                <button class="btn btn-primary" onclick="addToCart('$issue_id', '$title', $price)">
                                    <i class="bi bi-cart-plus"></i> В корзину
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="col-lg-4">
                <div class="card mb-4">
                    <div class="card-header bg-primary text-white">
                        <h5 class="card-title mb-0">Информация о выпуске</h5>
                    </div>
                    <div class="card-body">
                        <ul class="list-group list-group-flush">
                            <li class="list-group-item d-flex justify-content-between">
                                <span>Номер выпуска:</span>
                                <span><strong>$number</strong></span>
                            </li>
                            <li class="list-group-item d-flex justify-content-between">
                                <span>Дата публикации:</span>
                                <span><strong>$date</strong></span>
                            </li>
                            <li class="list-group-item d-flex justify-content-between">
                                <span>Количество статей:</span>
                                <span><strong>@{[scalar(@article_ids)]}</strong></span>
                            </li>
                            <li class="list-group-item d-flex justify-content-between">
                                <span>Цена:</span>
                                <span><strong>$price ₽</strong></span>
                            </li>
                        </ul>
                    </div>
                </div>
                
                <div class="card">
                    <div class="card-header bg-secondary text-white">
                        <h5 class="card-title mb-0">Как приобрести</h5>
                    </div>
                    <div class="card-body">
                        <p>Для приобретения выпуска добавьте его в корзину и оформите заказ. После оплаты вы получите доступ к полным текстам статей.</p>
                        <button class="btn btn-primary w-100" onclick="addToCart('$issue_id', '$title', $price)">
                            <i class="bi bi-cart-plus"></i> Добавить в корзину
                        </button>
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
    function addToCart(issueId, title, price) {
        // Get existing cart from localStorage or create new one
        let cart = JSON.parse(localStorage.getItem('cart') || '[]');
        
        // Check if item already exists in cart
        let existingItem = cart.find(item => item.id === issueId);
        
        if (existingItem) {
            existingItem.quantity += 1;
        } else {
            // Add item to cart
            cart.push({
                id: issueId,
                title: title,
                price: price,
                type: 'issue',
                quantity: 1
            });
        }
        
        // Save updated cart
        localStorage.setItem('cart', JSON.stringify(cart));
        
        // Show notification
        alert('Выпуск добавлен в корзину');
    }
    </script>
</body>
</html>
HTML
}

# Function to display error message
sub print_error {
    my $message = shift;
    
    print <<HTML;
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Ошибка | Научный журнал</title>
    <link href="/css/bootstrap.min.css" rel="stylesheet">
    <link href="/css/styles.css" rel="stylesheet">
</head>
<body>
    <div class="container my-5">
        <div class="alert alert-danger">
            <h4 class="alert-heading">Ошибка!</h4>
            <p>$message</p>
            <hr>
            <p class="mb-0">
                <a href="/cgi-bin/issues.pl" class="btn btn-primary">Вернуться к списку выпусков</a>
            </p>
        </div>
    </div>
</body>
</html>
HTML
} 