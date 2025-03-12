#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
use Encode qw(decode encode);
use POSIX qw(strftime);

# Подключаем модуль для работы с БД
require "./db_utils.pl";
db_utils->import(qw(
    init_database
    get_all_users
    get_all_issues
    get_all_articles
    get_all_orders
    get_user_by_id
    get_issue_by_id
    get_article_by_id
    get_order_by_id
    get_order_details
    create_issue
    update_issue
    delete_issue
    create_article
    update_article
    delete_article
    update_order_status
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
my $action = $q->param('action') || 'dashboard';

# Получаем данные сессии из cookie
my $session_cookie = $q->cookie('session');
my ($user_id, $user_role) = split(/:/, $session_cookie) if $session_cookie;

# Проверяем, авторизован ли пользователь и имеет ли права администратора
unless ($user_id && ($user_role eq 'admin' || $user_role eq 'editor')) {
    print $q->redirect(-uri => "/cgi-bin/auth.pl?error=У вас нет прав для доступа к этой странице");
    exit;
}

# Обработка действий
if ($action eq 'dashboard') {
    show_dashboard();
} elsif ($action eq 'users') {
    show_users();
} elsif ($action eq 'issues') {
    show_issues();
} elsif ($action eq 'articles') {
    show_articles();
} elsif ($action eq 'orders') {
    show_orders();
} elsif ($action eq 'stats') {
    show_stats();
} elsif ($action eq 'edit_issue') {
    edit_issue();
} elsif ($action eq 'save_issue') {
    save_issue();
} elsif ($action eq 'delete_issue') {
    delete_issue_action();
} elsif ($action eq 'edit_article') {
    edit_article();
} elsif ($action eq 'save_article') {
    save_article();
} elsif ($action eq 'delete_article') {
    delete_article_action();
} elsif ($action eq 'edit_order') {
    edit_order();
} elsif ($action eq 'save_order') {
    save_order();
} else {
    show_dashboard();
}

# Функция для отображения панели управления
sub show_dashboard {
    my $error = $q->param('error') || '';
    my $success = $q->param('success') || '';
    
    # Получаем статистику
    my @users = get_all_users();
    my @issues = get_all_issues();
    my @articles = get_all_articles();
    my @orders = get_all_orders();
    
    # Считаем количество заказов по статусам
    my %order_stats;
    foreach my $order (@orders) {
        $order_stats{$order->{status}}++;
    }
    
    # Считаем общую сумму продаж
    my $total_sales = 0;
    foreach my $order (@orders) {
        $total_sales += $order->{total} if $order->{status} eq 'completed';
    }
    
    binmode(STDOUT, ":utf8");
    print "Content-Type: text/html; charset=utf-8\n\n";
    
    print <<HTML;
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Панель администратора - Научный журнал</title>
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
        
        .admin-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 2rem;
        }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
            gap: 1.5rem;
            margin-bottom: 2rem;
        }
        
        .stat-card {
            background-color: white;
            border-radius: var(--border-radius);
            padding: 1.5rem;
            box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
            text-align: center;
        }
        
        .stat-value {
            font-size: 2.5rem;
            font-weight: bold;
            margin-bottom: 0.5rem;
            color: var(--primary-color);
        }
        
        .stat-label {
            color: #666;
            font-size: 1rem;
        }
        
        .recent-section {
            margin-bottom: 2rem;
        }
        
        .recent-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 1rem;
        }
        
        .recent-list {
            background-color: white;
            border-radius: var(--border-radius);
            box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
            overflow: hidden;
        }
        
        .recent-item {
            padding: 1rem;
            border-bottom: 1px solid #eee;
        }
        
        .recent-item:last-child {
            border-bottom: none;
        }
        
        .admin-nav {
            display: flex;
            background-color: var(--primary-color);
            border-radius: var(--border-radius);
            overflow: hidden;
            margin-bottom: 2rem;
        }
        
        .admin-nav a {
            color: white;
            padding: 1rem 1.5rem;
            text-decoration: none;
            transition: background-color 0.3s;
        }
        
        .admin-nav a:hover {
            background-color: rgba(255, 255, 255, 0.1);
        }
        
        .admin-nav a.active {
            background-color: var(--secondary-color);
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
                <a href="/cgi-bin/auth.pl?action=profile">Личный кабинет</a>
            </nav>
        </div>
    </header>
    
    <main class="main">
        <div class="container">
            <div class="admin-header">
                <h1>Панель администратора</h1>
                <a href="/cgi-bin/auth.pl?action=profile" class="btn">Вернуться в профиль</a>
            </div>
            
HTML

    if ($error) {
        print "<div class='alert alert-error'>$error</div>";
    }
    
    if ($success) {
        print "<div class='alert alert-success'>$success</div>";
    }

    print <<HTML;
            <div class="admin-nav">
                <a href="/cgi-bin/admin.pl?action=dashboard" class="active">Обзор</a>
                <a href="/cgi-bin/admin.pl?action=users">Пользователи</a>
                <a href="/cgi-bin/admin.pl?action=issues">Выпуски</a>
                <a href="/cgi-bin/admin.pl?action=articles">Статьи</a>
                <a href="/cgi-bin/admin.pl?action=orders">Заказы</a>
                <a href="/cgi-bin/admin.pl?action=stats">Статистика</a>
            </div>
            
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-value">@{[scalar @users]}</div>
                    <div class="stat-label">Пользователей</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value">@{[scalar @issues]}</div>
                    <div class="stat-label">Выпусков</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value">@{[scalar @articles]}</div>
                    <div class="stat-label">Статей</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value">@{[scalar @orders]}</div>
                    <div class="stat-label">Заказов</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value">$total_sales</div>
                    <div class="stat-label">Продажи (руб.)</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value">@{[$order_stats{completed} || 0]}</div>
                    <div class="stat-label">Выполненных заказов</div>
                </div>
            </div>
            
            <div class="row">
                <div class="col-md-6">
                    <div class="recent-section">
                        <div class="recent-header">
                            <h2>Последние заказы</h2>
                            <a href="/cgi-bin/admin.pl?action=orders" class="btn">Все заказы</a>
                        </div>
                        <div class="recent-list">
HTML

    # Выводим последние 5 заказов
    my @recent_orders = sort { $b->{date} cmp $a->{date} } @orders;
    @recent_orders = @recent_orders[0..4] if @recent_orders > 5;
    
    if (@recent_orders) {
        foreach my $order (@recent_orders) {
            my $user = get_user_by_id($order->{user_id});
            my $status_class = $order->{status} eq 'completed' ? 'text-success' : 
                              ($order->{status} eq 'cancelled' ? 'text-danger' : 'text-warning');
            
            print <<HTML;
                            <div class="recent-item">
                                <div><strong>Заказ #$order->{id}</strong> от $order->{date}</div>
                                <div>Покупатель: $user->{fullname}</div>
                                <div>Сумма: $order->{total} руб.</div>
                                <div>Статус: <span class="$status_class">$order->{status}</span></div>
                                <div><a href="/cgi-bin/admin.pl?action=edit_order&id=$order->{id}">Подробнее</a></div>
                            </div>
HTML
        }
    } else {
        print "<div class='recent-item'>Нет заказов</div>";
    }

    print <<HTML;
                        </div>
                    </div>
                </div>
                
                <div class="col-md-6">
                    <div class="recent-section">
                        <div class="recent-header">
                            <h2>Последние статьи</h2>
                            <a href="/cgi-bin/admin.pl?action=articles" class="btn">Все статьи</a>
                        </div>
                        <div class="recent-list">
HTML

    # Выводим последние 5 статей
    my @recent_articles = sort { $b->{publication_date} cmp $a->{publication_date} } @articles;
    @recent_articles = @recent_articles[0..4] if @recent_articles > 5;
    
    if (@recent_articles) {
        foreach my $article (@recent_articles) {
            my $issue = get_issue_by_id($article->{issue_id});
            
            print <<HTML;
                            <div class="recent-item">
                                <div><strong>$article->{title}</strong></div>
                                <div>Авторы: $article->{authors}</div>
                                <div>Выпуск: №$issue->{number}, $issue->{year}</div>
                                <div><a href="/cgi-bin/admin.pl?action=edit_article&id=$article->{id}">Редактировать</a></div>
                            </div>
HTML
        }
    } else {
        print "<div class='recent-item'>Нет статей</div>";
    }

    print <<HTML;
                        </div>
                    </div>
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
                <p><a href="/cgi-bin/auth.pl?action=profile">Личный кабинет</a></p>
            </div>
        </div>
        <div class="container text-center mt-3">
            <p>&copy; 2025 Научный журнал. Все права защищены.</p>
        </div>
    </footer>
    
    <script src="/js/main.js"></script>
</body>
</html>
HTML
} 