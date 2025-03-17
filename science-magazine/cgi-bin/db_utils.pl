#!/usr/bin/perl
package db_utils;

use strict;
use warnings;
use utf8;
use DB_File;
use Encode qw(decode encode);
use Digest::MD5 qw(md5_hex);
use POSIX qw(strftime);
use CGI::Carp qw(fatalsToBrowser);

# Пути к файлам базы данных
our $USERS_DB = "/usr/local/apache2/data/users.db";
our $ISSUES_DB = "/usr/local/apache2/data/issues.db";
our $ARTICLES_DB = "/usr/local/apache2/data/articles.db";
our $ORDERS_DB = "/usr/local/apache2/data/orders.db";
our $ORDER_DETAILS_DB = "/usr/local/apache2/data/order_details.db";
our $SUBMISSIONS_DB = "/usr/local/apache2/data/submissions.db";

# Функция для инициализации базы данных
sub init_database {
    # Создаем файлы БД, если они не существуют
    ensure_db_exists($USERS_DB);
    ensure_db_exists($ISSUES_DB);
    ensure_db_exists($ARTICLES_DB);
    ensure_db_exists($ORDERS_DB);
    ensure_db_exists($ORDER_DETAILS_DB);
    ensure_db_exists($SUBMISSIONS_DB);
    
    # Добавляем тестовые данные, если БД пустые
    add_test_data();
}

# Функция для создания файла БД, если он не существует
sub ensure_db_exists {
    my ($db_file) = @_;
    
    unless (-e $db_file) {
        my %db;
        tie %db, 'DB_File', $db_file, O_CREAT|O_RDWR, 0666, $DB_HASH
            or die "Не удалось создать $db_file: $!";
        untie %db;
    }
}

# Функция для кодирования строки в UTF-8
sub encode_utf8 {
    my ($str) = @_;
    return encode("UTF-8", $str);
}

# Функция для декодирования строки из UTF-8
sub decode_utf8 {
    my ($str) = @_;
    return decode("UTF-8", $str);
}

