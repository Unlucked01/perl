#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use DB_File;
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
use Encode qw(decode encode);
use POSIX qw(strftime);
use File::Basename;
use Cwd qw(abs_path);

# Включаем вывод ошибок в браузер
BEGIN {
    $ENV{PERL_CGI_STDERR_TO_BROWSER} = 1;
}

binmode(STDOUT, ":utf8");
print "Content-type: text/html; charset=utf-8\n\n";

my $q = CGI->new;
my $action = $q->param('action') || 'form';

# Используем фиксированный путь к файлу словаря
my $dict_file = "/usr/local/apache2/data/spellcheck_dict.db";

# Функция для отображения формы проверки правописания
sub show_form {
    print <<HTML;
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Проверка правописания</title>
    <link rel="stylesheet" href="/css/style.css">
</head>
<body>
    <div class="container">
        <h2>Проверка правописания</h2>
        
        <div class="card">
            <form action="/cgi-bin/spellcheck.pl" method="post">
                <input type="hidden" name="action" value="check">
                <div class="form-group">
                    <label for="text">Введите текст для проверки:</label>
                    <textarea id="text" name="text" rows="10" required></textarea>
                </div>
                <button type="submit" class="btn">Проверить правописание</button>
            </form>
        </div>
        
        <div class="navigation-buttons">
            <button onclick="window.location.href='/cgi-bin/dict_manage.pl'" class="btn btn-secondary">
                Управление словарем
            </button>
            <button onclick="window.location.href='/index.html'" class="btn btn-secondary">
                На главную
            </button>
        </div>
    </div>
</body>
</html>
HTML
}

