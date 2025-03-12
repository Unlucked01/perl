#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
use Encode qw(decode encode);

# Подключаем модуль для работы с БД
require "./db_utils.pl";
db_utils->import(qw(
    init_database
    get_article_by_id
    get_issue_by_id
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
my $id = $q->param('id');

# Получаем данные сессии из cookie
my $session_cookie = $q->cookie('session');
my ($user_id, $user_role) = split(/:/, $session_cookie) if $session_cookie;

# Проверяем, авторизован ли пользователь
unless ($user_id) {
    print $q->redirect(-uri => "/cgi-bin/auth.pl?error=Для просмотра статьи необходимо войти в систему");
    exit;
}

# Проверяем, указан ли ID статьи
unless ($id) {
    print $q->redirect(-uri => "/cgi-bin/issues.pl?error=Статья не найдена");
    exit;
}

# Получаем данные статьи
my $article = get_article_by_id($id);
unless ($article) {
    print $q->redirect(-uri => "/cgi-bin/issues.pl?error=Статья не найдена");
    exit;
}

# Получаем данные выпуска
my $issue = get_issue_by_id($article->{issue_id});

binmode(STDOUT, ":utf8");
print "Content-Type: text/html; charset=utf-8\n\n";

print <<HTML;
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$article->{title} - Научный журнал</title>
    <link rel="stylesheet" href="/css/style.css">
    <style>
        .article-header {
            margin-bottom: 2rem;
        }
        
        .article-meta {
            color: #666;
            margin-bottom: 1rem;
        }
        
        .article-abstract {
            font-style: italic;
            margin-bottom: 2rem;
            padding: 1rem;
            background-color: #f9f9f9;
            border-left: 4px solid var(--secondary-color);
        }
        
        .article-content {
            line-height: 1.8;
        }
        
        .article-content p {
            margin-bottom: 1.5rem;
        }
        
        .article-content h2 {
            margin-top: 2rem;
            margin-bottom: 1rem;
        }
        
        .article-content img {
            max-width: 100%;
            height: auto;
            margin: 1.5rem 0;
        }
        
        .article-references {
            margin-top: 3rem;
            padding-top: 1.5rem;
            border-top: 1px solid #eee;
        }
        
        .article-references h3 {
            margin-bottom: 1rem;
        }
        
        .article-references ol {
            padding-left: 1.5rem;
        }
        
        .article-references li {
            margin-bottom: 0.5rem;
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
            <div class="breadcrumbs mb-3">
                <a href="/cgi-bin/issues.pl">Выпуски журнала</a> &gt; 
                <a href="/cgi-bin/issues.pl?action=view&id=$issue->{id}">Выпуск №$issue->{number}, $issue->{year}</a> &gt; 
                Статья
            </div>
            
            <article class="card">
                <div class="article-header">
                    <h1>$article->{title}</h1>
                    <div class="article-meta">
                        <p><strong>Авторы:</strong> $article->{authors}</p>
                        <p><strong>Ключевые слова:</strong> $article->{keywords}</p>
                    </div>
                    
                    <div class="article-abstract">
                        <strong>Аннотация:</strong> $article->{abstract}
                    </div>
                </div>
                
                <div class="article-content">
                    $article->{content}
                </div>
                
                <div class="article-references">
                    <h3>Список литературы</h3>
                    <ol>
HTML

# Выводим список литературы
my @references = split(/\n/, $article->{references});
foreach my $reference (@references) {
    print "<li>$reference</li>\n";
}

print <<HTML;
                    </ol>
                </div>
            </article>
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