# Функция для добавления тестовых данных
sub add_test_data {
    # Добавляем тестового администратора, если нет пользователей
    my %users;
    tie %users, 'DB_File', $USERS_DB, O_RDWR, 0666, $DB_HASH
        or die "Не удалось открыть $USERS_DB: $!";
    
    if (!%users) {
        # Добавляем администратора
        my $admin_id = "1";
        my $admin_data = encode_utf8(join("|", 
            "admin",                                # логин
            md5_hex("admin123"),                    # пароль (хеш)
            "Администратор Системы",                # ФИО
            "admin\@example.com",                    # email
            "+7 (123) 456-78-90",                   # телефон
            "г. Москва, ул. Примерная, д. 1",       # адрес
            "admin",                                # роль
            strftime("%Y-%m-%d", localtime)         # дата регистрации
        ));
        $users{$admin_id} = $admin_data;
        
        # Добавляем редактора
        my $editor_id = "2";
        my $editor_data = encode_utf8(join("|", 
            "editor",                               # логин
            md5_hex("editor123"),                   # пароль (хеш)
            "Редактор Журнала",                     # ФИО
            "editor\@example.com",                   # email
            "+7 (123) 456-78-91",                   # телефон
            "г. Москва, ул. Научная, д. 2",         # адрес
            "editor",                               # роль
            strftime("%Y-%m-%d", localtime)         # дата регистрации
        ));
        $users{$editor_id} = $editor_data;
        
        # Добавляем обычного пользователя
        my $user_id = "3";
        my $user_data = encode_utf8(join("|", 
            "user",                                 # логин
            md5_hex("user123"),                     # пароль (хеш)
            "Иванов Иван Иванович",                 # ФИО
            "user\@example.com",                     # email
            "+7 (123) 456-78-92",                   # телефон
            "г. Санкт-Петербург, ул. Читательская, д. 3", # адрес
            "user",                                 # роль
            strftime("%Y-%m-%d", localtime)         # дата регистрации
        ));
        $users{$user_id} = $user_data;
    }
    untie %users;
    
    # Добавляем тестовые выпуски, если их нет
    my %issues;
    tie %issues, 'DB_File', $ISSUES_DB, O_RDWR, 0666, $DB_HASH
        or die "Не удалось открыть $ISSUES_DB: $!";
    
    if (!%issues) {
        # Добавляем три тестовых выпуска
        my $issue1_id = "1";
        my $issue1_data = encode_utf8(join("|", 
            "1",                                    # номер выпуска
            "2023",                                 # год издания
            "1",                                    # месяц издания
            "Информационные технологии",            # название выпуска
            "Специальный выпуск, посвященный современным исследованиям в области информационных технологий.", # описание
            "/images/issue-cover-placeholder.jpg",  # обложка
            "published",                            # статус
            "2023-01-15"                            # дата публикации
        ));
        $issues{$issue1_id} = $issue1_data;
        
        my $issue2_id = "2";
        my $issue2_data = encode_utf8(join("|", 
            "2",                                    # номер выпуска
            "2023",                                 # год издания
            "4",                                    # месяц издания
            "Междисциплинарные исследования",       # название выпуска
            "В этом выпуске представлены статьи по различным направлениям научных исследований.", # описание
            "/images/issue-cover-placeholder.jpg",  # обложка
            "published",                            # статус
            "2023-04-20"                            # дата публикации
        ));
        $issues{$issue2_id} = $issue2_data;
        
        my $issue3_id = "3";
        my $issue3_data = encode_utf8(join("|", 
            "3",                                    # номер выпуска
            "2023",                                 # год издания
            "7",                                    # месяц издания
            "Экология и устойчивое развитие",       # название выпуска
            "Тематический выпуск по проблемам экологии и устойчивого развития.", # описание
            "/images/issue-cover-placeholder.jpg",  # обложка
            "published",                            # статус
            "2023-07-10"                            # дата публикации
        ));
        $issues{$issue3_id} = $issue3_data;
    }
    untie %issues;
    
    # Добавляем тестовые статьи, если их нет
    my %articles;
    tie %articles, 'DB_File', $ARTICLES_DB, O_RDWR, 0666, $DB_HASH
        or die "Не удалось открыть $ARTICLES_DB: $!";
    
    if (!%articles) {
        # Добавляем статьи для первого выпуска
        my $article1_id = "1";
        my $article1_data = encode_utf8(join("|", 
            "1",                                    # ID выпуска
            "Искусственный интеллект в медицине",   # название статьи
            "Петров П.П., Сидоров С.С.",            # авторы
            "В статье рассматриваются современные подходы к применению искусственного интеллекта в медицинской диагностике и лечении.", # аннотация
            "Статья посвящена исследованию применения методов искусственного интеллекта в медицинской практике. Авторы анализируют существующие системы поддержки принятия решений, основанные на машинном обучении, и их эффективность в диагностике различных заболеваний. Особое внимание уделяется этическим аспектам использования ИИ в здравоохранении.", # полный текст
            "300",                                  # цена
            "published",                            # статус
            "2023-01-10"                            # дата публикации
        ));
        $articles{$article1_id} = $article1_data;
        
        my $article2_id = "2";
        my $article2_data = encode_utf8(join("|", 
            "1",                                    # ID выпуска
            "Квантовые вычисления: перспективы развития", # название статьи
            "Иванов И.И., Кузнецов К.К.",           # авторы
            "Статья представляет обзор современного состояния и перспектив развития квантовых вычислений.", # аннотация
            "В данной работе авторы рассматривают текущее состояние технологий квантовых вычислений, основные достижения и проблемы в этой области. Проводится сравнительный анализ различных подходов к созданию квантовых компьютеров, включая сверхпроводящие кубиты, ионные ловушки и фотонные системы. Авторы также обсуждают потенциальные применения квантовых вычислений в криптографии, моделировании материалов и оптимизации.", # полный текст
            "350",                                  # цена
            "published",                            # статус
            "2023-01-12"                            # дата публикации
        ));
        $articles{$article2_id} = $article2_data;
        
        # Добавляем статьи для второго выпуска
        my $article3_id = "3";
        my $article3_data = encode_utf8(join("|", 
            "2",                                    # ID выпуска
            "Нейробиология творчества",             # название статьи
            "Смирнова А.А., Викторов В.В.",           # авторы
            "Исследование нейробиологических основ творческого мышления и процессов генерации новых идей.", # аннотация
            "Статья посвящена изучению нейробиологических механизмов, лежащих в основе творческого мышления. Авторы анализируют результаты современных исследований с использованием функциональной магнитно-резонансной томографии (фМРТ) и электроэнцефалографии (ЭЭГ), которые позволяют наблюдать активность мозга в процессе решения творческих задач. Рассматриваются различия в активации мозговых структур у людей с высоким и низким уровнем креативности, а также влияние различных факторов на творческие способности.", # полный текст
            "280",                                  # цена
            "published",                            # статус
            "2023-04-15"                            # дата публикации
        ));
        $articles{$article3_id} = $article3_data;
        
        # Добавляем статьи для третьего выпуска
        my $article4_id = "4";
        my $article4_data = encode_utf8(join("|", 
            "3",                                    # ID выпуска
            "Устойчивое развитие городских экосистем", # название статьи
            "Николаев Н.Н., Федорова Е.Е.",         # авторы
            "Анализ современных подходов к обеспечению устойчивого развития городских экосистем в условиях климатических изменений.", # аннотация
            "В статье рассматриваются проблемы и перспективы устойчивого развития городских экосистем в контексте глобальных климатических изменений. Авторы анализируют различные стратегии адаптации городской среды к изменениям климата, включая создание зеленой инфраструктуры, внедрение энергоэффективных технологий и развитие устойчивых транспортных систем. Особое внимание уделяется интеграции природных элементов в городскую среду и их роли в повышении устойчивости городских экосистем.", # полный текст
            "320",                                  # цена
            "published",                            # статус
            "2023-07-05"                            # дата публикации
        ));
        $articles{$article4_id} = $article4_data;
    }
    untie %articles;
}

