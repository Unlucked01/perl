#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use DB_File;
use POSIX qw(strftime);
use Encode qw(decode encode);
use CGI qw(:standard);

# Set output to UTF-8
binmode(STDOUT, ":utf8");
print "Content-type: text/plain; charset=utf-8\n\n";

# Use CGI to parse the input
my $q = CGI->new;
my $text = $q->param('text');
my $direction = $q->param('direction') || 'en2ru';

# Make sure text is properly decoded
$text = decode('UTF-8', $text) unless Encode::is_utf8($text);

# Debug output
print STDERR "Input: '$text', Direction: '$direction'\n";

my %dictionary;
tie %dictionary, 'DB_File', 'dictionary.db', O_RDONLY, 0666, $DB_HASH
    or die "Cannot open dictionary.db: $!";

my %reverse_dictionary;
while (my ($eng, $rus) = each %dictionary) {
    # Decode for reverse lookup
    my $decoded_rus = $rus;
    $decoded_rus = decode('UTF-8', $decoded_rus) unless Encode::is_utf8($decoded_rus);
    $reverse_dictionary{$decoded_rus} = $eng;
}

my @words = split(/\s+/, lc($text));
my @translated_words;
my $all_words_translated = 1;

foreach my $word (@words) {
    if ($direction eq 'en2ru' && exists $dictionary{$word}) {
        # Decode for display
        my $translation = $dictionary{$word};
        $translation = decode('UTF-8', $translation) unless Encode::is_utf8($translation);
        push @translated_words, $translation;
    }
    elsif ($direction eq 'ru2en' && exists $reverse_dictionary{$word}) {
        push @translated_words, $reverse_dictionary{$word};
    }
    else {
        push @translated_words, "$word";
        $all_words_translated = 0;
    }
}

my $translated_text = join(' ', @translated_words);
untie %dictionary;

if ($all_words_translated && @words > 0) {
    my $is_duplicate = 0;
    if (open(my $fh, '<:utf8', 'translations.txt')) {
        my $last_line = '';
        while (my $line = <$fh>) {
            $last_line = $line;
        }
        close $fh;
        
        if ($last_line =~ /^$text\t$translated_text\t/) {
            $is_duplicate = 1;
        }
    }
    
    if (!$is_duplicate) {
        my $timestamp = strftime("%Y-%m-%d %H:%M:%S", localtime);
        open(my $fh, '>>:utf8', 'translations.txt') or die "Could not open file: $!";
        print $fh "$text\t$translated_text\t$timestamp\n";
        close $fh;
    }
}

print $translated_text; 