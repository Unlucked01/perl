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
my $orders_path = "/usr/local/apache2/data/orders.db";
my $articles_path = "/usr/local/apache2/data/articles.db";
my $issues_path = "/usr/local/apache2/data/issues.db";

# Check if user is logged in
my $session_cookie = $cgi->cookie('session') || '';
my ($user_email, $user_name, $user_role) = check_session($session_cookie);

# Verify admin or editor role
if (!$user_email || ($user_role ne 'admin' && $user_role ne 'editor')) {
    print $cgi->redirect('/cgi-bin/login.pl');
    exit;
}

# Handle actions
my $action = $cgi->param('action') || 'dashboard';
my $subaction = $cgi->param('subaction') || '';

if ($action eq 'users') {
    if ($subaction eq 'add') {
        handle_add_user();
    } elsif ($subaction eq 'edit') {
        handle_edit_user();
    } else {
        display_users();
    }
} elsif ($action eq 'articles') {
    if ($subaction eq 'add') {
        handle_add_article();
    } elsif ($subaction eq 'edit') {
        handle_edit_article();
    } elsif ($subaction eq 'review') {
        handle_review_article();
    } else {
        display_articles();
    }
} elsif ($action eq 'orders') {
    if ($subaction eq 'create') {
        handle_create_order();
    } elsif ($subaction eq 'view') {
        handle_view_order();
    } else {
        display_orders();
    }
} else {
    display_dashboard();
}

# Function to check session
sub check_session {
    my $session_id = shift;
    
    if (!$session_id) {
        return ('', '', '');
    }
    
    # Get session data from database
    my %sessions;
    if (tie %sessions, 'DB_File', $sessions_path, O_RDONLY, 0644, $DB_HASH) {
        if (exists $sessions{$session_id}) {
            my ($email, $role, $expiry) = split(':::', $sessions{$session_id});
            
            # Check if session is expired
            if ($expiry > time()) {
                # Get user data from users database
                my %users;
                if (tie %users, 'DB_File', $db_path, O_RDONLY, 0644, $DB_HASH) {
                    if (exists $users{$email}) {
                        my ($password, $name, $role) = split(':::', $users{$email});
                        untie %users;
                        untie %sessions;
                        return ($email, $name, $role);
                    }
                    untie %users;
                }
            }
        }
        untie %sessions;
    }
    
    return ('', '', '');
}


