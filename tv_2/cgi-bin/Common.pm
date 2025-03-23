#!/usr/bin/perl
package Common;

use strict;
use warnings;
use utf8;
use DB_File;
use Encode qw(decode encode);
use POSIX qw(strftime);

# Пути к файлам базы данных
our $data_dir = "/usr/local/apache2/data";
our $channels_db = "$data_dir/channels.db";
our $programs_db = "$data_dir/programs.db";
our $categories_db = "$data_dir/categories.db";
our $schedule_db = "$data_dir/schedule.db";

# Функция для кодирования данных в JSON
sub encode_json {
    my ($data) = @_;
    my $json = '';
    
    if (ref($data) eq 'HASH') {
        $json = '{';
        my @pairs;
        foreach my $key (keys %$data) {
            my $value = $data->{$key};
            if (!ref($value)) {
                push @pairs, qq("$key":"$value");
            } else {
                push @pairs, qq("$key":) . encode_json($value);
            }
        }
        $json .= join(',', @pairs);
        $json .= '}';
    } elsif (ref($data) eq 'ARRAY') {
        $json = '[';
        my @items;
        foreach my $item (@$data) {
            if (!ref($item)) {
                push @items, qq("$item");
            } else {
                push @items, encode_json($item);
            }
        }
        $json .= join(',', @items);
        $json .= ']';
    } else {
        $json = qq("$data");
    }
    
    return $json;
}

# Функция для декодирования JSON
sub decode_json {
    my ($json) = @_;
    
    if ($json =~ /^\{(.*)\}$/) {
        my $content = $1;
        my %result;
        
        while ($content =~ /"([^"]+)":"([^"]+)"/g) {
            $result{$1} = $2;
        }
        
        return \%result;
    }
    
    return {};
}

# Функция для создания базы данных, если она не существует
sub ensure_db_exists {
    unless (-d $data_dir) {
        mkdir $data_dir or die "Не удалось создать директорию $data_dir: $!";
    }
    
    init_channels_db();
    init_categories_db();
    init_programs_db();
    init_schedule_db();
}

sub init_channels_db {
    unless (-e $channels_db) {
        my %channels;
        tie %channels, 'DB_File', $channels_db, O_CREAT|O_RDWR, 0666, $DB_HASH
            or die "Не удалось создать $channels_db: $!";
        
        my @initial_channels = (
            {
                id => 1,
                name => 'Первый канал',
                logo => '/img/channel1.png',
                description => 'Первый канал - ведущий телеканал России с широким спектром программ.'
            },
            {
                id => 2,
                name => 'Россия 1',
                logo => '/img/channel2.png',
                description => 'Россия 1 - общероссийский телеканал с информационными, развлекательными и познавательными программами.'
            },
            {
                id => 3,
                name => 'НТВ',
                logo => '/img/channel3.png',
                description => 'НТВ - российский телеканал с фокусом на новости, сериалы и развлекательные шоу.'
            },
            {
                id => 4,
                name => 'ТНТ',
                logo => '/img/channel4.png',
                description => 'ТНТ - развлекательный телеканал с комедийными шоу и сериалами.'
            },
            {
                id => 5,
                name => 'СТС',
                logo => '/img/channel5.png',
                description => 'СТС - развлекательный телеканал для всей семьи.'
            }
        );
        
        foreach my $channel (@initial_channels) {
            my $id = $channel->{id};
            my $data = encode_json($channel);
            $channels{$id} = encode('UTF-8', $data);
        }
        
        untie %channels;
    }
}

sub init_categories_db {
   unless (-e $categories_db) {
        my %categories;
        tie %categories, 'DB_File', $categories_db, O_CREAT|O_RDWR, 0666, $DB_HASH
            or die "Не удалось создать $categories_db: $!";
        
        my @initial_categories = (
            {
                id => 1,
                name => 'Фильмы',
                description => 'Художественные фильмы различных жанров',
                icon => '/img/category_film.png'
            },
            {
                id => 2,
                name => 'Сериалы',
                description => 'Многосерийные телевизионные фильмы',
                icon => '/img/category_series.png'
            },
            {
                id => 3,
                name => 'Новости',
                description => 'Информационные программы и новостные выпуски',
                icon => '/img/category_news.png'
            },
            {
                id => 4,
                name => 'Спорт',
                description => 'Спортивные трансляции и обзоры',
                icon => '/img/category_sport.png'
            },
            {
                id => 5,
                name => 'Детские',
                description => 'Программы для детей',
                icon => '/img/category_kids.png'
            },
            {
                id => 6,
                name => 'Развлекательные',
                description => 'Развлекательные шоу и программы',
                icon => '/img/category_entertainment.png'
            }
        );
        
        foreach my $category (@initial_categories) {
            my $id = $category->{id};
            my $data = encode_json($category);
            $categories{$id} = encode('UTF-8', $data);
        }
        
        untie %categories;
    }
}

