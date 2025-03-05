#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use DB_File;
use Encode qw(decode encode);

binmode(STDOUT, ":utf8");
print "Content-type: text/plain; charset=utf-8\n\n";

my %dictionary;
tie %dictionary, 'DB_File', 'dictionary.db', O_RDONLY, 0666, $DB_HASH
    or die "Cannot open dictionary.db: $!";

print "\nDictionary Contents (Decoded):\n";
print "==============================\n";
foreach my $key (sort keys %dictionary) {
    my $value = decode('UTF-8', $dictionary{$key}, Encode::FB_CROAK);
    print "Key: '$key', Value: '$value'\n";
}

untie %dictionary; 