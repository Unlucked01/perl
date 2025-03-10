#!/usr/bin/perl

use strict;
use warnings;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use File::Basename;
use lib dirname(__FILE__) . '/lib';
use SpellCheck;
use Dictionary;
use Encode qw(decode encode);
use utf8;

my $cgi = CGI->new;
print $cgi->header(-charset => 'UTF-8');

# Создаем экземпляр проверки правописания
my $spellcheck = SpellCheck->new();

if ($cgi->param('action') eq 'check') {
    # Получаем текст для проверки
    my $text = decode('UTF-8', $cgi->param('text') || '');
    
    # Проверяем текст
    my $errors = $spellcheck->check_text($text);
    
    # Выводим результаты проверки
    print_check_results($text, $errors);
}
elsif ($cgi->param('action') eq 'apply_corrections') {
    # Получаем текст и исправления
    my $text = decode('UTF-8', $cgi->param('text') || '');
    my %corrections;
    
    # Обрабатываем исправления
    foreach my $param ($cgi->param()) {
        if ($param =~ /^correction_(.+)$/) {
            my $word = decode('UTF-8', $1);
            my $correction = decode('UTF-8', $cgi->param($param) || '');
            
            if ($correction eq 'ignore') {
                # Игнорируем слово
                next;
            }
            elsif ($correction eq 'add') {
                # Добавляем слово в словарь
                $spellcheck->{dictionary}->add_word($word);
                next;
            }
            elsif ($correction) {
                # Применяем исправление
                $corrections{$word} = $correction;
            }
        }
    }
    
    # Применяем исправления к тексту
    my $corrected_text = $spellcheck->apply_corrections($text, \%corrections);
    
    # Выводим исправленный текст
    print_corrected_text($corrected_text);
}
elsif ($cgi->param('action') eq 'upload_file') {
    # Обрабатываем загрузку файла
    my $fh = $cgi->upload('file');
    
    if ($fh) {
        my $text = '';
        while (my $line = <$fh>) {
            $text .= decode('UTF-8', $line);
        }
        
        # Проверяем текст
        my $errors = $spellcheck->check_text($text);
        
        # Выводим результаты проверки
        print_check_results($text, $errors);
    }
    else {
        print_error("Не удалось загрузить файл");
    }
}
else {
    # Выводим форму для ввода текста
    print_form();
}

sub print_form {
    print <<HTML;
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Проверка правописания</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .container { max-width: 800px; margin: 0 auto; }
        textarea { width: 100%; height: 200px; margin-bottom: 10px; }
        .button { padding: 8px 16px; background-color: #4CAF50; color: white; border: none; cursor: pointer; }
        .error { color: red; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Проверка правописания</h1>
        
        <h2>Ввод текста</h2>
        <form method="post" enctype="multipart/form-data">
            <textarea name="text" placeholder="Введите текст для проверки"></textarea>
            <input type="hidden" name="action" value="check">
            <button type="submit" class="button">Проверить</button>
        </form>
        
        <h2>Загрузка файла</h2>
        <form method="post" enctype="multipart/form-data">
            <input type="file" name="file">
            <input type="hidden" name="action" value="upload_file">
            <button type="submit" class="button">Загрузить и проверить</button>
        </form>
        
        <p><a href="dict_view.pl">Управление словарем</a></p>
    </div>
</body>
</html>
HTML
}

sub print_check_results {
    my ($text, $errors) = @_;
    
    print <<HTML;
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Результаты проверки</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .container { max-width: 800px; margin: 0 auto; }
        .error-word { color: red; text-decoration: underline; }
        .correction-form { margin-bottom: 20px; }
        .word-correction { margin-bottom: 10px; padding: 10px; background-color: #f5f5f5; }
        .button { padding: 8px 16px; background-color: #4CAF50; color: white; border: none; cursor: pointer; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Результаты проверки</h1>
HTML

    if (keys %$errors == 0) {
        print "<p>Ошибок не найдено!</p>";
        print "<p><a href='spellcheck.pl'>Вернуться к проверке</a></p>";
    }
    else {
        print "<p>Найдено " . scalar(keys %$errors) . " слов с возможными ошибками:</p>";
        
        print <<HTML;
        <form method="post" class="correction-form">
            <input type="hidden" name="action" value="apply_corrections">
            <input type="hidden" name="text" value="$text">
HTML
        
        foreach my $word (sort keys %$errors) {
            my $suggestions = $errors->{$word};
            
            print <<HTML;
            <div class="word-correction">
                <p>Слово: <span class="error-word">$word</span></p>
                <p>Варианты исправления:</p>
                <select name="correction_$word">
                    <option value="">Выберите вариант</option>
HTML
            
            foreach my $suggestion (@$suggestions) {
                my $suggestion_word = $suggestion->{word};
                my $similarity = int($suggestion->{similarity} * 100);
                print "<option value=\"$suggestion_word\">$suggestion_word (схожесть: $similarity%)</option>";
            }
            
            print <<HTML;
                    <option value="ignore">Оставить как есть</option>
                    <option value="add">Добавить в словарь</option>
                </select>
            </div>
HTML
        }
        
        print <<HTML;
            <button type="submit" class="button">Применить исправления</button>
        </form>
        <p><a href="spellcheck.pl">Отмена</a></p>
HTML
    }
    
    print <<HTML;
    </div>
</body>
</html>
HTML
}

sub print_corrected_text {
    my ($text) = @_;
    
    print <<HTML;
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Исправленный текст</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .container { max-width: 800px; margin: 0 auto; }
        .text-area { white-space: pre-wrap; background-color: #f5f5f5; padding: 15px; border: 1px solid #ddd; }
        .button { padding: 8px 16px; background-color: #4CAF50; color: white; border: none; cursor: pointer; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Исправленный текст</h1>
        
        <div class="text-area">$text</div>
        
        <p><a href="spellcheck.pl">Вернуться к проверке</a></p>
    </div>
</body>
</html>
HTML
}

sub print_error {
    my ($message) = @_;
    
    print <<HTML;
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Ошибка</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .container { max-width: 800px; margin: 0 auto; }
        .error { color: red; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Ошибка</h1>
        <p class="error">$message</p>
        <p><a href="spellcheck.pl">Вернуться к проверке</a></p>
    </div>
</body>
</html>
HTML
} 