#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Encode qw(decode encode);

binmode(STDOUT, ":utf8");
print "Content-type: text/html; charset=utf-8\n\n";

my @translations;
if (open(my $fh, '<:utf8', 'translations.txt')) {
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
    <meta charset="UTF-8">
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
            <div class="navigation-buttons" style="margin-top: 20px;">
            <button onclick="window.location.href='/translate.html'" class="btn btn-secondary">
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M19 12H6M12 5l-7 7 7 7"></path></svg>
                Back to Translator
            </button>
            <button onclick="window.location.href='/dict_manage.html'" class="btn btn-secondary">
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 14.66V20a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h5.34"></path><polygon points="18 2 22 6 12 16 8 16 8 12 18 2"></polygon></svg>
                View Dictionary
            </button>
        </div>
        </p>
    </div>
</body>
</html>
}; 