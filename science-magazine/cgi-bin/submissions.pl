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
    get_user_by_id
    get_submission_by_id
    get_all_submissions
    create_submission
    update_submission_status
    encode_utf8
    decode_utf8
));

# Инициализируем базу данных
init_database();

my $q = CGI->new;
my $action = $q->param('action') || 'list';

# Получаем данные сессии из cookie
my $session_cookie = $q->cookie('session');
my ($user_id, $user_role) = split(/:/, $session_cookie) if $session_cookie;

# Проверяем, авторизован ли пользователь
unless ($user_id) {
    print $q->redirect(-uri => "/cgi-bin/auth.pl?error=Для подачи рукописей необходимо авторизоваться");
    exit;
}

# Обработка действий
if ($action eq 'list') {
    show_submissions_list();
} elsif ($action eq 'new') {
    show_new_submission_form();
} elsif ($action eq 'submit') {
    process_submission();
} elsif ($action eq 'view') {
    view_submission();
} else {
    show_submissions_list();
}

# Функция для отображения списка рукописей пользователя
sub show_submissions_list {
    my $error = $q->param('error') || '';
    my $success = $q->param('success') || '';
    
    # Получаем все рукописи пользователя
    my @all_submissions = get_all_submissions();
    my @user_submissions = grep { $_->{user_id} eq $user_id } @all_submissions;
    
    binmode(STDOUT, ":utf8");
    print "Content-Type: text/html; charset=utf-8\n\n";
    
    print <<HTML;
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Мои рукописи - Научный журнал</title>
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
        
        .submission-list {
            margin-top: 20px;
        }
        
        .submission-item {
            background-color: white;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
            padding: 20px;
            margin-bottom: 20px;
        }
        
        .submission-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 10px;
        }
        
        .submission-title {
            font-size: 1.2rem;
            font-weight: bold;
            margin: 0;
        }
        
        .submission-status {
            padding: 5px 10px;
            border-radius: 3px;
            font-size: 0.8rem;
            font-weight: bold;
        }
        
        .status-new {
            background-color: #cce5ff;
            color: #004085;
        }
        
        .status-reviewing {
            background-color: #fff3cd;
            color: #856404;
        }
        
        .status-accepted {
            background-color: #d4edda;
            color: #155724;
        }
        
        .status-rejected {
            background-color: #f8d7da;
            color: #721c24;
        }
        
        .status-published {
            background-color: #d1ecf1;
            color: #0c5460;
        }
        
        .submission-date {
            color: #666;
            font-size: 0.9rem;
            margin-bottom: 10px;
        }
        
        .submission-abstract {
            margin-bottom: 15px;
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
            <h1>Мои рукописи</h1>
            
HTML

    if ($error) {
        print "<div class='alert alert-error'>$error</div>";
    }
    
    if ($success) {
        print "<div class='alert alert-success'>$success</div>";
    }

    print <<HTML;
            <div class="actions">
                <a href="/cgi-bin/submissions.pl?action=new" class="btn">Подать новую рукопись</a>
                <a href="/cgi-bin/auth.pl?action=profile" class="btn">Вернуться в профиль</a>
            </div>
            
            <div class="submission-list">
                <h2>Ваши рукописи</h2>
HTML

    if (@user_submissions) {
        foreach my $submission (sort { $b->{submission_date} cmp $a->{submission_date} } @user_submissions) {
            my $status_class = "status-" . $submission->{status};
            my $status_text = 
                $submission->{status} eq 'new' ? 'Новая' :
                $submission->{status} eq 'reviewing' ? 'На рецензии' :
                $submission->{status} eq 'accepted' ? 'Принята' :
                $submission->{status} eq 'rejected' ? 'Отклонена' :
                $submission->{status} eq 'published' ? 'Опубликована' : 'Неизвестно';
            
            print <<HTML;
                <div class="submission-item">
                    <div class="submission-header">
                        <h3 class="submission-title">$submission->{title}</h3>
                        <span class="submission-status $status_class">$status_text</span>
                    </div>
                    <div class="submission-date">Дата подачи: $submission->{submission_date}</div>
                    <div class="submission-abstract">
                        <strong>Аннотация:</strong>
                        <p>$submission->{abstract}</p>
                    </div>
                    <div class="submission-actions">
                        <a href="/cgi-bin/submissions.pl?action=view&id=$submission->{id}" class="btn">Просмотреть детали</a>
                    </div>
                </div>
HTML
        }
    } else {
        print "<p>У вас пока нет поданных рукописей.</p>";
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
                <p>Email: info\@scientific-journal.com</p>
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

# Функция для отображения формы подачи новой рукописи
sub show_new_submission_form {
    binmode(STDOUT, ":utf8");
    print "Content-Type: text/html; charset=utf-8\n\n";
    
    my $user = get_user_by_id($user_id);
    
    print <<HTML;
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Подача рукописи - Научный журнал</title>
    <link rel="stylesheet" href="/css/style.css">
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
            <h1>Подача рукописи</h1>
            
            <form method="post" action="/cgi-bin/submissions.pl?action=submit" class="form">
                <div class="form-group">
                    <label for="title">Название статьи:</label>
                    <input type="text" id="title" name="title" required class="form-control">
                </div>
                
                <div class="form-group">
                    <label for="authors">Авторы (ФИО через запятую):</label>
                    <input type="text" id="authors" name="authors" required class="form-control" value="$user->{full_name}">
                </div>
                
                <div class="form-group">
                    <label for="abstract">Аннотация:</label>
                    <textarea id="abstract" name="abstract" required class="form-control" rows="5"></textarea>
                </div>
                
                <div class="form-group">
                    <label for="content">Полный текст статьи:</label>
                    <textarea id="content" name="content" required class="form-control" rows="15"></textarea>
                </div>
                
                <div class="form-group">
                    <label for="author_comments">Комментарии для редакции (необязательно):</label>
                    <textarea id="author_comments" name="author_comments" class="form-control" rows="3"></textarea>
                </div>
                
                <div class="form-group">
                    <button type="submit" class="btn">Отправить рукопись</button>
                    <a href="/cgi-bin/submissions.pl" class="btn">Отмена</a>
                </div>
            </form>
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
                <p>Email: info\@scientific-journal.com</p>
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

# Функция для обработки отправки рукописи
sub process_submission {
    my $title = $q->param('title');
    my $authors = $q->param('authors');
    my $abstract = $q->param('abstract');
    my $content = $q->param('content');
    my $author_comments = $q->param('author_comments') || '';
    
    # Проверяем обязательные поля
    unless ($title && $authors && $abstract && $content) {
        print $q->redirect(-uri => "/cgi-bin/submissions.pl?action=new&error=Пожалуйста, заполните все обязательные поля");
        return;
    }
    
    # Создаем новую рукопись
    my $submission_id = create_submission(
        $user_id,
        $title,
        $authors,
        $abstract,
        $content,
        $author_comments
    );
    
    # Перенаправляем на страницу со списком рукописей
    print $q->redirect(-uri => "/cgi-bin/submissions.pl?success=Ваша рукопись успешно отправлена и будет рассмотрена редакцией");
}

# Функция для просмотра деталей рукописи
sub view_submission {
    my $submission_id = $q->param('id');
    
    # Получаем рукопись по ID
    my $submission = get_submission_by_id($submission_id);
    
    # Проверяем, что рукопись существует и принадлежит текущему пользователю
    unless ($submission && $submission->{user_id} eq $user_id) {
        print $q->redirect(-uri => "/cgi-bin/submissions.pl?error=Рукопись не найдена или у вас нет прав для ее просмотра");
        return;
    }
    
    binmode(STDOUT, ":utf8");
    print "Content-Type: text/html; charset=utf-8\n\n";
    
    # Определяем текст статуса
    my $status_text = 
        $submission->{status} eq 'new' ? 'Новая' :
        $submission->{status} eq 'reviewing' ? 'На рецензии' :
        $submission->{status} eq 'accepted' ? 'Принята' :
        $submission->{status} eq 'rejected' ? 'Отклонена' :
        $submission->{status} eq 'published' ? 'Опубликована' : 'Неизвестно';
    
    # Определяем класс статуса для стилизации
    my $status_class = "status-" . $submission->{status};
    
    print <<HTML;
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Просмотр рукописи - Научный журнал</title>
    <link rel="stylesheet" href="/css/style.css">
    <style>
        .submission-details {
            background-color: white;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
            padding: 20px;
            margin-bottom: 20px;
        }
        
        .submission-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
        }
        
        .submission-title {
            font-size: 1.5rem;
            font-weight: bold;
            margin: 0;
        }
        
        .submission-status {
            padding: 5px 10px;
            border-radius: 3px;
            font-size: 0.8rem;
            font-weight: bold;
        }
        
        .status-new {
            background-color: #cce5ff;
            color: #004085;
        }
        
        .status-reviewing {
            background-color: #fff3cd;
            color: #856404;
        }
        
        .status-accepted {
            background-color: #d4edda;
            color: #155724;
        }
        
        .status-rejected {
            background-color: #f8d7da;
            color: #721c24;
        }
        
        .status-published {
            background-color: #d1ecf1;
            color: #0c5460;
        }
        
        .submission-meta {
            margin-bottom: 20px;
            color: #666;
        }
        
        .submission-section {
            margin-bottom: 20px;
        }
        
        .submission-section h3 {
            margin-top: 0;
            border-bottom: 1px solid #eee;
            padding-bottom: 10px;
        }
        
        .reviewer-comments {
            background-color: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            border-left: 4px solid #6c757d;
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
            <h1>Просмотр рукописи</h1>
            
            <div class="submission-details">
                <div class="submission-header">
                    <h2 class="submission-title">$submission->{title}</h2>
                    <span class="submission-status $status_class">$status_text</span>
                </div>
                
                <div class="submission-meta">
                    <p><strong>Авторы:</strong> $submission->{authors}</p>
                    <p><strong>Дата подачи:</strong> $submission->{submission_date}</p>
                </div>
                
                <div class="submission-section">
                    <h3>Аннотация</h3>
                    <p>$submission->{abstract}</p>
                </div>
                
                <div class="submission-section">
                    <h3>Полный текст</h3>
                    <div style="max-height: 400px; overflow-y: auto;">
                        <pre style="white-space: pre-wrap;">$submission->{content}</pre>
                    </div>
                </div>
                
                <div class="submission-section">
                    <h3>Комментарии автора</h3>
                    <p>@{[$submission->{author_comments} || "Нет комментариев"]}</p>
                </div>
HTML

    # Показываем комментарии рецензента, если они есть
    if ($submission->{reviewer_comments}) {
        print <<HTML;
                <div class="submission-section">
                    <h3>Комментарии рецензента</h3>
                    <div class="reviewer-comments">
                        <p>$submission->{reviewer_comments}</p>
                    </div>
                </div>
HTML
    }

    print <<HTML;
            </div>
            
            <div class="actions">
                <a href="/cgi-bin/submissions.pl" class="btn">Вернуться к списку рукописей</a>
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
                <p>Email: info\@scientific-journal.com</p>
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