# Function to display admin dashboard
sub display_dashboard {
    my $page_title = "Панель управления";
    display_admin_header($page_title);
    
    # Get counts from databases
    my $users_count = 0;
    my $articles_count = 0;
    my $articles_pending = 0;
    my $orders_count = 0;
    my $orders_new = 0;
    my $issues_count = 0;
    my $issues_upcoming = 0;
    
    # Count users
    my %users_data;
    if (tie %users_data, 'DB_File', $db_path, O_RDONLY, 0644, $DB_HASH) {
        $users_count = scalar(keys %users_data);
        untie %users_data;
    }
    
    # Count articles and pending articles
    my %articles_data;
    my @recent_articles = ();
    if (tie %articles_data, 'DB_File', $articles_path, O_RDONLY, 0644, $DB_HASH) {
        $articles_count = scalar(keys %articles_data);
        
        # Get recent articles and count pending
        foreach my $article_id (keys %articles_data) {
            my ($title, $authors, $date, $status, $abstract) = split(':::', $articles_data{$article_id});
            
            if ($status eq "На рассмотрении") {
                $articles_pending++;
            }
            
            # Store recent articles for display (limit to 3)
            push @recent_articles, [$article_id, $title, $authors, $date, $status];
        }
        
        # Sort articles by date (newest first) and limit to 3
        @recent_articles = sort { $b->[3] cmp $a->[3] } @recent_articles;
        if (scalar(@recent_articles) > 3) {
            @recent_articles = @recent_articles[0..2];
        }
        
        untie %articles_data;
    }
    
    # Count orders and new orders
    my %orders_data;
    my @recent_orders = ();
    if (tie %orders_data, 'DB_File', $orders_path, O_RDONLY, 0644, $DB_HASH) {
        $orders_count = scalar(keys %orders_data);
        
        # Get recent orders and count new ones
        foreach my $order_id (keys %orders_data) {
            my ($user_email, $date, $amount, $status) = split(':::', $orders_data{$order_id});
            
            if ($status eq "В обработке") {
                $orders_new++;
            }
            
            # Store recent orders for display (limit to 3)
            push @recent_orders, [$order_id, $user_email, $date, $amount, $status];
        }
        
        # Sort orders by date (newest first) and limit to 3
        @recent_orders = sort { $b->[2] cmp $a->[2] } @recent_orders;
        if (scalar(@recent_orders) > 3) {
            @recent_orders = @recent_orders[0..2];
        }
        
        untie %orders_data;
    }
    
    # Count issues
    my %issues_data;
    if (tie %issues_data, 'DB_File', $issues_path, O_RDONLY, 0644, $DB_HASH) {
        $issues_count = scalar(keys %issues_data);
        $issues_upcoming = 1; # Assuming one upcoming issue
        untie %issues_data;
    }
    
    # Dashboard content
    print <<HTML;
        <div class="row">
            <div class="col-md-3 mb-4">
                <div class="card border-primary h-100">
                    <div class="card-body text-center">
                        <h1 class="display-4 mb-2">$articles_count</h1>
                        <h5 class="card-title">Статьи</h5>
                        <p class="card-text text-muted">$articles_pending на рассмотрении</p>
                    </div>
                </div>
            </div>
            
            <div class="col-md-3 mb-4">
                <div class="card border-success h-100">
                    <div class="card-body text-center">
                        <h1 class="display-4 mb-2">$issues_count</h1>
                        <h5 class="card-title">Выпуски</h5>
                        <p class="card-text text-muted">$issues_upcoming готовится к публикации</p>
                    </div>
                </div>
            </div>
            
            <div class="col-md-3 mb-4">
                <div class="card border-warning h-100">
                    <div class="card-body text-center">
                        <h1 class="display-4 mb-2">$users_count</h1>
                        <h5 class="card-title">Пользователи</h5>
                        <p class="card-text text-muted">5 новых за месяц</p>
                    </div>
                </div>
            </div>
            
            <div class="col-md-3 mb-4">
                <div class="card border-danger h-100">
                    <div class="card-body text-center">
                        <h1 class="display-4 mb-2">$orders_count</h1>
                        <h5 class="card-title">Заказы</h5>
                        <p class="card-text text-muted">$orders_new новых заказа</p>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="row">
            <div class="col-md-6 mb-4">
                <div class="card">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h5 class="mb-0">Последние статьи</h5>
                        <a href="/cgi-bin/admin.pl?action=articles" class="btn btn-sm btn-primary">Все статьи</a>
                    </div>
                    <div class="list-group list-group-flush">
HTML

    # Display recent articles
    foreach my $article (@recent_articles) {
        my ($article_id, $title, $authors, $date, $status) = @$article;
        my $status_class = "primary";
        
        if ($status eq "Принята") {
            $status_class = "success";
        } elsif ($status eq "Отклонена") {
            $status_class = "danger";
        } elsif ($status eq "На рассмотрении") {
            $status_class = "warning";
        }
        
        print <<HTML;
                        <a href="#" class="list-group-item list-group-item-action">
                            <div class="d-flex w-100 justify-content-between">
                                <h6 class="mb-1">$title</h6>
                                <small class="text-muted">$date</small>
                            </div>
                            <p class="mb-1">Авторы: $authors</p>
                            <small><span class="badge bg-$status_class">$status</span></small>
                        </a>
HTML
    }

    print <<HTML;
                    </div>
                </div>
            </div>
            
            <div class="col-md-6 mb-4">
                <div class="card">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h5 class="mb-0">Последние заказы</h5>
                        <a href="/cgi-bin/admin.pl?action=orders" class="btn btn-sm btn-primary">Все заказы</a>
                    </div>
                    <div class="list-group list-group-flush">
HTML

    # Display recent orders
    foreach my $order (@recent_orders) {
        my ($order_id, $user_email, $date, $amount, $status) = @$order;
        my $status_class = "success";
        
        if ($status eq "В обработке") {
            $status_class = "warning";
        } elsif ($status eq "Отменен") {
            $status_class = "danger";
        }
        
        print <<HTML;
                        <a href="#" class="list-group-item list-group-item-action">
                            <div class="d-flex w-100 justify-content-between">
                                <h6 class="mb-1">$order_id</h6>
                                <small class="text-muted">$date</small>
                            </div>
                            <p class="mb-1">Пользователь: $user_email</p>
                            <div class="d-flex justify-content-between">
                                <small><span class="badge bg-$status_class">$status</span></small>
                                <small class="text-end">$amount ₽</small>
                            </div>
                        </a>
HTML
    }

    print <<HTML;
                    </div>
                </div>
            </div>
        </div>
HTML

    display_admin_footer();
}

