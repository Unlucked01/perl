#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
use Encode qw(decode encode);
use DB_File;

# Подключаем модуль для работы с БД
require "./db_utils.pl";
db_utils->import(qw(
    init_database
    get_all_issues
    get_issue_by_id
    get_articles_by_issue_id
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
my $action = $q->param('action') || 'list';
my $id = $q->param('id');

# Получаем данные сессии из cookie
my $session_cookie = $q->cookie('session');
my ($user_id, $user_role) = split(/:/, $session_cookie) if $session_cookie;

# Обработка действий
if ($action eq 'list') {
    show_issues_list();
} elsif ($action eq 'view' && $id) {
    show_issue_details($id);
} else {
    show_issues_list();
}

# Функция для отображения списка выпусков
sub show_issues_list {
    my $year_filter = $q->param('year') || '';
    
    # Получаем все выпуски
    my @issues = get_all_issues();
    
    # Фильтруем по году, если указан
    if ($year_filter) {
        @issues = grep { $_->{year} eq $year_filter } @issues;
    }
    
    # Получаем список уникальных годов для фильтра
    my %years;
    foreach my $issue (@issues) {
        $years{$issue->{year}} = 1;
    }
    my @years = sort { $b <=> $a } keys %years;
    
    binmode(STDOUT, ":utf8");
    print "Content-Type: text/html; charset=utf-8\n\n";
    
    print <<HTML;
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Выпуски журнала - Научный журнал</title>
    <link rel="stylesheet" href="/css/style.css">
    <style>
        .filter-bar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 2rem;
            padding: 1rem;
            background-color: #f5f5f5;
            border-radius: var(--border-radius);
        }
        
        .filter-group {
            display: flex;
            align-items: center;
        }
        
        .filter-label {
            margin-right: 0.5rem;
            font-weight: bold;
        }
        
        .filter-select {
            padding: 0.5rem;
            border: 1px solid #ddd;
            border-radius: var(--border-radius);
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
                <a href="/cgi-bin/issues.pl" class="active">Выпуски</a>
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
            <h1 class="mb-4">Выпуски журнала</h1>
            
            <div class="filter-bar">
                <div class="filter-group">
                    <span class="filter-label">Год:</span>
                    <select class="filter-select" id="year-filter" onchange="applyFilter()">
                        <option value="">Все годы</option>
HTML

    foreach my $year (@years) {
        my $selected = $year_filter eq $year ? 'selected' : '';
        print qq(<option value="$year" $selected>$year</option>);
    }

    print <<HTML;
                    </select>
                </div>
            </div>
            
            <div class="issues-grid">
HTML

    if (@issues) {
        foreach my $issue (@issues) {
            my %month_names = (
                1 => 'Январь',
                2 => 'Февраль',
                3 => 'Март',
                4 => 'Апрель',
                5 => 'Май',
                6 => 'Июнь',
                7 => 'Июль',
                8 => 'Август',
                9 => 'Сентябрь',
                10 => 'Октябрь',
                11 => 'Ноябрь',
                12 => 'Декабрь'
            );
            
            my $month_name = $month_names{$issue->{month}} || '';
            
            print <<HTML;
                <div class="issue-card">
                    <img src="/images/issue-cover-placeholder.jpg" alt="Обложка выпуска" class="issue-cover">
                    <div class="issue-info">
                        <h3 class="issue-title">$issue->{title}</h3>
                        <div class="issue-date">$month_name $issue->{year}</div>
                        <p class="issue-description">$issue->{description}</p>
                        <a href="/cgi-bin/issues.pl?action=view&id=$issue->{id}" class="btn">Подробнее</a>
                    </div>
                </div>
HTML
        }
    } else {
        print "<p>Выпуски не найдены.</p>";
    }

    print <<HTML;
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
    function applyFilter() {
        var yearFilter = document.getElementById('year-filter').value;
        window.location.href = '/cgi-bin/issues.pl?year=' + yearFilter;
    }
    
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
    
    function addToCart(id, title, price) {
        var cart = JSON.parse(localStorage.getItem('cart') || '[]');
        
        // Проверяем, есть ли уже такой товар в корзине
        var existingItem = cart.find(function(item) {
            return item.id === id;
        });
        
        if (existingItem) {
            existingItem.quantity += 1;
        } else {
            cart.push({
                id: id,
                title: title,
                price: price,
                quantity: 1
            });
        }
        
        localStorage.setItem('cart', JSON.stringify(cart));
        updateCartCounter();
        
        alert('Статья добавлена в корзину!');
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

# Функция для отображения деталей выпуска
sub show_issue_details {
    my ($id) = @_;
    
    # Получаем данные выпуска
    my $issue = get_issue_by_id($id);
    unless ($issue) {
        print $q->redirect(-uri => "/cgi-bin/issues.pl?error=Выпуск не найден");
        return;
    }
    
    # Получаем статьи выпуска
    my @articles = get_articles_by_issue_id($id);
    
    # Определяем название месяца
    my %month_names = (
        1 => 'Январь',
        2 => 'Февраль',
        3 => 'Март',
        4 => 'Апрель',
        5 => 'Май',
        6 => 'Июнь',
        7 => 'Июль',
        8 => 'Август',
        9 => 'Сентябрь',
        10 => 'Октябрь',
        11 => 'Ноябрь',
        12 => 'Декабрь'
    );
    
    my $month_name = $month_names{$issue->{month}} || '';
    
    binmode(STDOUT, ":utf8");
    print "Content-Type: text/html; charset=utf-8\n\n";
    
    print <<HTML;
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$issue->{title} - Научный журнал</title>
    <link rel="stylesheet" href="/css/style.css">
    <style>
        .issue-header {
            display: flex;
            margin-bottom: 2rem;
        }
        
        .issue-cover-large {
            width: 250px;
            height: auto;
            margin-right: 2rem;
            border-radius: var(--border-radius);
            box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
        }
        
        .issue-details {
            flex: 1;
        }
        
        .article-list {
            margin-top: 2rem;
        }
        
        .article-item {
            margin-bottom: 1.5rem;
            padding-bottom: 1.5rem;
            border-bottom: 1px solid #eee;
        }
        
        .article-title {
            margin-bottom: 0.5rem;
        }
        
        .article-authors {
            color: #666;
            margin-bottom: 0.5rem;
        }
        
        .article-abstract {
            margin-bottom: 1rem;
        }
        
        .article-actions {
            display: flex;
            gap: 0.5rem;
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
                <a href="/cgi-bin/issues.pl" class="active">Выпуски</a>
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
            <div class="breadcrumbs mb-3">
                <a href="/cgi-bin/issues.pl">Выпуски журнала</a> &gt; 
                Выпуск №$issue->{number}, $issue->{year}
            </div>
            
            <div class="card">
                <div class="issue-header">
                    <img src="/images/issue-cover-placeholder.jpg" alt="Обложка выпуска" class="issue-cover-large">
                    <div class="issue-details">
                        <h1>$issue->{title}</h1>
                        <p><strong>Выпуск №$issue->{number}, $issue->{year}</strong></p>
                        <p><strong>Дата выпуска:</strong> $month_name $issue->{year}</p>
                        <p>$issue->{description}</p>
                    </div>
                </div>
                
                <h2>Статьи выпуска</h2>
                <div class="article-list">
HTML

    if (@articles) {
        foreach my $article (@articles) {
            print <<HTML;
                    <div class="article-item">
                        <h3 class="article-title">$article->{title}</h3>
                        <div class="article-authors">Авторы: $article->{authors}</div>
                        <div class="article-abstract">
                            <strong>Аннотация:</strong> $article->{abstract}
                        </div>
                        <div class="article-actions">
                            <button class="btn" onclick="addToCart('$article->{id}', '$article->{title}', $article->{price})">
                                Добавить в корзину ($article->{price} руб.)
                            </button>
HTML

            # Если пользователь авторизован и имеет доступ к полному тексту
            if ($user_id) {
                print qq(<a href="/cgi-bin/articles.pl?id=$article->{id}" class="btn">Просмотреть статью</a>);
            }

            print <<HTML;
                        </div>
                    </div>
HTML
        }
    } else {
        print "<p>В этом выпуске нет статей.</p>";
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
    
    function addToCart(id, title, price) {
        var cart = JSON.parse(localStorage.getItem('cart') || '[]');
        
        // Проверяем, есть ли уже такой товар в корзине
        var existingItem = cart.find(function(item) {
            return item.id === id;
        });
        
        if (existingItem) {
            existingItem.quantity += 1;
        } else {
            cart.push({
                id: id,
                title: title,
                price: price,
                quantity: 1
            });
        }
        
        localStorage.setItem('cart', JSON.stringify(cart));
        updateCartCounter();
        
        alert('Статья добавлена в корзину!');
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