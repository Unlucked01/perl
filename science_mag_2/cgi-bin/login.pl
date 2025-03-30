#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DB_File;
use Digest::SHA qw(sha256_hex);

my $cgi = CGI->new;
print $cgi->header(-type => 'text/html', -charset => 'UTF-8');

# Define paths
my $db_path = "/usr/local/apache2/data/users.db";
my $sessions_path = "/usr/local/apache2/data/sessions.db";

# Check if this is a form submission
my $action = $cgi->param('action') || 'display_form';

if ($action eq 'login') {
    process_login();
} elsif ($action eq 'register') {
    process_registration();
} else {
    display_form();
}

# Function to display login/registration form
sub display_form {
    my $error = shift || '';
    my $success = shift || '';
    
    print <<HTML;
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Вход в систему | Научный журнал</title>
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
                    </ul>
                    <div class="d-flex">
                        <a href="/cart.html" class="btn btn-outline-light me-2">
                            <i class="bi bi-cart"></i> Корзина
                        </a>
                        <a href="/cgi-bin/login.pl" class="btn btn-outline-light active">Войти</a>
                    </div>
                </div>
            </div>
        </nav>
    </header>

    <main class="container my-4">
        <div class="row justify-content-center">
            <div class="col-md-6">
HTML

    # Display error message if there is one
    if ($error) {
        print <<HTML;
                <div class="alert alert-danger alert-dismissible fade show" role="alert">
                    $error
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                </div>
HTML
    }

    # Display success message if there is one
    if ($success) {
        print <<HTML;
                <div class="alert alert-success alert-dismissible fade show" role="alert">
                    $success
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                </div>
HTML
    }

    print <<HTML;
                <div class="card mb-4">
                    <div class="card-header">
                        <ul class="nav nav-tabs card-header-tabs" id="loginTab" role="tablist">
                            <li class="nav-item" role="presentation">
                                <button class="nav-link active" id="login-tab" data-bs-toggle="tab" data-bs-target="#login" type="button" role="tab" aria-controls="login" aria-selected="true">Вход</button>
                            </li>
                            <li class="nav-item" role="presentation">
                                <button class="nav-link" id="register-tab" data-bs-toggle="tab" data-bs-target="#register" type="button" role="tab" aria-controls="register" aria-selected="false">Регистрация</button>
                            </li>
                        </ul>
                    </div>
                    <div class="card-body">
                        <div class="tab-content" id="loginTabContent">
                            <div class="tab-pane fade show active" id="login" role="tabpanel" aria-labelledby="login-tab">
                                <form method="post" action="/cgi-bin/login.pl">
                                    <input type="hidden" name="action" value="login">
                                    <div class="mb-3">
                                        <label for="loginEmail" class="form-label">Email</label>
                                        <input type="email" class="form-control" id="loginEmail" name="email" required>
                                    </div>
                                    <div class="mb-3">
                                        <label for="loginPassword" class="form-label">Пароль</label>
                                        <input type="password" class="form-control" id="loginPassword" name="password" required>
                                    </div>
                                    <div class="mb-3 form-check">
                                        <input type="checkbox" class="form-check-input" id="rememberMe" name="remember_me">
                                        <label class="form-check-label" for="rememberMe">Запомнить меня</label>
                                    </div>
                                    <button type="submit" class="btn btn-primary">Войти</button>
                                </form>
                            </div>
                            <div class="tab-pane fade" id="register" role="tabpanel" aria-labelledby="register-tab">
                                <form method="post" action="/cgi-bin/login.pl">
                                    <input type="hidden" name="action" value="register">
                                    <div class="mb-3">
                                        <label for="regName" class="form-label">Имя</label>
                                        <input type="text" class="form-control" id="regName" name="name" required>
                                    </div>
                                    <div class="mb-3">
                                        <label for="regEmail" class="form-label">Email</label>
                                        <input type="email" class="form-control" id="regEmail" name="email" required>
                                    </div>
                                    <div class="mb-3">
                                        <label for="regPassword" class="form-label">Пароль</label>
                                        <input type="password" class="form-control" id="regPassword" name="password" required>
                                    </div>
                                    <div class="mb-3">
                                        <label for="regConfirmPassword" class="form-label">Подтверждение пароля</label>
                                        <input type="password" class="form-control" id="regConfirmPassword" name="confirm_password" required>
                                    </div>
                                    <div class="mb-3 form-check">
                                        <input type="checkbox" class="form-check-input" id="termsAgreement" name="terms_agreement" required>
                                        <label class="form-check-label" for="termsAgreement">Я согласен с условиями использования</label>
                                    </div>
                                    <button type="submit" class="btn btn-primary">Зарегистрироваться</button>
                                </form>
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
</body>
</html>
HTML
}

# Function to process login form
sub process_login {
    my $email = $cgi->param('email');
    my $password = $cgi->param('password');
    
    # Simple validation
    if (!$email || !$password) {
        display_form("Все поля должны быть заполнены.");
        return;
    }
    
    # Check if user exists and password is correct
    my %users;
    tie %users, 'DB_File', $db_path, O_RDONLY, 0644, $DB_HASH or display_form("Ошибка базы данных: $!");
    
    if (exists $users{$email}) {
        my ($stored_password, $name, $role) = split(':::', $users{$email});
        
        if ($stored_password eq sha256_hex($password)) {
            # Password is correct, create session
            my $session_id = create_session($email, $role);
            
            # Set cookie
            my $cookie = $cgi->cookie(
                -name => 'session',
                -value => $session_id,
                -expires => '+1d',
                -path => '/'
            );
            
            print $cgi->redirect(
                -uri => '/cgi-bin/profile.pl',
                -cookie => $cookie
            );
            
            untie %users;
            return;
        }
    }
    
    untie %users;
    display_form("Неверный email или пароль.");
}

# Function to process registration form
sub process_registration {
    my $name = $cgi->param('name');
    my $email = $cgi->param('email');
    my $password = $cgi->param('password');
    my $confirm_password = $cgi->param('confirm_password');
    my $terms_agreement = $cgi->param('terms_agreement');
    
    # Simple validation
    if (!$name || !$email || !$password || !$confirm_password) {
        display_form("Все поля должны быть заполнены.");
        return;
    }
    
    if ($password ne $confirm_password) {
        display_form("Пароли не совпадают.");
        return;
    }
    
    if (!$terms_agreement) {
        display_form("Необходимо согласиться с условиями использования.");
        return;
    }
    
    # Check if email already exists
    my %users;
    tie %users, 'DB_File', $db_path, O_CREAT|O_RDWR, 0644, $DB_HASH or display_form("Ошибка базы данных: $!");
    
    if (exists $users{$email}) {
        untie %users;
        display_form("Пользователь с таким email уже существует.");
        return;
    }
    
    # Hash the password
    my $hashed_password = sha256_hex($password);
    
    # Store user data (password, name, role)
    $users{$email} = "$hashed_password:::$name:::customer";
    
    untie %users;
    
    display_form("", "Регистрация успешно завершена. Теперь вы можете войти в систему.");
}

# Function to create a session
sub create_session {
    my ($email, $role) = @_;
    
    my $session_id = sha256_hex(time() . rand() . $email);
    
    my %sessions;
    tie %sessions, 'DB_File', $sessions_path, O_CREAT|O_RDWR, 0644, $DB_HASH or display_form("Ошибка базы данных сессий: $!");
    
    # Store session data
    my $expiry = time() + 86400; # 24 hours
    $sessions{$session_id} = "$email:::$role:::$expiry";
    
    untie %sessions;
    
    return $session_id;
} 