#!/usr/bin/perl
use strict;
use warnings;

print "Введите исходный каталог для перемещения: ";
chomp(my $src_dir = <>);

print "Введите каталог назначения: ";
chomp(my $dst_dir = <>);

sub move_directory {
    my ($src, $dst) = @_;
    if (!-d $dst) {
        mkdir($dst) or die "Не могу создать каталог $dst: $!";
        print "Создан каталог: $dst\n";
    }

    opendir(DIR, $src) or die "Не могу открыть каталог $src: $!";
    my @files = readdir(DIR);
    closedir(DIR);

    # Проходим по каждому файлу/каталогу
    foreach my $file (@files) {
        next if ($file eq '.' or $file eq '..' or $file eq '.git');  # Пропускаем спецкаталоги

        my $src_path = "$src/$file";
        my $dst_path = "$dst/$file";

        if (-d $src_path) {
            # Если это каталог, рекурсивно перемещаем его
            print "Перемещаем каталог: $src_path -> $dst_path\n";
            move_directory($src_path, $dst_path);
        } else {
            # Это файл, перемещаем его с помощью rename
            print "Перемещаем файл: $src_path -> $dst_path\n";
            rename($src_path, $dst_path) or die "Не могу переместить файл $src_path: $!";
        }
    }

    rmdir($src) or warn "Не могу удалить каталог $src: $!";
    print "Удалён каталог: $src\n";
}

if (-d $src_dir) {
    if (!-d $dst_dir) {
        mkdir($dst_dir) or die "Не могу создать целевой каталог $dst_dir: $!";
        print "Целевой каталог $dst_dir создан\n";
    }

    move_directory($src_dir, $dst_dir);
    print "Каталог $src_dir перемещён в $dst_dir\n";
} else {
    die "Исходный каталог $src_dir не существует.\n";
}