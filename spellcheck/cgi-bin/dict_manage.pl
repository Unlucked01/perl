#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use DB_File;
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
use Encode qw(decode encode);
use POSIX qw(strftime);

# Включаем вывод ошибок в браузер
BEGIN {
    $ENV{PERL_CGI_STDERR_TO_BROWSER} = 1;
}

binmode(STDOUT, ":utf8");
print "Content-type: text/html; charset=utf-8\n\n";

my $q = CGI->new;
my $action = $q->param('action') || 'view';
my $search = $q->param('search') || '';
$search = decode('UTF-8', $search) unless Encode::is_utf8($search);

# Используем фиксированный путь к файлу словаря
my $dict_file = "/usr/local/apache2/data/spellcheck_dict.db";

# Функция для создания словаря, если он не существует
sub ensure_dictionary_exists {
    unless (-e $dict_file) {
        print "<!-- Creating dictionary at $dict_file -->\n";
        my %dictionary;
        tie %dictionary, 'DB_File', $dict_file, O_CREAT|O_RDWR, 0666, $DB_HASH
            or die "Cannot create $dict_file: $!";
        
        # Добавляем начальные слова в словарь
        my @initial_words = (
            'привет', 'мир', 'компьютер', 'программа', 'словарь', 
            'проверка', 'правописание', 'текст', 'ошибка', 'исправление',
            'алгоритм', 'система', 'интерфейс', 'пользователь', 'файл',
            'данные', 'анализ', 'результат', 'процесс', 'функция'
        );
        
        foreach my $word (@initial_words) {
            # Кодируем слово в UTF-8 перед сохранением
            my $encoded_word = encode('UTF-8', $word);
            $dictionary{$encoded_word} = strftime("%Y-%m-%d", localtime);
        }
        
        untie %dictionary;
    }
}

# Вспомогательные функции для пагинации
sub max {
    my ($a, $b) = @_;
    return $a > $b ? $a : $b;
}

sub min {
    my ($a, $b) = @_;
    return $a < $b ? $a : $b;
}

# Функция для отображения словаря
sub view_dictionary {
    my %dictionary;
    tie %dictionary, 'DB_File', $dict_file, O_RDONLY, 0666, $DB_HASH
        or die "Cannot open $dict_file: $!";
    
    my @words;
    while (my ($encoded_word, $date) = each %dictionary) {
        # Декодируем слово из UTF-8
        my $word = decode('UTF-8', $encoded_word);
        push @words, { word => $word, date => $date };
    }
    
    # Фильтрация по поисковому запросу
    if ($search) {
        @words = grep { $_->{word} =~ /$search/i } @words;
    }
    
    # Сортировка по алфавиту
    @words = sort { $a->{word} cmp $b->{word} } @words;
    
    # Пагинация
    my $page = $q->param('page') || 1;
    my $per_page = 50;
    my $total = scalar @words;
    my $pages = int(($total + $per_page - 1) / $per_page);
    $page = 1 if $page < 1;
    $page = $pages if $page > $pages && $pages > 0;
    
    my $start = ($page - 1) * $per_page;
    my $end = $start + $per_page - 1;
    $end = $total - 1 if $end >= $total;
    
    my @page_words = @words[$start..$end];
    
    print <<HTML;
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Управление словарем проверки правописания</title>
    <link rel="stylesheet" href="/css/style.css">
    <script>
        function confirmDelete(word) {
            if (confirm('Вы уверены, что хотите удалить слово "' + word + '" из словаря?')) {
                window.location.href = '/cgi-bin/dict_manage.pl?action=delete&word=' + encodeURIComponent(word);
            }
        }
    </script>
    <style>
        .pagination {
            display: flex;
            justify-content: center;
            margin: 20px 0;
        }
        .pagination a, .pagination span {
            padding: 8px 16px;
            text-decoration: none;
            border: 1px solid #ddd;
            margin: 0 4px;
        }
        .pagination a:hover {
            background-color: #f1f1f1;
        }
        .pagination .active {
            background-color: #4a6fa5;
            color: white;
            border: 1px solid #4a6fa5;
        }
    </style>
</head>
<body>
    <div class="container">
        <h2>Управление словарем проверки правописания</h2>
        
        <div class="card">
            <form action="/cgi-bin/dict_manage.pl" method="get">
                <div class="form-group" style="display: flex; gap: 10px;">
                    <input type="text" name="search" placeholder="Поиск по словарю..." value="$search" style="flex: 1;">
                    <button type="submit" class="btn">Поиск</button>
                    <button type="button" onclick="window.location.href='/cgi-bin/dict_manage.pl'" class="btn btn-secondary">Сбросить</button>
                </div>
            </form>
        </div>
        
        <div class="card">
            <h3>Добавить новое слово</h3>
            <form action="/cgi-bin/dict_manage.pl" method="get">
                <input type="hidden" name="action" value="add">
                <div class="form-group" style="display: flex; gap: 10px;">
                    <input type="text" name="word" placeholder="Введите слово..." required style="flex: 1;">
                    <button type="submit" class="btn">Добавить</button>
                </div>
            </form>
        </div>
        
        <div class="card">
            <h3>Словарь</h3>
            <table id="dictionary-table">
                <tr>
                    <th>Слово</th>
                    <th>Дата добавления</th>
                    <th>Действия</th>
                </tr>
HTML
    
    if (@page_words) {
        foreach my $item (@page_words) {
            my $word = $item->{word};
            my $date = $item->{date};
            
            # Экранируем слово для безопасного вывода в HTML
            my $escaped_word = encode_entities($word);
            
            print <<HTML;
                <tr>
                    <td>$escaped_word</td>
                    <td>$date</td>
                    <td>
                        <button onclick="confirmDelete('$escaped_word')" class="delete-btn" title="Удалить '$escaped_word'">
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path><line x1="10" y1="11" x2="10" y2="17"></line><line x1="14" y1="11" x2="14" y2="17"></line></svg>
                        </button>
                    </td>
                </tr>
HTML
        }
    } else {
        print <<HTML;
                <tr>
                    <td colspan="3" style="text-align: center; padding: 20px;">
                        Словарь пуст или не найдено слов, соответствующих поисковому запросу.
                    </td>
                </tr>
HTML
    }
    
    print "</table>\n";
    
    # Пагинация
    if ($pages > 1) {
        print "<div class='pagination'>\n";
        
        if ($page > 1) {
            print "<a href='/cgi-bin/dict_manage.pl?page=".($page-1)."&search=$search'>&laquo;</a>\n";
        } else {
            print "<span>&laquo;</span>\n";
        }
        
        my $start_page = max(1, $page - 2);
        my $end_page = min($pages, $page + 2);
        
        for (my $i = $start_page; $i <= $end_page; $i++) {
            if ($i == $page) {
                print "<span class='active'>$i</span>\n";
            } else {
                print "<a href='/cgi-bin/dict_manage.pl?page=$i&search=$search'>$i</a>\n";
            }
        }
        
        if ($page < $pages) {
            print "<a href='/cgi-bin/dict_manage.pl?page=".($page+1)."&search=$search'>&raquo;</a>\n";
        } else {
            print "<span>&raquo;</span>\n";
        }
        
        print "</div>\n";
    }
    
    print <<HTML;
        </div>
        
        <div class="navigation-buttons" style="margin-top: 20px;">
            <button onclick="window.location.href='/cgi-bin/spellcheck.pl'" class="btn btn-secondary">
                Назад к проверке
            </button>
            <button onclick="window.location.href='/index.html'" class="btn btn-secondary">
                На главную
            </button>
        </div>
    </div>
</body>
</html>
HTML

    untie %dictionary;
}

