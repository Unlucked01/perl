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

my $message = '';
my $error = '';

if ($cgi->param('action') eq 'add') {
    my $word = decode('UTF-8', $cgi->param('word') || '');
    
    if ($word) {
        if ($dictionary->exists($word)) {
            $error = "Слово '$word' уже существует в словаре";
        }
        else {
            $dictionary->add_word($word);
            $message = "Слово '$word' успешно добавлено в словарь";
        }
    }
    else {
        $error = "Пожалуйста, введите слово";
    }
}

# Выводим HTML-страницу
print <<HTML;
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Добавление слова в словарь</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .container { max-width: 800px; margin: 0 auto; }
        .form-group { margin-bottom: 15px; }
        .form-group label { display: block; margin-bottom: 5px; }
        .form-group input[type="text"] { width: 100%; padding: 8px; }
        .button { padding: 8px 16px; background-color: #4CAF50; color: white; border: none; cursor: pointer; }
        .success { color: green; }
        .error { color: red; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Добавление слова в словарь</h1>
        
        <form method="post">
            <div class="form-group">
                <label for="word">Слово:</label>
                <input type="text" id="word" name="word" required>
            </div>
            
            <input type="hidden" name="action" value="add">
            <button type="submit" class="button">Добавить</button>
        </form>
        
        <div class="message">
HTML

if ($message) {
    print "<p class=\"success\">$message</p>";
}

if ($error) {
    print "<p class=\"error\">$error</p>";
}

print <<HTML;
        </div>
        
        <p><a href="dict_view.pl">Вернуться к списку слов</a></p>
    </div>
</body>
</html>
HTML 