sub init_programs_db {
    unless (-e $programs_db) {
        my %programs;
        tie %programs, 'DB_File', $programs_db, O_CREAT|O_RDWR, 0666, $DB_HASH
            or die "Не удалось создать $programs_db: $!";
        
        my @initial_programs = (
            {
                id => 1,
                name => 'Новости',
                description => 'Последние новости и события в стране и мире',
                category_id => 3,
                duration => 30
            },
            {
                id => 2,
                name => 'Вечерний Ургант',
                description => 'Вечернее развлекательное шоу с Иваном Ургантом',
                category_id => 6,
                duration => 60
            },
            {
                id => 3,
                name => 'Время',
                description => 'Информационная программа',
                category_id => 3,
                duration => 45
            },
            {
                id => 4,
                name => 'Футбол. Чемпионат России',
                description => 'Прямая трансляция матча чемпионата России по футболу',
                category_id => 4,
                duration => 120
            },
            {
                id => 5,
                name => 'Маша и Медведь',
                description => 'Мультсериал о приключениях девочки Маши и Медведя',
                category_id => 5,
                duration => 15
            },
            {
                id => 6,
                name => 'Шерлок Холмс',
                description => 'Детективный сериал о знаменитом сыщике',
                category_id => 2,
                duration => 90
            },
            {
                id => 7,
                name => 'Титаник',
                description => 'Художественный фильм о крушении легендарного лайнера',
                category_id => 1,
                duration => 180
            },
            {
                id => 8,
                name => 'Смешарики',
                description => 'Мультсериал для детей',
                category_id => 5,
                duration => 20
            },
            {
                id => 9,
                name => 'Что? Где? Когда?',
                description => 'Интеллектуальная игра',
                category_id => 6,
                duration => 90
            },
            {
                id => 10,
                name => 'Хоккей. КХЛ',
                description => 'Трансляция матча Континентальной хоккейной лиги',
                category_id => 4,
                duration => 150
            }
        );
        
        foreach my $program (@initial_programs) {
            my $id = $program->{id};
            my $data = encode_json($program);
            $programs{$id} = encode('UTF-8', $data);
        }
        
        untie %programs;
    }
}

sub init_schedule_db {
     unless (-e $schedule_db) {
        my %schedule;
        tie %schedule, 'DB_File', $schedule_db, O_CREAT|O_RDWR, 0666, $DB_HASH
            or die "Не удалось создать $schedule_db: $!";
        
        my @initial_schedule = (
            {
                id => 1,
                channel_id => 1,
                program_id => 1,
                date => strftime("%Y-%m-%d", localtime),
                start_time => '08:00',
                end_time => '08:30'
            },
            {
                id => 2,
                channel_id => 1,
                program_id => 3,
                date => strftime("%Y-%m-%d", localtime),
                start_time => '21:00',
                end_time => '21:45'
            },
            {
                id => 3,
                channel_id => 1,
                program_id => 2,
                date => strftime("%Y-%m-%d", localtime),
                start_time => '23:30',
                end_time => '00:30'
            },
            {
                id => 4,
                channel_id => 2,
                program_id => 1,
                date => strftime("%Y-%m-%d", localtime),
                start_time => '09:00',
                end_time => '09:30'
            },
            {
                id => 5,
                channel_id => 2,
                program_id => 7,
                date => strftime("%Y-%m-%d", localtime),
                start_time => '20:00',
                end_time => '23:00'
            },
            {
                id => 6,
                channel_id => 3,
                program_id => 1,
                date => strftime("%Y-%m-%d", localtime),
                start_time => '10:00',
                end_time => '10:30'
            },
            {
                id => 7,
                channel_id => 3,
                program_id => 4,
                date => strftime("%Y-%m-%d", localtime),
                start_time => '18:00',
                end_time => '20:00'
            },
            {
                id => 8,
                channel_id => 4,
                program_id => 6,
                date => strftime("%Y-%m-%d", localtime),
                start_time => '19:00',
                end_time => '20:30'
            },
            {
                id => 9,
                channel_id => 4,
                program_id => 9,
                date => strftime("%Y-%m-%d", localtime),
                start_time => '22:00',
                end_time => '23:30'
            },
            {
                id => 10,
                channel_id => 5,
                program_id => 5,
                date => strftime("%Y-%m-%d", localtime),
                start_time => '07:00',
                end_time => '07:15'
            },
            {
                id => 11,
                channel_id => 5,
                program_id => 8,
                date => strftime("%Y-%m-%d", localtime),
                start_time => '07:30',
                end_time => '07:50'
            },
            {
                id => 12,
                channel_id => 5,
                program_id => 10,
                date => strftime("%Y-%m-%d", localtime),
                start_time => '19:30',
                end_time => '22:00'
            }
        );
        
        foreach my $item (@initial_schedule) {
            my $id = $item->{id};
            my $data = encode_json($item);
            $schedule{$id} = encode('UTF-8', $data);
        }
        
        untie %schedule;
    }
}

