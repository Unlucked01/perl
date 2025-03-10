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

my $old_word = decode('UTF-8', $cgi->param('word') || '');
my $message = '';
my $error = '';

if ($cgi->param('action') eq 'edit') {
    my $new_word = decode('UTF-8', $cgi->param('new_word') || '');
    
    if ($old_word && $new_word) {
        if ($old_word eq $new_word) {
            $message = "Слово не изменилось";
        }
        elsif ($dictionary->exists($new_word)) {
            $error = "Слово '$new_word' уже существует в словаре";
        }
        else {
            $dictionary->edit_word($old_word, $new_word);
            $message = "Слово '$old_word' успешно изменено на '$new_word'";
            $old_word = $new_word; # Обновляем слово для отображения в форме
        }
    }
    else {
        $error = "Пожалуйста, введите новое слово";
    }
}

# Выводим HTML-страницу
print <<HTML;
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Редактирование слова</title>
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
        <h1>Редактирование слова</h1>
HTML

if (!$old_word) {
    print <<HTML;
        <p class="error">Не указано слово для редактирования</p>
        <p><a href="dict_view.pl">Вернуться к списку слов</a></p>
HTML
}
elsif (!$dictionary->exists($old_word) && !$message) {
    print <<HTML;
        <p class="error">Слово '$old_word' не найдено в словаре</p>
        <p><a href="dict_view.pl">Вернуться к списку слов</a></p>
HTML
}
else {
    print <<HTML;
        <form method="post">
            <div class="form-group">
                <label for="old_word">Текущее слово:</label>
                <input type="text" id="old_word" value="$old_word" readonly>
            </div>
            
            <div class="form-group">
                <label for="new_word">Новое слово:</label>
                <input type="text" id="new_word" name="new_word" value="$old_word" required>
            </div>
            
            <input type="hidden" name="word" value="$old_word">
            <input type="hidden" name="action" value="edit">
            <button type="submit" class="button">Сохранить</button>
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
HTML
}

print <<HTML;
        <p><a href="dict_view.pl">Вернуться к списку слов</a></p>
    </div>
</body>
</html>
HTML 