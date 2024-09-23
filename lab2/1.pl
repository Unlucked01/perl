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

@union = @intersection = @diff = @sym_diff = ();
%hashA = %hashB = ();

foreach $e (@A) {$hashA{$e}++};
foreach $e (@B) {$hashB{$e}++};

%union = (%hashA, %hashB);
@union = keys %union;

foreach $e (@union) {
    if (exists $hashA{$e} && exists $hashB{$e}) {
        push @intersection, $e;
    }
    if (exists $hashA{$e} && !exists $hashB{$e}) {
        push @diff, $e;
    }
    if ((exists $hashA{$e} && !exists $hashB{$e}) || 
    	(exists $hashB{$e} && !exists $hashA{$e})) {
        push @sym_diff, $e;
    }
}

print "A = @A\n";
print "B = @B\n";
print "Объединение: @union\n";
print "Пересечение: @intersection\n";
print "Разность: @diff\n";
print "Симметричная разность: @sym_diff\n";
