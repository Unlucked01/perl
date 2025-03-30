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

# Check if database exists, if not, show initialization message
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

# Get sorting and filtering parameters
my $sort_by = $cgi->param('sort') || 'date_desc';
my $filter_year = $cgi->param('year') || 'all';
my $search_query = $cgi->param('query') || '';

# Retrieve issues from the database
my %issues;
tie %issues, 'DB_File', $issues_path, O_RDONLY, 0644, $DB_HASH 
    or die "Cannot open issues database: $!";

# Process issues data
my @issues_data;
foreach my $issue_id (keys %issues) {
    my ($number, $date, $title, $description, $articles, $price) = split(/:::/, $issues{$issue_id});
    my $year = '';
    if ($date =~ /(\d{2})\.(\d{2})\.(\d{4})/) {
        $year = $3;
    }
    
    # Filter by year if specified
    next if ($filter_year ne 'all' && $year ne $filter_year);
    
    # Filter by search query if specified
    if ($search_query) {
        my $query_lower = lc($search_query);
        my $title_lower = lc($title);
        my $description_lower = lc($description);
        next unless ($title_lower =~ /$query_lower/ || $description_lower =~ /$query_lower/);
    }
    
    push @issues_data, {
        id => $issue_id,
        number => $number,
        date => $date,
        title => $title,
        description => $description,
        articles => $articles,
        price => $price,
        year => $year
    };
}
untie %issues;

# Sort issues
if ($sort_by eq 'date_desc') {
    @issues_data = sort { $b->{date} cmp $a->{date} } @issues_data;
} elsif ($sort_by eq 'date_asc') {
    @issues_data = sort { $a->{date} cmp $b->{date} } @issues_data;
} elsif ($sort_by eq 'title_asc') {
    @issues_data = sort { $a->{title} cmp $b->{title} } @issues_data;
} elsif ($sort_by eq 'title_desc') {
    @issues_data = sort { $b->{title} cmp $a->{title} } @issues_data;
}

# Get unique years for filtering
my %years;
foreach my $issue (@issues_data) {
    $years{$issue->{year}} = 1 if $issue->{year};
}
my @unique_years = sort { $b <=> $a } keys %years;

# Generate HTML page
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
                            <a class="nav-link active" href="/cgi-bin/issues.pl">Выпуски</a>
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
        <div class="row mb-4">
            <div class="col-12">
                <h1 class="display-5 mb-3">Выпуски журнала</h1>
                <div class="card p-3">
                    <div class="row mb-3">
                        <div class="col-md-6">
                            <form class="search-form" method="get" action="/cgi-bin/issues.pl">
                                <div class="input-group">
                                    <input type="text" class="form-control" placeholder="Поиск по выпускам..." name="query" value="$search_query" aria-label="Поиск">
                                    <button class="btn btn-outline-primary" type="submit">
                                        <i class="bi bi-search"></i>
                                    </button>
                                </div>
                            </form>
                        </div>
                        <div class="col-md-6">
                            <div class="d-flex justify-content-md-end mt-3 mt-md-0">
                                <div class="btn-group">
                                    <button type="button" class="btn btn-outline-secondary dropdown-toggle" data-bs-toggle="dropdown" aria-expanded="false">
                                        Сортировка
                                    </button>
                                    <ul class="dropdown-menu">
                                        <li><a class="dropdown-item" href="/cgi-bin/issues.pl?sort=date_desc">По дате (сначала новые)</a></li>
                                        <li><a class="dropdown-item" href="/cgi-bin/issues.pl?sort=date_asc">По дате (сначала старые)</a></li>
                                        <li><a class="dropdown-item" href="/cgi-bin/issues.pl?sort=title_asc">По названию (А-Я)</a></li>
                                        <li><a class="dropdown-item" href="/cgi-bin/issues.pl?sort=title_desc">По названию (Я-А)</a></li>
                                    </ul>
                                </div>
                                <div class="btn-group ms-2">
                                    <button type="button" class="btn btn-outline-secondary dropdown-toggle" data-bs-toggle="dropdown" aria-expanded="false">
                                        Год
                                    </button>
                                    <ul class="dropdown-menu">
                                        <li><a class="dropdown-item" href="/cgi-bin/issues.pl?year=all">Все годы</a></li>
HTML

# Add years to the dropdown
foreach my $year (@unique_years) {
    print qq(<li><a class="dropdown-item" href="/cgi-bin/issues.pl?year=$year">$year</a></li>\n);
}

print <<HTML;
                                    </ul>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="row">
            <!-- List of issues -->
            <div class="col-12">
                <div class="row">
HTML

# Display issues
if (@issues_data) {
    foreach my $issue (@issues_data) {
        my $issue_number = $issue->{number};
        my $issue_date = $issue->{date};
        my $issue_title = $issue->{title};
        my $issue_description = $issue->{description};
        my $issue_year = $issue->{year} || 'Н/Д';
        my $issue_id = $issue->{id};
        my $issue_price = $issue->{price};
        my @articles = split(',', $issue->{articles});
        my $articles_count = scalar @articles;
        
        print <<ISSUE;
                    <div class="col-md-4 mb-4">
                        <div class="card h-100">
                            <img src="https://placehold.co/600x400/e5e5e5/636363?text=Выпуск+$issue_id" class="card-img-top" alt="$issue_title">
                            <div class="card-body">
                                <span class="badge bg-primary mb-2">$issue_year</span>
                                <h5 class="card-title">$issue_number</h5>
                                <p class="card-text">$issue_description</p>
                                <div class="d-flex justify-content-between align-items-center">
                                    <small class="text-muted">$articles_count статей</small>
                                    <small class="text-muted">Опубликован: $issue_date</small>
                                </div>
                            </div>
                            <div class="card-footer d-flex justify-content-between bg-white border-top-0">
                                <a href="/cgi-bin/issue.pl?id=$issue_id" class="btn btn-sm btn-outline-primary">Подробнее</a>
                                <button class="btn btn-sm btn-primary add-to-cart-btn" data-id="$issue_id" data-title="$issue_number" data-price="$issue_price">В корзину</button>
                            </div>
                        </div>
                    </div>
ISSUE
    }
} else {
    print <<NORESULTS;
                    <div class="col-12">
                        <div class="alert alert-info">
                            <h4 class="alert-heading">Выпуски не найдены</h4>
                            <p>По вашему запросу не найдено выпусков журнала. Попробуйте изменить параметры поиска.</p>
                        </div>
                    </div>
NORESULTS
}

print <<HTML;
                </div>
                
                <!-- Pagination -->
                <nav aria-label="Навигация по страницам" class="mt-4">
                    <ul class="pagination justify-content-center">
                        <li class="page-item disabled">
                            <a class="page-link" href="#" tabindex="-1" aria-disabled="true">Предыдущая</a>
                        </li>
                        <li class="page-item active"><a class="page-link" href="#">1</a></li>
                        <li class="page-item"><a class="page-link" href="#">2</a></li>
                        <li class="page-item"><a class="page-link" href="#">3</a></li>
                        <li class="page-item">
                            <a class="page-link" href="#">Следующая</a>
                        </li>
                    </ul>
                </nav>
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
            // Add to cart buttons
            const addToCartButtons = document.querySelectorAll('.add-to-cart-btn');
            
            addToCartButtons.forEach(button => {
                button.addEventListener('click', function() {
                    const issueId = this.getAttribute('data-id');
                    const title = this.getAttribute('data-title');
                    const price = this.getAttribute('data-price');
                    
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