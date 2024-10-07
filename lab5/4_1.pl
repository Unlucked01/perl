#!/usr/bin/perl
use strict;
use warnings;

if (@ARGV < 2) {
    die "Использование: $0 <папка> <кол-во файлов>\n";
}

my ($dir1, $num_files) = @ARGV;

mkdir($dir1) unless -d $dir1;

sub create_test_files {
    my ($dir) = @_;
    for my $i (1..$num_files) {
        my $file_path = "$dir/$i.txt";
        open(my $fh, '>', $file_path) or die "Не могу создать файл $file_path: $!";
        print $fh "Это тестовый файл $i в папке $dir\n";
        close($fh);
        print "Создан файл: $file_path\n";
    }
}

create_test_files($dir1);