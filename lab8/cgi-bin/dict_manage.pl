#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use DB_File;

print "Content-type: text/html; charset=utf-8\n\n";

my %dictionary;
tie %dictionary, 'DB_File', 'dictionary.db', O_RDWR, 0666, $DB_HASH
    or die "Cannot open dictionary.db: $!";

# Handle form submissions
if ($ENV{'REQUEST_METHOD'} eq 'POST') {
    my $buffer;
    read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
    my %params;
    foreach my $pair (split(/&/, $buffer)) {
        my ($name, $value) = split(/=/, $pair);
        $value =~ tr/+/ /;
        $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
        $params{$name} = $value;
    }

    if ($params{action} eq 'add') {
        $dictionary{$params{eng_word}} = $params{rus_word};
    }
    elsif ($params{action} eq 'delete') {
        delete $dictionary{$params{eng_word}};
    }
}

# If it's a GET request, just return the dictionary table
print <<HTML;
<h3>Current Dictionary</h3>
<table border="1" style="width: 100%">
    <tr>
        <th>English</th>
        <th>Russian</th>
    </tr>
HTML

foreach my $eng_word (sort keys %dictionary) {
    print "<tr><td>$eng_word</td><td>$dictionary{$eng_word}</td></tr>\n";
}

print "</table>\n";

untie %dictionary; 