# Function to display users
sub display_users {
    my $page_title = "Пользователи";
    display_admin_header($page_title);
    
    # Get all users from the database
    my %users_data;
    my @users_list = ();
    
    if (tie %users_data, 'DB_File', $db_path, O_RDONLY, 0644, $DB_HASH) {
        foreach my $email (keys %users_data) {
            my ($password, $name, $role) = split(':::', $users_data{$email});
            push @users_list, [$email, $name, $role];
        }
        untie %users_data;
    }
    
    # Users content
    print <<HTML;
        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h5 class="mb-0">Пользователи</h5>
                <a href="/cgi-bin/admin.pl?action=users&subaction=add" class="btn btn-sm btn-primary">
                    <i class="bi bi-plus-circle"></i> Добавить пользователя
                </a>
            </div>
            <div class="card-body">
                <div class="table-responsive">
                    <table class="table table-striped">
                        <thead>
                            <tr>
                                <th>Email</th>
                                <th>Имя</th>
                                <th>Роль</th>
                                <th>Действия</th>
                            </tr>
                        </thead>
                        <tbody>
HTML

    # Display each user from the database
    foreach my $user (@users_list) {
        my ($email, $name, $role) = @$user;
        my $role_class = "primary";
        if ($role eq "admin") {
            $role_class = "danger";
        } elsif ($role eq "editor") {
            $role_class = "warning";
        }
        
        print <<HTML;
                            <tr>
                                <td>$email</td>
                                <td>$name</td>
                                <td><span class="badge bg-$role_class">$role</span></td>
                                <td>
                                    <a href="/cgi-bin/admin.pl?action=users&subaction=edit&email=$email" class="btn btn-sm btn-outline-primary">
                                        <i class="bi bi-pencil"></i> Редактировать
                                    </a>
                                </td>
                            </tr>
HTML
    }

    print <<HTML;
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
HTML

    display_admin_footer();
}

# Function to display articles
sub display_articles {
    my $page_title = "Статьи";
    display_admin_header($page_title);
    
    # Get message parameters
    my $message = $cgi->param('message') || '';
    my $error = $cgi->param('error') || '';
    
    # Display messages if any
    if ($message) {
        print <<HTML;
        <div class="alert alert-success alert-dismissible fade show" role="alert">
            $message
            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>
HTML
    }
    
    if ($error) {
        print <<HTML;
        <div class="alert alert-danger alert-dismissible fade show" role="alert">
            $error
            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>
HTML
    }
    
    # Get all articles from the database
    my %articles_data;
    my @articles_list = ();
    
    if (tie %articles_data, 'DB_File', $articles_path, O_RDONLY, 0644, $DB_HASH) {
        foreach my $article_id (keys %articles_data) {
            my ($title, $authors, $date, $status, $abstract) = split(':::', $articles_data{$article_id});
            push @articles_list, [$article_id, $title, $authors, $date, $status, $abstract];
        }
        untie %articles_data;
    }
    
    # Articles content
    print <<HTML;
        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h5 class="mb-0">Статьи</h5>
                <a href="/cgi-bin/admin.pl?action=articles&subaction=add" class="btn btn-sm btn-primary">
                    <i class="bi bi-plus-circle"></i> Добавить статью
                </a>
            </div>
            <div class="card-body">
                <div class="table-responsive">
                    <table class="table table-striped">
                        <thead>
                            <tr>
                                <th>Название</th>
                                <th>Авторы</th>
                                <th>Дата</th>
                                <th>Статус</th>
                                <th>Действия</th>
                            </tr>
                        </thead>
                        <tbody>
HTML

    # Display each article from the database
    foreach my $article (@articles_list) {
        my ($article_id, $title, $authors, $date, $status) = @$article;
        my $status_class = "primary";
        
        if ($status eq "Принята") {
            $status_class = "success";
        } elsif ($status eq "Отклонена") {
            $status_class = "danger";
        } elsif ($status eq "На рассмотрении") {
            $status_class = "warning";
        }
        
        print <<HTML;
                            <tr>
                                <td>$title</td>
                                <td>$authors</td>
                                <td>$date</td>
                                <td><span class="badge bg-$status_class">$status</span></td>
                                <td>
                                    <a href="/cgi-bin/admin.pl?action=articles&subaction=edit&id=$article_id" class="btn btn-sm btn-outline-primary">
                                        <i class="bi bi-eye"></i> Просмотр
                                    </a>
HTML
        
        # Only show accept/reject buttons for articles under review
        if ($status eq "На рассмотрении") {
            print <<HTML;
                                    <a href="/cgi-bin/admin.pl?action=articles&subaction=review&id=$article_id&decision=accept" class="btn btn-sm btn-outline-success">
                                        <i class="bi bi-check-circle"></i> Принять
                                    </a>
                                    <a href="/cgi-bin/admin.pl?action=articles&subaction=review&id=$article_id&decision=reject" class="btn btn-sm btn-outline-danger">
                                        <i class="bi bi-x-circle"></i> Отклонить
                                    </a>
HTML
        }
        
        print <<HTML;
                                </td>
                            </tr>
HTML
    }

    print <<HTML;
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
HTML

    display_admin_footer();
}

