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

print qq{
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Translation History</title>
    <link rel="stylesheet" href="/css/style.css">
    <style>
        body {
            margin: 0;
            padding: 0;
            font-family: Arial, sans-serif;
            display: flex;
            min-height: 100vh;
            flex-direction: column;
        }
        
        .header {
            background-color: #2c3e50;
            color: white;
            text-align: center;
            padding: 15px;
            margin: 0;
        }
        
        .header h1 {
            margin: 0;
            color: white;
        }
        
        .main-content {
            display: flex;
            flex: 1;
        }
        
        .nav-menu {
            background-color: #34495e;
            width: 200px;
            padding: 15px;
        }
        
        .nav-menu ul {
            list-style: none;
            padding: 0;
            margin: 0;
        }
        
        .nav-menu li {
            margin: 15px 0;
        }
        
        .nav-menu a {
            color: white;
            text-decoration: none;
            display: block;
            padding: 8px 15px;
            border-radius: 4px;
        }
        
        .nav-menu a:hover {
            background-color: #2c3e50;
        }
        
        .content {
            flex: 1;
            padding: 20px;
        }
        
        .container {
            max-width: 800px;
            margin: 0 auto;
            background-color: white;
            border-radius: 5px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
            padding: 20px;
        }
        
        .btn {
            background-color: #3498db;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            transition: background-color 0.3s;
        }
        
        .btn:hover {
            background-color: #2980b9;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        
        th, td {
            padding: 10px;
            text-align: left;
            border: 1px solid #ddd;
        }
        
        th {
            background-color: #f2f2f2;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>Online Translation System</h1>
    </div>
    
    <div class="main-content">
        <div class="nav-menu">
            <ul>
                <li><a href="/translate.html">Translator</a></li>
                <li><a href="/dict_manage.html">Dictionary Management</a></li>
                <li><a href="/cgi-bin/history.pl">Translation History</a></li>
            </ul>
        </div>
        
        <div class="content">
            <div class="container">
                <h2>Translation History</h2>
                <table>
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
                <div class="navigation-buttons" style="margin-top: 20px; display: flex; justify-content: flex-start;">
                    <button onclick="window.location.href='/translate.html'" class="btn">
                        Back to Translator
                    </button>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
}; 