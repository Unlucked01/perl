#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use DB_File;
use Encode qw(decode encode);
use CGI qw(:standard);

binmode(STDOUT, ":utf8");
print "Content-type: text/html; charset=utf-8\n\n";

my $q = CGI->new;
my %dictionary;
tie %dictionary, 'DB_File', 'dictionary.db', O_RDWR, 0666, $DB_HASH
    or die "Cannot open dictionary.db: $!";

my $search_term = $q->param('search') || '';
$search_term = lc($search_term);

if ($q->request_method eq 'POST') {
    my $action = $q->param('action');
    my $eng_word = $q->param('eng_word');
    
    if ($action eq 'add' && $eng_word) {
        my $rus_word = $q->param('rus_word');
        $rus_word = encode('UTF-8', $rus_word) if Encode::is_utf8($rus_word);
        $dictionary{$eng_word} = $rus_word;
    }
    elsif ($action eq 'delete' && $eng_word) {
        delete $dictionary{$eng_word};
    }
}

print <<HTML;
<table id="dictionary-table">
    <tr>
        <th>English</th>
        <th>Russian</th>
        <th>Actions</th>
    </tr>
HTML

my @filtered_keys;
if ($search_term) {
    foreach my $eng_word (keys %dictionary) {
        my $rus_word = $dictionary{$eng_word};
        $rus_word = decode('UTF-8', $rus_word) unless Encode::is_utf8($rus_word);
        
        if (lc($eng_word) =~ /$search_term/ || lc($rus_word) =~ /$search_term/) {
            push @filtered_keys, $eng_word;
        }
    }
} else {
    @filtered_keys = keys %dictionary;
}

if (@filtered_keys == 0) {
print <<HTML;
<tr>
    <td colspan="3" style="text-align: center; padding: 20px;">No entries found</td>
</tr>
HTML
} else {
    foreach my $eng_word (sort @filtered_keys) {
        my $rus_word = $dictionary{$eng_word};
        $rus_word = decode('UTF-8', $rus_word) unless Encode::is_utf8($rus_word);
        
        my $safe_eng = $eng_word;
        $safe_eng =~ s/&/&amp;/g;
        $safe_eng =~ s/</&lt;/g;
        $safe_eng =~ s/>/&gt;/g;
        $safe_eng =~ s/"/&quot;/g;
        
        print <<HTML;
<tr>
    <td><strong>$safe_eng</strong></td>
    <td>$rus_word</td>
    <td>
        <button class="delete-btn" onclick="deleteWord('$safe_eng')" title="Delete '$safe_eng'">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path><line x1="10" y1="11" x2="10" y2="17"></line><line x1="14" y1="11" x2="14" y2="17"></line></svg>
        </button>
    </td>
</tr>
HTML
    }
}

print "</table>\n";

my $count = scalar @filtered_keys;
my $total = scalar keys %dictionary;
if ($search_term && $count != $total) {
    print "<p style='margin-top: 10px; text-align: right;'>Showing $count of $total entries</p>\n";
}

untie %dictionary; 