# Функция для вычисления расстояния Левенштейна
sub levenshtein {
    my ($str1, $str2) = @_;
    my @ar1 = split(//, lc($str1));
    my @ar2 = split(//, lc($str2));
    
    my @dist;
    $dist[0][0] = 0;
    
    for (my $i = 1; $i <= scalar @ar1; $i++) {
        $dist[$i][0] = $i;
    }
    
    for (my $j = 1; $j <= scalar @ar2; $j++) {
        $dist[0][$j] = $j;
    }
    
    for (my $i = 1; $i <= scalar @ar1; $i++) {
        for (my $j = 1; $j <= scalar @ar2; $j++) {
            my $cost = ($ar1[$i-1] eq $ar2[$j-1]) ? 0 : 1;
            $dist[$i][$j] = min(
                $dist[$i-1][$j] + 1,      # удаление
                $dist[$i][$j-1] + 1,      # вставка
                $dist[$i-1][$j-1] + $cost # замена
            );
        }
    }
    
    return $dist[scalar @ar1][scalar @ar2];
}

# Функция для нахождения минимального значения
sub min {
    my $min = shift;
    foreach my $val (@_) {
        $min = $val if $val < $min;
    }
    return $min;
}

# Функция для вычисления схожести слов (в процентах)
sub similarity {
    my ($word1, $word2) = @_;
    my $max_length = length($word1) > length($word2) ? length($word1) : length($word2);
    return 0 if $max_length == 0;
    
    my $distance = levenshtein($word1, $word2);
    my $similarity = 1 - ($distance / $max_length);
    return int($similarity * 100);
}

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

# Функция для проверки, существует ли слово в словаре
sub word_exists_in_dictionary {
    my ($word) = @_;
    my %dictionary;
    my $exists = 0;
    
    tie %dictionary, 'DB_File', $dict_file, O_RDONLY, 0666, $DB_HASH
        or die "Cannot open $dict_file: $!";
    
    # Кодируем слово в UTF-8 перед поиском
    my $encoded_word = encode('UTF-8', $word);
    $exists = exists $dictionary{$encoded_word};
    
    untie %dictionary;
    
    return $exists;
}

# Функция для добавления слова в словарь
sub add_to_dictionary {
    my ($word) = @_;
    my %dictionary;
    
    tie %dictionary, 'DB_File', $dict_file, O_RDWR, 0666, $DB_HASH
        or die "Cannot open $dict_file: $!";
    
    # Кодируем слово в UTF-8 перед сохранением
    my $encoded_word = encode('UTF-8', $word);
    $dictionary{$encoded_word} = strftime("%Y-%m-%d", localtime);
    
    untie %dictionary;
    
    return 1;
}

# Функция для поиска похожих слов в словаре
sub find_similar_words {
    my ($word, $threshold) = @_;
    my %dictionary;
    my @similar;
    
    tie %dictionary, 'DB_File', $dict_file, O_RDONLY, 0666, $DB_HASH
        or die "Cannot open $dict_file: $!";
    
    while (my ($encoded_dict_word, $date) = each %dictionary) {
        # Декодируем слово из UTF-8
        my $dict_word = decode('UTF-8', $encoded_dict_word);
        my $sim = similarity($word, $dict_word);
        if ($sim >= $threshold) {
            push @similar, { word => $dict_word, similarity => $sim };
        }
    }
    
    untie %dictionary;
    
    # Сортируем по убыванию схожести
    @similar = sort { $b->{similarity} <=> $a->{similarity} } @similar;
    
    return \@similar;
}

# Функция для проверки текста
sub check_text {
    my $text = $q->param('text');
    $text = decode('UTF-8', $text) unless Encode::is_utf8($text);
    
    # Разбиваем текст на слова
    my @words = split(/\s+/, $text);
    my @misspelled;
    
    # Проверяем каждое слово
    for (my $i = 0; $i < scalar @words; $i++) {
        my $word = $words[$i];
        
        # Удаляем знаки пунктуации для проверки
        my $clean_word = $word;
        $clean_word =~ s/[.,!?;:"(){}[\]<>]+$//;
        
        # Пропускаем пустые строки и слова с цифрами
        next if $clean_word eq '' || $clean_word =~ /\d/;
        
        # Проверяем, есть ли слово в словаре
        unless (word_exists_in_dictionary($clean_word)) {
            # Ищем похожие слова
            my $similar_words = find_similar_words($clean_word, 80);
            
            push @misspelled, {
                position => $i,
                word => $clean_word,
                similar => $similar_words
            };
        }
    }
    
    # Выводим результаты проверки
    print <<HTML;
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Результаты проверки правописания</title>
    <link rel="stylesheet" href="/css/style.css">
    <script src="/js/spellcheck.js"></script>
    <style>
        .misspelled {
            color: #f44336;
            font-weight: bold;
        }
        .suggestion {
            background-color: #f9f9f9;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 15px;
        }
        .suggestion-list {
            margin-top: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h2>Результаты проверки правописания</h2>
HTML
    
    if (@misspelled) {
        print <<HTML;
        <div class="card">
            <h3>Найдены слова с возможными ошибками:</h3>
            
            <form action="/cgi-bin/spellcheck.pl" method="post">
                <input type="hidden" name="action" value="apply_corrections">
                <input type="hidden" name="original_text" value="$text">
HTML

        foreach my $error (@misspelled) {
            my $position = $error->{position};
            my $word = $error->{word};
            my $similar_words = $error->{similar};
            
            print <<HTML;
                <div class="suggestion">
                    <p>Слово: <span class="misspelled">$word</span></p>
                    <input type="hidden" name="position_$position" value="$position">
                    <input type="hidden" id="replace_$position" name="replace_$position" value="$word">
HTML

            if ($similar_words && @$similar_words) {
                print "<div class='suggestion-list'>\n";
                print "<p>Возможные варианты:</p>\n";
                
                foreach my $similar (@$similar_words) {
                    my $sim_word = $similar->{word};
                    my $similarity = $similar->{similarity};
                    
                    print <<HTML;
                    <button type="button" class="btn" onclick="replaceWord($position, '$sim_word')" style="margin-right: 5px; margin-bottom: 5px;">
                        $sim_word <small>($similarity%)</small>
                    </button>
HTML
                }
                
                print "</div>\n";
            } else {
                print "<p>Похожих слов не найдено.</p>\n";
            }
            
            print <<HTML;
                    <div style="margin-top: 10px;">
                        <button type="button" class="btn btn-secondary" onclick="addToDictionary('$word')">
                            Добавить "$word" в словарь
                        </button>
                    </div>
                </div>
HTML
        }
        
        print <<HTML;
                <div style="margin-top: 20px; text-align: center;">
                    <button type="submit" class="btn">Применить исправления</button>
                </div>
            </form>
        </div>
HTML
    } else {
        print <<HTML;
        <div class="card">
            <h3>Ошибок не найдено!</h3>
            <p>Все слова в тексте написаны правильно или присутствуют в словаре.</p>
        </div>
HTML
    }
    
    print <<HTML;
        <div class="navigation-buttons" style="margin-top: 20px;">
            <button onclick="window.location.href='/cgi-bin/spellcheck.pl'" class="btn btn-secondary">
                Проверить другой текст
            </button>
            <button onclick="window.location.href='/cgi-bin/dict_manage.pl'" class="btn btn-secondary">
                Управление словарем
            </button>
        </div>
    </div>
</body>
</html>
HTML
}

# Функция для добавления слова в словарь через AJAX
sub add_word_ajax {
    my $word = $q->param('word');
    $word = decode('UTF-8', $word) unless Encode::is_utf8($word);
    
    if ($word) {
        ensure_dictionary_exists();
        if (add_to_dictionary($word)) {
            print "Слово \"$word\" успешно добавлено в словарь.";
        } else {
            print "Ошибка при добавлении слова в словарь.";
        }
    } else {
        print "Слово не указано.";
    }
}

# Функция для применения исправлений
sub apply_corrections {
    my $original_text = $q->param('original_text');
    $original_text = decode('UTF-8', $original_text) unless Encode::is_utf8($original_text);
    
    my @words = split(/\s+/, $original_text);
    
    # Применяем исправления
    for (my $i = 0; $i < scalar @words; $i++) {
        my $position = $q->param("position_$i");
        my $replacement = $q->param("replace_$i");
        $replacement = decode('UTF-8', $replacement) unless Encode::is_utf8($replacement);
        
        if (defined $position && defined $replacement && $position == $i) {
            # Сохраняем знаки пунктуации
            my $punctuation = '';
            if ($words[$i] =~ /([.,!?;:"(){}[\]<>]+)$/) {
                $punctuation = $1;
            }
            $words[$i] = $replacement . $punctuation;
        }
    }
    
    my $corrected_text = join(' ', @words);
    
    # Выводим результат
    print <<HTML;
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Исправленный текст</title>
    <link rel="stylesheet" href="/css/style.css">
</head>
<body>
    <div class="container">
        <h2>Исправленный текст</h2>
        
        <div class="card">
            <div style="background-color: #f9f9f9; padding: 15px; border-radius: 5px; margin-bottom: 20px;">
                $corrected_text
            </div>
            
            <div class="form-group">
                <label for="corrected_text">Скопируйте исправленный текст:</label>
                <textarea id="corrected_text" rows="10" readonly>$corrected_text</textarea>
            </div>
        </div>
        
        <div class="navigation-buttons" style="margin-top: 20px;">
            <button onclick="window.location.href='/cgi-bin/spellcheck.pl'" class="btn btn-secondary">
                Назад к проверке
            </button>
        </div>
    </div>
</body>
</html>
HTML
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

    if ($action eq 'form') {
        show_form();
    } elsif ($action eq 'check') {
        check_text();
    } elsif ($action eq 'add_word') {
        add_word_ajax();
    } elsif ($action eq 'apply_corrections') {
        apply_corrections();
    } else {
        show_form();
    }
};

if ($@) {
    print "<h2>Произошла ошибка:</h2><pre>$@</pre>";
} 