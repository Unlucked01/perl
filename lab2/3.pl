#!/usr/bin/perl

@A = ();
print "Введите элементы первого массива:\n";
while (my $element = <>) {
    chomp($element);
    last if $element eq '';
    push(@A, $element);
};

%B = ();
print "Введите элементы второго массива:\n";
while (my $element = <>) {
    chomp($element);
    last if $element eq '';
    push(@B, $element);
};

@C;

$max_len = $#A + $#B; 

for my $i (0 .. $max_len) {
    if ($i % 2 == 0) {
        push @C, shift @A if @A;
    } else {
        push @C, shift @B if @B;
    }
}

print "Результирующий массив: @C\n";
