#!/usr/bin/perl
use strict;
use warnings;

my ($dir, $ext) = @ARGV;

if (not defined $dir) {
    print "Введите каталог для просмотра: ";
    chomp($dir = <>);
}

if (not defined $ext) {
    print "Введите расширение файлов для удаления (например, .txt): ";
    chomp($ext = <>);
}

sub delete_files_with_extension {
    my ($current_dir) = @_;
    chdir($current_dir) or die "Не могу перейти в каталог $current_dir: $!";

    opendir(DIR, ".") or die "Не могу открыть каталог $current_dir: $!";
    my @files = readdir(DIR);   # Читаем содержимое каталога
    closedir(DIR);

    # Проходим по каждому файлу/каталогу
    foreach my $file (@files) {
        next if ($file eq '.' or $file eq '..' or $file eq '.git');  # Пропускаем спецкаталоги

        if (-d $file) {
            # Если это каталог, рекурсивно обходим его
            delete_files_with_extension("$current_dir/$file");
        } elsif (-f $file) {
            my $extention = ( split /\./, $file )[-1];
            if ($extention eq $ext) {
                print "Удаляю файл: $current_dir/$file\n";
                unlink($file) or warn "Не могу удалить файл $file: $!";
            }
        }
    }

    chdir("..") or die "Не могу вернуться в родительский каталог";
}

delete_files_with_extension($dir);