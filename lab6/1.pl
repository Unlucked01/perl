#!/usr/bin/perl

# ./1.pl /Users/unlucked/7sem/perl print 0

sub traverse_directory {
    my ($directory, $sequence, $case_sensitive, $results) = @_;

    opendir my $dh, $directory or die "$directory: $!";
    
    while (my $entry = readdir $dh) {
        next if $entry eq '.' or $entry eq '..' or $entry eq '.git';
        my $path = "$directory/$entry";

        if (-d $path) {
            traverse_directory($path, $sequence, $case_sensitive, $results);
        } 
        elsif (-f $path) {
            check_file_for_sequence($path, $sequence, $case_sensitive, $results);
        }
    }

    closedir $dh;
}

sub check_file_for_sequence {
    my ($file, $sequence, $case_sensitive, $results) = @_;
    open my $fh, '<', $file or return;
    my $count = 0;
    
    while (my $line = <$fh>) {
        if ($case_sensitive) {
            $count += () = $line =~ m/$sequence/g;
        } else {
            $count += () = $line =~ m/$sequence/ig;
        }
    }
    
    close $fh;

    if ($count > 0) {
        $results->{$file} = $count;
    }
}

sub main {
    my $directory = $ARGV[0];
    my $sequence = $ARGV[1];
    my $mode = $ARGV[2];

    unless (defined $directory && defined $sequence && defined $mode) {
        print "Введите название каталога: ";
        chomp($directory = <STDIN>);
        print "Введите последовательность для поиска: ";
        chomp($sequence = <STDIN>);
        print "Выберите режим работы (1 - с учетом регистра, 0 - без учета регистра): ";
        chomp($mode = <STDIN>);
    }

    my $case_sensitive = $mode ? 1 : 0;
    my %results;

    traverse_directory($directory, $sequence, $case_sensitive, \%results);

    print "Каталог: $directory\n";
    print "Последовательность поиска: \"$sequence\"\n";
    print "Чувствительно к регистру: ", ($case_sensitive ? "Да" : "Нет"), "\n";
    print "-" x 50, "\n";
    
    if (%results) {
        foreach my $file (keys %results) {
            print "Файл: $file\n";
            print "Встречается: $results{$file} раз(a)\n";
            print "-" x 50, "\n";
        }
    } else {
        print "Нет файлов с заданной последовательностью.\n";
    }
}

main();