#!/usr/bin/perl

@A = ();
print "Введите элементы массива:\n";
while (my $element = <>) {
    chomp($element);
    last if $element eq '';
    push(@A, $element);
};

print "Массив до: \n@A\n";

for (my $i = 0; $i < $#A; $i += 2) {
    @A[$i, $i + 1] = @A[$i + 1, $i];
}

print "Массив после:\n@A\n";