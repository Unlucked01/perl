#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DB_File;
use Encode;

my $cgi = CGI->new;

# Define paths
my $db_path = "/usr/local/apache2/data/users.db";
my $sessions_path = "/usr/local/apache2/data/sessions.db";
my $issues_path = "/usr/local/apache2/data/issues.db";

# Check if user is logged in
my $session_cookie = $cgi->cookie('session') || '';
my ($user_email, $user_name, $user_role) = check_session($session_cookie);

print $cgi->header(-type => 'text/html', -charset => 'UTF-8');

# Display issues page
print_issues_page();

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

# Function to display issues page
sub print_issues_page {
    print <<HTML;
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Выпуски | Научный журнал</title>
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

    # Display user profile dropdown if logged in, or login button if not
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
        <h1 class="mb-4">Выпуски журнала</h1>
        
        <div class="row">
HTML

    # Display issues from the database
    my %issues;
    if (tie %issues, 'DB_File', $issues_path, O_RDONLY, 0644, $DB_HASH) {
        my @issue_keys = sort keys %issues;
        
        foreach my $issue_id (@issue_keys) {
            my ($number, $date, $title, $description, $articles, $price) = split(':::', $issues{$issue_id});
            
            print <<HTML;
            <div class="col-md-6 mb-4">
                <div class="card">
                    <div class="card-body">
                        <h5 class="card-title">$title</h5>
                        <h6 class="card-subtitle mb-2 text-muted">$number ($date)</h6>
                        <p class="card-text">$description</p>
                        <p class="card-text"><strong>Цена:</strong> $price ₽</p>
                        <a href="/cgi-bin/issue.pl?id=$issue_id" class="btn btn-primary">Подробнее</a>
                        <button class="btn btn-outline-primary" onclick="addToCart('$issue_id', '$title', $price)">В корзину</button>
                    </div>
                </div>
            </div>
HTML
        }
        
        untie %issues;
    } else {
        print <<HTML;
            <div class="col-12">
                <div class="alert alert-warning">
                    Выпуски не найдены. Пожалуйста, зайдите позже.
                </div>
            </div>
HTML
    }

    print <<HTML;
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