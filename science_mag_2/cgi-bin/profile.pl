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

# Check if user is logged in
my $session_cookie = $cgi->cookie('session') || '';
my ($user_email, $user_name, $user_role) = check_session($session_cookie);

if (!$user_email) {
    # Not logged in, use HTTP redirect
    print $cgi->redirect(-uri => '/cgi-bin/login.pl');
    exit;
}

# Handle actions
my $action = $cgi->param('action') || 'display_profile';

if ($action eq 'update_profile') {
    update_profile();
} elsif ($action eq 'change_password') {
    change_password();
} elsif ($action eq 'logout') {
    logout();
} elsif ($action eq 'delete_order') {
    delete_order();
} else {
    display_profile();
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

# Function to get user orders
sub get_user_orders {
    my $email = shift;
    my @orders;
    
    # Check if orders database exists
    if (-e $orders_path) {
        my %orders_db;
        if (tie %orders_db, 'DB_File', $orders_path, O_RDONLY, 0644, $DB_HASH) {
            # Debug: Write all orders to a log file
            open my $debug_log, '>>', '/tmp/profile_debug.log';
            print $debug_log "Looking for orders for user: $email\n";
            print $debug_log "All orders in database:\n";
            
            # Query orders by user email from database
            foreach my $order_id (keys %orders_db) {
                print $debug_log "Order ID: $order_id, Data: " . $orders_db{$order_id} . "\n";
                
                my ($order_email, $date, $amount, $status) = split(':::', $orders_db{$order_id});
                print $debug_log "  Parsed: email=$order_email, date=$date, amount=$amount, status=$status\n";
                
                # Check for email match (also consider admin can see all orders)
                if ($order_email eq $email || ($user_role eq 'admin')) {
                    push @orders, [$order_id, $date, $amount, $status];
                    print $debug_log "  MATCHED - adding to results (email match or admin access)\n";
                } else {
                    print $debug_log "  Did NOT match user email\n";
                }
            }
            
            close $debug_log;
            untie %orders_db;
        }
    }
    
    return @orders;
}

# Function to get user articles
sub get_user_articles {
    my $email = shift;
    my @articles;
    
    # Check if articles database exists
    if (-e $articles_path) {
        my %articles_db;
        if (tie %articles_db, 'DB_File', $articles_path, O_RDONLY, 0644, $DB_HASH) {
            foreach my $article_id (keys %articles_db) {
                my ($title, $authors, $date, $status, $abstract) = split(':::', $articles_db{$article_id});

                if ($authors =~ /$user_email/i || $authors =~ /$user_name/i) {
                    push @articles, [$article_id, $title, $authors, $date, $status];
                }
            }
            
            untie %articles_db;
        }
    }
    
    return @articles;
}

# Function to display profile
sub display_profile {
    # Get user orders
    my @orders = get_user_orders($user_email);
    
    # Get user articles
    my @articles = get_user_articles($user_email);
    
    # Print header here inside the display function
    print $cgi->header(-type => 'text/html', -charset => 'UTF-8');

    print <<HTML;
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Личный кабинет | Научный журнал</title>
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
                                <li><a class="dropdown-item active" href="/cgi-bin/profile.pl">Личный кабинет</a></li>
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
                <li class="breadcrumb-item active" aria-current="page">Личный кабинет</li>
            </ol>
        </nav>
        
        <div class="profile-header">
            <div class="container">
                <div class="row align-items-center">
                    <div class="col-md-8">
                        <h1>Личный кабинет</h1>
                        <p class="lead">Добро пожаловать, $user_name!</p>
                    </div>
                    <div class="col-md-4 text-md-end">
                        <span class="badge bg-primary">$user_role</span>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="row">
            <div class="col-md-3 mb-4">
                <div class="card">
                    <div class="card-header">
                        <h5 class="mb-0">Навигация</h5>
                    </div>
                    <div class="list-group list-group-flush">
                        <a href="#profile" class="list-group-item list-group-item-action active" data-bs-toggle="list">Профиль</a>
                        <a href="#orders" class="list-group-item list-group-item-action" data-bs-toggle="list">История заказов</a>
                        <a href="#password" class="list-group-item list-group-item-action" data-bs-toggle="list">Сменить пароль</a>
                        <a href="#articles" class="list-group-item list-group-item-action" data-bs-toggle="list">Мои статьи</a>
                    </div>
                </div>
            </div>
            <div class="col-md-9">
                <div class="tab-content">
                    <div class="tab-pane fade show active" id="profile">
                        <div class="card">
                            <div class="card-header d-flex justify-content-between align-items-center">
                                <h5 class="mb-0">Профиль пользователя</h5>
                                <button class="btn btn-sm btn-primary" id="editProfileBtn">Редактировать</button>
                            </div>
                            <div class="card-body">
                                <form method="post" action="/cgi-bin/profile.pl" id="profileForm">
                                    <input type="hidden" name="action" value="update_profile">
                                    <div class="mb-3">
                                        <label for="profileName" class="form-label">Имя</label>
                                        <input type="text" class="form-control" id="profileName" name="name" value="$user_name" disabled>
                                    </div>
                                    <div class="mb-3">
                                        <label for="profileEmail" class="form-label">Email</label>
                                        <input type="email" class="form-control" id="profileEmail" value="$user_email" disabled readonly>
                                    </div>
                                    <div class="mb-3">
                                        <label for="profileRole" class="form-label">Роль</label>
                                        <input type="text" class="form-control" id="profileRole" value="$user_role" disabled readonly>
                                    </div>
                                    <button type="submit" class="btn btn-primary" style="display: none;" id="saveProfileBtn">Сохранить</button>
                                    <button type="button" class="btn btn-secondary" style="display: none;" id="cancelEditBtn">Отмена</button>
                                </form>
                            </div>
                        </div>
                    </div>
                    <div class="tab-pane fade" id="orders">
                        <div class="card">
                            <div class="card-header">
                                <h5 class="mb-0">История заказов</h5>
                            </div>
                            <div class="card-body">
HTML

    if (@orders) {
        print <<HTML;
                                <div class="table-responsive">
                                    <table class="table table-striped">
                                        <thead>
                                            <tr>
                                                <th>№ заказа</th>
                                                <th>Дата</th>
                                                <th>Сумма</th>
                                                <th>Статус</th>
                                                <th>Действия</th>
                                            </tr>
                                        </thead>
                                        <tbody>
HTML

        foreach my $order (@orders) {
            my ($order_id, $date, $amount, $status) = @$order;
            print <<HTML;
                                            <tr>
                                                <td>$order_id</td>
                                                <td>$date</td>
                                                <td>$amount ₽</td>
                                                <td><span class="badge bg-success">$status</span></td>
                                                <td>
                                                    <a href="/cgi-bin/order.pl?id=$order_id" class="btn btn-sm btn-outline-primary">Подробнее</a>
                                                    <a href="/cgi-bin/profile.pl?action=delete_order&id=$order_id" class="btn btn-sm btn-outline-danger ms-1" 
                                                        onclick="return confirm('Вы уверены, что хотите удалить этот заказ?')">
                                                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-x" viewBox="0 0 16 16">
                                                            <path d="M4.646 4.646a.5.5 0 0 1 .708 0L8 7.293l2.646-2.647a.5.5 0 0 1 .708.708L8.707 8l2.647 2.646a.5.5 0 0 1-.708.708L8 8.707l-2.646 2.647a.5.5 0 0 1-.708-.708L7.293 8 4.646 5.354a.5.5 0 0 1 0-.708z"/>
                                                        </svg>
                                                    </a>
                                                </td>
                                            </tr>
HTML
        }

        print <<HTML;
                                        </tbody>
                                    </table>
                                </div>
HTML
    } else {
        print <<HTML;
                                <div class="alert alert-info">
                                    У вас пока нет заказов. <a href="/issues.html" class="alert-link">Перейдите к выпускам</a>, чтобы сделать заказ.
                                </div>
HTML
    }

    print <<HTML;
                            </div>
                        </div>
                    </div>
                    <div class="tab-pane fade" id="password">
                        <div class="card">
                            <div class="card-header">
                                <h5 class="mb-0">Сменить пароль</h5>
                            </div>
                            <div class="card-body">
                                <form method="post" action="/cgi-bin/profile.pl">
                                    <input type="hidden" name="action" value="change_password">
                                    <div class="mb-3">
                                        <label for="currentPassword" class="form-label">Текущий пароль</label>
                                        <input type="password" class="form-control" id="currentPassword" name="current_password" required>
                                    </div>
                                    <div class="mb-3">
                                        <label for="newPassword" class="form-label">Новый пароль</label>
                                        <input type="password" class="form-control" id="newPassword" name="new_password" required>
                                    </div>
                                    <div class="mb-3">
                                        <label for="confirmPassword" class="form-label">Подтверждение нового пароля</label>
                                        <input type="password" class="form-control" id="confirmPassword" name="confirm_password" required>
                                    </div>
                                    <button type="submit" class="btn btn-primary">Сменить пароль</button>
                                </form>
                            </div>
                        </div>
                    </div>
                    <div class="tab-pane fade" id="articles">
                        <div class="card">
                            <div class="card-header d-flex justify-content-between align-items-center">
                                <h5 class="mb-0">Мои статьи</h5>
                                <a href="/cgi-bin/submit_article.pl" class="btn btn-sm btn-primary">
                                    <i class="bi bi-plus-circle"></i> Отправить новую статью
                                </a>
                            </div>
                            <div class="card-body">
HTML

    if (@articles) {
        print <<HTML;
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

        foreach my $article (@articles) {
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
                                                    <a href="/cgi-bin/view_article.pl?id=$article_id" class="btn btn-sm btn-outline-primary">Просмотр</a>
                                                </td>
                                            </tr>
HTML
        }

        print <<HTML;
                                        </tbody>
                                    </table>
                                </div>
HTML
    } else {
        print <<HTML;
                                <p>У вас пока нет отправленных статей.</p>
                                <div class="alert alert-info">
                                    <p class="mb-0">Чтобы отправить новую статью на рассмотрение, нажмите кнопку "Отправить новую статью".</p>
                                </div>
HTML
    }

    print <<HTML;
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
            // Edit profile functionality
            const editProfileBtn = document.getElementById('editProfileBtn');
            const saveProfileBtn = document.getElementById('saveProfileBtn');
            const cancelEditBtn = document.getElementById('cancelEditBtn');
            const profileName = document.getElementById('profileName');
            
            let originalName = profileName.value;
            
            editProfileBtn.addEventListener('click', function() {
                // Enable editing
                profileName.disabled = false;
                editProfileBtn.style.display = 'none';
                saveProfileBtn.style.display = 'inline-block';
                cancelEditBtn.style.display = 'inline-block';
                profileName.focus();
            });
            
            cancelEditBtn.addEventListener('click', function() {
                // Cancel editing
                profileName.disabled = true;
                profileName.value = originalName;
                editProfileBtn.style.display = 'inline-block';
                saveProfileBtn.style.display = 'none';
                cancelEditBtn.style.display = 'none';
            });
        });
    </script>
