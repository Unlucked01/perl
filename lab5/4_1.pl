#!/usr/bin/perl

if (@ARGV < 3) {
    die "Использование: $0 <папка> <кол-во файлов> <расширение>\n";
}

my ($dir1, $num_files, $ext) = @ARGV;

mkdir($dir1) unless -d $dir1;

sub create_test_files {
    my ($dir) = @_;
    for my $i (1..$num_files) {
        my $file_path = "$dir/$i.$ext";
        open(my $fh, '>', $file_path) or die "Не могу создать файл $file_path: $!";
        print $fh "Это тестовый файл $i в папке $dir\n";
        close($fh);
        print "Создан файл: $file_path\n";
    }
}

create_test_files($dir1);