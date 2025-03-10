#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use DB_File;
use Encode qw(decode encode);

binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

my $dict_file = '../data/dictionary.db';
unlink $dict_file if -e $dict_file;

my %dictionary;
tie %dictionary, 'DB_File', $dict_file, O_CREAT|O_RDWR, 0666, $DB_HASH
    or die "Cannot create $dict_file: $!";

my @initial_words = qw(привет мир компьютер программа словарь текст проверка);

foreach my $word (@initial_words) {
    $word = encode('UTF-8', $word) if Encode::is_utf8($word);
    $dictionary{$word} = 1;
}

untie %dictionary;

tie %dictionary, 'DB_File', $dict_file, O_RDONLY, 0666, $DB_HASH
    or die "Cannot open $dict_file: $!";

print "Dictionary created successfully with the following entries:\n";
foreach my $key (sort keys %dictionary) {
    my $value = decode('UTF-8', $key) unless Encode::is_utf8($key);
    print "$value\n";
}

untie %dictionary;