</body>
</html>
HTML
}

# Function to update profile
sub update_profile {
    my $new_name = $cgi->param('name');
    
    # Simple validation
    if (!$new_name) {
        display_profile();
        return;
    }
    
    # Convert email to match the escaped format in the database
    my $db_email = $user_email;
    $db_email =~ s/@/\\@/g;
    
    # Update user name in database
    my %users;
    if (tie %users, 'DB_File', $db_path, O_RDWR, 0644, $DB_HASH) {
        if (exists $users{$db_email}) {
            my ($password, $name, $role) = split(':::', $users{$db_email});
            
            # Update name
            $users{$db_email} = "$password:::$new_name:::$role";
            
            # Update user_name for display
            $user_name = $new_name;
        }
        untie %users;
    }
    
    display_profile();
}

# Function to change password
sub change_password {
    my $current_password = $cgi->param('current_password');
    my $new_password = $cgi->param('new_password');
    my $confirm_password = $cgi->param('confirm_password');
    
    # Simple validation
    if (!$current_password || !$new_password || !$confirm_password) {
        display_profile();
        return;
    }
    
    if ($new_password ne $confirm_password) {
        display_profile();
        return;
    }
    
    # Convert email to match the escaped format in the database
    my $db_email = $user_email;
    $db_email =~ s/@/\\@/g;
    
    # Update password in database
    my %users;
    if (tie %users, 'DB_File', $db_path, O_RDWR, 0644, $DB_HASH) {
        if (exists $users{$db_email}) {
            my ($stored_password, $name, $role) = split(':::', $users{$db_email});
            
            # Verify current password as plaintext
            if ($stored_password eq $current_password) {
                # Update password with new plaintext password
                $users{$db_email} = "$new_password:::$name:::$role";
            }
        }
        untie %users;
    }
    
    display_profile();
}