# Функция для получения следующего ID
sub get_next_id {
    my ($db_file) = @_;
    
    my %db;
    tie %db, 'DB_File', $db_file, O_RDWR, 0666, $DB_HASH
        or die "Не удалось открыть $db_file: $!";
    
    my $max_id = 0;
    foreach my $id (keys %db) {
        $max_id = $id if $id > $max_id;
    }
    
    untie %db;
    return $max_id + 1;
}

# Функция для получения пользователя по логину
sub get_user_by_login {
    my ($login) = @_;
    
    my %users;
    tie %users, 'DB_File', $USERS_DB, O_RDWR, 0666, $DB_HASH
        or die "Не удалось открыть $USERS_DB: $!";
    
    my $user;
    foreach my $id (keys %users) {
        my @data = split(/\|/, decode_utf8($users{$id}));
        if ($data[0] eq $login) {
            $user = {
                id => $id,
                login => $data[0],
                password => $data[1],
                full_name => $data[2],
                email => $data[3],
                phone => $data[4],
                address => $data[5],
                role => $data[6],
                registration_date => $data[7]
            };
            last;
        }
    }
    
    untie %users;
    return $user;
}

# Функция для получения пользователя по ID
sub get_user_by_id {
    my ($id) = @_;
    
    my %users;
    tie %users, 'DB_File', $USERS_DB, O_RDWR, 0666, $DB_HASH
        or die "Не удалось открыть $USERS_DB: $!";
    
    my $user;
    if (exists $users{$id}) {
        my @data = split(/\|/, decode_utf8($users{$id}));
        $user = {
            id => $id,
            login => $data[0],
            password => $data[1],
            full_name => $data[2],
            email => $data[3],
            phone => $data[4],
            address => $data[5],
            role => $data[6],
            registration_date => $data[7]
        };
    }
    
    untie %users;
    return $user;
}

