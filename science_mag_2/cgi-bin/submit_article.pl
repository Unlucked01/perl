#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DB_File;

my $cgi = CGI->new;

# Define paths
my $db_path = "/usr/local/apache2/data/users.db";
my $sessions_path = "/usr/local/apache2/data/sessions.db";
my $articles_path = "/usr/local/apache2/data/articles.db";

# Check if user is logged in
my $session_cookie = $cgi->cookie('session') || '';
my ($user_email, $user_name, $user_role) = check_session($session_cookie);

if (!$user_email) {
    # Not logged in, redirect to login page
    print $cgi->redirect('/cgi-bin/login.pl');
    exit;
}

# Check if form was submitted
if ($cgi->param('title')) {
    # Get form data
    my $title = $cgi->param('title') || '';
    my $authors = $cgi->param('authors') || '';
    my $abstract = $cgi->param('abstract') || '';
    my $file = $cgi->upload('file');
    
    # Validate required fields
    if ($title && $authors && $abstract && $file) {
        # Generate article ID
        my $timestamp = time();
        my $article_id = "article-" . sprintf("%03d", int(rand(1000)));
        
        # Get current date
        my ($sec, $min, $hour, $day, $month, $year) = localtime(time);
        $year += 1900;
        $month += 1;
        my $date = sprintf("%02d.%02d.%04d", $day, $month, $year);
        
        # Default status is "Under Review"
        my $status = "На рассмотрении";
        
        # Save article data to database
        my %articles_data;
        if (tie %articles_data, 'DB_File', $articles_path, O_RDWR|O_CREAT, 0644, $DB_HASH) {
            $articles_data{$article_id} = join(':::', $title, $authors, $date, $status, $abstract);
            untie %articles_data;
            
            # Save file if provided
            if ($file) {
                my $upload_dir = "/usr/local/apache2/htdocs/uploads/articles";
                
                # Create directory if it doesn't exist
                unless (-d $upload_dir) {
                    mkdir $upload_dir, 0755 or warn "Could not create $upload_dir: $!";
                }
                
                my $filename = $article_id . "_" . $file;
                my $upload_file = "$upload_dir/$filename";
                
                # Open the uploaded file
                my $fh = $file;
                
                # Open the output file
                if (open(my $out, ">", $upload_file)) {
                    # Slurp the file content
                    local $/ = undef;
                    my $content = <$fh>;
                    print $out $content;
                    close $out;
                }
            }
            
            # Show success message
            display_page('Статья успешно отправлена на рассмотрение');
            exit;
        }
    }
    
    # If we get here, something went wrong
    display_page('Ошибка при отправке статьи. Пожалуйста, проверьте все поля и попробуйте снова.', 'error');
    exit;
}

# Display the article submission form
display_page();

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

# Function to display the submission form
sub display_page {
    my $message = shift || '';
    my $message_type = shift || 'success';
    
    # Output the HTTP header
    print $cgi->header(-type => 'text/html', -charset => 'UTF-8');
    
    print <<HTML;
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Отправка статьи | Научный журнал</title>
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
                            <a class="nav-link" href="/issues.html">Выпуски</a>
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
                        <a href="/cart.html" class="btn btn-outline-light me-2">
                            <i class="bi bi-cart"></i> Корзина
                        </a>
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
                    </div>
                </div>
            </div>
        </nav>
    </header>

    <main class="container my-4">
        <nav aria-label="breadcrumb" class="mb-4">
            <ol class="breadcrumb">
                <li class="breadcrumb-item"><a href="/index.html">Главная</a></li>
                <li class="breadcrumb-item"><a href="/cgi-bin/profile.pl">Личный кабинет</a></li>
                <li class="breadcrumb-item active" aria-current="page">Отправка статьи</li>
            </ol>
        </nav>
        
HTML

    # Display message if any
    if ($message) {
        my $alert_class = $message_type eq 'error' ? 'alert-danger' : 'alert-success';
        print <<HTML;
        <div class="alert $alert_class alert-dismissible fade show" role="alert">
            $message
            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>
HTML
    }

    print <<HTML;
        <div class="card">
            <div class="card-header">
                <h5 class="mb-0">Отправка статьи на рассмотрение</h5>
            </div>
            <div class="card-body">
                <p class="text-muted mb-4">
                    Заполните форму ниже, чтобы отправить свою статью на рассмотрение редакции журнала. 
                    После проверки редакцией, статья будет либо принята к публикации, либо отклонена.
                </p>
                
                <form action="/cgi-bin/submit_article.pl" method="post" enctype="multipart/form-data">
                    <div class="mb-3">
                        <label for="title" class="form-label">Название статьи</label>
                        <input type="text" class="form-control" id="title" name="title" required>
                    </div>
                    
                    <div class="mb-3">
                        <label for="authors" class="form-label">Авторы</label>
                        <input type="text" class="form-control" id="authors" name="authors" placeholder="Фамилия И.О., Фамилия И.О., ..." required>
                        <small class="form-text text-muted">Укажите всех авторов через запятую</small>
                    </div>
                    
                    <div class="mb-3">
                        <label for="abstract" class="form-label">Аннотация</label>
                        <textarea class="form-control" id="abstract" name="abstract" rows="5" required></textarea>
                    </div>
                    
                    <div class="mb-4">
                        <label for="file" class="form-label">Файл статьи (PDF, DOC, DOCX)</label>
                        <input type="file" class="form-control" id="file" name="file" accept=".pdf,.doc,.docx" required>
                        <small class="form-text text-muted">Максимальный размер файла: 10MB</small>
                    </div>
                    
                    <div class="alert alert-info">
                        <p class="mb-0"><strong>Обратите внимание:</strong> Отправляя статью, вы соглашаетесь с условиями публикации в нашем журнале.</p>
                    </div>
                    
                    <div class="d-flex gap-2">
                        <button type="submit" class="btn btn-primary">Отправить статью</button>
                        <a href="/cgi-bin/profile.pl" class="btn btn-secondary">Отмена</a>
                    </div>
                </form>
            </div>
        </div>
    </main>

    <footer class="bg-dark text-white py-4 mt-5">
        <div class="container">
            <div class="row">
                <div class="col-md-6">
                    <h5>Научный журнал</h5>
                    <p>Публикация научных статей в области науки и технологий</p>
                </div>
                <div class="col-md-3">
                    <h5>Ссылки</h5>
                    <ul class="list-unstyled">
                        <li><a href="/index.html" class="text-white">Главная</a></li>
                        <li><a href="/issues.html" class="text-white">Выпуски</a></li>
                        <li><a href="/about.html" class="text-white">О журнале</a></li>
                    </ul>
                </div>
                <div class="col-md-3">
                    <h5>Контакты</h5>
                    <address>
                        <p class="mb-1">Email: journal\@example.com</p>
                        <p class="mb-1">Телефон: +7 (123) 456-7890</p>
                    </address>
                </div>
            </div>
            <hr>
            <div class="text-center">
                <p class="mb-0">&copy; 2025 Научный журнал. Все права защищены.</p>
            </div>
        </div>
    </footer>

    <!-- Bootstrap JS -->
    <script src="/js/bootstrap.bundle.min.js"></script>
</body>
</html>
HTML
} 