# Function to logout
sub logout {
    # Delete session from database
    if ($session_cookie) {
        my %sessions;
        if (tie %sessions, 'DB_File', $sessions_path, O_RDWR, 0644, $DB_HASH) {
            delete $sessions{$session_cookie};
            untie %sessions;
        }
    }
    
    # Clear cookie
    my $cookie = $cgi->cookie(
        -name => 'session',
        -value => '',
        -expires => '-1d',
        -path => '/'
    );
    
    # Use HTTP redirect
    print $cgi->redirect(-uri => '/index.html', -cookie => $cookie);
}

# Function to delete an order
sub delete_order {
    my $order_id = $cgi->param('id') || '';
    
    # Debug log for deletion
    open my $log, '>>', '/tmp/profile_debug.log';
    print $log "Attempting to delete order ID: $order_id\n";
    
    # Validate user permission
    if (!$order_id) {
        print $log "No order ID provided\n";
        close $log;
        display_profile();
        return;
    }
    
    # Only admins or the order owner can delete
    my %orders;
    my $can_delete = 0;
    
    if (tie %orders, 'DB_File', $orders_path, O_RDWR, 0644, $DB_HASH) {
        if (exists $orders{$order_id}) {
            my ($order_email, $date, $amount, $status) = split(':::', $orders{$order_id});
            
            # Check if current user is owner or admin
            if ($user_role eq 'admin' || $order_email eq $user_email) {
                # Delete the order
                delete $orders{$order_id};
                print $log "Order deleted successfully\n";
                $can_delete = 1;
            } else {
                print $log "Permission denied: User $user_email cannot delete order for $order_email\n";
            }
        } else {
            print $log "Order not found\n";
        }
        untie %orders;
    } else {
        print $log "Failed to open orders database\n";
    }
    
    close $log;
    
    # Redirect back to profile page
    print $cgi->redirect(-uri => '/cgi-bin/profile.pl');
} 