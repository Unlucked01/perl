#!/usr/bin/perl

my $win1251_chars = "\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF".
                    "\xF0\xF1\xF2\xF3\xF4\xF5\xF6\xF7\xF8\xF9\xFA\xFB\xFC\xFD\xFE\xFF".
                    "\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF".
                    "\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF";


my $koi8r_chars   = "\xC1\xC2\xD7\xC7\xC4\xC5\xD6\xDA\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0".
                    "\xD2\xD3\xD4\xD5\xC6\xC8\xC3\xDE\xDB\xDD\xDF\xD9\xD8\xDC\xC0\xD1".
                    "\xE1\xE2\xF7\xE7\xE4\xE5\xF6\xFA\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0".
                    "\xF2\xF3\xF4\xF5\xE6\xE8\xE3\xFE\xFB\xFD\xFF\xF9\xF8\xFC\xE0\xF1";

print "Выберите направление перекодировки:\n";
print "1. Windows-1251 -> KOI8-R\n";
print "2. KOI8-R -> Windows-1251\n";
print "Ваш выбор: ";
my $choice = <STDIN>;
chomp $choice;

print "Введите имя входного файла: ";
my $input_file = <STDIN>;
chomp $input_file;

print "Введите имя выходного файла: ";
my $output_file = <STDIN>;
chomp $output_file;

my ($from_chars, $to_chars);
if ($choice == 1) {
    open my $in, '<:raw:encoding(Windows-1251)', $input_file or die "Не удалось открыть входной файл: $input_file\n";
    open my $out, '>:raw:encoding(KOI8-R)', $output_file or die "Не удалось открыть выходной файл: $output_file\n";
    while (my $line = <$in>) {
        $line =~ tr/$win1251_chars/$koi8r_chars/;
        print $out $line;
    }
} elsif ($choice == 2) {
    open my $in, '<:raw:encoding(KOI8-R)', $input_file or die "Не удалось открыть входной файл: $input_file\n";
    open my $out, '>:raw:encoding(Windows-1251)', $output_file or die "Не удалось открыть выходной файл: $output_file\n";
    while (my $line = <$in>) {
        $line =~ tr/$koi8r_chars/$win1251_chars/;
        print $out $line;
    }
} else {
    die "Неверный выбор. Завершение программы.\n";
}

close $in;
close $out;

print "\nПерекодировка завершена. Результат сохранён в $output_file\n";
