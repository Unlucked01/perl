#!/usr/bin/perl

my %roman2arabic = (
    'I' => 1,
    'V' => 5,
    'X' => 10,
    'L' => 50,
    'C' => 100,
    'D' => 500,
    'M' => 1000
);

my %roman_digit = (
    1    => 'IV',
    10   => 'XL',
    100  => 'CD',
    1000 => 'MMMMMM'
);

my @figure = reverse sort keys %roman_digit;

$roman_digit{$_} = [split(//, $roman_digit{$_}, 2)] foreach @figure;

sub isroman {
    my $arg = shift;
    $arg ne '' and
      $arg =~ /^(M{0,3})
                (D?C{0,3} | C[DM])
                (L?X{0,3} | X[LC])
                (V?I{0,3} | I[VX])$/ix;
}

sub arabic {
    my $arg = shift;
    isroman($arg) or return undef;
    my $last_digit = 1000;
    my $arabic = 0;
    foreach (split(//, uc $arg)) {
        my $digit = $roman2arabic{$_};
        $arabic -= 2 * $last_digit if $last_digit < $digit;
        $arabic += ($last_digit = $digit);
    }
    return $arabic;
}

sub Roman {
    my $arg = shift;
    0 < $arg and $arg < 4000 or return undef;
    my $roman = '';
    my $x;
    foreach (@figure) {
        my($digit, $i, $v) = (int($arg / $_), @{$roman_digit{$_}});
        if (1 <= $digit and $digit <= 3) {
            $roman .= $i x $digit;
        } elsif ($digit == 4) {
            $roman .= "$i$v";
        } elsif ($digit == 5) {
            $roman .= $v;
        } elsif (6 <= $digit and $digit <= 8) {
            $roman .= $v . $i x ($digit - 5);
        } elsif ($digit == 9) {
            $roman .= "$i$x";
        }
        $arg -= $digit * $_;
        $x = $i;
    }
    return $roman;
}

sub process_file {
    my ($input_file, $direction) = @_;
    
    open my $in_fh, '<', $input_file or die "Не могу открыть файл $input_file: $!";
    my @lines = <$in_fh>;
    close $in_fh;

    foreach my $line (@lines) {
        if ($direction eq "1") {
            $line =~ s/(\d+)/($1 > 0 && $1 < 4000) ? Roman($1) : $1/ge;
        } elsif ($direction eq "2") {
            $line =~ s/(\b\w+\b)/isroman($1) ? arabic($1) : $1/ge;
        }
    }

    open my $out_fh, '>', $input_file or die "Не могу открыть файл для записи: $!";
    print $out_fh @lines;
    close $out_fh;
}

sub main {
    print "Введите имя файла: ";
    chomp(my $input_file = <STDIN>);

    unless (-e $input_file) {
        die "Файл $input_file не существует.\n";
    }

    print "Выберите действие:\n";
    print "1. Перевести арабские числа в римские\n";
    print "2. Перевести римские числа в арабские\n";
    print "Ваш выбор: ";
    chomp(my $choice = <STDIN>);

    process_file($input_file, $choice);
    
    print "Файл обработан. Числа были переведены.\n";
}

main();