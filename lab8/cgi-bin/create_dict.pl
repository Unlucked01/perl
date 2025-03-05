#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use DB_File;
use Encode qw(decode encode);

binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

unlink 'dictionary.db' if -e 'dictionary.db';

my %dictionary;
tie %dictionary, 'DB_File', 'dictionary.db', O_CREAT|O_RDWR, 0666, $DB_HASH
    or die "Cannot create dictionary.db: $!";

my %initial_entries = (
    'hello' => 'привет',
    'world' => 'мир',
    'thank' => 'спасибо',
    'you' => 'тебе',
    'good' => 'хороший',
    'day' => 'день',
    'sun' => 'солнце'
);

foreach my $eng (keys %initial_entries) {
    my $rus = $initial_entries{$eng};
    $rus = encode('UTF-8', $rus) if Encode::is_utf8($rus);
    $dictionary{$eng} = $rus;
}

untie %dictionary;

tie %dictionary, 'DB_File', 'dictionary.db', O_RDONLY, 0666, $DB_HASH
    or die "Cannot open dictionary.db: $!";

print "Dictionary created successfully with the following entries:\n";
foreach my $key (sort keys %dictionary) {
    my $value = $dictionary{$key};
    $value = decode('UTF-8', $value) unless Encode::is_utf8($value);
    print "$key => $value\n";
}

untie %dictionary; 