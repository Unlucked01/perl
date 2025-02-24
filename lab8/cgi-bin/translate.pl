#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use DB_File;
use POSIX qw(strftime);

# Print HTTP headers
print "Content-type: text/plain; charset=utf-8\n\n";

# Read POST data
my $buffer;
read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
my ($text) = ($buffer =~ /text=([^&]+)/);
my ($direction) = ($buffer =~ /direction=([^&]+)/);
$direction ||= 'en2ru'; # Default to English to Russian
$text =~ tr/+/ /;
$text =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;

# Load dictionary
my %dictionary;
tie %dictionary, 'DB_File', 'dictionary.db', O_RDONLY, 0666, $DB_HASH
    or die "Cannot open dictionary.db: $!";

# Create reverse dictionary for Russian to English translation
my %reverse_dictionary;
while (my ($eng, $rus) = each %dictionary) {
    $reverse_dictionary{$rus} = $eng;
}

# Translate text
my @words = split(/\s+/, lc($text));
my @translated_words;
my $all_words_translated = 1;

foreach my $word (@words) {
    if ($direction eq 'en2ru' && exists $dictionary{$word}) {
        push @translated_words, $dictionary{$word};
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

# Save to history if all words were translated
if ($all_words_translated && @words > 0) {
    my $is_duplicate = 0;
    if (open(my $fh, '<', 'translations.txt')) {
        my $last_line = '';
        while (my $line = <$fh>) {
            $last_line = $line;
        }
        close $fh;
        
        if ($last_line =~ /^$text\t$translated_text\t/) {
            $is_duplicate = 1;
        }
    }
    
    # Only save if it's not a duplicate
    if (!$is_duplicate) {
        my $timestamp = strftime("%Y-%m-%d %H:%M:%S", localtime);
        open(my $fh, '>>', 'translations.txt') or die "Could not open file: $!";
        print $fh "$text\t$translated_text\t$timestamp\n";
        close $fh;
    }
}

print $translated_text; 