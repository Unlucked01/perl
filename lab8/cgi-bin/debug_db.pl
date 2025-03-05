#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use DB_File;
use Encode qw(decode encode);

# Set output to UTF-8
binmode(STDOUT, ":utf8");
print "Content-type: text/plain; charset=utf-8\n\n";

my %dictionary;
tie %dictionary, 'DB_File', 'dictionary.db', O_RDONLY, 0666, $DB_HASH
    or die "Cannot open dictionary.db: $!";

print "Dictionary Contents:\n";
print "====================\n";
foreach my $key (sort keys %dictionary) {
    print "Key: '$key', Value: '$dictionary{$key}'\n";
}

untie %dictionary; 