# Function to display orders
sub display_orders {
    my $page_title = "Заказы";
    display_admin_header($page_title);
    
    # Get all orders from the database
    my %orders_data;
    my @orders_list = ();
    
    if (tie %orders_data, 'DB_File', $orders_path, O_RDONLY, 0644, $DB_HASH) {
        foreach my $order_id (keys %orders_data) {
            my ($user_email, $date, $amount, $status) = split(':::', $orders_data{$order_id});
            push @orders_list, [$order_id, $user_email, $date, $amount, $status];
        }
        untie %orders_data;
    }
    
    # Orders content
    print <<HTML;
        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h5 class="mb-0">Заказы</h5>
                <div>
                    <a href="/cgi-bin/admin.pl?action=orders&subaction=export" class="btn btn-sm btn-outline-secondary">
                        <i class="bi bi-download"></i> Экспорт
                    </a>
                    <a href="/cgi-bin/admin.pl?action=orders&subaction=create" class="btn btn-sm btn-primary">
                        <i class="bi bi-plus-circle"></i> Создать заказ
                    </a>
                </div>
            </div>
            <div class="card-body">
                <div class="table-responsive">
                    <table class="table table-striped">
                        <thead>
                            <tr>
                                <th>№ заказа</th>
                                <th>Пользователь</th>
                                <th>Дата</th>
                                <th>Сумма</th>
                                <th>Статус</th>
                                <th>Действия</th>
                            </tr>
                        </thead>
                        <tbody>
HTML

    # Display each order from the database
    foreach my $order (@orders_list) {
        my ($order_id, $user_email, $date, $amount, $status) = @$order;
        my $status_class = "success";
        
        if ($status eq "В обработке") {
            $status_class = "warning";
        } elsif ($status eq "Отменен") {
            $status_class = "danger";
        }
        
        print <<HTML;
                            <tr>
                                <td>$order_id</td>
                                <td>$user_email</td>
                                <td>$date</td>
                                <td>$amount ₽</td>
                                <td><span class="badge bg-$status_class">$status</span></td>
                                <td>
                                    <a href="/cgi-bin/admin.pl?action=orders&subaction=view&id=$order_id" class="btn btn-sm btn-outline-primary">
                                        <i class="bi bi-eye"></i> Просмотр
                                    </a>
                                </td>
                            </tr>
HTML
    }

    print <<HTML;
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
HTML

    display_admin_footer();
}