# Функция для получения всех выпусков
sub get_all_issues {
    my %issues;
    tie %issues, 'DB_File', $ISSUES_DB, O_RDWR, 0666, $DB_HASH
        or die "Не удалось открыть $ISSUES_DB: $!";
    
    my @result;
    foreach my $id (keys %issues) {
        my @data = split(/\|/, decode_utf8($issues{$id}));
        push @result, {
            id => $id,
            number => $data[0],
            year => $data[1],
            month => $data[2],
            title => $data[3],
            description => $data[4],
            cover => $data[5],
            status => $data[6],
            publication_date => $data[7]
        };
    }
    
    untie %issues;
    return sort { $b->{year} <=> $a->{year} || $b->{month} <=> $a->{month} } @result;
}

# Функция для получения выпуска по ID
sub get_issue_by_id {
    my ($id) = @_;
    
    my %issues;
    tie %issues, 'DB_File', $ISSUES_DB, O_RDWR, 0666, $DB_HASH
        or die "Не удалось открыть $ISSUES_DB: $!";
    
    my $issue;
    if (exists $issues{$id}) {
        my @data = split(/\|/, decode_utf8($issues{$id}));
        $issue = {
            id => $id,
            number => $data[0],
            year => $data[1],
            month => $data[2],
            title => $data[3],
            description => $data[4],
            cover => $data[5],
            status => $data[6],
            publication_date => $data[7]
        };
    }
    
    untie %issues;
    return $issue;
}

# Функция для получения статей по ID выпуска
sub get_articles_by_issue_id {
    my ($issue_id) = @_;
    
    my %articles;
    tie %articles, 'DB_File', $ARTICLES_DB, O_RDWR, 0666, $DB_HASH
        or die "Не удалось открыть $ARTICLES_DB: $!";
    
    my @result;
    foreach my $id (keys %articles) {
        my @data = split(/\|/, decode_utf8($articles{$id}));
        if ($data[0] eq $issue_id) {
            push @result, {
                id => $id,
                issue_id => $data[0],
                title => $data[1],
                authors => $data[2],
                abstract => $data[3],
                content => $data[4],
                price => $data[5],
                status => $data[6],
                publication_date => $data[7]
            };
        }
    }
    
    untie %articles;
    return @result;
}

# Функция для получения статьи по ID
sub get_article_by_id {
    my ($id) = @_;
    
    my %articles;
    tie %articles, 'DB_File', $ARTICLES_DB, O_RDWR, 0666, $DB_HASH
        or die "Не удалось открыть $ARTICLES_DB: $!";
    
    my $article;
    if (exists $articles{$id}) {
        my @data = split(/\|/, decode_utf8($articles{$id}));
        $article = {
            id => $id,
            issue_id => $data[0],
            title => $data[1],
            authors => $data[2],
            abstract => $data[3],
            content => $data[4],
            price => $data[5],
            status => $data[6],
            publication_date => $data[7]
        };
    }
    
    untie %articles;
    return $article;
}

# Функция для создания заказа
sub create_order {
    my ($user_id, $total, $status, $payment_method, $receipt_number) = @_;
    
    my %orders;
    tie %orders, 'DB_File', $ORDERS_DB, O_RDWR, 0666, $DB_HASH
        or die "Не удалось открыть $ORDERS_DB: $!";
    
    my $order_id = get_next_id($ORDERS_DB);
    my $order_data = encode_utf8(join("|", 
        $user_id,
        $total,
        $status,
        $payment_method,
        $receipt_number,
        strftime("%Y-%m-%d %H:%M:%S", localtime)
    ));
    
    $orders{$order_id} = $order_data;
    untie %orders;
    
    return $order_id;
}

