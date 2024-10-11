#!/usr/bin/perl

sub move_dir {
    my ($src, $dst) = @_;

    mkdir($dst) unless -d $dst;

    opendir(my $dh, $src) or die "Не удалось открыть директорию $src: $!";
    my @files = readdir($dh);
    closedir($dh);

    foreach my $file (@files) {
        next if ($file eq '.' or $file eq '..' or $file eq '.git');

        my $src_path = "$src/$file";
        my $dst_path = "$dst/$file";

        if (-d $src_path) {
            print "Перемещаем каталог: $src_path -> $dst_path\n";
            move_directory($src_path, $dst_path);
        } else {
            print "Перемещаем файл: $src_path -> $dst_path\n";
            copy_and_remove_file($src_path, $dst_path);
        }
    }
    

    rmdir($src) or warn "Не удалось удалить каталог $src: $!\n";
}

sub copy_and_remove_file {
    my ($src, $dst) = @_;
    open(my $src_fh, '<', $src) or die "Не могу открыть файл $src для чтения: $!";
    open(my $dst_fh, '>', $dst) or die "Не могу открыть файл $dst для записи: $!";
    
    while (my $line = <$src_fh>) {
        print $dst_fh $line;
    }

    close($src_fh);
    close($dst_fh);

    unlink($src) or warn "Не могу удалить файл $src: $!";
}

print "Введите исходный каталог: ";
my $src_dir = <>;
chomp $src_dir;

print "Введите целевой каталог: ";
my $dest_dir = <>;
chomp $dest_dir;

move_dir($src_dir, $dest_dir);