# Function to display admin header
sub display_admin_header {
    my $page_title = shift;
    
    # Output the HTTP header first
    print $cgi->header(-type => 'text/html', -charset => 'UTF-8');
    
    print <<HTML;
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$page_title | Админ-панель | Научный журнал</title>
    <!-- Bootstrap CSS -->
    <link href="/css/bootstrap.min.css" rel="stylesheet">
    <link href="/css/bootstrap-icons.css" rel="stylesheet">
    <link href="/css/styles.css" rel="stylesheet">
    <style>
        .admin-sidebar {
            background-color: #212529;
            color: #fff;
            min-height: calc(100vh - 56px);
        }
        
        .admin-sidebar .nav-link {
            color: rgba(255, 255, 255, 0.75);
        }
        
        .admin-sidebar .nav-link:hover,
        .admin-sidebar .nav-link.active {
            color: #fff;
        }
        
        .admin-sidebar .nav-link i {
            margin-right: 0.5rem;
        }
    </style>
</head>
<body>
    <header>
        <nav class="navbar navbar-expand-lg navbar-dark bg-primary">
            <div class="container-fluid">
                <a class="navbar-brand" href="/cgi-bin/admin.pl">Админ-панель</a>
                <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav" aria-controls="navbarNav" aria-expanded="false" aria-label="Toggle navigation">
                    <span class="navbar-toggler-icon"></span>
                </button>
                <div class="collapse navbar-collapse" id="navbarNav">
                    <ul class="navbar-nav me-auto">
                        <li class="nav-item">
                            <a class="nav-link" href="/index.html">На сайт</a>
                        </li>
                    </ul>
                    <div class="d-flex">
                        <div class="dropdown">
                            <button class="btn btn-light dropdown-toggle" type="button" id="profileDropdown" data-bs-toggle="dropdown" aria-expanded="false">
                                $user_name <span class="badge bg-danger">$user_role</span>
                            </button>
                            <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="profileDropdown">
                                <li><a class="dropdown-item" href="/cgi-bin/profile.pl">Профиль</a></li>
                                <li><hr class="dropdown-divider"></li>
                                <li><a class="dropdown-item" href="/cgi-bin/profile.pl?action=logout">Выйти</a></li>
                            </ul>
                        </div>
                    </div>
                </div>
            </div>
        </nav>
    </header>

    <div class="container-fluid">
        <div class="row">
            <div class="col-md-2 admin-sidebar p-0">
                <div class="d-flex flex-column flex-shrink-0 p-3">
                    <ul class="nav nav-pills flex-column mb-auto">
                        <li class="nav-item">
                            <a href="/cgi-bin/admin.pl" class="nav-link @{[$action eq 'dashboard' ? 'active' : '']}">
                                <i class="bi bi-speedometer2"></i>
                                Панель управления
                            </a>
                        </li>
                        <li>
                            <a href="/cgi-bin/admin.pl?action=articles" class="nav-link @{[$action eq 'articles' ? 'active' : '']}">
                                <i class="bi bi-file-earmark-text"></i>
                                Статьи
                            </a>
                        </li>
                        <li>
                            <a href="/cgi-bin/admin.pl?action=orders" class="nav-link @{[$action eq 'orders' ? 'active' : '']}">
                                <i class="bi bi-cart"></i>
                                Заказы
                            </a>
                        </li>
                        <li>
                            <a href="/cgi-bin/admin.pl?action=users" class="nav-link @{[$action eq 'users' ? 'active' : '']}">
                                <i class="bi bi-people"></i>
                                Пользователи
                            </a>
                        </li>
                    </ul>
                </div>
            </div>
            
            <div class="col-md-10 p-4">
                <h1 class="mb-4">$page_title</h1>
HTML
}

# Function to display admin footer
sub display_admin_footer {
    print <<HTML;
            </div>
        </div>
    </div>

    <!-- Bootstrap JS -->
    <script src="/js/bootstrap.bundle.min.js"></script>
    <script src="/js/main.js"></script>
</body>
</html>
HTML
}

# Handler functions for user actions
sub handle_add_user {
    my $page_title = "Добавление пользователя";
    display_admin_header($page_title);
    
    print <<HTML;
        <div class="card">
            <div class="card-header">
                <h5 class="mb-0">Добавление нового пользователя</h5>
            </div>
            <div class="card-body">
                <form action="/cgi-bin/admin.pl" method="post">
                    <input type="hidden" name="action" value="users">
                    <input type="hidden" name="subaction" value="add">
                    
                    <div class="mb-3">
                        <label for="email" class="form-label">Email</label>
                        <input type="email" class="form-control" id="email" name="email" required>
                    </div>
                    
                    <div class="mb-3">
                        <label for="name" class="form-label">Имя</label>
                        <input type="text" class="form-control" id="name" name="name" required>
                    </div>
                    
                    <div class="mb-3">
                        <label for="password" class="form-label">Пароль</label>
                        <input type="password" class="form-control" id="password" name="password" required>
                    </div>
                    
                    <div class="mb-3">
                        <label for="role" class="form-label">Роль</label>
                        <select class="form-select" id="role" name="role" required>
                            <option value="user">Пользователь</option>
                            <option value="editor">Редактор</option>
                            <option value="admin">Администратор</option>
                        </select>
                    </div>
                    
                    <div class="d-flex gap-2">
                        <button type="submit" class="btn btn-primary">Добавить</button>
                        <a href="/cgi-bin/admin.pl?action=users" class="btn btn-secondary">Отмена</a>
                    </div>
                </form>
            </div>
        </div>
HTML

    display_admin_footer();
}