# Функция для добавления детали заказа
sub add_order_detail {
    my ($order_id, $article_id, $quantity, $price) = @_;
    
    my %order_details;
    tie %order_details, 'DB_File', $ORDER_DETAILS_DB, O_RDWR, 0666, $DB_HASH
        or die "Не удалось открыть $ORDER_DETAILS_DB: $!";
    
    my $detail_id = get_next_id($ORDER_DETAILS_DB);
    my $detail_data = encode_utf8(join("|", 
        $order_id,
        $article_id,
        $quantity,
        $price
    ));
    
    $order_details{$detail_id} = $detail_data;
    untie %order_details;
    
    return $detail_id;
}

# Функция для получения всех рукописей
sub get_all_submissions {
    my %submissions;
    tie %submissions, 'DB_File', $SUBMISSIONS_DB, O_RDWR, 0666, $DB_HASH
        or die "Не удалось открыть $SUBMISSIONS_DB: $!";
    
    my @result;
    foreach my $id (keys %submissions) {
        my @data = split(/\|/, decode_utf8($submissions{$id}));
        push @result, {
            id => $id,
            user_id => $data[0],
            title => $data[1],
            authors => $data[2],
            abstract => $data[3],
            content => $data[4],
            author_comments => $data[5],
            status => $data[6],
            submission_date => $data[7],
            reviewer_comments => $data[8]
        };
    }
    
    untie %submissions;
    return @result;
}

# Функция для получения рукописи по ID
sub get_submission_by_id {
    my ($id) = @_;
    
    my %submissions;
    tie %submissions, 'DB_File', $SUBMISSIONS_DB, O_RDWR, 0666, $DB_HASH
        or die "Не удалось открыть $SUBMISSIONS_DB: $!";
    
    my $submission;
    if (exists $submissions{$id}) {
        my @data = split(/\|/, decode_utf8($submissions{$id}));
        $submission = {
            id => $id,
            user_id => $data[0],
            title => $data[1],
            authors => $data[2],
            abstract => $data[3],
            content => $data[4],
            author_comments => $data[5],
            status => $data[6],
            submission_date => $data[7],
            reviewer_comments => $data[8]
        };
    }
    
    untie %submissions;
    return $submission;
}

# Функция для обновления статуса рукописи
sub update_submission_status {
    my ($id, $status, $reviewer_comments) = @_;
    
    my %submissions;
    tie %submissions, 'DB_File', $SUBMISSIONS_DB, O_RDWR, 0666, $DB_HASH
        or die "Не удалось открыть $SUBMISSIONS_DB: $!";
    
    if (exists $submissions{$id}) {
        my @data = split(/\|/, decode_utf8($submissions{$id}));
        $data[6] = $status;
        $data[8] = $reviewer_comments if defined $reviewer_comments;
        
        $submissions{$id} = encode_utf8(join("|", @data));
    }
    
    untie %submissions;
    return 1;
}

# Функция для создания новой рукописи
sub create_submission {
    my ($user_id, $title, $authors, $abstract, $content, $author_comments) = @_;
    
    my %submissions;
    tie %submissions, 'DB_File', $SUBMISSIONS_DB, O_RDWR, 0666, $DB_HASH
        or die "Не удалось открыть $SUBMISSIONS_DB: $!";
    
    my $submission_id = get_next_id($SUBMISSIONS_DB);
    my $submission_data = encode_utf8(join("|", 
        $user_id,
        $title,
        $authors,
        $abstract,
        $content,
        $author_comments,
        "new",  # начальный статус
        strftime("%Y-%m-%d", localtime),
        ""  # комментарии рецензента (пусто изначально)
    ));
    
    $submissions{$submission_id} = $submission_data;
    untie %submissions;
    
    return $submission_id;
}

# Экспортируем функции
sub import {
    my $pkg = shift;
    my $callpkg = caller;
    
    no strict 'refs';
    *{$callpkg . '::' . $_} = \&{$pkg . '::' . $_} for @_;
}

1; 