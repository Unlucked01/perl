package SpellCheck;

use strict;
use warnings;
use Dictionary;

sub new {
    my ($class, $dict_file) = @_;
    
    my $self = {
        dictionary => Dictionary->new($dict_file),
    };
    
    bless $self, $class;
    return $self;
}

sub check_text {
    my ($self, $text) = @_;
    
    my @words = $self->extract_words($text);
    my %results;
    
    foreach my $word (@words) {
        next if $word =~ /^\d+$/; # Пропускаем числа
        next if length($word) < 2; # Пропускаем короткие слова
        
        if (!$self->{dictionary}->exists($word)) {
            my @suggestions = $self->{dictionary}->find_similar($word);
            $results{$word} = \@suggestions if @suggestions;
        }
    }
    
    return \%results;
}

sub extract_words {
    my ($self, $text) = @_;
    
    # Разбиваем текст на слова, удаляя знаки препинания
    my @words = $text =~ /([а-яА-Яa-zA-Z]+)/g;
    
    return @words;
}

sub check_file {
    my ($self, $file_path) = @_;
    
    open my $fh, '<:encoding(UTF-8)', $file_path or die "Не удалось открыть файл $file_path: $!";
    my $text = do { local $/; <$fh> };
    close $fh;
    
    return $self->check_text($text);
}

sub apply_corrections {
    my ($self, $text, $corrections) = @_;
    
    foreach my $word (keys %$corrections) {
        my $correction = $corrections->{$word};
        next unless $correction; # Пропускаем, если нет исправления
        
        # Заменяем слово на исправленное, сохраняя регистр
        if ($word =~ /^[А-ЯA-Z]/) {
            # Если первая буква заглавная
            my $first_char = substr($correction, 0, 1);
            my $rest = substr($correction, 1);
            $correction = uc($first_char) . $rest;
        }
        
        $text =~ s/\b$word\b/$correction/g;
    }
    
    return $text;
}

sub save_corrected_text {
    my ($self, $text, $file_path) = @_;
    
    open my $fh, '>:encoding(UTF-8)', $file_path or die "Не удалось открыть файл $file_path для записи: $!";
    print $fh $text;
    close $fh;
    
    return 1;
}

1; 