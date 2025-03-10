#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use File::Basename;
use lib dirname(__FILE__) . '/lib';
use Dictionary;
use Encode qw(decode encode);

my $cgi = CGI->new;
binmode(STDOUT, ":utf8");
print $cgi->header(-charset => 'UTF-8');

# Создаем экземпляр словаря
my $dictionary = Dictionary->new();

# Получаем параметры пагинации
my $page = $cgi->param('page') || 1;
my $per_page = 50;
my $search = decode('UTF-8', $cgi->param('search') || '');

# Получаем все слова из словаря
my @all_words = $dictionary->get_all_words();

# Фильтруем слова, если задан поисковый запрос
if ($search) {
    @all_words = grep { $_ =~ /\Q$search\E/i } @all_words;
}

# Вычисляем общее количество страниц
my $total_words = scalar @all_words;
my $total_pages = int(($total_words + $per_page - 1) / $per_page);
$page = 1 if $page < 1;
$page = $total_pages if $page > $total_pages && $total_pages > 0;

# Получаем слова для текущей страницы
my $start = ($page - 1) * $per_page;
my $end = $start + $per_page - 1;
$end = $total_words - 1 if $end >= $total_words;
my @page_words = @all_words[$start..$end];

# Выводим HTML-страницу
print <<HTML;
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Управление словарем</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .container { max-width: 800px; margin: 0 auto; }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 8px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #f2f2f2; }
        .pagination { margin-top: 20px; }
        .pagination a { margin-right: 5px; padding: 5px 10px; text-decoration: none; background-color: #f2f2f2; }
        .pagination a.active { background-color: #4CAF50; color: white; }
        .search-form { margin-bottom: 20px; }
        .button { padding: 8px 16px; background-color: #4CAF50; color: white; border: none; cursor: pointer; }
        .action-button { padding: 5px 10px; margin-right: 5px; text-decoration: none; background-color: #f2f2f2; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Управление словарем</h1>
        
        <div class="search-form">
            <form method="get">
                <input type="text" name="search" value="$search" placeholder="Поиск слова">
                <button type="submit" class="button">Поиск</button>
            </form>
        </div>
        
        <p><a href="dict_add.pl" class="button">Добавить новое слово</a></p>
        
        <table>
            <tr>
                <th>Слово</th>
                <th>Действия</th>
            </tr>
HTML

foreach my $word (@page_words) {
    print <<HTML;
            <tr>
                <td>$word</td>
                <td>
                    <a href="dict_edit.pl?word=$word" class="action-button">Редактировать</a>
                    <a href="dict_delete.pl?word=$word" class="action-button" onclick="return confirm('Вы уверены, что хотите удалить слово?')">Удалить</a>
                </td>
            </tr>
HTML
}

print <<HTML;
        </table>
        
        <div class="pagination">
HTML

# Выводим пагинацию
if ($total_pages > 1) {
    my $prev_page = $page - 1;
    my $next_page = $page + 1;
    
    if ($page > 1) {
        print "<a href=\"?page=1&search=$search\">Первая</a>";
        print "<a href=\"?page=$prev_page&search=$search\">Предыдущая</a>";
    }
    
    # Выводим номера страниц
    my $start_page = max(1, $page - 2);
    my $end_page = min($total_pages, $page + 2);
    
    for my $p ($start_page..$end_page) {
        my $active = $p == $page ? ' class="active"' : '';
        print "<a href=\"?page=$p&search=$search\"$active>$p</a>";
    }
    
    if ($page < $total_pages) {
        print "<a href=\"?page=$next_page&search=$search\">Следующая</a>";
        print "<a href=\"?page=$total_pages&search=$search\">Последняя</a>";
    }
}

print <<HTML;
        </div>
        
        <p>Всего слов: $total_words</p>
        <p><a href="spellcheck.pl">Вернуться к проверке правописания</a></p>
    </div>
</body>
</html>
HTML

sub min {
    my ($a, $b) = @_;
    return $a < $b ? $a : $b;
}

sub max {
    my ($a, $b) = @_;
    return $a > $b ? $a : $b;
} 