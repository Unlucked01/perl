#!/usr/bin/perl
use strict;
use warnings;
use CGI qw/:standard/;
use CGI::Carp qw(fatalsToBrowser);
use DB_File;
use Fcntl qw(:DEFAULT :flock);

my $cgi = CGI->new;

# Define data paths
my $data_dir = "/usr/local/apache2/data";
my $issues_path = "$data_dir/issues.db";
my $db_path = "$data_dir/users.db";
my $sessions_path = "$data_dir/sessions.db";

# Check if user is logged in
my $session_cookie = $cgi->cookie('session') || '';
my ($user_email, $user_name, $user_role) = check_session($session_cookie);

print $cgi->header(-type => 'text/html', -charset => 'UTF-8');

# Print HTML header
print <<HTML;
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Главная | Научный журнал</title>
    <link href="/css/bootstrap.min.css" rel="stylesheet">
    <link href="/css/bootstrap-icons.css" rel="stylesheet">
    <link href="/css/styles.css" rel="stylesheet">
</head>
<body>
    <header>
        <nav class="navbar navbar-expand-lg navbar-dark bg-primary">
            <div class="container">
                <a class="navbar-brand" href="/index.pl">Научный журнал</a>
                <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                    <span class="navbar-toggler-icon"></span>
                </button>
                <div class="collapse navbar-collapse" id="navbarNav">
                    <ul class="navbar-nav me-auto">
                        <li class="nav-item">
                            <a class="nav-link active" href="/cgi-bin/index.pl">Главная</a>
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
                        <a href="/cgi-bin/cart.html" class="btn btn-outline-light me-2">
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
        <div class="jumbotron bg-light p-5 rounded">
            <h1 class="display-4">Добро пожаловать!</h1>
            <p class="lead">Добро пожаловать на сайт нашего научного журнала. Здесь вы найдете последние научные статьи и исследования.</p>
            <hr class="my-4">
            <p>Ознакомьтесь с последними выпусками или зарегистрируйтесь для доступа ко всем материалам.</p>
            <a class="btn btn-primary btn-lg" href="/cgi-bin/issues.pl" role="button">Смотреть выпуски</a>
        </div>

        <h2 class="my-4">Последние выпуски</h2>
        <div class="row">
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

# Check if issues database exists before trying to open it
if (-e $issues_path) {
    my %issues;
    # Use eval to catch errors
    eval {
        tie %issues, 'DB_File', $issues_path, O_RDONLY, 0644, $DB_HASH or die "Cannot open issues database: $!";
        
        # Get the last 4 issues (or less if there are fewer)
        my @issue_keys = sort { $b cmp $a } keys %issues;
        my $count = 0;
        
        foreach my $issue_id (@issue_keys) {
            last if $count >= 4; # Show only 4 latest issues
            
            my ($number, $date, $title, $description, $articles, $price) = split(/:::/, $issues{$issue_id});
            
            print <<HTML;
            <div class="col-md-6 mb-4">
                <div class="card">
                    <div class="card-body">
                        <h5 class="card-title">$title</h5>
                        <h6 class="card-subtitle mb-2 text-muted">$number ($date)</h6>
                        <p class="card-text">$description</p>
                        <p class="card-text"><strong>Цена:</strong> $price руб.</p>
                        <a href="/cgi-bin/issue.pl?id=$issue_id" class="btn btn-primary">Подробнее</a>
                        <button class="btn btn-outline-primary" onclick="addToCart('$issue_id')">В корзину</button>
                    </div>
                </div>
            </div>
HTML
            $count++;
        }
        
        untie %issues;
    };
    
    # If there was an error, display it
    if ($@) {
        print "<div class='alert alert-danger'>Ошибка при доступе к базе данных выпусков: $@</div>";
    }
} else {
    print "<div class='alert alert-warning'>База данных выпусков не найдена. Пожалуйста, обратитесь к администратору.</div>";
    print "<div class='alert alert-info'>Ожидаемый путь к базе данных: $issues_path</div>";
}

# Close the HTML
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
                <div class="col-md-6 text-md-end">
                    <a href="/about.html" class="text-white">О журнале</a> |
                    <a href="/contacts.html" class="text-white">Контакты</a>
                </div>
            </div>
        </div>
    </footer>

    <script src="/js/bootstrap.bundle.min.js"></script>
    <script>
    function addToCart(issueId) {
        // Check if user is logged in
        const isLoggedIn = Boolean("$user_email");
        
        if (!isLoggedIn) {
            alert('Для добавления в корзину необходимо войти в систему');
            window.location.href = '/cgi-bin/login.pl';
            return;
        }
        
        // Find the item details from the card that was clicked
        const cardElement = event.target.closest('.card');
        if (!cardElement) {
            alert('Ошибка при добавлении в корзину');
            return;
        }
        
        // Extract information from the card
        const title = cardElement.querySelector('.card-title').textContent;
        const priceText = cardElement.querySelector('.card-text strong').nextSibling.textContent;
        const price = parseInt(priceText.match(/\d+/)[0]); // Extract number from "500 руб."
        
        // Get existing cart
        let cart = JSON.parse(localStorage.getItem('cart') || '[]');
        
        // Check if item already exists in cart
        const existingItemIndex = cart.findIndex(item => item.id === issueId);
        
        if (existingItemIndex >= 0) {
            // Update quantity if item exists
            cart[existingItemIndex].quantity += 1;
        } else {
            // Add new item to cart
            cart.push({
                id: issueId,
                title: title,
                price: price,
                type: 'issue',
                quantity: 1
            });
        }
        
        // Save cart
        localStorage.setItem('cart', JSON.stringify(cart));
        
        // Show confirmation
        alert('Выпуск добавлен в корзину');
        
        // Update cart counter if exists
        updateCartCounter();
    }
    
    // Update cart count in the header
    function updateCartCounter() {
        const cart = JSON.parse(localStorage.getItem('cart') || '[]');
        const count = cart.reduce((total, item) => total + (item.quantity || 1), 0);
        
        // Find the cart button
        const cartBtn = document.querySelector('a[href="/cgi-bin/cart.html"]');
        if (cartBtn) {
            // Get or create badge
            let badge = cartBtn.querySelector('.badge');
            if (!badge && count > 0) {
                badge = document.createElement('span');
                badge.className = 'badge bg-danger ms-2';
                cartBtn.appendChild(badge);
            }
            
            if (badge) {
                if (count > 0) {
                    badge.textContent = count;
                    badge.style.display = 'inline-block';
                } else {
                    badge.style.display = 'none';
                }
            }
        }
    }
    
    // Initialize cart counter on load
    document.addEventListener('DOMContentLoaded', function() {
        updateCartCounter();
    });
    </script>
</body>
</html>
HTML

exit;