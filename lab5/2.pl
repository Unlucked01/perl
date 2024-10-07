#!/usr/bin/perl
use strict;
use warnings;

# ./2.pl /Users/unlucked/7sem/perl/

my ($dir, $output_option) = @ARGV;

# Если аргумент не указан, используем текущий каталог и вывод на экран
$dir = "." unless defined $dir;
$output_option = "output" unless defined $output_option;

my $fh;
if ($output_option eq 'file') {
    open($fh, '>', 'directory_tree.txt') or die "Не могу открыть файл: $!";
}

sub print_tree {
    my ($current_dir, $indent) = @_;
    chdir($current_dir) or die "Не могу перейти в каталог $current_dir: $!";
    
    opendir(DIR, ".") or die "Не могу открыть каталог $current_dir: $!";
    my @files = readdir(DIR);
    closedir(DIR);

    # Проходим по каждому файлу/каталогу
    foreach my $file (@files) {
        next if ($file eq '.' or $file eq '..' or $file eq '.git');  # Пропускаем спецкаталоги

        # Проверяем, является ли это каталогом или файлом
        if (-d $file) {
            my $output = "$indent Каталог: $file/\n";
            
            if ($output_option eq 'file') {
                print $fh $output;
            } else {
                print $output;
            }

            # Рекурсивно обходим этот каталог
            print_tree("$current_dir/$file", "$indent    ");
        } elsif (-f $file) {
            my $size = -s $file;
            my $is_readable = (-r $file) ? 'Чтение: да' : 'Чтение: нет';
            my $is_writable = (-w $file) ? 'Запись: да' : 'Запись: нет';
            
            my $output = sprintf(
                "$indent Файл: %s (Размер: %d байт, %s, %s)\n",
                $file, $size, $is_readable, $is_writable
            );
            
            if ($output_option eq 'file') {
                print $fh $output;
            } else {
                print $output;
            }
        }
    }
    
    chdir("..") or die "Не могу вернуться в родительский каталог";
}

print_tree($dir, "");

if ($output_option eq 'file') {
    close $fh;
}