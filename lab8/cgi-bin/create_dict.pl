#!/usr/bin/perl
use strict;
use warnings;
use DB_File;

my %dictionary;
tie %dictionary, 'DB_File', 'dictionary.db', O_CREAT|O_RDWR, 0666, $DB_HASH
    or die "Cannot create dictionary.db: $!";

# Initial dictionary entries
$dictionary{'hello'} = 'привет';
$dictionary{'world'} = 'мир';
$dictionary{'thank'} = 'спасибо';
$dictionary{'you'} = 'тебе';
$dictionary{'good'} = 'хороший';
$dictionary{'day'} = 'день';

untie %dictionary; 