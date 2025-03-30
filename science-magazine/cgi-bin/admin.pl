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
    get_all_submissions
    get_submission_by_id
    update_submission_status
    get_articles_by_issue_id
    edit_user
    edit_article
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
    display_edit_article_form();
} elsif ($action eq 'save_article') {
    save_article();
} elsif ($action eq 'delete_article') {
    delete_article_action();
} elsif ($action eq 'edit_order') {
    edit_order();
} elsif ($action eq 'save_order') {
    save_order();
} elsif ($action eq 'submissions') {
    show_submissions();
} elsif ($action eq 'view_submission') {
    view_submission();
} elsif ($action eq 'edit_submission_status') {
    edit_submission_status();
} elsif ($action eq 'publish_submission') {
    publish_submission();
} elsif ($action eq 'edit_user') {
    display_edit_user_form();
} elsif ($action eq 'save_user') {
    save_user();
} elsif ($action eq 'edit_user_action') {
    edit_user_action();
} elsif ($action eq 'edit_article') {
    edit_article();
} elsif ($action eq 'edit_article_action') {
    edit_article_action();
} elsif ($action eq 'delete_article') {
    delete_article_action();
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
                <a href="/cgi-bin/admin.pl?action=submissions">Рукописи</a>
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

sub show_submissions {
    my $q = shift || CGI->new;
    
    print $q->header(-charset=>'utf-8');
    print $q->start_html(-title=>'Управление рукописями', -encoding=>'utf-8');
    print "<h1>Управление рукописями</h1>";
    
    # Получаем все поданные рукописи из БД
    my @submissions = get_all_submissions();
    
    # Фильтр по статусу
    my $status_filter = $q->param('status') || 'all';
    my @filtered_submissions = $status_filter eq 'all' ? 
        @submissions : 
        grep { $_->{status} eq $status_filter } @submissions;
    
    # Навигация по статусам
    print "<div style='margin-bottom: 20px;'>";
    print "<a href='?action=submissions&status=all' class='btn " . ($status_filter eq 'all' ? 'active' : '') . "'>Все</a> ";
    print "<a href='?action=submissions&status=new' class='btn " . ($status_filter eq 'new' ? 'active' : '') . "'>Новые</a> ";
    print "<a href='?action=submissions&status=reviewing' class='btn " . ($status_filter eq 'reviewing' ? 'active' : '') . "'>На рецензии</a> ";
    print "<a href='?action=submissions&status=accepted' class='btn " . ($status_filter eq 'accepted' ? 'active' : '') . "'>Принятые</a> ";
    print "<a href='?action=submissions&status=rejected' class='btn " . ($status_filter eq 'rejected' ? 'active' : '') . "'>Отклоненные</a> ";
    print "</div>";
    
    if (@filtered_submissions) {
        print "<table border='1' style='width: 100%; border-collapse: collapse;'>";
        print "<tr><th>ID</th><th>Название</th><th>Автор</th><th>Дата подачи</th><th>Статус</th><th>Действия</th></tr>";
        
        foreach my $submission (sort { $b->{submission_date} cmp $a->{submission_date} } @filtered_submissions) {
            my $user = get_user_by_id($submission->{user_id});
            my $author_name = $user ? $user->{full_name} : "Неизвестный автор";
            
            # Определяем цвет статуса
            my $status_color = 
                $submission->{status} eq 'new' ? 'blue' :
                $submission->{status} eq 'reviewing' ? 'orange' :
                $submission->{status} eq 'accepted' ? 'green' :
                $submission->{status} eq 'rejected' ? 'red' : 'black';
            
            print "<tr>";
            print "<td>$submission->{id}</td>";
            print "<td>$submission->{title}</td>";
            print "<td>$author_name</td>";
            print "<td>$submission->{submission_date}</td>";
            print "<td style='color: $status_color;'>$submission->{status}</td>";
            print "<td>";
            print "<a href='?action=view_submission&id=$submission->{id}'>Просмотр</a> | ";
            print "<a href='?action=edit_submission_status&id=$submission->{id}'>Изменить статус</a>";
            if ($submission->{status} eq 'accepted') {
                print " | <a href='?action=publish_submission&id=$submission->{id}'>Опубликовать</a>";
            }
            print "</td>";
            print "</tr>";
        }
        
        print "</table>";
    } else {
        print "<p>Нет рукописей с выбранным статусом.</p>";
    }
    
    print "<p><a href='?' class='btn'>Вернуться в панель администратора</a></p>";
    
    print $q->end_html;
}

sub view_submission {
    my $q = shift || CGI->new;
    my $submission_id = $q->param('id');
    
    my $submission = get_submission_by_id($submission_id);
    unless ($submission) {
        print $q->redirect(-uri => "/cgi-bin/admin.pl?action=submissions&error=Рукопись не найдена");
        return;
    }
    
    my $user = get_user_by_id($submission->{user_id});
    
    print $q->header(-charset=>'utf-8');
    print $q->start_html(-title=>"Просмотр рукописи #$submission_id", -encoding=>'utf-8');
    
    print "<h1>Просмотр рукописи #$submission_id</h1>";
    
    print "<div style='background: #f5f5f5; padding: 20px; border-radius: 5px; margin-bottom: 20px;'>";
    print "<h2>$submission->{title}</h2>";
    
    print "<p><strong>Автор:</strong> " . ($user ? $user->{full_name} : "Неизвестный автор") . "</p>";
    print "<p><strong>Email:</strong> " . ($user ? $user->{email} : "Нет данных") . "</p>";
    print "<p><strong>Дата подачи:</strong> $submission->{submission_date}</p>";
    print "<p><strong>Статус:</strong> $submission->{status}</p>";
    
    print "<h3>Аннотация</h3>";
    print "<div style='background: white; padding: 15px; border-radius: 5px;'>";
    print "<p>$submission->{abstract}</p>";
    print "</div>";
    
    print "<h3>Полный текст</h3>";
    print "<div style='background: white; padding: 15px; border-radius: 5px; max-height: 400px; overflow-y: auto;'>";
    print "<pre style='white-space: pre-wrap;'>$submission->{content}</pre>";
    print "</div>";
    
    print "<h3>Комментарии автора</h3>";
    print "<div style='background: white; padding: 15px; border-radius: 5px;'>";
    print "<p>" . ($submission->{author_comments} || "Нет комментариев") . "</p>";
    print "</div>";
    
    if ($submission->{reviewer_comments}) {
        print "<h3>Комментарии рецензента</h3>";
        print "<div style='background: white; padding: 15px; border-radius: 5px;'>";
        print "<p>$submission->{reviewer_comments}</p>";
        print "</div>";
    }
    
    print "</div>";
    
    print "<div style='display: flex; gap: 10px;'>";
    print "<a href='?action=edit_submission_status&id=$submission_id' class='btn'>Изменить статус</a>";
    
    if ($submission->{status} eq 'accepted') {
        print "<a href='?action=publish_submission&id=$submission_id' class='btn'>Опубликовать</a>";
    }
    
    print "<a href='?action=submissions' class='btn'>Назад к списку</a>";
    print "</div>";
    
    print $q->end_html;
}

sub edit_submission_status {
    my $q = shift || CGI->new;
    my $submission_id = $q->param('id');
    
    my $submission = get_submission_by_id($submission_id);
    unless ($submission) {
        print $q->redirect(-uri => "/cgi-bin/admin.pl?action=submissions&error=Рукопись не найдена");
        return;
    }
    
    if ($q->param('save')) {
        my $new_status = $q->param('status');
        my $reviewer_comments = $q->param('reviewer_comments');
        
        # Обновляем статус рукописи
        update_submission_status($submission_id, $new_status, $reviewer_comments);
        
        print $q->redirect(-uri => "/cgi-bin/admin.pl?action=submissions&success=Статус рукописи успешно обновлен");
        return;
    }
    
    print $q->header(-charset=>'utf-8');
    print $q->start_html(-title=>"Изменение статуса рукописи #$submission_id", -encoding=>'utf-8');
    
    print "<h1>Изменение статуса рукописи #$submission_id</h1>";
    
    print "<form method='post' action='?action=edit_submission_status&id=$submission_id'>";
    print "<input type='hidden' name='save' value='1'>";
    
    print "<div style='margin-bottom: 20px;'>";
    print "<label for='status'><strong>Статус:</strong></label><br>";
    print "<select id='status' name='status' style='padding: 8px; width: 100%; max-width: 300px;'>";
    print "<option value='new'" . ($submission->{status} eq 'new' ? " selected" : "") . ">Новая</option>";
    print "<option value='reviewing'" . ($submission->{status} eq 'reviewing' ? " selected" : "") . ">На рецензии</option>";
    print "<option value='accepted'" . ($submission->{status} eq 'accepted' ? " selected" : "") . ">Принята</option>";
    print "<option value='rejected'" . ($submission->{status} eq 'rejected' ? " selected" : "") . ">Отклонена</option>";
    print "</select>";
    print "</div>";
    
    print "<div style='margin-bottom: 20px;'>";
    print "<label for='reviewer_comments'><strong>Комментарии рецензента:</strong></label><br>";
    print "<textarea id='reviewer_comments' name='reviewer_comments' style='padding: 8px; width: 100%; height: 200px;'>" . 
          ($submission->{reviewer_comments} || "") . "</textarea>";
    print "</div>";
    
    print "<div style='display: flex; gap: 10px;'>";
    print "<button type='submit' class='btn'>Сохранить</button>";
    print "<a href='?action=view_submission&id=$submission_id' class='btn'>Отмена</a>";
    print "</div>";
    
    print "</form>";
    
    print $q->end_html;
}

sub publish_submission {
    my $q = shift || CGI->new;
    my $submission_id = $q->param('id');
    
    my $submission = get_submission_by_id($submission_id);
    unless ($submission && $submission->{status} eq 'accepted') {
        print $q->redirect(-uri => "/cgi-bin/admin.pl?action=submissions&error=Рукопись не найдена или не может быть опубликована");
        return;
    }
    
    if ($q->param('save')) {
        my $issue_id = $q->param('issue_id');
        my $price = $q->param('price');
        
        # Создаем новую статью на основе рукописи
        my $article_id = create_article(
            $issue_id,
            $submission->{title},
            $submission->{authors},
            $submission->{abstract},
            $submission->{content},
            $price,
            'published',
            strftime("%Y-%m-%d", localtime)
        );
        
        # Обновляем статус рукописи на 'published'
        update_submission_status($submission_id, 'published', "Опубликована как статья #$article_id");
        
        print $q->redirect(-uri => "/cgi-bin/admin.pl?action=articles&success=Рукопись успешно опубликована как статья");
        return;
    }
    
    # Получаем список выпусков для выбора
    my @issues = get_all_issues();
    
    print $q->header(-charset=>'utf-8');
    print $q->start_html(-title=>"Публикация рукописи #$submission_id", -encoding=>'utf-8');
    
    print "<h1>Публикация рукописи #$submission_id</h1>";
    
    print "<form method='post' action='?action=publish_submission&id=$submission_id'>";
    print "<input type='hidden' name='save' value='1'>";
    
    print "<div style='margin-bottom: 20px;'>";
    print "<label for='issue_id'><strong>Выберите выпуск для публикации:</strong></label><br>";
    print "<select id='issue_id' name='issue_id' style='padding: 8px; width: 100%; max-width: 400px;' required>";
    print "<option value=''>-- Выберите выпуск --</option>";
    
    foreach my $issue (sort { $b->{year} <=> $a->{year} || $b->{number} <=> $a->{number} } @issues) {
        if ($issue->{status} eq 'published' || $issue->{status} eq 'in_progress') {
            print "<option value='$issue->{id}'>№$issue->{number} ($issue->{year}) - $issue->{title}</option>";
        }
    }
    
    print "</select>";
    print "</div>";
    
    print "<div style='margin-bottom: 20px;'>";
    print "<label for='price'><strong>Цена статьи (руб.):</strong></label><br>";
    print "<input type='number' id='price' name='price' value='300' min='0' style='padding: 8px; width: 200px;' required>";
    print "</div>";
    
    print "<div style='display: flex; gap: 10px;'>";
    print "<button type='submit' class='btn'>Опубликовать</button>";
    print "<a href='?action=view_submission&id=$submission_id' class='btn'>Отмена</a>";
    print "</div>";
    
    print "</form>";
    
    print $q->end_html;
}

sub show_users {
    my $q = shift || CGI->new;
    
    print $q->header(-charset=>'utf-8');
    print $q->start_html(-title=>'Пользователи', -encoding=>'utf-8');
    print "<h1>Пользователи</h1>";
    
    # Получаем всех пользователей из БД
    my @users = get_all_users();
    
    if (@users) {
        print "<table border='1' style='width: 100%; border-collapse: collapse;'>";
        print "<tr><th>ID</th><th>Имя</th><th>Email</th><th>Роль</th><th>Действия</th></tr>";
        
        foreach my $user (@users) {
            print "<tr>";
            print "<td>$user->{id}</td>";
            print "<td>$user->{fullname}</td>";
            print "<td>$user->{email}</td>";
            print "<td>$user->{role}</td>";
            print "<td>";
            print "<a href='?action=edit_user&id=$user->{id}'>Редактировать</a> | ";
            print "<a href='?action=delete_user&id=$user->{id}'>Удалить</a>";
            print "</td>";
            print "</tr>";
        }
        
        print "</table>";
    } else {
        print "<p>Нет пользователей.</p>";
    }
    
    print "<p><a href='?' class='btn'>Вернуться в панель администратора</a></p>";
    
    print $q->end_html;
}

sub show_issues {
    my $q = shift || CGI->new;
    
    print $q->header(-charset=>'utf-8');
    print $q->start_html(-title=>'Выпуски', -encoding=>'utf-8');
    print "<h1>Выпуски</h1>";
    
    # Получаем все выпуски из БД
    my @issues = get_all_issues();
    
    if (@issues) {
        print "<table border='1' style='width: 100%; border-collapse: collapse;'>";
        print "<tr><th>ID</th><th>Номер</th><th>Год</th><th>Название</th><th>Статус</th><th>Действия</th></tr>";
        
        foreach my $issue (@issues) {
            print "<tr>";
            print "<td>$issue->{id}</td>";
            print "<td>$issue->{number}</td>";
            print "<td>$issue->{year}</td>";
            print "<td>$issue->{title}</td>";
            print "<td>$issue->{status}</td>";
            print "<td>";
            print "<a href='?action=edit_issue&id=$issue->{id}'>Редактировать</a> | ";
            print "<a href='?action=delete_issue&id=$issue->{id}'>Удалить</a>";
            print "</td>";
            print "</tr>";
        }
        
        print "</table>";
    } else {
        print "<p>Нет выпусков.</p>";
    }
    
    print "<p><a href='?' class='btn'>Вернуться в панель администратора</a></p>";
    
    print $q->end_html;
}

sub show_articles {
    my $q = shift || CGI->new;
    
    print $q->header(-charset=>'utf-8');
    print $q->start_html(-title=>'Статьи', -encoding=>'utf-8');
    print "<h1>Статьи</h1>";
    
    # Получаем все статьи из БД
    my @articles = get_all_articles();
    
    if (@articles) {
        print "<table border='1' style='width: 100%; border-collapse: collapse;'>";
        print "<tr><th>ID</th><th>Название</th><th>Авторы</th><th>Выпуск</th><th>Действия</th></tr>";
        
        foreach my $article (@articles) {
            my $issue = get_issue_by_id($article->{issue_id});
            print "<tr>";
            print "<td>$article->{id}</td>";
            print "<td>$article->{title}</td>";
            print "<td>$article->{authors}</td>";
            print "<td>№$issue->{number}, $issue->{year}</td>";
            print "<td>";
            print "<a href='?action=edit_article&id=$article->{id}'>Редактировать</a> | ";
            print "<a href='?action=delete_article&id=$article->{id}'>Удалить</a>";
            print "</td>";
            print "</tr>";
        }
        
        print "</table>";
    } else {
        print "<p>Нет статей.</p>";
    }
    
    print "<p><a href='?' class='btn'>Вернуться в панель администратора</a></p>";
    
    print $q->end_html;
}

sub show_orders {
    my $q = shift || CGI->new;
    
    print $q->header(-charset=>'utf-8');
    print $q->start_html(-title=>'Заказы', -encoding=>'utf-8');
    print "<h1>Заказы</h1>";
    
    # Получаем все заказы из БД
    my @orders = get_all_orders();
    
    if (@orders) {
        print "<table border='1' style='width: 100%; border-collapse: collapse;'>";
        print "<tr><th>ID</th><th>Покупатель</th><th>Сумма</th><th>Статус</th><th>Действия</th></tr>";
        
        foreach my $order (@orders) {
            my $user = get_user_by_id($order->{user_id});
            print "<tr>";
            print "<td>$order->{id}</td>";
            print "<td>$user->{fullname}</td>";
            print "<td>$order->{total} руб.</td>";
            print "<td>$order->{status}</td>";
            print "<td>";
            print "<a href='?action=edit_order&id=$order->{id}'>Редактировать</a> | ";
            print "<a href='?action=delete_order&id=$order->{id}'>Удалить</a>";
            print "</td>";
            print "</tr>";
        }
        
        print "</table>";
    } else {
        print "<p>Нет заказов.</p>";
    }
    
    print "<p><a href='?action=profile' class='btn'>Вернуться в панель администратора</a></p>";
    
    print $q->end_html;
}

sub show_stats {
    my $q = shift || CGI->new;
    
    print $q->header(-charset=>'utf-8');
    print $q->start_html(-title=>'Статистика', -encoding=>'utf-8');
    print "<h1>Статистика</h1>";
    
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
    
    print "<p>Статистика пользователей: @{[scalar @users]}</p>";
    print "<p>Статистика выпусков: @{[scalar @issues]}</p>";
    print "<p>Статистика статей: @{[scalar @articles]}</p>";
    print "<p>Статистика заказов: @{[scalar @orders]}</p>";
    print "<p>Общая сумма продаж: $total_sales руб.</p>";
    print "<p>Выполненных заказов: @{[$order_stats{completed} || 0]}</p>";
    
    print "<p><a href='?' class='btn'>Вернуться в панель администратора</a></p>";
    
    print $q->end_html;
}

sub edit_issue {
    my $q = shift || CGI->new;
    my $issue_id = $q->param('id');
    my $error = $q->param('error') || '';
    
    my $issue = {};
    if ($issue_id) {
        $issue = get_issue_by_id($issue_id);
        unless ($issue) {
            print $q->redirect(-uri => "/cgi-bin/admin.pl?action=issues&error=Выпуск не найден");
            return;
        }
    }
    
    print $q->header(-charset=>'utf-8');
    print $q->start_html(-title=>($issue_id ? "Редактирование выпуска" : "Создание выпуска"), -encoding=>'utf-8');
    
    my $form_title = $issue_id ? "Редактирование выпуска #$issue_id" : "Создание нового выпуска";
    print "<h1>$form_title</h1>";
    
    if ($error) {
        print "<div class='alert alert-error'>$error</div>";
    }
    
    print "<form method='post' action='/cgi-bin/admin.pl?action=save_issue' enctype='multipart/form-data'>";
    if ($issue_id) {
        print "<input type='hidden' name='id' value='$issue_id'>";
    }
    
    print <<HTML;
    <div style='margin-bottom: 20px;'>
        <label for='number'><strong>Номер выпуска:</strong></label><br>
        <input type='number' id='number' name='number' value='@{[$issue->{number} || ""]}' required style='padding: 8px; width: 100%;'>
    </div>
    
    <div style='margin-bottom: 20px;'>
        <label for='year'><strong>Год издания:</strong></label><br>
        <input type='number' id='year' name='year' value='@{[$issue->{year} || (localtime)[5] + 1900]}' required style='padding: 8px; width: 100%;'>
    </div>
    
    <div style='margin-bottom: 20px;'>
        <label for='month'><strong>Месяц издания:</strong></label><br>
        <select id='month' name='month' required style='padding: 8px; width: 100%;'>
HTML
    
    my @month_names = ('Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь');
    for my $i (1..12) {
        my $selected = ($issue->{month} && $issue->{month} eq $i) ? " selected" : "";
        print "<option value='$i'$selected>$month_names[$i-1]</option>";
    }
    
    print <<HTML;
        </select>
    </div>
    
    <div style='margin-bottom: 20px;'>
        <label for='title'><strong>Название выпуска:</strong></label><br>
        <input type='text' id='title' name='title' value='@{[$issue->{title} || ""]}' required style='padding: 8px; width: 100%;'>
    </div>
    
    <div style='margin-bottom: 20px;'>
        <label for='description'><strong>Описание:</strong></label><br>
        <textarea id='description' name='description' rows='5' style='padding: 8px; width: 100%;'>@{[$issue->{description} || ""]}</textarea>
    </div>
    
    <div style='margin-bottom: 20px;'>
        <label for='cover'><strong>Обложка:</strong></label><br>
        <input type='text' id='cover' name='cover' value='@{[$issue->{cover} || "/images/issue-cover-placeholder.jpg"]}' style='padding: 8px; width: 100%;'>
        <small>Укажите путь к изображению обложки (например, /images/cover.jpg)</small>
    </div>
    
    <div style='margin-bottom: 20px;'>
        <label for='status'><strong>Статус:</strong></label><br>
        <select id='status' name='status' required style='padding: 8px; width: 100%;'>
            <option value='draft'@{[$issue->{status} eq 'draft' ? " selected" : ""]}>Черновик</option>
            <option value='in_progress'@{[$issue->{status} eq 'in_progress' ? " selected" : ""]}>В работе</option>
            <option value='published'@{[$issue->{status} eq 'published' ? " selected" : ""]}>Опубликован</option>
        </select>
    </div>
    
    <div style='margin-bottom: 20px;'>
        <label for='publication_date'><strong>Дата публикации:</strong></label><br>
        <input type='date' id='publication_date' name='publication_date' value='@{[$issue->{publication_date} || strftime("%Y-%m-%d", localtime)]}' style='padding: 8px; width: 100%;'>
    </div>
    
    <div style='display: flex; gap: 10px;'>
        <button type='submit' class='btn'>Сохранить</button>
        <a href='/cgi-bin/admin.pl?action=issues' class='btn'>Отмена</a>
    </div>
HTML
    
    print "</form>";
    print $q->end_html;
}

sub display_edit_user_form {
    my $q = shift || CGI->new;
    my $id = $q->param('id');
    my $error = $q->param('error') || '';
    
    my $user = {};
    if ($id) {
        $user = get_user_by_id($id);
        unless ($user) {
            print $q->redirect(-uri => "/cgi-bin/admin.pl?action=users&error=Пользователь не найден");
            return;
        }
    }
    
    print $q->header(-charset=>'utf-8');
    print $q->start_html(-title=>($id ? "Редактирование пользователя" : "Создание пользователя"), -encoding=>'utf-8');
    
    my $form_title = $id ? "Редактирование пользователя #$id" : "Создание нового пользователя";
    print "<h1>$form_title</h1>";
    
    if ($error) {
        print "<div class='alert alert-error'>$error</div>";
    }
    
    print "<form method='post' action='/cgi-bin/admin.pl?action=save_user' enctype='multipart/form-data'>";
    if ($id) {
        print "<input type='hidden' name='id' value='$id'>";
    }
    
    print <<HTML;
    <div style='margin-bottom: 20px;'>
        <label for='login'><strong>Логин:</strong></label><br>
        <input type='text' id='login' name='login' value='@{[$user->{login} || ""]}' required style='padding: 8px; width: 100%;'>
    </div>
    
    <div style='margin-bottom: 20px;'>
        <label for='password'><strong>Пароль:</strong></label><br>
        <input type='password' id='password' name='password' style='padding: 8px; width: 100%;'>
        <small>Оставьте пустым, чтобы сохранить текущий пароль</small>
    </div>
    
    <div style='margin-bottom: 20px;'>
        <label for='fullname'><strong>ФИО:</strong></label><br>
        <input type='text' id='fullname' name='fullname' value='@{[$user->{fullname} || ""]}' required style='padding: 8px; width: 100%;'>
    </div>
    
    <div style='margin-bottom: 20px;'>
        <label for='email'><strong>Email:</strong></label><br>
        <input type='email' id='email' name='email' value='@{[$user->{email} || ""]}' required style='padding: 8px; width: 100%;'>
    </div>
    
    <div style='margin-bottom: 20px;'>
        <label for='phone'><strong>Телефон:</strong></label><br>
        <input type='text' id='phone' name='phone' value='@{[$user->{phone} || ""]}' style='padding: 8px; width: 100%;'>
    </div>
    
    <div style='margin-bottom: 20px;'>
        <label for='address'><strong>Адрес:</strong></label><br>
        <textarea id='address' name='address' rows='3' style='padding: 8px; width: 100%;'>@{[$user->{address} || ""]}</textarea>
    </div>
    
    <div style='margin-bottom: 20px;'>
        <label for='role'><strong>Роль:</strong></label><br>
        <select id='role' name='role' required style='padding: 8px; width: 100%;'>
            <option value='user'@{[$user->{role} eq 'user' ? " selected" : ""]}>Пользователь</option>
            <option value='editor'@{[$user->{role} eq 'editor' ? " selected" : ""]}>Редактор</option>
            <option value='admin'@{[$user->{role} eq 'admin' ? " selected" : ""]}>Администратор</option>
        </select>
    </div>
    
    <div style='display: flex; gap: 10px;'>
        <button type='submit' class='btn'>Сохранить</button>
        <a href='/cgi-bin/admin.pl?action=users' class='btn'>Отмена</a>
    </div>
HTML
    
    print "</form>";
    print $q->end_html;
}

sub save_user {
    my $q = shift || CGI->new;
    
    my $id = $q->param('id') || '';
    my $login = $q->param('login');
    my $password = $q->param('password');
    my $fullname = $q->param('fullname');
    my $email = $q->param('email');
    my $phone = $q->param('phone') || '';
    my $address = $q->param('address') || '';
    my $role = $q->param('role');
    
    # Проверка обязательных полей
    unless ($login && $fullname && $email && $role) {
        my $redirect_url = $id 
            ? "/cgi-bin/admin.pl?action=edit_user&id=$id&error=Заполните все обязательные поля"
            : "/cgi-bin/admin.pl?action=edit_user&error=Заполните все обязательные поля";
        print $q->redirect(-uri => $redirect_url);
        return;
    }
    
    if ($id) {
        if (edit_user($id, $login, $password, $fullname, $email, $phone, $address, $role)) {
            print $q->redirect(-uri => "/cgi-bin/admin.pl?action=users&success=Пользователь успешно обновлен");
        } else {
            print $q->redirect(-uri => "/cgi-bin/admin.pl?action=edit_user&id=$id&error=Ошибка при обновлении пользователя");
        }
    } else {
        # Create new user functionality would go here
        # This would require a create_user function in db_utils.pl
        print $q->redirect(-uri => "/cgi-bin/admin.pl?action=users&error=Создание новых пользователей не реализовано");
    }
}

sub display_edit_article_form {
    my $q = shift || CGI->new;
    my $id = $q->param('id');
    my $error = $q->param('error') || '';
    
    my $article = {};
    if ($id) {
        $article = get_article_by_id($id);
        unless ($article) {
            print $q->redirect(-uri => "/cgi-bin/admin.pl?action=articles&error=Статья не найдена");
            return;
        }
    }
    
    # Get all issues for the dropdown
    my @issues = get_all_issues();
    
    print $q->header(-charset=>'utf-8');
    print $q->start_html(-title=>($id ? "Редактирование статьи" : "Создание статьи"), -encoding=>'utf-8');
    
    my $form_title = $id ? "Редактирование статьи #$id" : "Создание новой статьи";
    print "<h1>$form_title</h1>";
    
    if ($error) {
        print "<div class='alert alert-error'>$error</div>";
    }
    
    print "<form method='post' action='/cgi-bin/admin.pl?action=save_article' enctype='multipart/form-data'>";
    if ($id) {
        print "<input type='hidden' name='id' value='$id'>";
    }
    
    print <<HTML;
    <div style='margin-bottom: 20px;'>
        <label for='issue_id'><strong>Выпуск:</strong></label><br>
        <select id='issue_id' name='issue_id' required style='padding: 8px; width: 100%;'>
HTML
    
    foreach my $issue (sort { $b->{year} <=> $a->{year} || $b->{number} <=> $a->{number} } @issues) {
        my $selected = ($article->{issue_id} && $article->{issue_id} == $issue->{id}) ? " selected" : "";
        print "<option value='$issue->{id}'$selected>№$issue->{number} ($issue->{year}) - $issue->{title}</option>";
    }
    
    print <<HTML;
        </select>
    </div>
    
    <div style='margin-bottom: 20px;'>
        <label for='title'><strong>Название статьи:</strong></label><br>
        <input type='text' id='title' name='title' value='@{[$article->{title} || ""]}' required style='padding: 8px; width: 100%;'>
    </div>
    
    <div style='margin-bottom: 20px;'>
        <label for='authors'><strong>Авторы:</strong></label><br>
        <input type='text' id='authors' name='authors' value='@{[$article->{authors} || ""]}' required style='padding: 8px; width: 100%;'>
        <small>Укажите авторов через запятую</small>
    </div>
    
    <div style='margin-bottom: 20px;'>
        <label for='abstract'><strong>Аннотация:</strong></label><br>
        <textarea id='abstract' name='abstract' rows='5' style='padding: 8px; width: 100%;'>@{[$article->{abstract} || ""]}</textarea>
    </div>
    
    <div style='margin-bottom: 20px;'>
        <label for='content'><strong>Полный текст:</strong></label><br>
        <textarea id='content' name='content' rows='15' style='padding: 8px; width: 100%;'>@{[$article->{content} || ""]}</textarea>
    </div>
    
    <div style='margin-bottom: 20px;'>
        <label for='price'><strong>Цена (руб.):</strong></label><br>
        <input type='number' id='price' name='price' value='@{[$article->{price} || "300"]}' min='0' required style='padding: 8px; width: 100px;'>
    </div>
    
    <div style='margin-bottom: 20px;'>
        <label for='status'><strong>Статус:</strong></label><br>
        <select id='status' name='status' required style='padding: 8px; width: 100%;'>
            <option value='draft'@{[$article->{status} eq 'draft' ? " selected" : ""]}>Черновик</option>
            <option value='published'@{[$article->{status} eq 'published' ? " selected" : ""]}>Опубликована</option>
        </select>
    </div>
    
    <div style='display: flex; gap: 10px;'>
        <button type='submit' class='btn'>Сохранить</button>
        <a href='/cgi-bin/admin.pl?action=articles' class='btn'>Отмена</a>
    </div>
HTML
    
    print "</form>";
    print $q->end_html;
}

sub save_article {
    my $q = shift || CGI->new;
    
    my $article_id = $q->param('id') || '';
    my $issue_id = $q->param('issue_id');
    my $title = $q->param('title');
    my $authors = $q->param('authors');
    my $abstract = $q->param('abstract') || '';
    my $content = $q->param('content') || '';
    my $price = $q->param('price');
    my $status = $q->param('status');
    
    # Проверка обязательных полей
    unless ($issue_id && $title && $authors && $price && $status) {
        my $redirect_url = $article_id 
            ? "/cgi-bin/admin.pl?action=edit_article&id=$article_id&error=Заполните все обязательные поля"
            : "/cgi-bin/admin.pl?action=edit_article&error=Заполните все обязательные поля";
        print $q->redirect(-uri => $redirect_url);
        return;
    }
    
    if ($article_id) {
        # Update existing article
        if (edit_article($article_id, $issue_id, $title, $authors, $abstract, $content, $price, $status)) {
            print $q->redirect(-uri => "/cgi-bin/admin.pl?action=articles&success=Статья успешно обновлена");
        } else {
            print $q->redirect(-uri => "/cgi-bin/admin.pl?action=edit_article&id=$article_id&error=Ошибка при обновлении статьи");
        }
    } else {
        # Create new article
        my $publication_date = strftime("%Y-%m-%d", localtime);
        my $new_article_id = create_article($issue_id, $title, $authors, $abstract, $content, $price, $status, $publication_date);
        
        if ($new_article_id) {
            print $q->redirect(-uri => "/cgi-bin/admin.pl?action=articles&success=Статья успешно создана");
        } else {
            print $q->redirect(-uri => "/cgi-bin/admin.pl?action=edit_article&error=Ошибка при создании статьи");
        }
    }
}

sub delete_article_action {
    my $q = shift || CGI->new;
    my $id = $q->param('id');
    
    unless ($id) {
        print $q->redirect(-uri => "/cgi-bin/admin.pl?action=articles&error=Не указан ID статьи");
        return;
    }
    
    if (delete_article($id)) {
        print $q->redirect(-uri => "/cgi-bin/admin.pl?action=articles&success=Статья успешно удалена");
    } else {
        print $q->redirect(-uri => "/cgi-bin/admin.pl?action=articles&error=Ошибка при удалении статьи");
    }
}

sub save_issue {
    my $q = shift || CGI->new;
    
    my $issue_id = $q->param('id') || '';
    my $number = $q->param('number');
    my $year = $q->param('year');
    my $month = $q->param('month');
    my $title = $q->param('title');
    my $description = $q->param('description') || '';
    my $cover = $q->param('cover') || '/images/issue-cover-placeholder.jpg';
    my $status = $q->param('status');
    my $publication_date = $q->param('publication_date') || strftime("%Y-%m-%d", localtime);
    
    # Проверка обязательных полей
    unless ($number && $year && $month && $title && $status) {
        my $redirect_url = $issue_id 
            ? "/cgi-bin/admin.pl?action=edit_issue&id=$issue_id&error=Заполните все обязательные поля"
            : "/cgi-bin/admin.pl?action=edit_issue&error=Заполните все обязательные поля";
        print $q->redirect(-uri => $redirect_url);
        return;
    }
    
    if ($issue_id) {
        # Update existing issue
        if (update_issue($issue_id, $number, $year, $month, $title, $description, $cover, $status, $publication_date)) {
            print $q->redirect(-uri => "/cgi-bin/admin.pl?action=issues&success=Выпуск успешно обновлен");
        } else {
            print $q->redirect(-uri => "/cgi-bin/admin.pl?action=edit_issue&id=$issue_id&error=Ошибка при обновлении выпуска");
        }
    } else {
        # Create new issue
        my $new_issue_id = create_issue($number, $year, $month, $title, $description, $cover, $status, $publication_date);
        if ($new_issue_id) {
            print $q->redirect(-uri => "/cgi-bin/admin.pl?action=issues&success=Выпуск успешно создан");
        } else {
            print $q->redirect(-uri => "/cgi-bin/admin.pl?action=edit_issue&error=Ошибка при создании выпуска");
        }
    }
} 