sub handle_edit_user {
    my $page_title = "Редактирование пользователя";
    display_admin_header($page_title);
    
    my $email = $cgi->param('email') || '';
    
    # Get user data
    my %users_data;
    my ($name, $role) = ('', '');
    
    if (tie %users_data, 'DB_File', $db_path, O_RDONLY, 0644, $DB_HASH) {
        if (exists $users_data{$email}) {
            my ($password, $stored_name, $stored_role) = split(':::', $users_data{$email});
            $name = $stored_name;
            $role = $stored_role;
        }
        untie %users_data;
    }
    
    print <<HTML;
        <div class="card">
            <div class="card-header">
                <h5 class="mb-0">Редактирование пользователя</h5>
            </div>
            <div class="card-body">
                <form action="/cgi-bin/admin.pl" method="post">
                    <input type="hidden" name="action" value="users">
                    <input type="hidden" name="subaction" value="edit">
                    <input type="hidden" name="email" value="$email">
                    
                    <div class="mb-3">
                        <label for="name" class="form-label">Имя</label>
                        <input type="text" class="form-control" id="name" name="name" value="$name" required>
                    </div>
                    
                    <div class="mb-3">
                        <label for="password" class="form-label">Новый пароль (оставьте пустым, чтобы не менять)</label>
                        <input type="password" class="form-control" id="password" name="password">
                    </div>
                    
                    <div class="mb-3">
                        <label for="role" class="form-label">Роль</label>
                        <select class="form-select" id="role" name="role" required>
                            <option value="user" @{[$role eq 'user' ? 'selected' : '']}>Пользователь</option>
                            <option value="editor" @{[$role eq 'editor' ? 'selected' : '']}>Редактор</option>
                            <option value="admin" @{[$role eq 'admin' ? 'selected' : '']}>Администратор</option>
                        </select>
                    </div>
                    
                    <div class="d-flex gap-2">
                        <button type="submit" class="btn btn-primary">Сохранить</button>
                        <a href="/cgi-bin/admin.pl?action=users" class="btn btn-secondary">Отмена</a>
                    </div>
                </form>
            </div>
        </div>
HTML

    display_admin_footer();
}

# Handler functions for article actions
sub handle_add_article {
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
                
                # Redirect to articles list with success message
                print $cgi->redirect("/cgi-bin/admin.pl?action=articles&message=" . $cgi->escape("Статья успешно добавлена"));
                exit;
            }
        }
        
        # If we get here, something went wrong
        print $cgi->redirect("/cgi-bin/admin.pl?action=articles&error=" . $cgi->escape("Ошибка при добавлении статьи"));
        exit;
    }
    
    # Display the add article form
    my $page_title = "Добавление статьи";
    display_admin_header($page_title);
    
    print <<HTML;
        <div class="card">
            <div class="card-header">
                <h5 class="mb-0">Добавление новой статьи</h5>
            </div>
            <div class="card-body">
                <form action="/cgi-bin/admin.pl" method="post" enctype="multipart/form-data">
                    <input type="hidden" name="action" value="articles">
                    <input type="hidden" name="subaction" value="add">
                    
                    <div class="mb-3">
                        <label for="title" class="form-label">Название</label>
                        <input type="text" class="form-control" id="title" name="title" required>
                    </div>
                    
                    <div class="mb-3">
                        <label for="authors" class="form-label">Авторы</label>
                        <input type="text" class="form-control" id="authors" name="authors" required>
                    </div>
                    
                    <div class="mb-3">
                        <label for="abstract" class="form-label">Аннотация</label>
                        <textarea class="form-control" id="abstract" name="abstract" rows="3" required></textarea>
                    </div>
                    
                    <div class="mb-3">
                        <label for="file" class="form-label">Файл статьи</label>
                        <input type="file" class="form-control" id="file" name="file" required>
                    </div>
                    
                    <div class="d-flex gap-2">
                        <button type="submit" class="btn btn-primary">Добавить</button>
                        <a href="/cgi-bin/admin.pl?action=articles" class="btn btn-secondary">Отмена</a>
                    </div>
                </form>
            </div>
        </div>
HTML

    display_admin_footer();
}

