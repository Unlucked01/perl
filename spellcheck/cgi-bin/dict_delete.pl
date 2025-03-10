#!/usr/bin/perl

use strict;
use warnings;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use File::Basename;
use lib dirname(__FILE__) . '/lib';
use Dictionary;
use Encode qw(decode encode);
use utf8;

my $cgi = CGI->new;
print $cgi->header(-charset => 'UTF-8');

# Создаем экземпляр словаря
my $dictionary = Dictionary->new();

my $word = decode('UTF-8', $cgi->param('word') || '');
my $message = '';
my $error = '';

if ($cgi->param('action') eq 'delete') {
    if ($word) {
        if ($dictionary->exists($word)) {
            $dictionary->delete_word($word);
            $message = "Слово '$word' успешно удалено из словаря";
        }
        else {
            $error = "Слово '$word' не найдено в словаре";
        }
    }
    else {
        $error = "Не указано слово для удаления";
    }
}

# Выводим HTML-страницу
print <<HTML;
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Удаление слова из словаря</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .container { max-width: 800px; margin: 0 auto; }
        .form-group { margin-bottom: 15px; }
        .form-group label { display: block; margin-bottom: 5px; }
        .button { padding: 8px 16px; background-color: #4CAF50; color: white; border: none; cursor: pointer; }
        .success { color: green; }
        .error { color: red; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Удаление слова из словаря</h1>
HTML

if (!$word) {
    print <<HTML;
        <p class="error">Не указано слово для удаления</p>
        <p><a href="dict_view.pl">Вернуться к списку слов</a></p>
HTML
}
elsif (!$cgi->param('action')) {
    print <<HTML;
        <p>Вы действительно хотите удалить слово '$word' из словаря?</p>
        
        <form method="post">
            <input type="hidden" name="word" value="$word">
            <input type="hidden" name="action" value="delete">
            <button type="submit" class="button">Да, удалить</button>
            <a href="dict_view.pl" style="margin-left: 10px;">Отмена</a>
        </form>
HTML
}
else {
    if ($message) {
        print "<p class=\"success\">$message</p>";
    }
    
    if ($error) {
        print "<p class=\"error\">$error</p>";
    }
    
    print "<p><a href=\"dict_view.pl\">Вернуться к списку слов</a></p>";
}

print <<HTML;
    </div>
</body>
</html>
HTML 