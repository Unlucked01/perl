#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DB_File;

my $cgi = CGI->new;
print $cgi->header(-type => 'text/html', -charset => 'UTF-8');

# Define paths
my $data_dir = "/usr/local/apache2/data";
my $issues_path = "$data_dir/issues.db";
my $articles_path = "$data_dir/articles.db";

# Check if databases exist, if not, show initialization message
unless (-e $issues_path && -e $articles_path) {
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

# Get issue ID from query parameters
my $issue_id = $cgi->param('id');

# Error if no issue ID provided
unless ($issue_id) {
    show_error("Issue ID не указан");
    exit;
}

# Retrieve issue data from the database
my %issues;
tie %issues, 'DB_File', $issues_path, O_RDONLY, 0644, $DB_HASH 
    or show_error("Cannot open issues database: $!");

# Check if issue exists
unless (exists $issues{$issue_id}) {
    untie %issues;
    show_error("Выпуск не найден");
    exit;
}

# Parse issue data
my ($number, $date, $title, $description, $articles_ids, $price) = split(/:::/, $issues{$issue_id});
untie %issues;

# Get article data
my %articles;
tie %articles, 'DB_File', $articles_path, O_RDONLY, 0644, $DB_HASH 
    or show_error("Cannot open articles database: $!");

my @articles_list = split(/,/, $articles_ids);
my @articles_data;
my %authors_map;

foreach my $article_id (@articles_list) {
    next unless exists $articles{$article_id};
    
    my ($article_title, $authors, $article_date, $status, $abstract) = split(/:::/, $articles{$article_id});
    
    # Skip articles not in "Принята" status
    next unless $status eq "Принята";
    
    push @articles_data, {
        id => $article_id,
        title => $article_title,
        authors => $authors,
        date => $article_date,
        abstract => $abstract
    };
    
    # Collect unique authors
    foreach my $author (split(/,\s*/, $authors)) {
        $authors_map{$author} = 1;
    }
}
untie %articles;

# Get the year from the date
my $issue_year = '';
if ($date =~ /(\d{2})\.(\d{2})\.(\d{4})/) {
    $issue_year = $3;
}

# Generate HTML page
print <<HTML;
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$number | Научный журнал</title>
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
        <nav aria-label="breadcrumb" class="mb-4">
            <ol class="breadcrumb">
                <li class="breadcrumb-item"><a href="/index.html">Главная</a></li>
                <li class="breadcrumb-item"><a href="/cgi-bin/issues.pl">Выпуски</a></li>
                <li class="breadcrumb-item active" aria-current="page">$number</li>
            </ol>
        </nav>
        
        <div class="row mb-4">
            <div class="col-md-4">
                <img src="https://placehold.co/600x800/e5e5e5/636363?text=Выпуск+$issue_id" class="img-fluid rounded" alt="$number">
            </div>
            <div class="col-md-8">
                <h1>$number</h1>
                <p class="lead">$description</p>
                
                <div class="d-flex gap-2 mb-4">
                    <span class="badge bg-primary">$issue_year</span>
                    <span class="badge bg-secondary">@{[scalar @articles_data]} статей</span>
                    <span class="badge bg-info">Опубликован: $date</span>
                </div>
                
                <div class="card mb-4">
                    <div class="card-body">
                        <h5 class="card-title">Информация о выпуске</h5>
                        <table class="table table-striped">
                            <tbody>
                                <tr>
                                    <th scope="row">Дата публикации</th>
                                    <td>$date</td>
                                </tr>
                                <tr>
                                    <th scope="row">Количество страниц</th>
                                    <td>@{[scalar @articles_data * 15 + 10]}</td>
                                </tr>
                                <tr>
                                    <th scope="row">Формат файла</th>
                                    <td>PDF</td>
                                </tr>
                                <tr>
                                    <th scope="row">Размер файла</th>
                                    <td>@{[int(rand(10) + 5)]}.@{[int(rand(9) + 1)]} MB</td>
                                </tr>
                                <tr>
                                    <th scope="row">Главный редактор</th>
                                    <td>Иванов И.И.</td>
                                </tr>
                                <tr>
                                    <th scope="row">ISBN</th>
                                    <td>978-5-6040376-1-@{[int(rand(9) + 1)]}</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
                
                <div class="d-grid mb-3">
                    <button class="btn btn-lg btn-primary" id="addToCartBtn" data-id="$issue_id" data-title="$number" data-price="$price">
                        <i class="bi bi-cart-plus"></i> Добавить в корзину ($price ₽)
                    </button>
                </div>
                <div class="d-flex gap-2">
                    <button class="btn btn-outline-secondary">
                        <i class="bi bi-cloud-download"></i> Оглавление
                    </button>
                    <button class="btn btn-outline-secondary">
                        <i class="bi bi-share"></i> Поделиться
                    </button>
                    <button class="btn btn-outline-secondary">
                        <i class="bi bi-bookmark"></i> В закладки
                    </button>
                </div>
            </div>
        </div>
        
        <div class="row">
            <div class="col-12">
                <div class="card">
                    <div class="card-header">
                        <ul class="nav nav-tabs card-header-tabs" id="issueTab" role="tablist">
                            <li class="nav-item" role="presentation">
                                <button class="nav-link active" id="articles-tab" data-bs-toggle="tab" data-bs-target="#articles" type="button" role="tab" aria-controls="articles" aria-selected="true">Статьи</button>
                            </li>
                            <li class="nav-item" role="presentation">
                                <button class="nav-link" id="authors-tab" data-bs-toggle="tab" data-bs-target="#authors" type="button" role="tab" aria-controls="authors" aria-selected="false">Авторы</button>
                            </li>
                        </ul>
                    </div>
                    <div class="card-body">
                        <div class="tab-content" id="issueTabContent">
                            <div class="tab-pane fade show active" id="articles" role="tabpanel" aria-labelledby="articles-tab">
                                <div class="list-group">
HTML

# Display articles
if (@articles_data) {
    my $page_number = 5;
    foreach my $article (@articles_data) {
        my $article_title = $article->{title};
        my $article_authors = $article->{authors};
        my $article_abstract = $article->{abstract};
        my $end_page = $page_number + int(rand(10) + 5);
        
        print <<ARTICLE;
                                    <a href="#" class="list-group-item list-group-item-action">
                                        <div class="d-flex w-100 justify-content-between">
                                            <h5 class="mb-1">$article_title</h5>
                                            <small>стр. $page_number-$end_page</small>
                                        </div>
                                        <p class="mb-1">$article_abstract</p>
                                        <small class="text-muted">$article_authors</small>
                                    </a>
ARTICLE
        $page_number = $end_page + 1;
    }
} else {
    print <<NO_ARTICLES;
                                    <div class="alert alert-info">
                                        <h4 class="alert-heading">Статьи не найдены</h4>
                                        <p>В данном выпуске нет доступных статей.</p>
                                    </div>
NO_ARTICLES
}

print <<HTML;
                                </div>
                            </div>
                            <div class="tab-pane fade" id="authors" role="tabpanel" aria-labelledby="authors-tab">
                                <div class="row row-cols-1 row-cols-md-2 g-4">
HTML

# Display authors
if (keys %authors_map) {
    my @academic_titles = (
        'Доктор технических наук', 
        'Кандидат технических наук', 
        'Доктор медицинских наук', 
        'Кандидат физико-математических наук', 
        'Доктор философских наук', 
        'Профессор'
    );
    
    my @author_descriptions = (
        'Профессор кафедры компьютерных наук, специалист в области машинного обучения.',
        'Ведущий исследователь в области глубоких нейронных сетей и компьютерного зрения.',
        'Специалист в области медицинской диагностики и анализа изображений.',
        'Эксперт в области этики искусственного интеллекта и социальных последствий технологического развития.',
        'Профессор университета, автор многочисленных научных публикаций.',
        'Ведущий специалист в своей области, руководитель исследовательской группы.',
        'Молодой ученый, активно развивающий инновационные подходы в своей области.'
    );
    
    foreach my $author (sort keys %authors_map) {
        my $title = $academic_titles[int(rand(scalar @academic_titles))];
        my $description = $author_descriptions[int(rand(scalar @author_descriptions))];
        
        print <<AUTHOR;
                                    <div class="col">
                                        <div class="card h-100">
                                            <div class="card-body">
                                                <h5 class="card-title">$author</h5>
                                                <h6 class="card-subtitle mb-2 text-muted">$title</h6>
                                                <p class="card-text">$description</p>
                                                <a href="#" class="card-link">Профиль</a>
                                                <a href="#" class="card-link">Публикации</a>
                                            </div>
                                        </div>
                                    </div>
AUTHOR
    }
} else {
    print <<NO_AUTHORS;
                                    <div class="col-12">
                                        <div class="alert alert-info">
                                            <h4 class="alert-heading">Информация об авторах отсутствует</h4>
                                            <p>К сожалению, информация об авторах данного выпуска недоступна.</p>
                                        </div>
                                    </div>
NO_AUTHORS
}

print <<HTML;
                                </div>
                            </div>
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
        document.addEventListener('DOMContentLoaded', function() {
            // Get the "Add to Cart" button
            const addToCartBtn = document.getElementById('addToCartBtn');
            
            if (addToCartBtn) {
                addToCartBtn.addEventListener('click', function() {
                    // Get issue info from button data attributes
                    const issueId = this.getAttribute('data-id');
                    const title = this.getAttribute('data-title');
                    
                    // Add to cart (using function from main.js)
                    addToCart(issueId, title, 'https://placehold.co/600x800/e5e5e5/636363?text=Выпуск+' + issueId);
                    showNotification(`"\${title}" добавлен в корзину`);
                });
            }
        });
    </script>
</body>
</html>
HTML

# Function to show error message
sub show_error {
    my $message = shift;
    
    print <<HTML;
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Ошибка | Научный журнал</title>
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
        <div class="alert alert-danger">
            <h4 class="alert-heading">Ошибка!</h4>
            <p>$message</p>
            <hr>
            <p class="mb-0">Пожалуйста, вернитесь на <a href="/index.html" class="alert-link">главную страницу</a> или перейдите к <a href="/cgi-bin/issues.pl" class="alert-link">списку выпусков</a>.</p>
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
} 