sub handle_edit_article {
    my $article_id = $cgi->param('id') || '';
    
    # Check if form was submitted for editing
    if ($cgi->param('title') && $article_id) {
        # Get form data
        my $title = $cgi->param('title') || '';
        my $authors = $cgi->param('authors') || '';
        my $abstract = $cgi->param('abstract') || '';
        my $file = $cgi->upload('file');
        
        # Get current article data
        my %articles_data;
        my ($old_title, $old_authors, $date, $status, $old_abstract) = ('', '', '', '', '');
        
        if (tie %articles_data, 'DB_File', $articles_path, O_RDWR, 0644, $DB_HASH) {
            if (exists $articles_data{$article_id}) {
                ($old_title, $old_authors, $date, $status, $old_abstract) = split(':::', $articles_data{$article_id});
                
                # Update article data
                $articles_data{$article_id} = join(':::', $title, $authors, $date, $status, $abstract);
                untie %articles_data;
                
                # Save new file if provided
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
                
                # Redirect to articles list with success message
                print $cgi->redirect("/cgi-bin/admin.pl?action=articles&message=" . $cgi->escape("Статья успешно обновлена"));
                exit;
            }
        }
        
        # If we get here, something went wrong
        print $cgi->redirect("/cgi-bin/admin.pl?action=articles&error=" . $cgi->escape("Ошибка при обновлении статьи"));
        exit;
    }
    
    # Display the edit article form
    my $page_title = "Редактирование статьи";
    display_admin_header($page_title);
    
    # Get article data
    my %articles_data;
    my ($title, $authors, $date, $status, $abstract) = ('', '', '', '', '');
    
    if (tie %articles_data, 'DB_File', $articles_path, O_RDONLY, 0644, $DB_HASH) {
        if (exists $articles_data{$article_id}) {
            ($title, $authors, $date, $status, $abstract) = split(':::', $articles_data{$article_id});
        }
        untie %articles_data;
    }
    
    print <<HTML;
        <div class="card">
            <div class="card-header">
                <h5 class="mb-0">Редактирование статьи</h5>
            </div>
            <div class="card-body">
                <form action="/cgi-bin/admin.pl" method="post" enctype="multipart/form-data">
                    <input type="hidden" name="action" value="articles">
                    <input type="hidden" name="subaction" value="edit">
                    <input type="hidden" name="id" value="$article_id">
                    
                    <div class="mb-3">
                        <label for="title" class="form-label">Название</label>
                        <input type="text" class="form-control" id="title" name="title" value="$title" required>
                    </div>
                    
                    <div class="mb-3">
                        <label for="authors" class="form-label">Авторы</label>
                        <input type="text" class="form-control" id="authors" name="authors" value="$authors" required>
                    </div>
                    
                    <div class="mb-3">
                        <label for="abstract" class="form-label">Аннотация</label>
                        <textarea class="form-control" id="abstract" name="abstract" rows="3" required>$abstract</textarea>
                    </div>
                    
                    <div class="mb-3">
                        <label for="file" class="form-label">Новый файл статьи (оставьте пустым, чтобы не менять)</label>
                        <input type="file" class="form-control" id="file" name="file">
                    </div>
                    
                    <div class="d-flex gap-2">
                        <button type="submit" class="btn btn-primary">Сохранить</button>
                        <a href="/cgi-bin/admin.pl?action=articles" class="btn btn-secondary">Отмена</a>
                    </div>
                </form>
            </div>
        </div>
HTML

    display_admin_footer();
}

sub handle_review_article {
    my $article_id = $cgi->param('id') || '';
    my $decision = $cgi->param('decision') || '';
    
    # We don't output headers before potentially sending a redirect
    my $redirect_url = '';
    
    if ($article_id && $decision) {
        my %articles_data;
        if (tie %articles_data, 'DB_File', $articles_path, O_RDWR, 0644, $DB_HASH) {
            if (exists $articles_data{$article_id}) {
                my ($title, $authors, $date, $status, $abstract) = split(':::', $articles_data{$article_id});
                
                # Only allow review of articles under review
                if ($status eq "На рассмотрении") {
                    $status = ($decision eq 'accept') ? 'Принята' : 'Отклонена';
                    $articles_data{$article_id} = join(':::', $title, $authors, $date, $status, $abstract);
                    
                    # Set success message
                    my $message = ($decision eq 'accept') ? 
                        "Статья успешно принята" : 
                        "Статья успешно отклонена";
                    
                    $redirect_url = "/cgi-bin/admin.pl?action=articles&message=" . $cgi->escape($message);
                }
            }
            untie %articles_data;
        }
    }
    
    # If redirect URL wasn't set, set error redirect
    if (!$redirect_url) {
        $redirect_url = "/cgi-bin/admin.pl?action=articles&error=" . $cgi->escape("Ошибка при обработке статьи");
    }
    
    # Now do the redirect - this prints the headers
    print $cgi->redirect($redirect_url);
    exit;
}