# Common functions to get data from databases
sub get_all_channels {
    my ($search) = @_;
    my %channels;
    my @channel_list;
    
    tie %channels, 'DB_File', $channels_db, O_RDONLY, 0666, $DB_HASH
        or die "Не удалось открыть $channels_db: $!";
    
    foreach my $id (sort keys %channels) {
        my $data = decode('UTF-8', $channels{$id});
        my $channel = decode_json($data);
        $channel->{id} = $id;
        
        # Фильтрация по поисковому запросу
        if (!$search || $channel->{name} =~ /$search/i) {
            push @channel_list, $channel;
        }
    }
    
    untie %channels;
    
    return \@channel_list;
}

# Common HTML header function
sub html_header {
    my ($title, $active_page) = @_;
    
    return <<HTML;
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$title - ТВ Программа</title>
    <link rel="stylesheet" href="/css/style.css">
    <script src="/js/script.js"></script>
</head>
<body>
    <div class="container">
        <header>
            <h1>ТВ Программа</h1>
            <nav>
                <ul>
                    <li><a href="/index.html" class="@{[$active_page eq 'home' ? 'active' : '']}">Главная</a></li>
                    <li><a href="/cgi-bin/channels.pl" class="@{[$active_page eq 'channels' ? 'active' : '']}">Телеканалы</a></li>
                    <li><a href="/cgi-bin/programs.pl" class="@{[$active_page eq 'programs' ? 'active' : '']}">Программа передач</a></li>
                    <li><a href="/cgi-bin/admin.pl" class="@{[$active_page eq 'admin' ? 'active' : '']}">Управление</a></li>
                    <li><a href="/about.html" class="@{[$active_page eq 'about' ? 'active' : '']}">О проекте</a></li>
                </ul>
            </nav>
        </header>
HTML
}

# Common HTML footer function
sub html_footer {
    return <<HTML;
        <footer>
            <div class="footer-content">
                <div class="footer-section">
                    <h3>ТВ Программа</h3>
                    <p>Сервис для просмотра телепрограммы</p>
                </div>
                <div class="footer-section">
                    <h3>Навигация</h3>
                    <ul>
                        <li><a href="/index.html">Главная</a></li>
                        <li><a href="/cgi-bin/channels.pl">Телеканалы</a></li>
                        <li><a href="/cgi-bin/programs.pl">Программа передач</a></li>
                        <li><a href="/about.html">О проекте</a></li>
                    </ul>
                </div>
                <div class="footer-section">
                    <h3>Контакты</h3>
                    <p>Email: info\@tvprogram.ru</p>
                    <p>Телефон: +7 (123) 456-78-90</p>
                </div>
            </div>
            <div class="footer-bottom">
                <p>&copy; 2023 ТВ Программа. Все права защищены.</p>
            </div>
        </footer>
        
        <div class="scroll-buttons">
            <button onclick="scrollToTop()" class="scroll-top" title="Наверх">↑</button>
            <button onclick="scrollToBottom()" class="scroll-bottom" title="Вниз">↓</button>
        </div>
    </div>
</body>
</html>
HTML
}

1; # Return true value at the end of the module 