# Функция для добавления слова в словарь
sub add_word {
    my $word = $q->param('word');
    $word = decode('UTF-8', $word) unless Encode::is_utf8($word);
    
    if ($word) {
        my %dictionary;
        tie %dictionary, 'DB_File', $dict_file, O_RDWR, 0666, $DB_HASH
            or die "Cannot open $dict_file: $!";
        
        # Кодируем слово в UTF-8 перед сохранением
        my $encoded_word = encode('UTF-8', $word);
        $dictionary{$encoded_word} = strftime("%Y-%m-%d", localtime);
        
        untie %dictionary;
        
        print <<HTML;
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Слово добавлено</title>
    <link rel="stylesheet" href="/css/style.css">
</head>
<body>
    <div class="container">
        <div class="card" style="text-align: center; margin-top: 50px;">
            <h3>Слово "$word" успешно добавлено в словарь.</h3>
            <p style="margin-top: 20px;">
                <a href="/cgi-bin/dict_manage.pl" class="btn">Вернуться к словарю</a>
            </p>
        </div>
    </div>
</body>
</html>
HTML
    } else {
        print <<HTML;
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Ошибка</title>
    <link rel="stylesheet" href="/css/style.css">
</head>
<body>
    <div class="container">
        <div class="card" style="text-align: center; margin-top: 50px;">
            <h3>Ошибка: слово не указано.</h3>
            <p style="margin-top: 20px;">
                <a href="/cgi-bin/dict_manage.pl" class="btn">Вернуться к словарю</a>
            </p>
        </div>
    </div>
</body>
</html>
HTML
    }
}

# Функция для удаления слова из словаря
sub delete_word {
    my $word = $q->param('word');
    $word = decode('UTF-8', $word) unless Encode::is_utf8($word);
    
    if ($word) {
        my %dictionary;
        tie %dictionary, 'DB_File', $dict_file, O_RDWR, 0666, $DB_HASH
            or die "Cannot open $dict_file: $!";
        
        # Кодируем слово в UTF-8 перед удалением
        my $encoded_word = encode('UTF-8', $word);
        delete $dictionary{$encoded_word};
        
        untie %dictionary;
        
        print <<HTML;
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Слово удалено</title>
    <link rel="stylesheet" href="/css/style.css">
</head>
<body>
    <div class="container">
        <div class="card" style="text-align: center; margin-top: 50px;">
            <h3>Слово "$word" успешно удалено из словаря.</h3>
            <p style="margin-top: 20px;">
                <a href="/cgi-bin/dict_manage.pl" class="btn">Вернуться к словарю</a>
            </p>
        </div>
    </div>
</body>
</html>
HTML
    } else {
        print <<HTML;
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Ошибка</title>
    <link rel="stylesheet" href="/css/style.css">
</head>
<body>
    <div class="container">
        <div class="card" style="text-align: center; margin-top: 50px;">
            <h3>Ошибка: слово не указано.</h3>
            <p style="margin-top: 20px;">
                <a href="/cgi-bin/dict_manage.pl" class="btn">Вернуться к словарю</a>
            </p>
        </div>
    </div>
</body>
</html>
HTML
    }
}

# Вспомогательная функция для экранирования HTML-сущностей
sub encode_entities {
    my ($text) = @_;
    $text =~ s/&/&amp;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    $text =~ s/"/&quot;/g;
    $text =~ s/'/&#39;/g;
    return $text;
}

# Основной код
eval {
    ensure_dictionary_exists();

    if ($action eq 'view') {
        view_dictionary();
    } elsif ($action eq 'add') {
        add_word();
    } elsif ($action eq 'delete') {
        delete_word();
    } else {
        view_dictionary();
    }
};

if ($@) {
    print "<h2>Произошла ошибка:</h2><pre>$@</pre>";
} 