# Handler functions for order actions
sub handle_create_order {
    my $page_title = "Создание заказа";
    display_admin_header($page_title);
    
    # Get all users for the dropdown
    my %users_data;
    my @users_list = ();
    
    if (tie %users_data, 'DB_File', $db_path, O_RDONLY, 0644, $DB_HASH) {
        foreach my $email (keys %users_data) {
            my ($password, $name, $role) = split(':::', $users_data{$email});
            push @users_list, [$email, $name];
        }
        untie %users_data;
    }
    
    print <<HTML;
        <div class="card">
            <div class="card-header">
                <h5 class="mb-0">Создание нового заказа</h5>
            </div>
            <div class="card-body">
                <form action="/cgi-bin/admin.pl" method="post">
                    <input type="hidden" name="action" value="orders">
                    <input type="hidden" name="subaction" value="create">
                    
                    <div class="mb-3">
                        <label for="user_email" class="form-label">Пользователь</label>
                        <select class="form-select" id="user_email" name="user_email" required>
                            <option value="">Выберите пользователя</option>
HTML

    foreach my $user (@users_list) {
        my ($email, $name) = @$user;
        print <<HTML;
                            <option value="$email">$name ($email)</option>
HTML
    }

    print <<HTML;
                        </select>
                    </div>
                    
                    <div class="mb-3">
                        <label for="amount" class="form-label">Сумма</label>
                        <input type="number" class="form-control" id="amount" name="amount" required>
                    </div>
                    
                    <div class="mb-3">
                        <label for="status" class="form-label">Статус</label>
                        <select class="form-select" id="status" name="status" required>
                            <option value="В обработке">В обработке</option>
                            <option value="Оплачен">Оплачен</option>
                            <option value="Отменен">Отменен</option>
                        </select>
                    </div>
                    
                    <div class="d-flex gap-2">
                        <button type="submit" class="btn btn-primary">Создать</button>
                        <a href="/cgi-bin/admin.pl?action=orders" class="btn btn-secondary">Отмена</a>
                    </div>
                </form>
            </div>
        </div>
HTML

    display_admin_footer();
}

sub handle_view_order {
    my $page_title = "Просмотр заказа";
    display_admin_header($page_title);
    
    my $order_id = $cgi->param('id') || '';
    
    # Get order data
    my %orders_data;
    my ($user_email, $date, $amount, $status) = ('', '', '', '');
    
    if (tie %orders_data, 'DB_File', $orders_path, O_RDONLY, 0644, $DB_HASH) {
        if (exists $orders_data{$order_id}) {
            ($user_email, $date, $amount, $status) = split(':::', $orders_data{$order_id});
        }
        untie %orders_data;
    }
    
    # Get user data
    my %users_data;
    my $user_name = '';
    
    if (tie %users_data, 'DB_File', $db_path, O_RDONLY, 0644, $DB_HASH) {
        if (exists $users_data{$user_email}) {
            my ($password, $name, $role) = split(':::', $users_data{$user_email});
            $user_name = $name;
        }
        untie %users_data;
    }
    
    print <<HTML;
        <div class="card">
            <div class="card-header">
                <h5 class="mb-0">Информация о заказе</h5>
            </div>
            <div class="card-body">
                <div class="row mb-3">
                    <div class="col-sm-3 text-muted">Номер заказа:</div>
                    <div class="col-sm-9">$order_id</div>
                </div>
                
                <div class="row mb-3">
                    <div class="col-sm-3 text-muted">Пользователь:</div>
                    <div class="col-sm-9">$user_name ($user_email)</div>
                </div>
                
                <div class="row mb-3">
                    <div class="col-sm-3 text-muted">Дата:</div>
                    <div class="col-sm-9">$date</div>
                </div>
                
                <div class="row mb-3">
                    <div class="col-sm-3 text-muted">Сумма:</div>
                    <div class="col-sm-9">$amount ₽</div>
                </div>
                
                <div class="row mb-3">
                    <div class="col-sm-3 text-muted">Статус:</div>
                    <div class="col-sm-9">
                        <span class="badge bg-success">$status</span>
                    </div>
                </div>
                
                <div class="d-flex gap-2">
                    <a href="/cgi-bin/admin.pl?action=orders" class="btn btn-secondary">Назад к списку</a>
                </div>
            </div>
        </div>
HTML

    display_admin_footer();
}