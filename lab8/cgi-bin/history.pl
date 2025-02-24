#!/usr/bin/perl
use strict;
use warnings;
use utf8;

# Print HTTP headers
print "Content-type: text/html; charset=utf-8\n\n";

# Read translation history from file
my @translations;
if (open(my $fh, '<', 'translations.txt')) {
    while (my $line = <$fh>) {
        chomp $line;
        my ($source_text, $translated_text, $timestamp) = split(/\t/, $line);
        push @translations, {
            source => $source_text,
            translated => $translated_text,
            time => $timestamp
        };
    }
    close $fh;
}

# Generate HTML
print qq{
<!DOCTYPE html>
<html>
<head>
    <title>Translation History</title>
    <link rel="stylesheet" href="/css/style.css">
</head>
<body>
    <div class="container">
        <h2>Translation History</h2>
        <table border="1" style="width: 100%">
            <tr>
                <th>Original Text</th>
                <th>Translated Text</th>
                <th>Time</th>
            </tr>
};

# Print translation history
foreach my $trans (reverse @translations) {
    print "<tr>\n";
    print "<td>$trans->{source}</td>\n";
    print "<td>$trans->{translated}</td>\n";
    print "<td>$trans->{time}</td>\n";
    print "</tr>\n";
}

print qq{
        </table>
        <p>
            <button onclick="window.location.href='/translate.html'" class="btn">Back to Translator</button>
            <button onclick="window.location.href='/dict_manage.html'" class="btn">Manage Dictionary</button>
        </p>
    </div>
</body>
</html>
}; 