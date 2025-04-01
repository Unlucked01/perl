#!/usr/bin/perl
use strict;
use warnings;
use CGI qw/:standard/;
use CGI::Carp qw(fatalsToBrowser);
use DB_File;
use Fcntl qw(:DEFAULT :flock);

my $cgi = CGI->new;
print $cgi->header(-type => 'text/html', -charset => 'UTF-8');

# Define data paths
my $data_dir = "/usr/local/apache2/data";
my $issues_path = "$data_dir/issues.db";

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
                    </ul>
                    <div class="d-flex">
                        <a href="/cgi-bin/cart.pl" class="btn btn-outline-light me-2">
                            <i class="bi bi-cart"></i> Корзина
                        </a>
                        <a href="/cgi-bin/login.pl" class="btn btn-outline-light">Войти</a>
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
        // Get existing cart from localStorage or create new one
        let cart = JSON.parse(localStorage.getItem('cart') || '[]');
        
        // Add item to cart
        cart.push({type: 'issue', id: issueId});
        
        // Save updated cart
        localStorage.setItem('cart', JSON.stringify(cart));
        
        // Notify user
        alert('Выпуск добавлен в корзину');
    }
    </script>
</body>
</html>
HTML

exit;