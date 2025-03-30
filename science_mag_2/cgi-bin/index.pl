#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DB_File;

my $cgi = CGI->new;
print $cgi->header(-type => 'text/html', -charset => 'UTF-8');

my $data_dir = "/usr/local/apache2/data";
my $issues_path = "$data_dir/issues.db";

# Check if database exists, if not, create empty database or show initialization message
unless (-e $issues_path) {
    print <<HTML;
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>База данных отсутствует | Научный журнал</title>
    <link href="/css/bootstrap.min.css" rel="stylesheet">
    <link href="/css/bootstrap-icons.css" rel="stylesheet">
    <link href="/css/styles.css" rel="stylesheet">
</head>
<body>
    <div class="container my-5">
        <div class="alert alert-warning">
            <h4 class="alert-heading">База данных не инициализирована!</h4>
            <p>Для корректной работы сайта необходимо инициализировать базу данных.</p>
            <hr>
            <p>Запустите скрипт инициализации базы данных, выполнив следующую команду:</p>
            <pre>perl /usr/local/apache2/cgi-bin/init_db.pl</pre>
        </div>
    </div>
</body>
</html>
HTML
    exit;
}

# Retrieve issues from the database
my %issues;
tie %issues, 'DB_File', $issues_path, O_RDONLY, 0644, $DB_HASH 
    or die "Cannot open issues database: $!";

# Process issues data
my @issues_data;
foreach my $issue_id (keys %issues) {
    my ($number, $date, $title, $description, $articles, $price) = split(/:::/, $issues{$issue_id});
    
    push @issues_data, {
        id => $issue_id,
        number => $number,
        date => $date,
        title => $title,
        description => $description,
        articles => $articles,
        price => $price
    };
}
untie %issues;

# Sort issues by date (newest first) and get the latest 3
@issues_data = sort { $b->{date} cmp $a->{date} } @issues_data;
@issues_data = @issues_data[0..2] if scalar(@issues_data) > 3;

# Generate HTML page
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
                <a class="navbar-brand" href="/cgi-bin/index.pl">Научный журнал</a>
                <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav" aria-controls="navbarNav" aria-expanded="false" aria-label="Toggle navigation">
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
                        <a href="/cart.html" class="btn btn-outline-light me-2">
                            <i class="bi bi-cart"></i> Корзина
                        </a>
                        <a href="/cgi-bin/login.pl" class="btn btn-outline-light">Войти</a>
                    </div>
                </div>
            </div>
        </nav>
    </header>

    <main class="container my-4">
        <section class="row mb-4">
            <div class="col-md-8">
                <div class="p-4 p-md-5 mb-4 text-bg-dark rounded">
                    <div class="col-md-8 px-0">
                        <h1 class="display-4">Добро пожаловать в Научный журнал</h1>
                        <p class="lead my-3">Научный журнал предлагает передовые исследования и публикации в различных областях науки.</p>
                        <p class="lead mb-0"><a href="/cgi-bin/issues.pl" class="text-white fw-bold">Смотреть последние выпуски...</a></p>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="card mb-4">
                    <div class="card-header">
                        <h5>Новости</h5>
                    </div>
                    <div class="card-body">
                        <h5 class="card-title">Открыт прием статей для нового выпуска</h5>
                        <p class="card-text">Редакционная коллегия принимает статьи для публикации в новом выпуске журнала.</p>
                        <a href="#" class="btn btn-primary">Подробнее</a>
                    </div>
                </div>
            </div>
        </section>

        <section class="row mb-4">
            <h2 class="mb-3">Последние выпуски</h2>
HTML

# Display latest issues
if (@issues_data) {
    foreach my $issue (@issues_data) {
        my $issue_id = $issue->{id};
        my $issue_number = $issue->{number};
        my $issue_description = $issue->{description};
        
        print <<ISSUE;
            <div class="col-md-4 mb-3">
                <div class="card h-100">
                    <img src="https://placehold.co/600x400/e5e5e5/636363?text=Выпуск+$issue_id" class="card-img-top" alt="$issue_number">
                    <div class="card-body">
                        <h5 class="card-title">$issue_number</h5>
                        <p class="card-text">$issue_description</p>
                    </div>
                    <div class="card-footer">
                        <a href="/cgi-bin/issue.pl?id=$issue_id" class="btn btn-sm btn-outline-primary">Подробнее</a>
                        <button class="btn btn-sm btn-primary add-to-cart-btn" data-id="$issue_id" data-title="$issue_number">В корзину</button>
                    </div>
                </div>
            </div>
ISSUE
    }
} else {
    print <<NO_ISSUES;
            <div class="col-12">
                <div class="alert alert-info">
                    <p>В настоящее время нет доступных выпусков. Пожалуйста, проверьте позже.</p>
                </div>
            </div>
NO_ISSUES
}

print <<HTML;
        </section>
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
            // Add to cart buttons
            const addToCartButtons = document.querySelectorAll('.add-to-cart-btn');
            
            addToCartButtons.forEach(button => {
                button.addEventListener('click', function() {
                    const issueId = this.getAttribute('data-id');
                    const title = this.getAttribute('data-title');
                    
                    // Add to cart (using function from main.js)
                    addToCart(issueId, title, 'https://placehold.co/600x400/e5e5e5/636363?text=Выпуск+' + issueId);
                    showNotification(`"\${title}" добавлен в корзину`);
                });
            });
        });
    </script>
</body>
</html>
HTML